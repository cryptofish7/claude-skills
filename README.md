# Claude Code Skills & Agents

A collection of user-level skills and agents for [Claude Code](https://docs.anthropic.com/en/docs/claude-code).

## Quick Start

```
git clone https://github.com/cryptofish7/claude-skills.git
cd claude-skills
./install.sh
```

## Skills

| Skill | Triggers | Description |
|-------|----------|-------------|
| **ralph** | "ralph", "work on tasks", "autopilot" | Your autonomous developer. Give it a task list (`TASKS.md` or GitHub Issues) and it works through every task end-to-end — planning, coding, testing, docs, CI/CD, PR, code review, and merge — then moves to the next. Watch real-time progress via `Ctrl+T`. |
| **setup-workflow** | "setup workflow", "init workflow" | Run once at the start of a project. Adds a standardized development pipeline to your `CLAUDE.md` so every Claude Code session follows the same steps: verify, update docs, audit CI/CD, commit, PR, review, merge. |
| **ci-cd-pipeline** | "add CI/CD", "update CI", "review pipeline" | Scans your project — language, test framework, linter, Docker, deploy targets — and creates or updates GitHub Actions workflows to match. Produces an audit report of what to add, remove, or update, with setup steps for new deploy targets. |
| **docs-consolidator** | "consolidate docs", "audit docs", "organize docs" | Reads all your project docs and finds what's duplicated, misplaced, or stale. Builds a registry of which doc owns which topic, then moves content to its canonical home and replaces duplicates with cross-references. |
| **smoke-test** | "smoke test", "deploy locally", "run deploy" | Creates a `deploy.sh` script that verifies your project works locally. Detects your language, package manager, linter, test framework, and CLI entry points, then builds a multi-stage test script. Only tests what's implemented — skips stubs. Grows with your project. |
| **bug-bash-update** | "bug bash update", "update bug bash" | Updates `docs/BUG_BASH_GUIDE.md` after completing tasks. Adds checklist items for new features, annotates bug fixes with PR references, and verifies fixes in the browser before marking them complete. |
| **skill-reviewer** | "review skills", "audit skills", "skill review" | Inventories all installed skills and agents, then deep-reviews selected ones for conciseness, clarity, scope overlap, and token efficiency. Shows before/after rewrites for each issue found. |
| **reflect** | "reflect", "retrospective", "session review" | Analyzes the current conversation for learnings — mistakes, decisions, patterns — and persists approved insights to CLAUDE.md, project memory, or new skill stubs. |
| **claudemd-auditor** | "audit claudemd", "review claude.md", "optimize claude.md" | Audits all CLAUDE.md files for redundancy, verbosity, and content better stored in project memory. Reports estimated token savings and offers to apply fixes. |

## Agents

| Agent | Triggers | Description |
|-------|----------|-------------|
| **code-reviewer** | "review PR", "review my changes", "code review" | Senior code reviewer. Point it at a PR, staged changes, or specific files and it checks for bugs, security issues, and maintainability problems. Each finding gets a severity (Critical / Warning / Nit) with exact file:line and a suggested fix. |
| **debugger** | "debug this", "fix this error", "why is this failing" | Systematic debugger. Reproduces the issue, traces it to the root cause, applies a minimal fix, then verifies by re-running the failing test and the broader suite. Works on errors, test failures, behavioral bugs, and performance issues. |

## Hooks

| Hook | Event | Description |
|------|-------|-------------|
| **optimization-hint** | `UserPromptSubmit` | When a session has 8+ tool calls, suggests optimizations based on the dominant tool type (e.g., save findings to memory, create a Makefile target, consolidate subagents). |
| **word-count-check** | `UserPromptSubmit` | Warns when a prompt exceeds 50 words, nudging the user to clarify their desired outcome before proceeding. |

## Dependencies

**ci-cd-pipeline**, **docs-consolidator**, **smoke-test**, **bug-bash-update**, **code-reviewer**, and **debugger** are standalone — install any combination you like.

**ralph** and **setup-workflow** depend on all of the above. Install the full set for them to work.

**skill-reviewer**, **reflect**, and **claudemd-auditor** are standalone utilities with no dependencies.

## Uninstall

```
./uninstall.sh
```

## License

MIT
