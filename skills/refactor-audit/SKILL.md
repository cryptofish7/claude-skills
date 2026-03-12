---
name: refactor-audit
description: Audit a codebase for refactoring opportunities across all packages/sections. Spawns parallel refactor subagents per section, collects suggestions without executing, then presents a ranked plan for approval. Use when the user asks to "audit for refactors", "refactoring suggestions", "code quality review", "refactor plan", "find refactoring opportunities", or "what should we clean up".
---

# Refactor Audit

Analyze a codebase for refactoring opportunities across all packages. Designed to be non-destructive — collects and ranks suggestions without executing any changes.

## Workflow

### Phase 1: Discover project sections

Scan the repository to identify distinct sections of the codebase. Each section should be a coherent unit (package, service, module) with its own domain.

1. Read the project root: `package.json`, workspace configs (`pnpm-workspace.yaml`, `lerna.json`), `Cargo.toml` workspaces, monorepo `packages/` or `apps/` directories, top-level folders with their own build configs.
2. For each discovered section, note:
   - Root path
   - Language/framework
   - Approximate size (file count)
   - Key focus areas for refactoring (infer from the section's domain — e.g., contracts care about gas optimization, frontends care about component decomposition)
3. Build a section table:

```
| Section | Root path | Language | Focus areas |
|---------|-----------|----------|-------------|
| ... | ... | ... | ... |
```

If the user provided an explicit section breakdown in their prompt, use that instead of auto-discovering.

### Phase 2: Parallel refactor analysis

Spawn one `refactor` subagent per section **in parallel**. Each subagent receives:

- The section's root path and focus areas from Phase 1
- The analysis-only instructions below

**Subagent instructions (include verbatim in each subagent prompt):**

> Analyze the code in `{root_path}` for refactoring opportunities. **Do NOT make any changes — analysis only.**
>
> For each suggestion, provide:
> 1. **What**: File(s) and specific code to change (include line numbers)
> 2. **Why**: How this improves the code (readability, performance, maintainability, correctness)
> 3. **Size**: `quick-win` (< 30 min), `moderate` (1-2 hrs), or `significant` (half-day+)
> 4. **Risk**: `low` (safe rename/extract), `medium` (logic restructure, needs tests), `high` (behavioral change, cross-cutting)
> 5. **Category**: One of: `dead-code`, `duplication`, `extraction`, `simplification`, `naming`, `type-safety`, `performance`, `error-handling`, `organization`
>
> Focus areas for this section: {focus_areas}
>
> Prioritize suggestions that:
> - Remove dead code or unused imports
> - Eliminate duplication (especially copy-pasted logic)
> - Extract reusable functions from repeated patterns
> - Simplify overly complex conditionals or nested logic
> - Improve type safety (remove `any`, add missing types)
>
> Flag any **cross-package opportunities** — shared logic that could move to a common package, inconsistent patterns across packages, or duplicated utilities.
>
> Output your suggestions as a structured list grouped by category.

### Phase 3: Consolidate and rank

After all subagents complete:

1. **Deduplicate**: Merge suggestions that touch the same code or propose the same change from different angles.
2. **Group cross-cutting suggestions**: Collect cross-package opportunities into their own section.
3. **Filter**: Drop suggestions that are:
   - Cosmetic-only with no readability benefit
   - High-risk with low payoff
   - Likely to cause merge conflicts with active work (check recent branches if possible)
4. **Rank** remaining suggestions by impact-to-effort ratio within each size category:
   - Quick wins first (highest value per minute)
   - Then moderate suggestions
   - Then significant suggestions

### Phase 4: Present the plan

Present the consolidated suggestions to the user:

```
## Refactor Audit Report

### Quick Wins
- [ ] **[category]** `path/to/file.ts:L42` — [what to change]. *Why:* [reason]. Risk: [low/medium].

### Moderate
- [ ] **[category]** `path/to/file.ts:L100-150` — [what to change]. *Why:* [reason]. Risk: [low/medium/high].

### Significant
- [ ] **[category]** `path/to/file.ts` + `other/file.ts` — [what to change]. *Why:* [reason]. Risk: [medium/high].

### Cross-Package Opportunities
- [ ] [description of shared pattern or utility that spans packages]

### Skipped
- [suggestion]: [why it was dropped]
```

Wait for user approval. The user may:
- Approve all suggestions
- Approve a subset (by checking items)
- Ask for more detail on specific suggestions
- Reject the audit entirely

**Do not execute any refactors until the user explicitly approves.**

### Phase 5: Execute approved refactors

After approval, for each approved suggestion:

1. Spawn a `refactor` subagent (or `general-purpose` for cross-package changes) to implement the change.
2. Group related suggestions into a single subagent call when they touch the same files.
3. After each subagent completes, run the section's test suite to verify behavior is preserved.
4. If tests fail, revert and flag the suggestion as blocked.

Commit approved changes in logical groups (one commit per category or per section, not one per suggestion).

## Guidelines

- **Behavior preservation is paramount.** Every suggestion must maintain identical external behavior. If a suggestion might change behavior, it must be flagged as high-risk.
- **Don't refactor what you don't understand.** If the subagent can't determine why code exists, flag it as "needs investigation" rather than suggesting removal.
- **Respect existing patterns.** If the codebase consistently uses a pattern (even if suboptimal), don't suggest changing isolated instances. Either suggest a codebase-wide migration or leave it alone.
- **No style wars.** Don't suggest reformatting, reordering imports, or changing naming conventions unless there's a concrete readability or correctness benefit.
- **Test coverage matters.** Suggestions affecting untested code should be flagged as higher risk. Consider suggesting tests as a prerequisite.
- **Cross-package suggestions need extra scrutiny.** Moving code between packages affects build order, dependencies, and deployment. Always flag these as `significant` size minimum.
