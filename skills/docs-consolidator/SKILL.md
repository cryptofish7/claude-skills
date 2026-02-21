---
name: docs-consolidator
description: Audit and consolidate project documentation in the docs/ folder. Use when the user wants to clean up docs, check docs are up to date, deduplicate information across docs, ensure information lives in the right doc, or reorganize documentation. Triggers on requests like "consolidate docs", "clean up documentation", "audit docs", "organize docs", "sync docs with code".
---

# Docs Consolidator

Audit, deduplicate, and reorganize project documentation so every piece of information has one home and all docs stay current.

## Workflow

### Phase 1: Build the inventory

1. Check if `.claude/doc-registry.md` exists in the project root.
   - **If it exists:** read it and use it as the authoritative registry. Skip to step 4.
   - **If it doesn't exist:** continue to step 2 to discover and generate one.
2. Find all documentation files: scan `docs/`, root `CLAUDE.md` (or `docs/CLAUDE.md` if symlinked), `README.md`, and any other `.md` files referenced by CLAUDE.md.
3. For each doc, read it and note:
   - What information it currently contains (section-level summary)
   - Its apparent purpose (infer from filename, headers, and content)
   - Its line count
4. If no registry existed, build one: assign each doc a purpose and ownership domain. Use these common categories as a guide:
   - **CLAUDE.md** — Orientation for Claude Code sessions: conventions, gotchas, pointers. NOT a wiki.
   - **PRD / product doc** — Product logic, user stories, feature specs, business rules
   - **Architecture doc** — System design, data flow, database schema, API endpoints
   - **Tasks / progress doc** — Current tasks, completed work, backlog
   - **Deployment / CI-CD docs** — Deployment config, pipelines, environment setup
   - **Security docs** — Threat models, trust assumptions, audit scope
   - **Testing docs** — Test checklists, QA guides
   - **Setup / infra docs** — Database setup, service config, hosting details
5. If the registry was generated (not loaded from file), write it to `.claude/doc-registry.md` in the project root using this format:

```markdown
# Document Registry

Each doc has ONE purpose. Information belongs in the doc that owns that domain.

| File | Purpose | Owns |
|------|---------|------|
| `path/to/doc.md` | Brief purpose | What information this doc is the canonical source for |

## Overlap Rules

- [category] → `canonical-doc.md`, not [other doc]
```

Present the generated registry to the user and ask for approval before continuing. The user may want to adjust purposes or ownership boundaries.

### Phase 2: Identify problems

Read every doc (if not already read in Phase 1) and compare against the registry. Flag:

- **Misplaced information**: content that belongs in a different doc per ownership rules (e.g., architecture details in CLAUDE.md, progress updates in an architecture doc)
- **Duplication**: the same information restated in multiple docs. Identify the canonical home and where the duplicates are.
- **Stale content**: references to removed code, outdated addresses, old instructions, TODOs that are done, etc. Cross-check against actual code when uncertain.
- **Missing information**: important topics not documented anywhere, or docs that reference sections that don't exist.
- **Poor organization**: docs where sections are out of logical order, or where related information is scattered across unrelated sections.

### Phase 3: Present the plan

Present findings as a structured report to the user:

```
## Doc Audit Report

### Misplaced Information
- [ ] [source doc] → [target doc]: [what to move]

### Duplications
- [ ] [info]: found in [doc A] and [doc B]. Keep in [canonical doc], remove from [other].

### Stale Content
- [ ] [doc]: [what's stale and why]

### Organization Issues
- [ ] [doc]: [what to reorder/restructure]
```

Ask the user to approve the plan before making any changes.

### Phase 4: Execute changes

After approval, apply changes doc by doc:

1. Move misplaced content to the correct doc
2. Deduplicate — keep the best version in the canonical location, replace duplicates with a brief cross-reference (e.g., "See `ARCHITECTURE.md` for database schema")
3. Remove or update stale content
4. Reorder sections for logical flow
5. Update any cross-references that broke due to moves

### Phase 5: Verify

1. Check that every doc has the content it should own and nothing else
2. Grep for broken cross-references (doc paths, section links)
3. If CLAUDE.md has a "Reference Documents" section, confirm it matches the actual docs
4. Present a brief summary of all changes made

## Guidelines

- Prefer cross-references over duplication. A one-line pointer is better than a restated paragraph.
- Don't merge docs unless the user explicitly asks. The goal is to put information in the right place, not reduce the number of files.
- Preserve the user's writing style and voice. Clean up structure, not prose.
- When uncertain whether content is stale, flag it for the user rather than deleting.
- If an `archive/` directory exists, move superseded docs there rather than deleting.
- Keep CLAUDE.md lean: orientation, commands, conventions, gotchas. Everything else belongs in a specific doc.
