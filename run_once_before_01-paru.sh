#!/usr/bin/env bash
# Install paru if not already present. Runs ONCE per machine, before dotfiles apply.
set -euo pipefail
log() { printf '[chezmoi/paru] %s\n' "$*"; }

if command -v paru >/dev/null 2>&1; then
  log "paru already installed at $(command -v paru)"
  exit 0
fi

log "installing paru from AUR (requires sudo for makepkg -si)"
sudo pacman -S --noconfirm --needed base-devel git
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
git clone https://aur.archlinux.org/paru.git "$tmp/paru"
cd "$tmp/paru"
makepkg -si --noconfirm
log "paru installed at $(command -v paru)"
