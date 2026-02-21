---
name: claudemd-auditor
description: Audit CLAUDE.md files for redundancy, verbosity, and content better stored in memory. Triggers on "audit claudemd", "review claude.md", "slim down claude.md", "optimize claude.md", "claudemd audit".
---

# CLAUDE.md Auditor

Analyze all CLAUDE.md files for a project, identify savings from redundancy, verbosity, and memory-movable content, and offer to apply fixes.

## Workflow

### Phase 1: Collect all CLAUDE.md files

Read every CLAUDE.md that applies to this project:

1. Project root `CLAUDE.md`
2. Any `packages/*/CLAUDE.md` (monorepo sub-packages)
3. User-level memory: `~/.claude/CLAUDE.md` (if exists)
4. Project memory: `~/.claude/projects/<project-path>/CLAUDE.md` (if exists)

For each file, record:
- Full path
- Line count
- Estimated token count (lines * 1.7 as rough heuristic)

### Phase 2: Analyze for issues

Scan each file for three categories of issues:

#### 2a. Redundancy

- Instructions that say the same thing in different words within one file
- Rules restated across multiple CLAUDE.md files
- Content that duplicates information from docs referenced by CLAUDE.md (e.g., architecture details that already live in a dedicated architecture doc)
- Sections that restate framework/tool defaults (things Claude already knows)

#### 2b. Verbosity

- Wordy phrasing that can be compressed without losing meaning
- Apply the "would a senior engineer need this spelled out?" test
- Overlong examples where a one-liner would suffice
- Unnecessary caveats, hedging, or repetitive formatting
- Multi-sentence rules that could be a single sentence

#### 2c. Memory candidates

Content that is stable, rarely changes, and doesn't need to be checked into the repo:

- Personal preferences (editor settings, preferred style choices)
- Environment-specific paths or URLs
- API keys, contract addresses, deploy targets for specific environments
- Tool configurations that are user-specific
- Local port assignments or machine-specific setup

These belong in project memory (`~/.claude/projects/<path>/CLAUDE.md`) which is gitignored and persists across sessions.

### Phase 3: Present findings

Output a structured report grouped by file and category:

```
## CLAUDE.md Audit Report

### File: CLAUDE.md (247 lines, ~420 tokens)

#### Redundancy
- [ ] Lines X-Y: [description] — duplicates [other location]

#### Verbosity
- [ ] Lines X-Y: [current text snippet] → [compressed version]

#### Memory Candidates
- [ ] Lines X-Y: [content] — stable/personal, move to project memory

### File: packages/frontend/CLAUDE.md (50 lines, ~85 tokens)
...

### Summary
- Current: X total lines / ~Y tokens across N files
- After fixes: ~X lines / ~Y tokens (Z% reduction)
```

Ask the user which changes to apply. They can approve all, select specific items, or skip categories entirely.

### Phase 4: Apply approved changes

1. Edit CLAUDE.md files to compress approved verbose sections (in-place rewrites)
2. Remove approved redundant content
3. Move approved memory candidates to `~/.claude/projects/<path>/CLAUDE.md` (create the file if needed, append to existing content)
4. Verify no cross-references broke by grepping for any paths or section names that were moved or removed
5. Present a brief summary of what changed

## Guidelines

- **Be specific.** Quote line numbers and actual text, not vague observations.
- **Preserve intent.** Compress prose, don't change behavior or remove rules.
- **Conservative memory moves.** Only suggest moving content that is truly stable and personal/environment-specific. Repo-essential content (build commands, quality standards, workflow steps) stays in the repo.
- **Show before/after** for every verbosity fix so the user can judge.
- **Don't touch intentionally detailed sections.** "Mistakes to Avoid" stories, debugging war stories, and similar sections are detailed on purpose — flag them as candidates only if they are genuinely redundant.
- **Respect the doc hierarchy.** If content belongs in a `docs/` file rather than CLAUDE.md, suggest moving it there (not to memory). Memory is only for non-repo content.
- **No false positives.** If a file is already lean, say so. Don't manufacture issues to justify the audit.
