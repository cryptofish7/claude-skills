#!/usr/bin/env bash
prompt="$(cat)"
word_count=$(echo "$prompt" | wc -w | tr -d ' ')
if [ "$word_count" -gt 50 ]; then
  echo "[Hook note: This prompt is ${word_count} words. Please check that the desired outcome is clearly stated before proceeding. If it's ambiguous, ask a clarifying question.]"
fi
