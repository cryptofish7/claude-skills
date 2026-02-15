## Workflow

### Starting a Session

1. Read project documentation for context (e.g., PRD, architecture docs, README).
2. Check the task tracker (e.g., `docs/TASKS.md`, GitHub Issues) for current progress. Identify the next incomplete task.
3. Start from a clean state on the default branch:
   ```bash
   git checkout main && git pull origin main
   ```

### During Development — Orchestrator Pattern

If you were spawned as a Task Runner by an orchestrator (like Ralph), follow the Pipeline section of your prompt instead of this workflow.

**You are the orchestrator.** Your role is to coordinate subagents, verify results, and make decisions. Do NOT write implementation code directly. All code generation of more than ~10 lines goes to a subagent via the Task tool. This preserves your context window for coordination across the full task lifecycle.

**Subagent roster:**

| Subagent | How to spawn | Purpose | Writes code? |
|----------|-------------|---------|-------------|
| Planner | Task tool (`subagent_type=Explore`) | Analyze code, produce implementation plan | No |
| Implementer | Task tool (`subagent_type=general-purpose`) | Execute approved plan, write code + tests | Yes |
| Code reviewer | `code-reviewer` agent | Review PR for bugs, security, style | No |
| Debugger | `debugger` agent | Diagnose and fix errors, CI failures | Yes |

**Development flow:**

1. **Plan**: Use the Task tool to spawn an Explore subagent. Pass it the task description, file structure, and relevant docs. It reads code and returns an implementation plan. Review the plan yourself — check for completeness, gaps, and alignment with the task. If it's lacking, re-plan with more specific instructions. Do not ask the user to approve the plan.
2. **Implement**: Once the plan looks solid, use the Task tool to spawn an implementation subagent. Pass it the full approved plan and CLAUDE.md conventions. The subagent writes all code and tests.
3. **Verify**: After the subagent completes, run the full verify suite (lint, format, typecheck, test). If verification fails, spawn the `debugger` agent for test failures or a Task subagent for lint/type errors.
4. When stuck or going in circles, stop. Re-plan before continuing.

**When the orchestrator acts directly** (exceptions):
- Git operations (commit, branch, push, merge)
- Running commands (tests, linters, CI checks)
- Trivial fixes (1-2 lines: typo, import, format issue)
- Task tracker updates
- Spawning audit subagents (docs, CI/CD, smoke test) — see Step 2 of the post-task pipeline

**Verification protocol**: After any subagent writes code, the orchestrator runs the full verify suite before proceeding. Never trust subagent output without verification.

**Progress tracking**: Use TaskCreate to register each development and pipeline step. Prefix every `subject` and `activeForm` with the responsible agent in brackets so the user can see who's doing what (e.g., `subject: "[Planner] Plan: add auth"`, `activeForm: "[Planner] Planning auth"`). Mark `in_progress` when starting, `completed` when done. The user sees live progress via `Ctrl+T`.

### After Completing a Task — Autonomous Pipeline

Run this pipeline after every completed task. No user input required unless a step fails and cannot be auto-resolved.

**Step 1: Verify locally.**
Run the project's linting, formatting, type checking, and test commands. Check the Commands section of this file or `pyproject.toml`/`package.json`/`Makefile` for the exact commands. Fix any failures before proceeding.

**Step 2: Audit docs, CI/CD, and deploy script (parallel).**
Spawn these as **parallel Task subagents** (`subagent_type=general-purpose`). Each subagent gets the relevant skill instructions and an explicit directive: "Execute autonomously. Do not ask the user for approval — review your own plan and proceed."

- **Docs audit**: Read `~/.claude/skills/docs-consolidator/SKILL.md` and pass its contents. The subagent audits and consolidates project docs.
- **CI/CD audit**: Read `~/.claude/skills/ci-cd-pipeline/SKILL.md` and pass its contents. The subagent ensures GitHub Actions matches the current project state.
- **Smoke test update**: Read `~/.claude/skills/smoke-test/SKILL.md` and pass its contents. The subagent updates deploy.sh with smoke tests for new functionality.
- **Bug bash update**: Read `~/.claude/skills/bug-bash-update/SKILL.md` and pass its contents. The subagent updates docs/BUG_BASH_GUIDE.md with new checklist items for features and fix annotations for bugs. For bug fixes, it verifies the fix in the browser before marking [x].

Skip any if the skill is unavailable. Wait for all subagents to complete before proceeding.

**Step 3: Commit all changes.**
Stage and commit everything from the task and from Step 2. Write a concise, descriptive commit message. Use conventional commit prefixes when appropriate (`feat:`, `fix:`, `chore:`, `docs:`, `ci:`, `refactor:`, `test:`).

**Step 4: Push to a new branch and open a PR.**
- Create a branch with a descriptive name: `<type>/<short-slug>` (e.g., `feat/core-types`, `fix/timestamp-bug`, `chore/update-deps`).
- Push and open a PR:
  ```bash
  git checkout -b <branch-name>
  git push -u origin <branch-name>
  gh pr create --fill
  ```

**Step 5: Code review and CI (parallel).**
Start both immediately after opening the PR:

- **5a**: Spawn the `code-reviewer` subagent to review the PR.
- **5b**: Run `gh pr checks --watch --fail-fast` to monitor CI.

Handling results:
- If review returns Critical or Warning findings:
  - **3+ line fixes**: Spawn a Task subagent to apply them. Do not fix directly.
  - **1-2 line fixes**: The orchestrator may apply these directly.
  - Commit and push fixes. CI restarts automatically on the new push.
- If CI fails:
  1. Identify the failure: `gh pr checks` then `gh run view <run-id> --log-failed`.
  2. Spawn the `debugger` subagent with the failure context.
  3. Apply the fix on the same branch, commit, and push.
  4. Max 3 CI retries. If still failing, stop and ask the user for help.
- **Proceed to Step 6 when**: review is clean (APPROVE or only Nits) AND CI passes.

**Step 6: Merge the PR and clean up.**
```bash
gh pr merge --squash --delete-branch
git checkout main && git pull origin main
```
- **If merge conflict:**
  1. Rebase onto the default branch: `git fetch origin main && git rebase origin/main`.
  2. Force-push safely: `git push --force-with-lease`.
  3. Wait for CI again (return to Step 5b). Max 1 retry.
  4. If the conflict persists, stop and ask the user for help.

**Step 7: Conserve context.**
Keep context lean by delegating implementation to Task subagents rather than writing code directly. If running as a Task Runner, report your result and exit.

### After Making a Mistake

- Add a specific rule to "Mistakes to Avoid" at the bottom of this file.
