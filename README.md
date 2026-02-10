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
| **ralph** | "ralph", "work on tasks", "autopilot" | Autonomous task runner. Finds the next incomplete task, implements it, runs the full pipeline (verify, docs, CI/CD, commit, PR, review, CI, merge), then moves to the next task. |
| **setup-workflow** | "setup workflow", "init workflow" | Bootstraps the autonomous development pipeline into a project's CLAUDE.md. Installs all required skills and agents. |
| **ci-cd-pipeline** | "add CI/CD", "update CI", "review pipeline" | Analyzes a repo and maintains GitHub Actions workflows. Detects language, tooling, test frameworks, Docker, and deploy targets. |
| **docs-consolidator** | "consolidate docs", "audit docs", "organize docs" | Audits project documentation, deduplicates content, and moves information to canonical locations. |
| **smoke-test** | "smoke test", "deploy locally", "run deploy" | Generates and maintains a `deploy.sh` smoke test script that grows with the project. |

## Agents

| Agent | Triggers | Description |
|-------|----------|-------------|
| **code-reviewer** | "review PR", "review my changes", "code review" | Reviews PRs, staged/unstaged changes, or specific files for bugs, security issues, and maintainability. |
| **debugger** | "debug this", "fix this error", "why is this failing" | Diagnoses errors, test failures, behavioral bugs, and performance issues. |

## Dependencies

**ci-cd-pipeline**, **docs-consolidator**, **smoke-test**, **code-reviewer**, and **debugger** are standalone.

**ralph** and **setup-workflow** depend on all of the above — install the full set for them to work.

## Uninstall

```
./uninstall.sh
```

## License

MIT
