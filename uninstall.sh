#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILLS_DIR="$HOME/.claude/skills"
AGENTS_DIR="$HOME/.claude/agents"
HOOKS_DIR="$HOME/.claude/hooks"

GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

info()  { echo -e "${GREEN}[+]${NC} $1"; }
warn()  { echo -e "${YELLOW}[!]${NC} $1"; }

shopt -s nullglob

for skill_dir in "$REPO_DIR"/skills/*/; do
    skill_name="$(basename "$skill_dir")"
    target="$SKILLS_DIR/$skill_name"

    if [ -L "$target" ]; then
        existing="$(readlink "$target")"
        if [ "$existing" = "$skill_dir" ] || [ "$existing" = "${skill_dir%/}" ]; then
            rm "$target"
            info "$skill_name (skill) — removed"
        else
            warn "$skill_name (skill) — points elsewhere ($existing), skipping"
        fi
    fi
done

for agent_file in "$REPO_DIR"/agents/*.md; do
    agent_name="$(basename "$agent_file")"
    target="$AGENTS_DIR/$agent_name"

    if [ -L "$target" ]; then
        existing="$(readlink "$target")"
        if [ "$existing" = "$agent_file" ]; then
            rm "$target"
            info "${agent_name%.md} (agent) — removed"
        else
            warn "${agent_name%.md} (agent) — points elsewhere ($existing), skipping"
        fi
    fi
done

for hook_file in "$REPO_DIR"/hooks/*.sh; do
    hook_name="$(basename "$hook_file")"
    target="$HOOKS_DIR/$hook_name"

    if [ -L "$target" ]; then
        existing="$(readlink "$target")"
        if [ "$existing" = "$hook_file" ]; then
            rm "$target"
            info "${hook_name%.sh} (hook) — removed"
        else
            warn "${hook_name%.sh} (hook) — points elsewhere ($existing), skipping"
        fi
    fi
done

echo ""
info "Done. Removed all skills, agents, and hooks installed by this repo."
