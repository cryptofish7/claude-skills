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
2. Map changed files to BUG_BASH_GUIDE sections:
   - Read the existing section headings in `docs/BUG_BASH_GUIDE.md`
   - Match changed file paths to the section that covers that area of the app
   - Use directory structure and component names as signals (e.g., `components/auth/` → an "Authentication" section)
   - If no section matches, check if a new section is warranted for an entirely new feature

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

1. Read the deployment URL from `docs/BUG_BASH_GUIDE.md` (look in "Test Environment" or "Prerequisites" section).
2. If no URL is listed, stop and ask the user for the deployed URL.
3. NEVER use localhost. Bug bash verification must happen on a deployed build.
4. Open the deployment in the browser using browser automation tools.
5. Navigate to the relevant page/feature for the fix.
6. Visually confirm the fix works as expected:
   - Check that the bug behavior is no longer present
   - Check that the correct behavior is now shown
7. Take a screenshot as evidence.

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

## Verification Rules (MANDATORY)

These rules apply to ALL bug bash verification — both Phase 4 fix verification and general checklist testing.

1. **DO: Test in the browser** — ALL verification must happen via Claude in Chrome MCP tools (navigate, click, screenshot, read page). DO NOT use unit tests, `cast`, `forge test`, contract calls, or code review as verification. If the browser extension is not connected, stop and tell the user.

2. **DO: Test on a deployed build** — Read the deployment URL from `docs/BUG_BASH_GUIDE.md`. NEVER use `localhost`. Bug bash tests deployed code, not local dev servers.

3. **DO: Act autonomously in the browser** — Click buttons, navigate pages, scroll, take screenshots without asking user permission. Browser interactions during testing are routine actions. Only purchases, entering personal data, and account creation need explicit user approval.

4. **DO: Ask the user to unblock, never skip** — When blocked (wallet not connected, insufficient funds, auth required, extension not responding), tell the user exactly what's needed and wait. DO NOT silently skip items or mark them "cannot test" without first asking the user if they can resolve the blocker.

5. **DO: Follow marking conventions exactly:**
   - `[ ]` = unverified (not yet tested)
   - `[!]` = bug found (describe inline)
   - `[!] FIXED` = fix applied but NOT yet verified in browser
   - `[x]` = verified working in browser with screenshot evidence
   - NEVER mark `[x]` without having taken a browser screenshot confirming the behavior. Code review or test output is not sufficient.
