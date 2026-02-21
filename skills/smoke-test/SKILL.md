---
name: smoke-test
description: Generate and maintain a local deploy script (scripts/deploy.sh). Discovers project services, deploys them locally, and health-checks each one. Use when the user asks to "smoke test", "deploy locally", "test local deploy", "update deploy script", "run deploy", or "run smoke test".
---

# Local Deploy Script

Generate and maintain a `scripts/deploy.sh` script that deploys the project locally and health-checks each service. Designed to be called repeatedly — each invocation re-audits the project and adds, removes, or updates stages to match what's currently deployed.

## Workflow

### Phase 1: Discover project state

Build a project profile by detecting:

1. **Language & runtime** — Check file extensions and config files (`pyproject.toml`, `package.json`, `go.mod`, `Cargo.toml`, etc.). Note the minimum required version (e.g., `requires-python = ">=3.11"`).
2. **Package manager** — pip/uv/poetry, npm/yarn/pnpm, cargo, go modules, etc.
3. **CLI entry point** — `main.py`, `src/index.ts`, `cmd/main.go`, `Cargo.toml [[bin]]`, etc.
4. **CLI commands** — Parse argument parsers or command definitions to find subcommands.
5. **Key modules** — Identify services, servers, and infrastructure components (databases, chain nodes, etc.).
6. **Existing scripts/deploy.sh** — If present, read it to understand current stages and compare with detected state.

### Phase 2: Design stages

Map discovered state to stages. **Only include stages for services and infrastructure that are implemented.**

Standard stage ordering:

1. **Environment** — Required tools and runtimes are available (version checks, binary existence)
2. **Build** — Compile/build steps needed before services can start (e.g., `forge build`, `pnpm build`, `cargo build`)
3. **Start services** — Start infrastructure (database, chain node, message queue) and application services (backend, frontend, indexer). Use a cleanup trap (`trap cleanup EXIT`) to tear down all started services on both success and failure.
4. **Health-check** — Verify each service responds correctly (HTTP endpoints return 200, RPC nodes answer queries, databases accept connections, pages load)

If an existing `scripts/deploy.sh` exists, produce a diff:
- Stages to **add** (new services or infrastructure detected since last run)
- Stages to **remove** (services removed)
- Stages to **update** (ports, commands, or endpoints changed)
- Stages **unchanged**

### Phase 3: Execute

1. Write or update `scripts/deploy.sh` (create the `scripts/` directory if needed)
2. Script structure:
   - `#!/usr/bin/env bash`
   - `set -euo pipefail`
   - Each stage is a function: `stage_N_name()`
   - Each stage prints `--- Stage N: <name> ---` before running
   - On success: prints `  PASS: <check>`
   - On failure: prints `  FAIL: <check>` and exits immediately
   - Final line on success: `echo "DEPLOY OK"`
   - The `set -e` flag handles fail-fast automatically
3. Run `chmod +x scripts/deploy.sh`

### Phase 4: Verify

1. Run `./scripts/deploy.sh`
2. Confirm it exits 0 with `DEPLOY OK`
3. If it fails, diagnose and fix the script (not the project code — the script should reflect reality)
4. Report result to user

## Guidelines

- **Deploy only** — No static analysis, linting, typechecking, or tests. CI handles verification.
- **Idempotent** — Safe to run repeatedly. No side effects beyond temporary files (cleaned up).
- **Only deploy what's implemented** — Never include services that aren't wired up yet.
- **Fast** — Prefer offline stages, but if the feature being tested requires network (e.g., fetching exchange data), include it. Guard network stages with a credentials check — if credentials aren't configured, prompt the user interactively (via `read -p`) and continue. Never persist credentials or silently skip functional stages.
- **Language-agnostic** — Detect Python/Node/Go/Rust/etc. patterns from config files. Don't hardcode for any language.
- **Portable** — Use POSIX-compatible bash. Avoid platform-specific commands where possible.
- **Minimal output on success** — Each stage prints its name and PASS/FAIL. No verbose logs unless a stage fails.
- **No project code changes** — The skill only creates/updates `scripts/deploy.sh`. It never modifies source code, tests, or configuration.
