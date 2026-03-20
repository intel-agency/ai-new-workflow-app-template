# Problems with the workflow assignments

## P1: 2 subagent delegation concurrent artificial limit

**Status: FIXED** (commit `bc4126c`) — validated in delta86 logs, model still echoes old behavior on pre-fix repos

**Root Cause:** The orchestrator agent was explicitly told to limit concurrent delegations to 2 in three places:
1. `.opencode/agents/orchestrator.md` step 5: `Build delegation tree (≤2 concurrent)`
2. `.opencode/agents/orchestrator.md` Delegation Depth Management: `Concurrent delegation limit: Maximum 2 concurrent delegations`
3. `AGENTS.md` coding conventions: `Keep orchestrator delegation-depth ≤2`

This is a prompt-level constraint only — opencode supports parallel Task tool calls natively with no hard limit. The model was obeying the instruction literally, serializing independent tasks unnecessarily.

**Fix:** Removed all three concurrent-limit references. The depth limit (max 2 nesting levels) is preserved since that's about nesting, not parallelism.

**Log validation (delta86):** At `07:22:55Z` the orchestrator still says "I can delegate up to 2 tasks concurrently" — this is expected because delta86 was seeded from the template BEFORE the P1 fix. New repos created from the updated template will not have this constraint.

```
Let me delegate these tasks. I'll start with the high-priority items. I can delegate up to 2 tasks concurrently.
Let me delegate:
1. GitHub expert - to create the GitHub project and import labels
2. Developer - to update the .labels.json file
Actually, let me think about this more carefully. The planner identified these tasks but I should delegate them in a logical order. Let me create a todo list and then delegate.
The planner has identified the setup tasks needed. Let me now delegate the execution to the appropriate specialists. I'll track progress and delegate the key tasks.

# Todos
[ ] Update .labels.json with OS-APOW agent-state labels
[ ] Create GitHub Project for issue tracking
[ ] Import labels to GitHub repository
[ ] Create Phase 0-3 milestones
[ ] Create Phase 1 user story issues
[ ] Report final project-setup status

• Update .labels.json with agent labels Developer Agent
• Create GitHub Project for tracking Github-Expert Agent
Thinking: Now let me delegate the first two high-priority tasks concurrently:
1. Developer to update the .labels.json file with agent-state labels
2. GitHub expert to create the GitHub Project and prepare for label import
Now delegating the high-priority tasks concurrently:
[watchdog] client output idle 76s, server I/O active (write_bytes=115478528) — subagent likely runn
```

## P2: Project creation permission blocked

**Status: FIXED** (commit `7f835c0`)

**Root Cause:** GitHub Projects V2 uses the GraphQL API, which requires the `project` OAuth scope. The workflow permissions block was missing `projects: write`. Additionally, the built-in `GITHUB_TOKEN` cannot manage Projects V2 at all — only a classic PAT with the `project` scope can.

**Fix:** Added `projects: write` to the orchestrator-agent.yml workflow permissions. The `GH_ORCHESTRATION_AGENT_TOKEN` PAT must also have the `project` scope — verify via PAT settings or `gh auth refresh -h github.com -s project`.

```
Thinking: The GitHub Project creation is blocked by permissions. I'll mark it as "completed" in the sense that we've done what we can and documented the limitation.
```

## P3: Mistaken belief project is .NET-based

**Status: OPEN** — needs investigation into the `create-project-structure` dynamic workflow definition and whether it hardcodes .NET assumptions.

```
• Execute create-project-structure Backend-Developer Agent
Now executing **Assignment 3: create-project-structure**. This requires Python adaptation as the assignment is designed for .NET.
```

## P4: /orchestrate-project-setup timeout and completion issues

**Status: PARTIALLY FIXED** — `--thinking` + `/proc/io` watchdog fixes prevent false-positive kills during subagent work; genuine subagent stalls still cause 15m idle kill

### Delta86 analysis (run 23332933790 — succeeded in 26m 14s)

**Timeline (UTC, 2026-03-20):**

| Time | Event |
|------|-------|
| 07:17:19 | opencode starts with `--thinking --print-logs` flags |
| 07:18:16 | Orchestrator matches `project-setup` clause, delegates to Planner Agent |
| 07:19:20–07:22:20 | **Watchdog: "server I/O active (write_bytes=...)" — fix working, no kill** |
| 07:22:25 | ✔ Planner Agent completes (~4m subagent run survived) |
| 07:23:35 | Delegates Developer + Github-Expert concurrently (2 tasks) |
| 07:24:50 | Watchdog: server I/O active |
| 07:24:56 | ✔ Github-Expert: "GITHUB_TOKEN doesn't have permission to create projects" (confirms P2) |
| 07:24:59 | ✔ Developer: labels.json updated |
| 07:25:47 | Delegates Import-labels + Create-milestones concurrently |
| 07:27:27 | ✔ Milestones complete |
| 07:27:27–07:42:51 | **Import-labels subagent STALLS — no server I/O for 15 minutes** |
| 07:42:51 | ⚠ "opencode idle for 15m (no output from client or server); terminating" |
| 07:42:51 | opencode exit code: 143 (SIGTERM) — wrapper returns exit 0 |

**Validated fixes:**
- `--thinking` flag streams thinking blocks during subagent work → prevents idle-output false positives
- `/proc/<pid>/io` monitoring detects server write_bytes changes → proves subagent is alive even when no client output
- 5 of 6 subagent delegations completed successfully without watchdog interference

**Remaining issues:**
1. **Import-labels subagent genuine stall:** For 15m after milestones completed, zero server I/O — the LLM API call or `gh` CLI command within the subagent hung. This is NOT a false-positive watchdog kill; the subagent actually froze.
2. **Exit code masking:** Wrapper returns 0 even when watchdog sends SIGTERM (exit 143). The workflow appears "succeeded" despite incomplete work (import-labels never finished).
3. **Incomplete task list:** Milestones done, labels.json updated, but: import-labels incomplete, Phase 1 issues not created, final status not reported.

### Golf43 analysis (run 23332549552 — still in_progress at 1h+)

Step 13 "Execute orchestrator agent in devcontainer" started at `07:02:12Z` and is still running. Cannot fetch logs from in-progress runs via `gh run view --log`. Either the orchestrator is processing many tasks successfully (fix keeping it alive), or it's stuck but the hard ceiling (90m) hasn't been hit yet.

<https://github.com/intel-agency/workflow-orchestration-queue-golf43/actions/runs/23332549552/job/67866999506>

<https://github.com/intel-agency/workflow-orchestration-queue-delta86/actions/runs/23332933790/job/67868109799>
