---
name: validate-and-commit
description: "Finishing workflow: update docs with implementation status, group staged changes into logical commits with meaningful messages, push only agent-changed files (leave unrelated uncommitted files alone). Use when: wrapping up a task, committing work, finalizing implementation, updating task doc status, grouping commits, push changes, finish up, done implementing, ready to commit."
argument-hint: "Optional: describe what was implemented (used to write commit messages and doc summary)"
---

# Validate and Commit

End-of-task finishing workflow. Updates documentation, groups changes into logical commits, and pushes — without touching files you didn't change.

## When to Use

- You've finished implementing something and need to commit + push
- You want the doc (plan, task file, README) updated with what was done
- You need changes split into logical commit groups rather than one giant commit
- You want a clean push that doesn't accidentally stage unrelated files

---

## Procedure

### Step 1 — Survey the workspace

Run `git status --short` and `git diff --stat HEAD` to get the full picture:
- Which files are **modified** (M), **new** (??), or **deleted** (D)?
- What was already staged vs. unstaged?
- Are there files you did NOT touch that should be left alone?

```powershell
git --no-pager status --short
git --no-pager diff --stat HEAD
```

### Step 2 — Update documentation (if applicable)

If a task/plan document was used (e.g., `docs/*.md`, `PLAN.md`, `pwsh-scripts.md`, or session plan):

1. **Check acceptance criteria** — tick any boxes that are now met.
2. **Add/update an Implementation Status section** with:
   - What was delivered (files created/changed)
   - Test results (pass counts, tool outputs)
   - Any remaining items or known caveats
3. Keep it factual and brief — a table of files + status is ideal.

Only update docs that are part of the task. Never create new markdown files for tracking.

### Step 3 — Identify YOUR changes

Separate files into two buckets:

| Bucket | Action |
|--------|--------|
| Files you created or modified as part of this task | Stage and commit |
| Pre-existing uncommitted files you did NOT touch | Leave unstaged — do NOT `git add .` |

Use `git diff --name-only HEAD` and `git ls-files --others --exclude-standard` to identify candidates. When in doubt about a file, check `git log --follow -- <file>` or skip it.

### Step 4 — Group into logical commits

Think about the *type* and *purpose* of each file changed and form groups. Common groupings:

| Group | Example files |
|-------|--------------|
| **feat** | New source files, scripts, main implementation |
| **test** | Test files, fixtures, test helpers |
| **docs** | README, plan docs, task files |
| **ci** | Workflow YAML, CI config |
| **fix** | Bug fixes, corrections to prior commits |
| **refactor** | Renames, restructuring without behavior change |

**Rule**: 1 group = 1 commit. If only 1–3 files total, one commit is fine.

### Step 5 — Commit each group

For each group:

```powershell
# Stage only the files in this group
git add <file1> <file2> ...

# Commit with a conventional message
git commit --no-gpg-sign -m "<type>(<scope>): <short summary>

<optional body: what and why, not how>

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

**Commit message rules**:
- Use [Conventional Commits](https://www.conventionalcommits.org/): `feat:`, `fix:`, `test:`, `docs:`, `ci:`, `refactor:`
- Subject line: imperative mood, ≤72 chars, no period
- Body: explain *what* changed and *why*, not *how*
- Always include the `Co-authored-by` trailer

### Step 6 — Verify before pushing

```powershell
git --no-pager log --oneline -5          # Review commit history
git --no-pager status --short            # Confirm nothing unintentionally staged
git --no-pager diff HEAD                 # Should be empty (or only expected unstaged files)
```

If anything looks wrong (wrong files staged, missing files), fix before pushing.

### Step 7 — Push

```powershell
git push
```

If the branch has no upstream yet:
```powershell
git push -u origin <branch-name>
```

---

## Quality Checks

Before finishing, verify:

- [ ] Docs reflect current implementation status (acceptance criteria ticked, status tables up to date)
- [ ] Each commit has a meaningful conventional message
- [ ] No unrelated files were accidentally staged
- [ ] `git status` is clean (or only expected pre-existing uncommitted files remain)
- [ ] Push succeeded

---

## Notes

- **GPG signing failures**: Use `--no-gpg-sign` if the commit hangs waiting for a pinentry prompt.
- **Merge conflicts**: Resolve before running this skill.
- **Active PR**: After pushing, the PR is automatically updated — no separate action needed.
- **Large changes**: If >5 logical groups exist, consider whether some belong in a separate PR.
