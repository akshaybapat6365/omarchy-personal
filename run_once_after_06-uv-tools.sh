#!/usr/bin/env bash
# Install uv-managed Python tools captured from main machine.
set -euo pipefail
log() { printf '[chezmoi/uv-tools] %s\n' "$*"; }

command -v uv >/dev/null 2>&1 || { log "uv not on PATH; skipping (install via paru -S uv first)"; exit 0; }

TOOLS=(
  claude-monitor
  claude-statusbar
  ddgs
  ytm-player
)

log "installing ${#TOOLS[@]} uv tools"
for t in "${TOOLS[@]}"; do
  uv tool install "$t" 2>&1 | tail -2 || log "uv tool install $t failed (re-run manually if needed)"
done
