---
name: ci-cd-pipeline
description: Analyze a repo and maintain its GitHub Actions CI/CD pipeline. Detects language, tooling, test frameworks, Docker, and deploy targets, then adds or removes workflow actions to match the project's current state. Use when the user asks to "add CI/CD", "update CI", "review pipeline", "set up GitHub Actions", "audit CI", "improve CI/CD", or any request about CI/CD pipelines, GitHub Actions workflows, or continuous integration.
---

# CI/CD Pipeline

Analyze a repository and maintain its GitHub Actions CI/CD pipeline. Designed to be called repeatedly — each invocation audits the current state and proposes additions and removals.

## Workflow

### Phase 1: Discover project state

Build a project profile by detecting:

1. **Language & runtime** — Check file extensions, config files (`pyproject.toml`, `package.json`, `go.mod`, `Cargo.toml`, `Gemfile`, etc.)
2. **Package manager** — pip/uv/poetry, npm/yarn/pnpm, cargo, go modules, etc.
3. **Tooling configs** — Lint (ruff, eslint, golangci-lint), format (ruff, prettier, gofmt), typecheck (mypy, pyright, tsc)
4. **Test framework** — pytest, jest, vitest, go test, cargo test, etc. Check for test files and config.
5. **Docker** — Dockerfile, docker-compose.yml, .dockerignore
6. **Deploy targets** — Railway, Fly.io, Vercel, AWS, Kubernetes manifests, Terraform, etc.
7. **Existing workflows** — Read all `.github/workflows/*.yml` files
8. **Python version / Node version** — From `requires-python`, `engines`, `.python-version`, `.nvmrc`, `.node-version`
9. **Dev dependencies** — Check what's available in dev/test dependency groups

Key files to check:
- `pyproject.toml`, `setup.cfg`, `setup.py`, `requirements*.txt`
- `package.json`, `tsconfig.json`
- `go.mod`, `Cargo.toml`, `Gemfile`, `pom.xml`, `build.gradle`
- `Dockerfile`, `docker-compose.yml`
- `.github/workflows/*.yml`

### Phase 2: Audit current pipeline

Read `~/.claude/skills/ci-cd-pipeline/references/actions-catalog.md` for the full catalog of actions with add/remove criteria.

For each action in the catalog:

| Signal present? | Action exists? | Decision |
|-----------------|---------------|----------|
| Yes | No | **Add** |
| Yes | Yes | Check config is correct, **update** if stale |
| No | Yes | **Remove** |
| No | No | Skip |

Produce a structured diff of proposed changes.

### Phase 3: Present the plan

Present findings to the user:

```
## CI/CD Audit Report

### Actions to Add
- [ ] [action]: [rationale based on detected signal]

### Manual Setup Required
> Only include this section when adding a deploy action.

[Platform name]:
1. [step from deploy-prerequisites.md]
2. [step from deploy-prerequisites.md]
3. Add `SECRET_NAME` to GitHub repo secrets (Settings → Secrets and variables → Actions)
4. [verification step]

### Actions to Remove
- [ ] [action]: [rationale — signal no longer present]

### Actions to Update
- [ ] [action]: [what changed and why]

### No Changes Needed
- [action]: correctly configured
```

When adding a deploy action, read `~/.claude/skills/ci-cd-pipeline/references/deploy-prerequisites.md` for the detected platform and include its setup steps in the **Manual Setup Required** section. This ensures the user knows what manual steps are needed before the workflow will function.

If running interactively, wait for user approval before making changes. If running autonomously (e.g., as a post-task audit subagent), proceed directly to Phase 4 — apply all additions and updates from the audit.

### Phase 4: Execute changes

After approval:

1. Create or edit `.github/workflows/*.yml` files
2. If a new tool is needed (e.g., adding mypy job but mypy isn't in deps), add it to dev dependencies
3. If a tool config is missing (e.g., `[tool.ruff]` section), add it to the project config file
4. Delete workflow files or jobs that are no longer needed
5. Run the tools locally to verify the pipeline starts green (lint, typecheck, test)
6. Present a summary of all changes made

## Guidelines

- Prefer fewer workflow files with multiple jobs over many single-job files.
- Standard layout: `ci.yml` for lint/typecheck/test, `security.yml` for audits/scanning, `deploy.yml` for deployment.
- All jobs in `ci.yml` should run in parallel unless they have dependencies.
- Use `actions/checkout@v4` and `actions/setup-python@v5` / `actions/setup-node@v4`.
- Pin action versions to major tags (e.g., `@v4`), not SHAs.
- CI triggers: `push` to main/master + `pull_request`. Security: `push` to main + weekly `schedule`.
- When adding tooling config, use the project's config file (e.g., `pyproject.toml` for Python, `package.json` for JS).
- When removing an action, also clean up any orphaned tool configs that were only used by that action.
