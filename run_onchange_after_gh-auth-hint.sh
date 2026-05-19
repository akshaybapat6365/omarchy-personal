#!/usr/bin/env bash
# Reminds the user to authenticate gh CLI if not already.
set -euo pipefail
log() { printf '[chezmoi/gh-auth] %s\n' "$*"; }

command -v gh >/dev/null 2>&1 || { log "gh CLI not installed yet; install via metapac sync first"; exit 0; }

if gh auth status >/dev/null 2>&1; then
  log "gh CLI already authenticated"
else
  cat <<'MSG'
[chezmoi/gh-auth] gh CLI not authenticated.

Run interactively after first apply:
    gh auth login
MSG
fi
