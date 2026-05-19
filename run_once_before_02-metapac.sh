#!/usr/bin/env bash
# Install metapac + age + 1password-cli via paru. Runs ONCE before dotfiles apply.
set -euo pipefail
log() { printf '[chezmoi/metapac] %s\n' "$*"; }

NEEDED=(metapac age 1password-cli)
MISSING=()
for p in "${NEEDED[@]}"; do
  pacman -Qi "$p" >/dev/null 2>&1 || MISSING+=("$p")
done

if [ "${#MISSING[@]}" -eq 0 ]; then
  log "all prereqs present: ${NEEDED[*]}"
  exit 0
fi

log "installing missing: ${MISSING[*]}"
paru -S --noconfirm --needed "${MISSING[@]}"
