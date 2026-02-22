---
name: ci-cd-pipeline
description: Analyze a repo and maintain its GitHub Actions CI/CD pipeline. Detects language, tooling, test frameworks, Docker, and deploy targets, then adds or removes workflow actions to match the project's current state. Use when the user asks to "add CI/CD", "update CI", "review pipeline", "set up GitHub Actions", "audit CI", "improve CI/CD", or any request about CI/CD pipelines, GitHub Actions workflows, or continuous integration.
---

# CI/CD Pipeline

Analyze a repository and maintain its GitHub Actions CI/CD pipeline. Designed to be called repeatedly — each invocation audits the current state and proposes additions and removals.

## Workflow

### Phase 1: Discover project state

Build a comprehensive project profile by scanning the entire repository:

1. **Language & runtime** — Check file extensions, config files (`pyproject.toml`, `package.json`, `go.mod`, `Cargo.toml`, `Gemfile`, `foundry.toml`, `hardhat.config.*`, `truffle-config.js`, `Move.toml`, etc.)
2. **Package manager** — pip/uv/poetry, npm/yarn/pnpm, cargo, go modules, etc.
3. **Tooling configs** — Lint, format, typecheck tools. Don't assume defaults — read actual config files (`.eslintrc*`, `prettier` in deps, `ruff` in deps, `tsconfig.json`, `foundry.toml`, `biome.json`, etc.)
4. **Test framework** — Detect from config files, dependency lists, and test file patterns (`tests/`, `test/`, `*_test.go`, `*.test.ts`, `*.t.sol`, etc.)
5. **Build tools** — Read `package.json` scripts, `Makefile` targets, `scripts/` directory, `foundry.toml`, `hardhat.config.*`, `Cargo.toml`, `pyproject.toml` build sections
6. **Docker** — `Dockerfile`, `docker-compose.yml`, `.dockerignore`
7. **Deploy targets** — Railway, Fly.io, Vercel, AWS, Kubernetes manifests, Terraform, etc.
8. **Existing workflows** — Read all `.github/workflows/*.yml` files. For each, note the jobs, triggers, and tools used.
9. **Version requirements** — From `requires-python`, `engines`, `.python-version`, `.nvmrc`, `.node-version`
10. **Dev dependencies** — Check what's available in dev/test dependency groups
11. **Monorepo structure** — Detect package boundaries (`packages/`, `apps/`, workspace configs in `package.json`, `pnpm-workspace.yaml`, Cargo workspaces, etc.)
12. **Custom scripts** — Read `scripts/` directory and `package.json` scripts to understand project-specific build/test/deploy commands

### Phase 2: Reason about pipeline coverage

Based on the discovered project profile, determine what CI jobs are needed. Do NOT reference a static catalog — reason from what the project actually uses.

**Evaluate coverage across these categories:**

1. **Code quality** — For each language/package detected, check if lint, format, and typecheck tools are configured. Identify the specific tool and command from the project's own config (e.g., `pnpm lint` from `package.json` scripts, `forge fmt --check` from `foundry.toml`, `ruff check .` from `pyproject.toml`).

2. **Testing** — For each test framework detected, identify the correct test command. Check for unit tests, integration tests, E2E tests, and fuzz tests. Look at `package.json` scripts, `Makefile` targets, and test config files to find the exact commands.

3. **Security** — Dependency audits based on detected package managers (`npm audit`, `pip-audit`, `cargo audit`, etc.). Secret scanning if the project handles credentials or has `.env` files.

4. **Build** — Compilation steps based on detected build tools (`forge build`, `pnpm build`, `cargo build`, `go build`, `docker build`, etc.). Only include if the project has build artifacts.

5. **Deploy** — Platform-specific deploy jobs based on detected deploy targets (Railway, Fly.io, Vercel, etc.).

**For each proposed job:**
- Derive the exact commands from the project's own config files — don't assume default commands.
- For monorepo/multi-package projects, determine if per-package jobs or matrix jobs are appropriate.

**Compare against existing workflows to classify each item:**

| Needed? | Exists in workflows? | Decision |
|---------|---------------------|----------|
| Yes | No | **Add** |
| Yes | Yes, but stale/misconfigured | **Update** (explain what changed) |
| No | Yes | **Remove** (tooling no longer present) |
| Yes | Yes, correctly configured | **Keep** |

### Phase 3: Present the plan

Present findings to the user:

```
## CI/CD Audit Report

### Actions to Add
- [ ] [action]: [rationale — what config/files were detected that justify this]

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
- When proposing a CI job, derive the exact commands from the project's own config (package.json scripts, Makefile targets, existing dev scripts) rather than assuming default commands.
- For monorepo/multi-package projects, detect package boundaries and create per-package or matrix jobs as appropriate.
- Don't propose actions for tools the project doesn't use. Only propose what the project profile supports.
