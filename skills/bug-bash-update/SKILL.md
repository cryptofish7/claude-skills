---
name: bug-bash-update
description: Update docs/BUG_BASH_GUIDE.md after implementing features or fixing bugs. Adds checklist items for new features, annotates fixes, and verifies fixes in the browser before marking them complete. Triggers on "bug bash update", "update bug bash", "update testing checklist".
---

# Bug Bash Update

Automatically update `docs/BUG_BASH_GUIDE.md` after completing a task. Adds testable checklist items for new features, annotates bug fixes, and verifies fixes in the browser before marking them as verified.

**Key principle:** Browser verification is the ultimate test. Code review alone isn't enough to mark something verified.

## Workflow

### Phase 1: Discover what changed

1. Analyze the git diff to understand what changed. Try these in order until one produces results:
   - `git diff --cached` (staged changes)
   - `git diff main...HEAD` (branch diff)
   - `git log -1 --format="%H" | xargs git diff HEAD~1` (last commit)
2. Read the changed files to understand the scope of the change.
3. Note the commit prefix (`feat:`, `fix:`, `refactor:`, `docs:`, `chore:`, `test:`, `ci:`).
4. Summarize: what area of the app changed, and what's the user-visible impact?

If no meaningful changes are detected (e.g., only CI, docs, or config changes with no user-visible impact), report "No bug bash updates needed" and stop.

### Phase 2: Map changes to BUG_BASH_GUIDE sections

1. Read `docs/BUG_BASH_GUIDE.md` in full.
2. Use this file-path to section mapping to identify affected sections:

| File path pattern | BUG_BASH_GUIDE section |
|---|---|
| `packages/frontend/src/app/page.tsx`, `components/home/` | Home Page / Landing |
| `packages/frontend/src/app/forecaster/`, `components/forecaster/` | Forecaster Profile |
| `packages/frontend/src/app/register/`, `hooks/useRegister`, `hooks/useMetaTxRegister` | Registration |
| `packages/frontend/src/components/trading/`, `hooks/useBuy`, `hooks/useSell` | Trading |
| `packages/frontend/src/components/conditional/`, `hooks/useConditional` | Conditional Markets |
| `packages/frontend/src/components/history/`, `hooks/useHistory` | History / Portfolio |
| `packages/frontend/src/components/layout/`, `components/nav/` | Navigation / Layout |
| `packages/contracts/src/` | Smart Contracts (if user-facing behavior changed) |
| `packages/indexer/` | Data / Indexer (if user-facing behavior changed) |

3. If the change doesn't map to any section, check if a new section is warranted. Only create a new section for entirely new features.

### Phase 3: Generate updates

Based on the commit prefix and type of change:

**`feat:` — New feature**
- Add `- [ ]` checklist items to the appropriate section
- Each item must be specific, testable, and include the expected result
- Format: `- [ ] [Action to take] → [Expected result]`
- Add 2-5 items per feature, covering the happy path and key edge cases
- Example: `- [ ] Click "Register" with valid X handle → Token created, redirected to profile page`

**`fix:` — Bug fix**
- Find the matching `[!]` item in the guide that describes the bug
- Change `[!]` to `[!] FIXED` and append the PR/commit reference
- Format: `- [!] FIXED (PR #XX) Original bug description → Fix: [brief description of fix]`
- If no matching `[!]` item exists, add a new `[x]` item describing what was fixed (since it was never tracked as a bug)

**`refactor:` — Refactoring**
- Only update if user-visible behavior changed
- If purely internal, report "No bug bash updates needed" and stop

**`test:`, `ci:`, `docs:`, `chore:` — Non-user-facing**
- Typically no updates needed. Only update if there's a user-visible side effect.

### Phase 4: Verify in browser

This phase applies **only to `fix:` commits** that changed items from `[!]` to `[!] FIXED`.

1. Determine the deployment URL:
   - Check for a Vercel preview deployment: `gh pr list --state open --json url,headRefName | jq`
   - Fall back to the testnet URL in BUG_BASH_GUIDE (typically `https://forecaster-brown.vercel.app/`)
   - Fall back to `http://localhost:3000` if running locally
2. Open the deployment in the browser using browser automation tools.
3. Navigate to the relevant page/feature for the fix.
4. Visually confirm the fix works as expected:
   - Check that the bug behavior is no longer present
   - Check that the correct behavior is now shown
5. Take a screenshot as evidence.

**If verified successfully:**
- Change `[!] FIXED` to `[x]` with verification notes
- Format: `- [x] Original description → Verified: [what was confirmed, date]`

**If NOT verified:**
- Leave as `[!] FIXED` — do NOT mark `[x]`
- Report what's still broken and what was observed
- The orchestrator should loop back to fix the issue before re-verifying

**If browser verification is not possible** (no deployment available, page requires auth that can't be automated, etc.):
- Leave as `[!] FIXED`
- Note why verification couldn't be completed
- The item will be verified in the next manual bug bash

## Guidelines

- Never remove existing checklist items — only add or modify status markers
- Keep checklist items concise but specific enough to be independently testable
- When adding items for a new feature, look at existing items for style/format consistency
- Group related items together under the same section
- If a section doesn't exist for a new feature area, create it following the existing heading hierarchy
- Always include the PR or commit reference when annotating fixes
- Screenshots from browser verification should be saved with descriptive names (e.g., `history-tab-fix-verified.png`)
