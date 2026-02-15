#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
SKILLS_DIR="$CLAUDE_DIR/skills"
AGENTS_DIR="$CLAUDE_DIR/agents"
HOOKS_DIR="$CLAUDE_DIR/hooks"

GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m'

info()  { echo -e "${GREEN}[+]${NC} $1"; }
warn()  { echo -e "${YELLOW}[!]${NC} $1"; }
error() { echo -e "${RED}[x]${NC} $1"; }

check_not_symlink() {
    local dir="$1" name="$2"
    if [ -L "$dir" ]; then
        error "$dir is a symlink to $(readlink "$dir")"
        echo "    Cannot install individual ${name} into a symlinked directory."
        echo "    Remove the symlink and create a real directory first:"
        echo "      rm \"$dir\" && mkdir -p \"$dir\""
        return 1
    fi
    return 0
}

check_not_symlink "$SKILLS_DIR" "skills" || exit 1
check_not_symlink "$AGENTS_DIR" "agents" || exit 1

mkdir -p "$SKILLS_DIR" "$AGENTS_DIR" "$HOOKS_DIR"

shopt -s nullglob

for skill_dir in "$REPO_DIR"/skills/*/; do
    skill_name="$(basename "$skill_dir")"
    target="$SKILLS_DIR/$skill_name"

    if [ -L "$target" ]; then
        existing="$(readlink "$target")"
        if [ "$existing" = "$skill_dir" ] || [ "$existing" = "${skill_dir%/}" ]; then
            info "$skill_name (skill) — already linked"
            continue
        else
            warn "$skill_name (skill) — replacing symlink (was $existing)"
        fi
    elif [ -d "$target" ]; then
        warn "$skill_name (skill) — directory exists, skipping (remove it manually to install)"
        continue
    fi

    ln -sfn "${skill_dir%/}" "$target"
    info "$skill_name (skill) — installed"
done

for agent_file in "$REPO_DIR"/agents/*.md; do
    agent_name="$(basename "$agent_file")"
    target="$AGENTS_DIR/$agent_name"

    if [ -L "$target" ]; then
        existing="$(readlink "$target")"
        if [ "$existing" = "$agent_file" ]; then
            info "${agent_name%.md} (agent) — already linked"
            continue
        else
            warn "${agent_name%.md} (agent) — replacing symlink (was $existing)"
        fi
    elif [ -f "$target" ]; then
        warn "${agent_name%.md} (agent) — file exists, skipping (remove it manually to install)"
        continue
    fi

    ln -sf "$agent_file" "$target"
    info "${agent_name%.md} (agent) — installed"
done

for hook_file in "$REPO_DIR"/hooks/*.sh; do
    hook_name="$(basename "$hook_file")"
    target="$HOOKS_DIR/$hook_name"

    if [ -L "$target" ]; then
        existing="$(readlink "$target")"
        if [ "$existing" = "$hook_file" ]; then
            info "${hook_name%.sh} (hook) — already linked"
            continue
        else
            warn "${hook_name%.sh} (hook) — replacing symlink (was $existing)"
        fi
    elif [ -f "$target" ]; then
        warn "${hook_name%.sh} (hook) — file exists, skipping (remove it manually to install)"
        continue
    fi

    ln -sf "$hook_file" "$target"
    info "${hook_name%.sh} (hook) — installed"
done

echo ""
info "Done. Skills, agents, and hooks are now available in Claude Code."
