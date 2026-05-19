#!/usr/bin/env bash
# Install global npm packages captured from main machine.
set -euo pipefail
log() { printf '[chezmoi/npm-globals] %s\n' "$*"; }

command -v npm >/dev/null 2>&1 || { log "npm not on PATH; skipping (install Node via mise first)"; exit 0; }

PKGS=(
  "@openai/codex"
  "bun"
  ccusage
  cline
  kanban
  oh-my-claude-sisyphus
  oh-my-codex
  "@code-yeongyu/comment-checker"
  "@involvex/youtube-music-cli"
)

log "installing ${#PKGS[@]} global npm packages"
npm install -g --silent "${PKGS[@]}" || log "some npm installs failed; re-run manually if needed"
