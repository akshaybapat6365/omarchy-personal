#!/usr/bin/env bash
# Make Quickshell the default shell instead of Waybar.
# Quickshell autostart is wired in via dot_config/hypr/autostart.conf.
set -euo pipefail
log() { printf '[chezmoi/quickshell-default] %s\n' "$*"; }

if command -v omarchy >/dev/null 2>&1; then
  log "toggling waybar off (idempotent)"
  omarchy toggle waybar || true
else
  log "omarchy command not found; skipping waybar toggle"
fi
