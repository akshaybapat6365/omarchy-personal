#!/usr/bin/env bash
# Install all packages declared in metapac/groups/*.toml. Idempotent.
set -euo pipefail
log() { printf '[chezmoi/metapac-sync] %s\n' "$*"; }

cd "$HOME/.local/share/chezmoi/metapac"
log "running metapac sync (this may take a while on a fresh machine)"
metapac sync --config metapac.toml || {
  log "metapac sync returned non-zero — review and re-run manually if needed"
  exit 0  # don't block the rest of apply
}
