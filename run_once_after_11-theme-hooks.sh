#!/usr/bin/env bash
# Install the theme-hook plugin manager (thpm), the theme-manager-plus UX
# layer, and the miasma theme. All three are idempotent: each block checks
# whether the tool/theme is already present before fetching.
#
# Verified install URLs (2026-05-19):
#   thpm:               OldJobobo/theme-hook-plugin-manager (branch: thpm)
#   theme-manager-plus: OldJobobo/theme-manager-plus        (branch: master)
#   miasma theme:       OldJobobo/omarchy-miasma-theme
set -euo pipefail
log() { printf '[chezmoi/theme-hooks] %s\n' "$*"; }

# 1. thpm — canonical theme-hook plugin manager.
if ! command -v thpm >/dev/null 2>&1; then
  log "installing thpm"
  curl -fsSL https://raw.githubusercontent.com/OldJobobo/theme-hook-plugin-manager/thpm/install.sh | bash
else
  log "thpm already installed"
fi

# 2. theme-manager-plus — theme switcher UX layer (provides omarchy-tmplus).
if ! command -v omarchy-tmplus >/dev/null 2>&1; then
  log "installing theme-manager-plus"
  curl -fsSL https://raw.githubusercontent.com/OldJobobo/theme-manager-plus/master/install.sh | bash
else
  log "theme-manager-plus already installed"
fi

# 3. miasma theme.
if command -v omarchy >/dev/null 2>&1; then
  if omarchy theme list 2>/dev/null | grep -qw miasma; then
    log "miasma theme already installed"
  else
    log "installing miasma theme"
    omarchy-theme-install https://github.com/OldJobobo/omarchy-miasma-theme.git || \
      log "omarchy-theme-install failed; re-run manually"
  fi
else
  log "omarchy command not found; skipping miasma theme install"
fi
