---
name: skill-reviewer
description: Audit installed skills and agents for bloat, overlap, and improvement opportunities. Use when the user wants to review, audit, list, or improve their skills and agents. Triggers on "review skills", "audit skills", "list skills", "skill review", "improve skills".
---

# Skill Reviewer

Inventory all installed skills and agents, then deep-review selected ones for conciseness, clarity, overlap, and token efficiency.

## Workflow

### Phase 1: Build inventory

Scan all skill and agent locations. For each item, count lines in the main file and any reference files.

**Locations:**
- Global skills: `~/.claude/skills/*/SKILL.md` + `references/*.md`
- Global agents: `~/.claude/agents/*.md`
- Project skills: `.claude/skills/*/SKILL.md` + `references/*.md`
- Project agents: `.claude/agents/*.md`

Build a table sorted by total lines (largest first):

```
| Scope   | Name             | Type  | Main Lines | Ref Lines | Total |
|---------|------------------|-------|------------|-----------|-------|
| global  | ci-cd-pipeline   | skill | 120        | 45        | 165   |
| project | bug-bash-update  | skill | 109        | 0         | 109   |
| global  | debugger         | agent | 98         | 0         | 98    |
```

### Phase 2: Ask what to review

Present the table. Ask the user which items to deep-review. They can pick one, several, or "all".

### Phase 3: Deep review

For each selected item, read the full content and analyze:

1. **Conciseness** — Verbose sections, redundant instructions, unnecessary examples. Flag anything that could be shorter without losing meaning.
2. **Clarity** — Ambiguous instructions, missing context, unclear phase transitions. Would another LLM session interpret this correctly?
3. **Scope overlap** — Responsibilities duplicated with other skills/agents in the inventory. Note which items overlap and what to consolidate.
4. **Token efficiency** — Estimate token count (words * 1.3). Flag sections that consume disproportionate tokens relative to their value.
5. **Structural consistency** — Does it follow the same patterns (frontmatter, phases, guidelines) as other skills? Note deviations.

### Phase 4: Present findings with rewrites

For each issue, show:
- **Current text** (quoted)
- **Problem** (one sentence)
- **Suggested rewrite** (the improved version)

After presenting all findings, ask the user which changes to apply. Then apply the approved edits.

## Guidelines

- Be specific. "This section is verbose" is useless. "Lines 12-18 repeat the trigger list from the frontmatter" is actionable.
- Preserve intent. Compress prose, don't change behavior.
- Don't review this skill (skill-reviewer) unless explicitly asked.
- When estimating tokens, use the rough formula: word count * 1.3.
- If a skill has no issues worth flagging, say so briefly and move on.
