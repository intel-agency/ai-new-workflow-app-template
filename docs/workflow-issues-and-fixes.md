# Workflow Issues & Remediation Plan

> **Sources analyzed:**
>
> - [yankee89-b repo](https://github.com/intel-agency/workflow-orchestration-queue-yankee89-b) — actions, issues, labels, projects, pull requests
> - [foxtrot54 PR #1](https://github.com/intel-agency/workflow-orchestration-queue-foxtrot54/pull/1) — all review comments (Codex + Gemini)
> - Local template files: `.github/.labels.json`, `orchestrator-agent.yml`, `orchestrator-agent-prompt.md`, `import-labels.ps1`, `ai-dynamic-workflows.md`
>
> **Date:** 2026-03-21

---

## Issue Summary

| # | Issue | Severity | Location | Category |
|---|-------|----------|----------|----------|
| 1 | `issues: labeled` trigger is commented out in workflow YAML | **P0 – Blocker** | `.github/workflows/orchestrator-agent.yml` | Orchestrator Workflow |
| 2 | Template `.labels.json` missing all `agent:*` and workflow labels | **P0 – Blocker** | `.github/.labels.json` | Labels / Template |
| 3 | No PR created in yankee89-b despite 1h12m orchestrator run | **P1 – Critical** | yankee89-b repo | Project Setup Workflow |
| 4 | No GitHub Project created in yankee89-b | **P1 – Critical** | yankee89-b repo | Project Setup Workflow |
| 5 | Label set incomplete in yankee89-b (17 vs 24 needed) | **P1 – Critical** | yankee89-b labels | Labels |
| 6 | Sentinel claim markers block reclaim after restart (30-min stale timeout) | **P1 – Critical** | `src/osapow/sentinel/orchestrator.py` | Orchestrator Code |
| 7 | `SENTINEL_BOT_LOGIN` not validated at startup | **P1 – Critical** | `src/osapow/sentinel/orchestrator.py` | Orchestrator Code |
| 8 | Incomplete label cleanup during requeue | **P2 – Medium** | `src/osapow/queue/github_queue.py` | Queue / Labels |
| 9 | `GITHUB_TOKEN` not validated in notifier `create_app()` | **P2 – Medium** | `src/osapow/notifier/service.py` | Notifier Service |
| 10 | Docker COPY order breaks editable install | **P2 – Medium** | `Dockerfile` | Infrastructure |
| 11 | Healthcheck uses `curl` instead of Python | **P2 – Medium** | `docker-compose.yml` | Infrastructure |
| 12 | `verify_signature()` silent on missing WEBHOOK_SECRET | **P2 – Medium** | `src/osapow/notifier/service.py` | Security |
| 13 | Missing `issue_comment.created` action handling | **P2 – Medium** | `src/osapow/notifier/service.py` | Webhook Events |
| 14 | Missing `pull_request_review` event support | **P2 – Medium** | `src/osapow/notifier/service.py` | Webhook Events |
| 15 | `pyproject.toml` entry point uses async — needs sync wrapper | **P2 – Medium** | `pyproject.toml` | Packaging |
| 16 | Traycerai bot edits trigger redundant orchestrator runs | **P3 – Low** | yankee89-b actions | Workflow Triggering |
| 17 | `.labels.json` URLs point to `nam20485/AgentAsAService` (stale source) | **P3 – Low** | `.github/.labels.json` | Template Hygiene |

---

## Detailed Issues & Proposed Solutions

---

### Issue 1: `issues: labeled` trigger is commented out in workflow YAML

**Location:** `.github/workflows/orchestrator-agent.yml`, line 4

**Description:**
The orchestrator workflow only triggers on `issues: [opened]`. The `labeled` event type is commented out. However, the orchestrator prompt's match clauses rely heavily on `labeled` events:

- `case (action = labeled && labels contains: "implementation:ready" && title contains: "Complete Implementation")` — drives the Epic cascade
- `case (action = labeled && labels contains: "implementation:ready" && title contains: "Epic")` — drives Epic implementation
- `case (action = labeled && labels contains: "implementation:complete" && title contains: "Epic")` — drives next-Epic creation

**Impact:** The entire self-bootstrapping cascade (Epic creation → Epic implementation → next Epic) **cannot function**. The orchestrator can only react to issue opens and workflow_run completions.

**Proposed Solutions:**

| Option | Description | Pros | Cons |
|--------|-------------|------|------|
| **A (Recommended)** | Uncomment `labeled` in the issues trigger: `types: [opened, labeled]` | Enables full cascade; minimal change | May trigger on unrelated label additions; needs guard logic in prompt |
| B | Add a separate workflow for label events with its own filter | Separation of concerns | More files to maintain; duplicates infra |
| C | Switch to `issue_comment` dispatch model (agent posts command comments) | Avoids label-trigger noise | Requires rewriting all prompt clauses; bigger refactor |

**Recommended fix:**

```yaml
on:
  issues:
    types: [opened, labeled]
```

Add a condition in the job to skip runs for labels that aren't workflow-relevant (e.g., only proceed if the label is `implementation:ready` or `implementation:complete`).

---

### Issue 2: Template `.labels.json` missing all `agent:*` and workflow labels

**Location:** `.github/.labels.json`

**Description:**
The template's labels file is a snapshot from `nam20485/AgentAsAService` and contains only 15 labels (GitHub defaults + `assigned`, `state:*`, `type:enhancement`). It is missing the OS-APOW workflow labels that the orchestrator state machine depends on:

**Missing labels:**
- `agent:queued` — Tasks waiting for agent
- `agent:in-progress` — Tasks being processed by agent
- `agent:success` — Successfully completed tasks
- `agent:error` — Tasks that failed
- `agent:infra-failure` — Infrastructure failures
- `agent:stalled-budget` — Budget exceeded (deferred)
- `implementation:complete` — Marks completed epics
- `epic` — Epic-level issues
- `story` — Story-level issues

**Evidence:** foxtrot54 repo has 24 labels (agent added them during project-setup). yankee89-b has only 17 (agent did NOT add them → broken state machine).

**Proposed Solutions:**

| Option | Description | Pros | Cons |
|--------|-------------|------|------|
| **A (Recommended)** | Add all required labels to `.github/.labels.json` in the template | Every new repo starts correct; single source of truth | Must keep in sync with orchestrator prompt |
| B | Have `import-labels.ps1` merge from a second "workflow-labels.json" file | Separates base labels from workflow labels | Two files to manage |
| C | Have the project-setup workflow create labels via `gh label create` on the fly | No template change needed | Non-deterministic; varies per run |

**Recommended fix:** Add the following entries to `.github/.labels.json`:

```json
{"name": "agent:queued",       "color": "0e8a16", "description": "Tasks waiting for agent"},
{"name": "agent:in-progress",  "color": "fbca04", "description": "Tasks being processed by agent"},
{"name": "agent:success",      "color": "0e8a16", "description": "Successfully completed tasks"},
{"name": "agent:error",        "color": "d73a4a", "description": "Tasks that failed"},
{"name": "agent:infra-failure","color": "b60205", "description": "Infrastructure failures"},
{"name": "agent:stalled-budget","color": "e99695","description": "Budget limit reached"},
{"name": "implementation:complete","color":"0e8a16","description":"Implementation completed"},
{"name": "epic",               "color": "3E4B9E", "description": "Epic-level issues"},
{"name": "story",              "color": "7057ff", "description": "Story-level issues"}
```

Also remove the stale `id`, `node_id`, and `url` fields that point to `nam20485/AgentAsAService` — `import-labels.ps1` only needs `name`, `color`, and `description`.

---

### Issue 3: No PR created in yankee89-b despite 1h12m orchestrator run

**Location:** yankee89-b repository — 0 open/closed PRs

**Description:**
The orchestrator-agent #2 ran for 1h 12m 47s and completed successfully, but the repo has 0 pull requests. The workflow plan specifies that `init-existing-repository` (Assignment 1) should create a `dynamic-workflow-project-setup` branch and a PR.

The orchestrator ran due to the `workflow_run` trigger (prebuild devcontainer completed), entered the `project-setup` dynamic workflow, but the agent appears to have only produced a workflow plan document (`plan_docs/workflow-plan.md`) without proceeding to actual repo initialization.

**Proposed Solutions:**

| Option | Description | Pros | Cons |
|--------|-------------|------|------|
| **A (Recommended)** | Fix the project-setup workflow to explicitly create the branch and PR as its first action, before proceeding to planning docs | Ensures critical infra is created early | Requires workflow script update |
| B | Add pre-flight validation in orchestrator that checks for branch/PR existence after each assignment | Catches failures; enables retry | More complex; post-hoc |
| C | Make `init-existing-repository` a mandatory non-skippable step with explicit failure if PR creation fails | Hard guarantee | May block other assignments |

**Root cause hypothesis:** The agent created the workflow plan but either (a) hit an error during PR creation that it silently swallowed, or (b) the `project-setup` workflow's `init-existing-repository` assignment was never reached because the orchestrator interpreted the `workflow_run` event data and stopped after the planning step.

**Recommended:** Investigate the full orchestrator agent log (requires authenticated access to Actions run #2). Also ensure the project-setup workflow has explicit "create PR" steps with error handling that surfaces failures.

---

### Issue 4: No GitHub Project created in yankee89-b

**Location:** yankee89-b repository — 0 projects

**Description:**
The workflow plan's Assignment 1 (`init-existing-repository`) specifies creating a GitHub Project (Board template) linked to the repository with columns: Not Started, In Progress, In Review, Done. No project exists.

Contrast with foxtrot54 which successfully created a project: "workflow-orchestration-queue-foxtrot54" (org project #6).

**Proposed Solutions:**

| Option | Description | Pros | Cons |
|--------|-------------|------|------|
| **A (Recommended)** | Add project creation as a scripted step in `trigger-project-setup.ps1` or a new `create-project.ps1` script | Deterministic; runs outside agent | Requires API permissions (org:project scope) |
| B | Keep it as an agent task but add explicit retry + validation | Agent handles it; less scripting | Subject to agent hallucination/failure |
| C | Make project creation a separate workflow step (GitHub Action) that runs before the orchestrator | Guaranteed by CI | More workflow complexity |

**Recommended:** Create a `scripts/create-project.ps1` that uses `gh project create` and `gh project link` with proper error handling. Call it from `trigger-project-setup.ps1`.

---

### Issue 5: Label set incomplete in yankee89-b (17 vs 24 needed)

**Location:** yankee89-b labels page

**Description:**
yankee89-b has 17 labels. foxtrot54 has 24 labels. The difference includes the `agent:*` state machine labels and `epic`/`story` taxonomy labels. The orchestrator cannot transition issues through the state machine without these labels.

**Current yankee89-b labels (17):** `assigned`, `assigned:copilot`, `bug`, `documentation`, `duplicate`, `enhancement`, `good first issue`, `help wanted`, `implementation:ready`, `invalid`, `planning`, `question`, `state`, `state:in-progress`, `state:planning`, `type:enhancement`, `wontfix`

**Missing (needed):** `agent:queued`, `agent:in-progress`, `agent:success`, `agent:error`, `agent:infra-failure`, `epic`, `story`

**This is a direct consequence of Issue 2** (template `.labels.json` incomplete). See Issue 2 for fix.

**Additional fix needed for yankee89-b specifically:** Run `import-labels.ps1` against the repo after updating `.labels.json`, or manually create the missing labels.

---

### Issue 6: Sentinel claim markers block reclaim after restart

**Location:** `src/osapow/sentinel/orchestrator.py` (foxtrot54 codebase, produced by project-setup)

**Description:**
Per Codex review: `_cleanup()` now requeues the active task back to `agent:queued` on shutdown, but `GitHubQueue.claim_task()` still treats another sentinel's `<!-- sentinel-claim: ... -->` comment as authoritative until `claim_stale_timeout_secs` expires (30 minutes by default). Because `main()` generates a new sentinel ID on every restart, the replacement process will refuse to reclaim the just-requeued task for up to 30 minutes.

**Proposed Solutions:**

| Option | Description | Pros | Cons |
|--------|-------------|------|------|
| **A (Recommended)** | On shutdown, delete the sentinel claim comment (or edit it to mark it expired) in addition to requeuing | Clean state on restart | Extra API call during shutdown |
| B | Allow sentinels to claim tasks even with existing claim markers if the task has `agent:queued` label | Faster recovery | Risk of dual-claim if cleanup races |
| C | Use a persistent sentinel ID (stored in a file or env var) so restarts reuse the same ID | Avoids the problem entirely | Adds state management complexity |

---

### Issue 7: `SENTINEL_BOT_LOGIN` not validated at startup

**Location:** `src/osapow/sentinel/orchestrator.py`, `main()` function

**Description:**
Per Codex review: `main()` only validates `GITHUB_TOKEN`, `GITHUB_ORG`, and `GITHUB_REPO` before constructing the orchestrator. If `SENTINEL_BOT_LOGIN` is blank, `GitHubQueue.claim_task()` skips the entire assign-and-verify branch (`if bot_login:`), allowing multiple sentinel processes to label-claim and execute the same queued issue in parallel.

**Proposed Solutions:**

| Option | Description | Pros | Cons |
|--------|-------------|------|------|
| **A (Recommended)** | Add `SENTINEL_BOT_LOGIN` to the required env var check and `sys.exit(1)` if missing | Fail-fast; prevents silent dual-execution | Breaking change if some deployments don't set it |
| B | Default to the authenticated user's login via `gh api /user` | Auto-discovers; no config needed | Extra API call; may fail |

---

### Issue 8: Incomplete label cleanup during requeue

**Location:** `src/osapow/queue/github_queue.py`, `requeue_with_feedback()`

**Description:**
Per Codex review: `handle_github_webhook()` sends retries from `agent:reconciling`, `agent:infra-failure`, and `agent:stalled-budget` into `requeue_with_feedback()`, but this helper only deletes `agent:success`, `agent:error`, and `agent:in-progress`. Requeueing from any of the other states leaves `agent:queued` alongside the old terminal label, creating contradictory state.

**Proposed Solutions:**

| Option | Description | Pros | Cons |
|--------|-------------|------|------|
| **A (Recommended)** | Add all `agent:*` labels to the cleanup list in `requeue_with_feedback()` | Complete cleanup; consistent state | None significant |
| B | Create a `remove_all_agent_labels()` helper called by all state transitions | DRY; used everywhere | Slightly more refactoring |

---

### Issue 9: `GITHUB_TOKEN` not validated in notifier `create_app()`

**Location:** `src/osapow/notifier/service.py`, `create_app()` function

**Description:**
Per Codex review: `create_app()` always constructs `GitHubQueue` from `os.environ.get("GITHUB_TOKEN", "")`, and the health endpoint stays green even when that value is empty. The notifier accepts and verifies webhooks but every later call to `add_to_queue()` / `requeue_with_feedback()` fails at runtime.

**Recommended fix:** Validate `GITHUB_TOKEN` is non-empty at app startup; return a degraded health status if not configured.

---

### Issue 10: Docker COPY order breaks editable install

**Location:** `Dockerfile`

**Description:**
Per Codex review: `COPY src/ ./src/` must come before `uv pip install -e .` for the editable install to find the package source.

**Recommended fix:** Reorder Dockerfile to COPY source before install.

---

### Issue 11: Healthcheck uses `curl` instead of Python

**Location:** `docker-compose.yml`

**Description:**
Per Codex review: The container doesn't include `curl`. Use a Python-based urllib healthcheck instead: `python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/health')"`.

**Recommended fix:** Replace `curl` healthcheck with Python-based check.

---

### Issue 12: `verify_signature()` silent on missing WEBHOOK_SECRET

**Location:** `src/osapow/notifier/service.py`

**Description:**
Per Codex review: If `WEBHOOK_SECRET` is not configured, signature verification silently passes, allowing any payload to be accepted.

**Recommended fix:** Raise an error or return 500 if `WEBHOOK_SECRET` is not set when a webhook arrives with an `X-Hub-Signature-256` header.

---

### Issue 13: Missing `issue_comment.created` action handling

**Location:** `src/osapow/notifier/service.py`

**Description:**
Per Codex review: The webhook handler didn't handle the `created` action for `issue_comment` events, only `edited`.

**Recommended fix:** Add `created` to the handled actions for `issue_comment`.

---

### Issue 14: Missing `pull_request_review` event support

**Location:** `src/osapow/notifier/service.py`

**Description:**
Per Codex review: `pull_request_review` events (submitted, edited) were not handled by the webhook receiver.

**Recommended fix:** Add `pull_request_review` event type handling.

---

### Issue 15: `pyproject.toml` entry point uses async — needs sync wrapper

**Location:** `pyproject.toml`

**Description:**
Per Codex review: Console script entry points must be synchronous functions. The entry point was pointing to an async function.

**Recommended fix:** Create a `run_main()` synchronous wrapper that calls `asyncio.run(main())` and point the entry point there.

---

### Issue 16: Traycerai bot edits trigger redundant orchestrator runs

**Location:** yankee89-b Actions tab

**Description:**
Orchestrator-agent runs #3-#6 were triggered by `traycerai` bot editing its comment on Issue #1. Each edit re-triggers the `issue_comment` workflow (if enabled), causing redundant runs.

**Proposed Solutions:**

| Option | Description | Pros | Cons |
|--------|-------------|------|------|
| **A (Recommended)** | Add `if: github.actor != 'traycerai[bot]'` condition to the workflow job | Prevents bot loops | Must maintain actor exclusion list |
| B | Ignore `edited` events for `issue_comment`, only react to `created` | Reduces noise | May miss legitimate edits |

---

### Issue 17: `.labels.json` URLs point to `nam20485/AgentAsAService`

**Location:** `.github/.labels.json`

**Description:**
The labels file was exported from a different repo (`nam20485/AgentAsAService`). The `id`, `node_id`, and `url` fields reference that repo. While `import-labels.ps1` only uses `name`, `color`, and `description`, the stale metadata is confusing.

**Recommended fix:** Strip `id`, `node_id`, and `url` fields from `.labels.json`, keeping only `name`, `color`, and `description`.

---

## Priority Fix Order

### Phase 1 — Unblock the orchestrator cascade (P0)

1. **Uncomment `labeled` trigger** in `orchestrator-agent.yml` (Issue 1)
2. **Add all required labels** to `.github/.labels.json` (Issue 2 + 5)
3. **Clean up stale metadata** in `.labels.json` (Issue 17)

### Phase 2 — Fix project-setup reliability (P1)

1. **Investigate yankee89-b orchestrator logs** to determine why no PR/project was created (Issue 3 + 4)
2. **Script project creation** as a deterministic step (Issue 4)
3. **Add bot-actor exclusion** to prevent traycerai edit loops (Issue 16)

### Phase 3 — Harden sentinel/notifier (P1-P2, apply to generated code)

1. **Validate `SENTINEL_BOT_LOGIN`** at startup (Issue 7)
2. **Delete claim markers** on shutdown (Issue 6)
3. **Complete label cleanup** in `requeue_with_feedback()` (Issue 8)
4. **Validate `GITHUB_TOKEN`** in notifier startup (Issue 9)
5. **Fix `WEBHOOK_SECRET` validation** (Issue 12)

### Phase 4 — Infrastructure & packaging (P2)

1. **Fix Docker COPY order** (Issue 10)
2. **Fix healthcheck** (Issue 11)
3. **Fix entry point** (Issue 15)
4. **Add missing event handlers** (Issues 13, 14)
