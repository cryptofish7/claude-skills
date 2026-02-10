# CI/CD Actions Catalog

Each action has signals for when to add and when to remove. Use these to drive audit decisions.

---

## 1. Code Quality

### Lint

| Language | Tool | Add when | Remove when |
|----------|------|----------|-------------|
| Python | ruff check | `ruff` in deps or `[tool.ruff]` exists | No Python source files remain |
| Python | flake8 | `flake8` in deps and ruff not present | Migrated to ruff |
| JavaScript/TypeScript | eslint | `eslint` in deps or `.eslintrc*` exists | No JS/TS source files remain |
| Go | golangci-lint | `go.mod` exists | No Go source files remain |
| Rust | clippy | `Cargo.toml` exists | No Rust source files remain |

### Format

| Language | Tool | Add when | Remove when |
|----------|------|----------|-------------|
| Python | ruff format | `ruff` in deps | No Python source files remain |
| Python | black | `black` in deps and ruff not present | Migrated to ruff |
| JavaScript/TypeScript | prettier | `prettier` in deps or `.prettierrc*` exists | No JS/TS source files remain |
| Go | gofmt | `go.mod` exists (built-in, no dep needed) | No Go source files remain |
| Rust | rustfmt | `Cargo.toml` exists (built-in) | No Rust source files remain |

### Type Check

| Language | Tool | Add when | Remove when |
|----------|------|----------|-------------|
| Python | mypy | `mypy` in deps or `[tool.mypy]` exists | No typed Python files remain |
| Python | pyright | `pyright` in deps or `pyrightconfig.json` exists | No typed Python files remain |
| TypeScript | tsc | `tsconfig.json` exists | No TS source files remain |

---

## 2. Testing

### Unit Tests

| Language | Tool | Add when | Remove when |
|----------|------|----------|-------------|
| Python | pytest | `pytest` in deps or `tests/` directory exists | No test files remain |
| JavaScript/TypeScript | jest | `jest` in deps or `jest.config.*` exists | No test files remain |
| JavaScript/TypeScript | vitest | `vitest` in deps or `vitest.config.*` exists | No test files remain |
| Go | go test | `go.mod` exists and `*_test.go` files exist | No test files remain |
| Rust | cargo test | `Cargo.toml` exists and `#[test]` found in source | No test files remain |

**Coverage**: Add `--cov` / `--coverage` flag when coverage tooling is in deps (pytest-cov, c8, istanbul, etc.).

### Python version matrix

Add a version matrix when `requires-python` specifies a range (e.g., `>=3.11`). Test on the minimum version plus the latest stable.

### Node version matrix

Add a version matrix when `engines.node` specifies a range. Test on LTS versions within the range.

---

## 3. Security

### Dependency Audit

| Language | Tool | Add when | Remove when |
|----------|------|----------|-------------|
| Python | pip-audit | Any Python project with dependencies | No Python deps remain |
| JavaScript | npm audit | `package-lock.json` exists | No JS deps remain |
| JavaScript | yarn audit | `yarn.lock` exists | No JS deps remain |
| Rust | cargo audit | `Cargo.toml` with dependencies | No Rust deps remain |
| Go | govulncheck | `go.mod` with dependencies | No Go deps remain |

**Schedule**: Run on push to main + weekly cron (`0 9 * * 1`).

### Secrets Scanning

| Tool | Add when | Remove when |
|------|----------|-------------|
| gitleaks | `.env.example` exists, or project handles credentials/API keys/tokens | Never — always keep if added |

---

## 4. Build

### Docker Image Build

| Signal | Action |
|--------|--------|
| `Dockerfile` exists | Add docker build + push job |
| `Dockerfile` removed | Remove docker build job |
| `docker-compose.yml` only (no Dockerfile) | Skip — compose is for local dev |

Use `docker/build-push-action@v5`. Build on push to main, push to registry only on tag/release.

### Package Build

| Language | Signal | Action |
|----------|--------|--------|
| Python | `[build-system]` in pyproject.toml | Add `pip install -e .` verification step (already covered by test job install) |
| JavaScript | `package.json` with `build` script | Add `npm run build` / `yarn build` job |
| Go | `main.go` or `cmd/` directory | Add `go build ./...` job |
| Rust | `Cargo.toml` | Already covered by `cargo test` which compiles |

---

## 5. Deploy

### Platform Detection

| Signal | Platform | Action | Required secrets |
|--------|----------|--------|-----------------|
| `railway.json` or `railway.toml` | Railway | Add Railway deploy job via `railwayapp/deploy-action` | `RAILWAY_TOKEN` |
| `fly.toml` | Fly.io | Add Fly deploy job via `superfly/flyctl-actions` | `FLY_API_TOKEN` |
| `vercel.json` or `"vercel"` in deps | Vercel | Add Vercel deploy (usually auto, skip unless manual config needed) | `VERCEL_TOKEN`, `VERCEL_ORG_ID`, `VERCEL_PROJECT_ID` |
| `*.tf` files | Terraform | Add `terraform plan` on PR, `terraform apply` on merge | Provider-specific (e.g., `AWS_ACCESS_KEY_ID`) |
| `k8s/` or `kubernetes/` manifests | Kubernetes | Add kubectl apply job | `KUBECONFIG` |
| `appspec.yml` | AWS CodeDeploy | Add CodeDeploy job | `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_REGION` |
| `serverless.yml` | Serverless Framework | Add `serverless deploy` job | Provider-specific credentials |

**Prerequisites**: Each platform requires manual setup before the deploy workflow will function. See `deploy-prerequisites.md` for step-by-step setup guides.

**Deploy triggers**: Only on push to main (or tag for releases). Never on PRs.

**Environment protection**: Use GitHub environments with required reviewers for production deploys.

---

## Workflow File Organization

| File | Contains | Trigger |
|------|----------|---------|
| `ci.yml` | lint, format, typecheck, test | push to main + PRs |
| `security.yml` | dependency audit, secrets scan | push to main + weekly schedule |
| `deploy.yml` | build + deploy | push to main (or tags) |

Only create files for categories that have at least one action. Delete empty workflow files.
