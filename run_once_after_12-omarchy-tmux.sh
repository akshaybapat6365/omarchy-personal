#!/usr/bin/env bash
# Install the omarchy-tmux theme-sync hook so tmux picks up Omarchy theme
# changes. Verified install URL (2026-05-19):
#   joaofelipegalvao/omarchy-tmux (branch: main)
set -euo pipefail
log() { printf '[chezmoi/omarchy-tmux] %s\n' "$*"; }

# The installer writes into ~/.config/tmux and adds a theme hook. Re-running
# it is benign (overwrites existing managed files with the same content),
# but we still gate on a marker file to keep this cheap on repeat applies.
MARKER="${XDG_CONFIG_HOME:-$HOME/.config}/tmux/.omarchy-tmux-installed"
if [[ -f "$MARKER" ]]; then
  log "omarchy-tmux already installed (marker present)"
  exit 0
fi

log "installing omarchy-tmux"
curl -fsSL https://raw.githubusercontent.com/joaofelipegalvao/omarchy-tmux/main/install.sh | bash

mkdir -p "$(dirname "$MARKER")"
touch "$MARKER"
