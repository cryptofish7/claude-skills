---
name: smoke-test
description: Generate and maintain a local smoke test script (deploy.sh). Discovers project tooling, tests only what's implemented, and grows as features are added. Use when the user asks to "smoke test", "deploy locally", "test local deploy", "update deploy script", "run deploy", or "run smoke test".
---

# Smoke Test

Generate and maintain a `deploy.sh` script that verifies the project runs correctly locally. Designed to be called repeatedly — each invocation re-audits the project and adds, removes, or updates stages to match what's currently implemented.

## Workflow

### Phase 1: Discover project state

Build a project profile by detecting:

1. **Language & runtime** — Check file extensions and config files (`pyproject.toml`, `package.json`, `go.mod`, `Cargo.toml`, etc.). Note the minimum required version (e.g., `requires-python = ">=3.11"`).
2. **Package manager** — pip/uv/poetry, npm/yarn/pnpm, cargo, go modules, etc.
3. **Tooling configs** — Lint (ruff, eslint), format (ruff, prettier), typecheck (mypy, pyright, tsc). Only include tools that are configured in the project.
4. **Test framework** — pytest, jest, vitest, go test, cargo test, etc. Check for test files and config.
5. **CLI entry point** — `main.py`, `src/index.ts`, `cmd/main.go`, `Cargo.toml [[bin]]`, etc.
6. **CLI commands** — Parse argument parsers or command definitions to find subcommands.
7. **Stub detection** — For each command/feature, check whether it's functional or a stub:
   - Look for: `"Not yet implemented"`, `"TODO"`, `pass` as sole body, placeholder prints, `unimplemented!()` macro
   - Check if the command has corresponding tests that exercise real logic (not just argument parsing)
   - A command is **functional** if it has real implementation code AND passing tests
8. **Key modules** — Identify importable modules that represent core functionality.
9. **Existing deploy.sh** — If present, read it to understand current stages and compare with detected state.

Key files to check:
- `pyproject.toml`, `package.json`, `go.mod`, `Cargo.toml`
- `Makefile`, `Justfile`, `Taskfile.yml`
- CLI entry points and their argument parsers
- Test directories and test files

### Phase 2: Design stages

Map discovered state to stages. **Only include stages for things that are implemented and working.** Skip stubs.

Standard stage ordering:

1. **Environment** — Runtime version check, required packages importable
2. **Static analysis** — Linter and typechecker pass (only if tools are configured)
3. **Tests** — Test runner with fail-fast flag (`pytest -x`, `npm test -- --bail`, `go test -failfast`)
4. **CLI smoke** — `--help` exits 0 for the main command and all subcommands
5. **Import smoke** — All key modules import without error
6. **Functional tests** — Run actual commands that are wired up (not stubs) with safe inputs. Examples:
   - A backtest command with a known strategy and small date range
   - A build command that produces expected output
   - A server that starts and responds to a health check, then shuts down

If an existing `deploy.sh` exists, produce a diff:
- Stages to **add** (new functionality detected since last run)
- Stages to **remove** (functionality removed or reverted to stub)
- Stages to **update** (tooling or commands changed)
- Stages **unchanged**

### Phase 3: Execute

1. Write or update `deploy.sh` in the project root
2. Script structure:
   - `#!/usr/bin/env bash`
   - `set -euo pipefail`
   - Each stage is a function: `stage_N_name()`
   - Each stage prints `--- Stage N: <name> ---` before running
   - On success: prints `  PASS: <check>`
   - On failure: prints `  FAIL: <check>` and exits immediately
   - Final line on success: `echo "DEPLOY OK"`
   - The `set -e` flag handles fail-fast automatically
3. Run `chmod +x deploy.sh`

### Phase 4: Verify

1. Run `./deploy.sh`
2. Confirm it exits 0 with `DEPLOY OK`
3. If it fails, diagnose and fix the script (not the project code — the script should reflect reality)
4. Report result to user

## Guidelines

- **Idempotent** — Safe to run repeatedly. No side effects beyond temporary files (cleaned up).
- **Only test what's implemented** — Never test stub commands. If a command prints "not yet implemented", skip it.
- **Fast** — Prefer offline stages, but if the feature being tested requires network (e.g., fetching exchange data), include it. Guard network stages with a credentials check — if credentials aren't configured, prompt the user interactively (via `read -p`), persist to `.env`, and continue. Never silently skip functional stages.
- **Use project tooling** — Don't install new tools. Use whatever lint/test/typecheck is already configured.
- **Language-agnostic** — Detect Python/Node/Go/Rust/etc. patterns from config files. Don't hardcode for any language.
- **Portable** — Use POSIX-compatible bash. Avoid platform-specific commands where possible.
- **Minimal output on success** — Each stage prints its name and PASS/FAIL. No verbose logs unless a stage fails.
- **No project code changes** — The skill only creates/updates `deploy.sh`. It never modifies source code, tests, or configuration.
