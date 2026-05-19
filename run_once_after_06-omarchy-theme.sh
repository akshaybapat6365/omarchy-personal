#!/usr/bin/env bash
# Set the active Omarchy theme to aether (or whichever theme this user prefers).
set -euo pipefail
log() { printf '[chezmoi/omarchy-theme] %s\n' "$*"; }

command -v omarchy >/dev/null 2>&1 || { log "omarchy command not found; skipping theme set"; exit 0; }

THEME="aether"
if omarchy theme list 2>/dev/null | grep -qw "$THEME"; then
  log "setting omarchy theme: $THEME"
  omarchy theme set "$THEME" 2>&1 | tail -3 || log "theme set returned non-zero; re-run manually"
else
  log "theme '$THEME' not installed yet; ensure 'aether' is in metapac/groups/desktop.toml"
fi
