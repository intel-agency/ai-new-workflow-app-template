# `project-setup` Orchestration Incomplete — Forensic Report

> **Date:** 2026-04-02
>
> **Scope:** Workflow run — single orchestrator-agent execution on `intel-agency/workflow-orchestration-service-yankee60`
>
> **Affected targets:** `intel-agency/workflow-orchestration-service-yankee60`, workflow `orchestrator-agent`, run [23878622026](https://github.com/intel-agency/workflow-orchestration-service-yankee60/actions/runs/23878622026), issue [#1](https://github.com/intel-agency/workflow-orchestration-service-yankee60/issues/1)
>
> **Pattern confirmed:** N/A — single run; no cross-run pattern to test (first and only orchestrator run on this repo)

---

## 1. Executive Summary

The orchestrator agent was triggered on `workflow-orchestration-service-yankee60` by issue #1 (label `orchestration:dispatch`, body `/orchestrate-dynamic-workflow $workflow_name = project-setup`). The GitHub Actions job concluded `success` — no infrastructure failure occurred. However, the agent posted an ❌ comment on the issue reporting that the `project-setup` workflow execution was **incomplete: 0 of 6 workflow assignments executed**.

The agent's self-reported root cause was a **template vs. instance context mismatch**: it classified the repository as a GitHub template repository rather than a seeded project instance.

The GitHub API `is_template` flag on the repo is `false` — correctly reflecting that this is a clone, not the upstream template. The agent did **not** misread the API. Instead, the agent read `AGENTS.md` (which is checked out and present in every run), where the `<template_usage><summary>` section explicitly states:

> *"This repository is a **GitHub template repo** (`intel-agency/workflow-orchestration-service-yankee60`)."*

The creation script replaced the placeholder repo name inside that sentence but left the **"GitHub template repo"** label text intact. The agent read that sentence, correctly acted on what it was told, and refused to execute `project-setup` — which the instructions elsewhere describe as intended for clones, not the template. The agent behaved correctly given the instructions it received. The instructions were wrong.

**Root cause in one sentence:** The `AGENTS.md` `<template_usage>` section is not updated by the creation script when a clone is produced, leaving every clone with text that identifies itself as the template.

**Recommended fix:** Update the creation script (`create-repo-with-plan-docs.ps1`) to rewrite the `<template_usage><summary>` block in `AGENTS.md` after cloning — replacing the "GitHub template repo" label with language appropriate to a project instance. Alternatively, restructure the `AGENTS.md` template so this block is a placeholder that gets replaced cleanly.

---

## 2. Forensic Evidence

### 2.1 Failure Inventory

| # | Repo / Workflow | Run ID | Date (UTC) | Stage Reached | Last Meaningful Output | Duration | Exit / Result |
|---|----------------|--------|------------|---------------|------------------------|----------|---------------|
| 1 | `workflow-orchestration-service-yankee60` / `orchestrator-agent` | [23878622026](https://github.com/intel-agency/workflow-orchestration-service-yankee60/actions/runs/23878622026) | 2026-04-02T01:06:41Z | Agent executed; dispatch clause parsed; project-setup analysis complete | ❌ comment on issue #1: "0 of 6 assignments executed" | ~11m 22s | CI: `success`; semantic: incomplete |

For completeness, all workflow runs on this repo:

| # | Workflow | Run ID | Date (UTC) | Trigger | Conclusion |
|---|----------|--------|------------|---------|------------|
| 1 | `validate` | [23878618068](https://github.com/intel-agency/workflow-orchestration-service-yankee60/actions/runs/23878618068) | 2026-04-02T01:06:32Z | push (Initial commit) | success |
| 2 | `CodeQL Setup` | [23878619009](https://github.com/intel-agency/workflow-orchestration-service-yankee60/actions/runs/23878619009) | 2026-04-02T01:06:34Z | dynamic | success |
| 3 | `validate` | [23878620021](https://github.com/intel-agency/workflow-orchestration-service-yankee60/actions/runs/23878620021) | 2026-04-02T01:06:37Z | push (Seed commit) | success |
| 4 | `orchestrator-agent` | [23878622026](https://github.com/intel-agency/workflow-orchestration-service-yankee60/actions/runs/23878622026) | 2026-04-02T01:06:41Z | issues (labeled) | **success** (CI); **incomplete** (semantic) |

### 2.2 Issue #1 Comment Timeline (chronological evidence)

| Time (UTC) | Actor | Comment (condensed) |
|------------|-------|---------------------|
| 2026-04-02T01:12:31Z | nam20485 (orchestrator) | 🤖 "Orchestrator triggered — invoking `project-setup` dynamic workflow..." |
| 2026-04-02T01:13:31Z | nam20485 (orchestrator) | 🤖 "Orchestrator triggered — matched `orchestration:dispatch` clause. Parsing dispatch body..." |
| 2026-04-02T01:17:21Z | nam20485 (orchestrator) | ❌ "`project-setup` workflow execution incomplete. Root Cause: This repository is a GitHub template repository... Assignments executed: 0 of 6. Critical barriers identified: Requires multi-agent delegation, template vs. instance context mismatch." |

The ~6-minute gap between run start (01:06:41Z) and first comment (01:12:31Z) is consistent with devcontainer pull, start, and opencode server boot time under normal conditions.

The ~4-minute gap between the second comment (01:13:31Z) and the final failure comment (01:17:21Z) represents the agent's analysis and decision phase.

### 2.3 Exceptions / Non-Matching Cases

- No prior orchestrator runs exist on this repo — this is the **first and only run**. There is no baseline to compare against.
- The `validate` workflow (runs 1 and 2 on push) succeeded cleanly, confirming the CI infrastructure and lint/scan/test pipeline are healthy.
- The `CodeQL Setup` run succeeded, confirming GitHub Advanced Security setup completed normally.
- No permissions failures, missing image errors, or timeout annotations are present in the run conclusion or visible from run metadata.

### 2.4 Success / Baseline Context

- **Infrastructure**: 100% success (3/3 non-orchestration runs succeeded). The devcontainer image was available, validation passed, and CodeQL was configured.
- **Orchestration trigger**: 100% of the routing logic worked — the `orchestration:dispatch` label was correctly matched, the dispatch body was parsed, and the `project-setup` command was identified.
- **Execution outcome**: 0% — zero of six planned assignments were executed. The agent chose to exit rather than attempt delegation.
- **CI vs. semantic mismatch**: The GitHub Actions job reported `success`, but the agent's output was effectively a no-op with a diagnostic explanation. This creates a silent failure pattern where CI green does not confirm work was done.

---

## 3. Root Cause Analysis

### 3.1 Immediate Cause

The orchestrator agent determined it was operating on a "template repository (not a project instance)" and refused to proceed with multi-agent delegation for the `project-setup` workflow. It exited cleanly (exit 0), so GitHub Actions reported success.

### 3.2 Mechanism

1. Issue #1 was created with label `orchestration:dispatch` on repo `workflow-orchestration-service-yankee60` at 2026-04-02T01:06:38Z — approximately 11 seconds after repo creation via the automation pipeline.
2. The `orchestrator-agent` workflow triggered on the `issues:labeled` event and started at 2026-04-02T01:06:41Z.
3. The devcontainer was started and the opencode server was launched (the ~6-minute setup phase is consistent with warm-runner devcontainer startup).
4. The agent matched the `orchestration:dispatch` clause and parsed the dispatch body: command = `orchestrate-dynamic-workflow`, `$workflow_name = project-setup`.
5. The agent retrieved and analyzed the workflow definition (`project-setup`). It concluded the target is designed to execute on **clones** of the template — a multi-agent project-setup pipeline.
6. The agent evaluated the execution context and classified this repo as a "template repository," concluding the required multi-agent delegation could not proceed.
7. The agent posted an ❌ diagnostic comment and exited 0. GitHub Actions recorded `success`.

### 3.3 Why This Area Is Fragile

**AGENTS.md is agent-readable source of truth — and it says the wrong thing in clones**: Every clone produced by the creation pipeline inherits `AGENTS.md` from the template. The `<template_usage><summary>` block reads:

```xml
<summary>
  This repository is a **GitHub template repo**
  (`intel-agency/workflow-orchestration-service-yankee60`).
  New project repositories are created from it using automation scripts...
</summary>
```

The creation script (`create-repo-with-plan-docs.ps1`) performs two text substitutions across all files:
- `ai-new-workflow-app-template` → new repo name
- `intel-agency` → new owner

Neither substitution touches the phrase **"GitHub template repo"**. The repo name inside the parentheses gets updated correctly, but the label before it does not. The AGENTS.md in yankee60 therefore identifies itself as the template, which the orchestrator reads as an authoritative self-description.

The `<template-clone-instances>` note immediately below says *"Once the template has been cloned into a new instance, this file must be updated to match the new repo's specifics"* — but the automation never performs this update.

**Secondary issue — `plan_docs/` spec filename mismatch**: The `create-workflow-plan` assignment's prerequisites list `new app spec.md` or `ai-new-app-template.md` as the expected primary spec filename. The actual file in yankee60 is `OS-APOW Implementation Specification v1.2.md`. The assignment says "or the closest equivalent", so this is a soft risk rather than a hard blocker, but it adds friction to the `pre-script-begin` event execution.

**CI success masking semantic failure**: The orchestrator exiting 0 after a no-op produces a CI-green run that delivered zero work. Without reading issue comments, the run appears successful.

### 3.4 Confidence Notes

- **Directly confirmed**: `is_template` API flag is `false` — the API correctly identifies this as a non-template repo. This was **not** the cause.
- **Directly observed**: AGENTS.md in the clone (fetched from `raw.githubusercontent.com`) contains the exact text *"This repository is a **GitHub template repo**"* in the `<template_usage><summary>` section.
- **Directly observed**: The repo contains OS-APOW plan docs, confirming it is a seeded project clone.
- **Directly observed**: Three issue comments showing the agent executed, parsed the dispatch, analyzed context, and reported a context-mismatch conclusion citing "Template repository (not a project instance)."
- **Well-supported inference**: The agent read AGENTS.md, found the "GitHub template repo" label, and acted on it. This matches the agent's reported conclusion exactly.

---

## 4. Solutions with Pros/Cons

### Solution A: Fix `AGENTS.md` in the existing clone and re-trigger *(unblocks yankee60 immediately)*

**Change:** Edit the `<template_usage><summary>` block in `workflow-orchestration-service-yankee60`'s `AGENTS.md` to replace the "GitHub template repo" label with language appropriate to a project instance. Commit directly to `main` (non-code change; no branch protection concern). Re-trigger the dispatch.

| Pros | Cons |
|------|------|
| Immediately unblocks this specific repo | One-off manual fix; doesn't prevent recurrence on future clones |
| Zero script changes needed; surgical, reversible | Must be done per-clone if automation isn't also fixed |
| Fully confirms the hypothesis when the re-trigger succeeds | |

**Implementation notes:**

Change the `<template_usage><summary>` from:

```xml
<summary>
  This repository is a **GitHub template repo**
  (`intel-agency/workflow-orchestration-service-yankee60`).
  New project repositories are created from it...
</summary>
```

To:

```xml
<summary>
  This repository is a **project instance** cloned from the
  `ai-new-workflow-app-template` GitHub template.
  It is an active project repo, not the template itself.
</summary>

```

Then re-trigger by re-labeling issue #1 with `orchestration:dispatch`.

---

### Solution B: Fix the creation script to rewrite the `AGENTS.md` template label at clone time *(prevents all future recurrences)*

**Change:** In `create-repo-with-plan-docs.ps1` (`nam20485/workflow-launch2`), after the placeholder substitution pass, add a targeted replacement that rewrites the `<template_usage><summary>` block to instance-appropriate language. This runs once per clone at creation time.

| Pros | Cons |
|------|------|
| Fixes the root cause for every future clone | Requires a change in `workflow-launch2` (separate repo) |
| Automated — no manual step needed per repo | Must stay in sync if AGENTS.md template block structure changes |
| Survives re-runs of the creation script (idempotent with a sed pattern) | Doesn't retro-fix already-created clones |

**Implementation notes:**

Add to the placeholder-replacement step in the script (after existing `sed` substitutions):

```powershell
# Rewrite the template_usage summary block from "template repo" to "project instance"
$agentsFile = Join-Path $cloneDir "AGENTS.md"
(Get-Content $agentsFile -Raw) -replace
  '(?s)(<template_usage>\s*<summary>)[^<]*(</summary>)',
  "`$1`n      This repository is a **project instance** cloned from the``n      ``ai-new-workflow-app-template`` GitHub template.``n      It is an active project repo, not the template itself.``n    `$2" |
  Set-Content $agentsFile
```

---

### Solution C: Restructure `AGENTS.md` in the template to use a placeholder that gets replaced cleanly *(architectural fix)*

**Change:** In `ai-new-workflow-app-template`'s `AGENTS.md`, replace the prose "GitHub template repo" label with a dedicated placeholder token (e.g., `__REPO_KIND__`) that the creation script substitutes with `project instance` in every clone.

| Pros | Cons |
|------|------|
| Self-documenting — the template clearly signals what needs replacing | Template AGENTS.md becomes slightly harder to read with a raw placeholder token |
| Consistent with how repo name and owner placeholders already work | Creation script must be updated to handle the new token |
| Future-proof — structure change in AGENTS.md won't break the replacement | |

**Implementation notes:**

Change template AGENTS.md `<summary>` to:

```xml
<summary>
  This repository is a **__REPO_KIND__**
  (`intel-agency/ai-new-workflow-app-template`).
  ...
</summary>

```

Add to the creation script's substitution list: `__REPO_KIND__` → `project instance cloned from ai-new-workflow-app-template`.

---

## 5. Recommendation

### Recommended Path

1. **Immediate (today):** Fix AGENTS.md in `workflow-orchestration-service-yankee60` — rewrite the `<template_usage><summary>` block from "GitHub template repo" to "project instance" language (Solution A). Commit to main, re-trigger the dispatch on issue #1.
2. **Short-term (this sprint):** Fix the creation script in `nam20485/workflow-launch2` to rewrite that AGENTS.md block automatically at clone time (Solution B). This prevents every future clone from hitting the same problem.
3. **Longer-term (optional hardening):** Restructure the template AGENTS.md to use an explicit placeholder token (Solution C), making the substitution requirement self-evident and machine-enforceable.

### Why This Recommendation

The root cause is definitively identified: the text in AGENTS.md tells the orchestrator it is running on the template, not a clone. Fixing the text takes minutes, is immediately verifiable by re-running the dispatch, and has zero infrastructure risk. When the re-trigger succeeds, the hypothesis is confirmed.

Solution B must follow, because every clone created since this template was built — and every clone created in the future until fixed — carries the same defect. It affects every project-setup run system-wide, not just yankee60.

Solution C is the cleanest long-term form, but is optional if the script-level fix in Solution B is applied promptly.

What this recommendation does **not** resolve:
- **The CI-green / semantic-failure mismatch**: the orchestrator exiting 0 after a total no-op is a separate design gap that warrants its own story.
- **The `plan_docs/` spec filename mismatch**: `create-workflow-plan` lists `new app spec.md` or `ai-new-app-template.md` as expected filenames; the actual file is `OS-APOW Implementation Specification v1.2.md`. The assignment instructions say "or equivalent", so this may not block execution, but it is worth monitoring in the re-trigger run.

---

## 6. Appendix

### 6.1 Raw Error Signatures

From issue #1 comment 4173976581 (2026-04-02T01:17:21Z):

```text
❌ `project-setup` workflow execution incomplete.

Root Cause: This repository is a GitHub template repository, but the
project-setup workflow is designed to execute on clones of this template,
not on the template repository itself.

Details:
- Workflow definition successfully retrieved and analyzed
- Repository state: Template repository (not a project instance)
- Assignments executed: 0 of 6
- Critical barriers identified: Requires multi-agent delegation,
  template vs. instance context mismatch
```

### 6.2 Route Confirmation Signatures

The dispatch was correctly routed before the context check failed:

```text
[01:12:31Z] 🤖 Orchestrator triggered — invoking `project-setup` dynamic workflow...
[01:13:31Z] 🤖 Orchestrator triggered — matched `orchestration:dispatch` clause.
            Parsing dispatch body...
```

These confirm the orchestrator started, the label filter passed, the dispatch body was parsed, and the command-to-workflow routing worked. The failure occurred after routing, during the context decision phase.

### 6.3 Confirmed Non-Cause

```bash
# Verified 2026-04-02 — is_template is false, confirming the GitHub API
# correctly identifies this repo as a clone, not the template itself.
gh api repos/intel-agency/workflow-orchestration-service-yankee60 --jq .is_template
# → false
```

This is expected and correct. The `is_template` flag was **not** the cause.

### 6.4 Confirmed Cause — AGENTS.md Text

Fetched from `raw.githubusercontent.com/intel-agency/workflow-orchestration-service-yankee60/main/AGENTS.md`:

```xml
<template_usage>
  <summary>
    This repository is a **GitHub template repo**
    (`intel-agency/workflow-orchestration-service-yankee60`).
    New project repositories are created from it using automation scripts in the
    `nam20485/workflow-launch2` repo...
  </summary>
  <template-clone-instances>
    Once the template has been cloned into a new instance, this file must be
    updated to match the new repo's specifics (e.g., name, links, instructions).
  </template-clone-instances>
  ...
```

The `<template-clone-instances>` note explicitly states this file must be updated post-clone — but the creation script does not do this. The orchestrator reads this text and classifies the repo as the template.

### 6.5 Fix to Apply on yankee60

Edit `AGENTS.md`, rewrite `<template_usage><summary>` to:

```xml
<summary>
  This repository is a **project instance** cloned from the
  `ai-new-workflow-app-template` GitHub template.
  It is an active project repo, not the template itself.
</summary>
```

Commit and push to `main`, then re-trigger the dispatch on issue #1.

### 6.6 Artifact Deadline

The `opencode-traces` artifact for run 23878622026 was uploaded with retention-days=14.
**Artifact expiry: 2026-04-16**. The AGENTS.md text finding makes this less critical for root cause confirmation, but the trace may still be useful for verifying what other signals the agent evaluated.

### 6.7 Sources Consulted

- Workflow runs: `GET /repos/intel-agency/workflow-orchestration-service-yankee60/actions/runs` — 4 total runs
- Issue: `intel-agency/workflow-orchestration-service-yankee60#1` — title, body, labels, 3 orchestrator comments
- Workflow definition: `.github/workflows/orchestrator-agent.yml` (raw, main branch) — step structure, skip-event filter, job permissions
- Repo structure: root listing, `plan_docs/` directory listing — OS-APOW spec and migration plan present
- Template repo: `intel-agency/ai-new-workflow-app-template` AGENTS.md — creation pipeline design, `create-repo-with-plan-docs.ps1` flow, delegation depth constraints

---

## 7. Implementation Status

> **Updated:** 2026-04-01

### 7.1 Changes Applied

#### Solution B — Creation script fix ✅ DONE (`nam20485/workflow-launch2`)

Commit [`3a23cdb`](https://github.com/nam20485/workflow-launch2/commit/3a23cdb) — *feat: rewrite AGENTS.md instance label after template clone*

`create-repo-with-plan-docs.ps1` was updated to rewrite the `<template_usage><summary>` label in `AGENTS.md` immediately after placeholder substitution in both execution paths:

1. **Main flow** (post-clone, pre-commit): replaces `**GitHub template repo**` with `**project instance** cloned from the \`intel-agency/ai-new-workflow-app-template\` GitHub template`
2. **Post-rebase recovery path**: re-applies the same rewrite if a template race forced a rebase before the seed commit could land

This is the fix that prevents all future clones from hitting this defect. The replacement is idempotent — if the label is already correct (e.g., re-run against the same clone), the step self-reports `skipped (already updated)`.

#### Plan doc filename standardisation ✅ DONE (`nam20485/workflow-launch2`)

Commit [`2951045`](https://github.com/nam20485/workflow-launch2/commit/2951045) — *docs: rename OS-APOW Implementation Specification to Application Implementation Specification*

The `OS-APOW Implementation Specification v1.2.md` files in all three `workflow-orchestration-service` plan_docs directories were renamed to `Application Implementation Specification.md` — aligning with the standard filename that assignment workflows expect when looking for the primary spec document. This partially addresses the secondary soft risk noted in §3.3.

### 7.2 Still Pending

#### Solution A — Fix `AGENTS.md` in the existing yankee60 clone ⏳ PENDING

The `AGENTS.md` in `intel-agency/workflow-orchestration-service-yankee60` still contains the old "GitHub template repo" label from before the script fix was applied. The creation script fix (Solution B) only protects new clones going forward.

**Required action:** Manually commit the corrected `<template_usage><summary>` block to `main` on `workflow-orchestration-service-yankee60` (see §6.5 for the exact replacement text), then re-trigger the dispatch by re-labeling issue #1 with `orchestration:dispatch`.

#### Solution C — Template placeholder restructuring ⏳ DEFERRED

Restructuring `AGENTS.md` in the source template to use an explicit `__REPO_KIND__` placeholder token remains optional hardening. Not required now that the script-level fix is in place.

#### Re-trigger validation ⏳ PENDING

Once the yankee60 `AGENTS.md` is corrected, re-triggering the dispatch will validate:
- The orchestrator no longer classifies the repo as a template
- All 6 `project-setup` assignments execute successfully
- CI green correctly corresponds to semantic work completed

Artifact retention deadline for the original run: **2026-04-16** (run 23878622026, retention 14 days).
