# Problems with the workflow assignments

## P1: 2 subagent delegation concurrent artificial limit

**Status: FIXED** (commit `bc4126c`)

**Root Cause:** The orchestrator agent was explicitly told to limit concurrent delegations to 2 in three places:
1. `.opencode/agents/orchestrator.md` step 5: `Build delegation tree (≤2 concurrent)`
2. `.opencode/agents/orchestrator.md` Delegation Depth Management: `Concurrent delegation limit: Maximum 2 concurrent delegations`
3. `AGENTS.md` coding conventions: `Keep orchestrator delegation-depth ≤2`

This is a prompt-level constraint only — opencode supports parallel Task tool calls natively with no hard limit. The model was obeying the instruction literally, serializing independent tasks unnecessarily.

**Fix:** Removed all three concurrent-limit references. The depth limit (max 2 nesting levels) is preserved since that's about nesting, not parallelism.

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

**Status: INVESTIGATING**

The golf43 run has been running 46+ minutes (still in progress — the `--thinking` and `/proc/io` watchdog fixes from commit `5e591f9` are keeping it alive). The delta86 run **succeeded** in 26m 14s.

The `--thinking` flag fix ensures the client streams thinking blocks to stdout during subagent delegations, preventing the idle watchdog from killing the process. The `/proc/io` monitoring provides a server-side fallback. Both are working as evidenced by the golf43 watchdog log: `server I/O active (write_bytes=...)`.

Remaining concern: even when not killed by the watchdog, runs may take too long if the orchestrator is serializing work unnecessarily (see P1 fix) or if subagent tasks are too broad/unfocused.

<https://github.com/intel-agency/workflow-orchestration-queue-golf43/actions/runs/23332549552/job/67866999506>

<https://github.com/intel-agency/workflow-orchestration-queue-delta86/actions/runs/23332933790/job/67868109799>
