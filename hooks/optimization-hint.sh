#!/usr/bin/env bash
# UserPromptSubmit hook: emit a one-line optimization hint when a session
# has accumulated 8+ tool calls and the prompt is non-exploratory.

set -euo pipefail

INPUT=$(cat)

PROMPT=$(echo "$INPUT" | jq -r '.prompt // ""')
TRANSCRIPT=$(echo "$INPUT" | jq -r '.transcript_path // ""')

# Skip exploratory prompts
if echo "$PROMPT" | grep -qiE '^\s*(what|how does|explain|show me|where is|find|search|explore|look at|read|understand)\b'; then
  exit 0
fi

# Need a transcript to count tool calls
if [[ -z "$TRANSCRIPT" || ! -f "$TRANSCRIPT" ]]; then
  exit 0
fi

# Count tool_use blocks in the transcript JSONL
TOTAL=$(grep -c '"tool_use"' "$TRANSCRIPT" 2>/dev/null || echo 0)

if (( TOTAL < 8 )); then
  exit 0
fi

# Count by tool type (|| true prevents pipefail on zero matches)
READ_COUNT=$( (grep -oE '"name"\s*:\s*"(Read|Grep|Glob)"' "$TRANSCRIPT" 2>/dev/null || true) | wc -l | tr -d ' ')
EDIT_COUNT=$( (grep -oE '"name"\s*:\s*"(Edit|Write)"' "$TRANSCRIPT" 2>/dev/null || true) | wc -l | tr -d ' ')
BASH_COUNT=$( (grep -oE '"name"\s*:\s*"Bash"' "$TRANSCRIPT" 2>/dev/null || true) | wc -l | tr -d ' ')
TASK_COUNT=$( (grep -oE '"name"\s*:\s*"Task"' "$TRANSCRIPT" 2>/dev/null || true) | wc -l | tr -d ' ')

# Pick the dominant category and emit a hint
if (( READ_COUNT > EDIT_COUNT && READ_COUNT > BASH_COUNT && READ_COUNT > TASK_COUNT )); then
  echo "Hint: This session has many search/read calls — consider using /memory to save key findings or an Explore agent for broad searches."
elif (( EDIT_COUNT > READ_COUNT && EDIT_COUNT > BASH_COUNT && EDIT_COUNT > TASK_COUNT )); then
  echo "Hint: This session has many edit/write calls — consider creating a reusable skill or script for this pattern."
elif (( BASH_COUNT > READ_COUNT && BASH_COUNT > EDIT_COUNT && BASH_COUNT > TASK_COUNT )); then
  echo "Hint: This session has many shell calls — consider adding a Makefile target or alias for repeated commands."
elif (( TASK_COUNT > READ_COUNT && TASK_COUNT > EDIT_COUNT && TASK_COUNT > BASH_COUNT )); then
  echo "Hint: This session has many subagent calls — consider consolidating related work into fewer, more focused agents."
else
  echo "Hint: This session has $TOTAL+ tool calls — consider a skill or /memory for repeated patterns."
fi

exit 0
