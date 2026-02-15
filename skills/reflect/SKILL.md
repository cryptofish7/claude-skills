---
name: reflect
description: Analyze the current conversation for learnings and persist approved insights. Triggers on "reflect", "retrospective", "session review", "what did we learn", "conversation review".
---

# Reflect

Analyze the current conversation session, extract actionable insights, and persist approved learnings to the appropriate destinations.

## Workflow

### Phase 1: Conversation Analysis

Scan the full conversation context for significant events:

- **Tasks completed** — What was built, fixed, or changed
- **Errors encountered** — Build failures, wrong commands, broken tests, misconfigurations
- **User corrections** — Rejected approaches, redirections, explicit feedback
- **Decisions made** — Architectural choices, trade-offs, tool selections
- **Patterns observed** — Repeated workflows, friction points, workarounds used more than once

Filter ruthlessly. Only keep medium/high significance findings — things that would save time or prevent mistakes in future sessions.

### Phase 2: Extract Insights

Classify each finding into one of five categories based on where it should be persisted:

| Category | Destination |
|---|---|
| Mistakes to avoid | `CLAUDE.md` "Mistakes to Avoid" section (append) |
| Skill opportunities | `~/.claude/skills/<name>/SKILL.md` (create stub) |
| Skill improvements | Edit existing skill's `SKILL.md` |
| Memory candidates | `~/.claude/projects/<path>/CLAUDE.md` (append) |
| Process improvements | Edit `CLAUDE.md` workflow sections |

For each finding, draft the exact content that would be written (the rule text, the stub, the edit, etc.).

### Phase 3: Present Findings

Output a structured report:

```
## Session Reflection

**Session summary:** [1-2 sentence overview of what happened]
**Findings:** N total across M categories

### Mistakes to Avoid
1. [Finding title] — [Specific rule to add]

### Skill Opportunities
2. [Skill name] — [What it would do, why it's warranted]

### Skill Improvements
3. [Existing skill name] — [What to change and why]

### Memory Candidates
4. [Knowledge item] — [Why it's worth remembering]

### Process Improvements
5. [Workflow change] — [Before → After]
```

Skip empty categories. If the session is clean (no findings), report "Clean session — no actionable insights found." and stop.

### Phase 4: User Decision

Use `AskUserQuestion` with multi-select to let the user choose which findings to apply. Present each finding as a numbered option.

Then execute only the approved actions:

- **Mistakes to avoid:** Append to the "Mistakes to Avoid" section of the project's `CLAUDE.md`.
- **Skill opportunities:** Create a minimal stub at `~/.claude/skills/<name>/SKILL.md` with frontmatter (name, description) and a `# TODO` section describing the skill's purpose. User can flesh it out later with skill-creator.
- **Skill improvements:** Show the diff before editing. Edit the existing skill's `SKILL.md`.
- **Memory candidates:** Append to `~/.claude/projects/<path>/CLAUDE.md`. Create the file if it doesn't exist.
- **Process improvements:** Show the before/after for the affected CLAUDE.md section. Edit in place.

## Guidelines

- **Be selective.** 2 high-quality findings beats 10 marginal ones. If nothing significant happened, say so.
- **Rules must be specific and actionable.** "Be careful with deployments" is noise. "Always verify on-chain bytecode after contract deployment — Foundry logs success during simulation before broadcast" is useful.
- **Check for duplicates.** Read the existing "Mistakes to Avoid" section and project memory before proposing additions. Don't add what's already there.
- **Skill opportunities require evidence.** Either 2+ occurrences of the same workflow in the session, or explicit user frustration with a repeated manual process.
- **Memory candidates must be non-obvious.** Don't propose things already captured in project docs, config files, or CLAUDE.md.
- **Don't self-reference.** This skill should never propose adding itself as a finding.
- **Respect scope.** Project-specific knowledge goes to project memory. Universal lessons go to CLAUDE.md. Don't mix them.
