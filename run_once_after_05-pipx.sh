#!/usr/bin/env bash
# Install pipx-managed Python tools captured from main machine.
set -euo pipefail
log() { printf '[chezmoi/pipx] %s\n' "$*"; }

command -v pipx >/dev/null 2>&1 || { log "pipx not on PATH; skipping (install via paru -S python-pipx first)"; exit 0; }

PKGS=(
  pytest
  terminal-ai-assistant
)

for p in "${PKGS[@]}"; do
  pipx install "$p" 2>&1 | tail -2 || log "pipx install $p skipped (likely already present)"
done
