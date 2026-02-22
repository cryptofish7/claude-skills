---
name: setup-workflow
description: Set up the autonomous post-task workflow for a project. Injects the standard development pipeline into CLAUDE.md and installs all required skills and agents (docs-consolidator, ci-cd-pipeline, smoke-test, bug-bash-update, code-reviewer, debugger). Use at the start of a new project. Triggers on "setup workflow", "init workflow", "add workflow", or "set up project workflow".
---

# Setup Workflow

Install the autonomous post-task development pipeline into a project's CLAUDE.md. All dependency skills and agents must be installed before running this skill.

## Dependencies

This workflow requires 6 tools:

| Dependency | Type | Live path |
|-----------|------|-----------|
| docs-consolidator | Skill | `~/.claude/skills/docs-consolidator/SKILL.md` |
| ci-cd-pipeline | Skill | `~/.claude/skills/ci-cd-pipeline/SKILL.md` |
| smoke-test | Skill | `~/.claude/skills/smoke-test/SKILL.md` |
| bug-bash-update | Skill | `~/.claude/skills/bug-bash-update/SKILL.md` |
| code-reviewer | Agent | `~/.claude/agents/code-reviewer.md` |
| debugger | Agent | `~/.claude/agents/debugger.md` |

## Workflow

### Phase 1: Check dependencies

For each dependency in the table above, check if the live file exists:

1. **Skills:** Check that `SKILL.md` exists at the live path.
2. **Agents:** Check that the agent `.md` file exists at the live path.
3. **ci-cd-pipeline references:** Also check this additional file:
   - `~/.claude/skills/ci-cd-pipeline/references/deploy-prerequisites.md`

If all dependencies are present, proceed to Phase 2.

If any are missing, report which ones and stop:
```
Missing dependencies:
- [dependency name]: expected at [path]
Install the missing skills/agents before running setup-workflow.
```

### Phase 2: Detect CLAUDE.md

Search for the project's CLAUDE.md file:
1. Check for `CLAUDE.md` in the project root
2. Check for `docs/CLAUDE.md`
3. Check if root `CLAUDE.md` is a symlink to `docs/CLAUDE.md`

If found, note the path. If not found, note that a new one will be created.

### Phase 3: Read current state

If CLAUDE.md exists:
1. Read it fully
2. Check if a `## Workflow` section already exists
3. Note the line range of the existing Workflow section (from `## Workflow` to the next `## ` heading or end of file)

### Phase 4: Inject workflow

Read `references/workflow-template.md` — this is the canonical workflow content.

**If a Workflow section exists:** Replace it (from `## Workflow` up to but not including the next `---` or `## ` heading) with the content of `workflow-template.md`.

**If CLAUDE.md exists but has no Workflow section:** Insert the workflow content after the first heading block (title + any introductory text before the first `---`).

**If no CLAUDE.md exists:** Create a new `CLAUDE.md` in the project root with this structure:
```markdown
# CLAUDE.md
## Project — Development Guide

This file provides context for Claude Code sessions working on this project.

---

[workflow-template.md content here]

---

## Commands

[Auto-detect from pyproject.toml / package.json / Makefile / Cargo.toml and list the project's lint, format, typecheck, and test commands]

---

## Mistakes to Avoid

*Claude: After any correction, add a rule here. Be specific.*
```

### Phase 5: Verify

1. Read the updated CLAUDE.md
2. Confirm the Workflow section contains the full pipeline
3. Confirm no other sections were accidentally modified
4. Report a summary of all changes made

## Guidelines

- Never modify any section of CLAUDE.md outside the Workflow section (unless creating a new file)
- The workflow template in `references/workflow-template.md` is the single source of truth
- If auto-detecting commands for a new CLAUDE.md, prefer reading the project's config files over guessing
- If a dependency is missing, tell the user to install it rather than attempting to create it
