#!/usr/bin/env bash
# bootstrap.sh — fresh-machine bootstrap for akshaybapat6365/omarchy-personal.
# Run on top of a clean Omarchy install. Idempotent; safe to re-run.
#
# Usage:
#   sh -c "$(curl -fsLS https://raw.githubusercontent.com/akshaybapat6365/omarchy-personal/main/bootstrap.sh)"

set -euo pipefail

BLUE=$'\033[1;34m'; YELLOW=$'\033[1;33m'; RED=$'\033[1;31m'; NC=$'\033[0m'
log()  { printf '%s[omarchy-personal]%s %s\n' "$BLUE"   "$NC" "$*"; }
warn() { printf '%s[omarchy-personal]%s %s\n' "$YELLOW" "$NC" "$*"; }
die()  { printf '%s[omarchy-personal ERROR]%s %s\n' "$RED" "$NC" "$*" >&2; exit 1; }

# --- Sanity ---
[ -f /etc/arch-release ] || die "This script targets Arch/Omarchy."
command -v omarchy >/dev/null 2>&1 || warn "omarchy command not found; ensure stock Omarchy is installed first (https://github.com/basecamp/omarchy)"
[ "$EUID" -ne 0 ] || die "Do not run as root. Run as your user; sudo is invoked where needed."

# --- chezmoi ---
if ! command -v chezmoi >/dev/null 2>&1; then
  log "installing chezmoi to ~/.local/bin"
  sh -c "$(curl -fsLS https://get.chezmoi.io)" -- -b "$HOME/.local/bin"
fi
export PATH="$HOME/.local/bin:$PATH"

# --- paru (AUR helper) ---
# metapac prefers paru; user may also have yay, which is fine for daily use.
if ! command -v paru >/dev/null 2>&1; then
  log "installing paru from AUR"
  sudo pacman -S --noconfirm --needed base-devel git
  tmp=$(mktemp -d)
  git clone https://aur.archlinux.org/paru.git "$tmp/paru"
  (cd "$tmp/paru" && makepkg -si --noconfirm)
  rm -rf "$tmp"
fi

# --- age identity (for encrypted chezmoi files) ---
AGE_ID="$HOME/.config/chezmoi/age-identity.txt"
if [ ! -f "$AGE_ID" ]; then
  if command -v op >/dev/null 2>&1 && op vault list >/dev/null 2>&1; then
    log "fetching age identity from 1Password"
    mkdir -p "$(dirname "$AGE_ID")"
    op read "op://Personal/age-omarchy/private" > "$AGE_ID"
    chmod 600 "$AGE_ID"
    log "age identity written to $AGE_ID"
  else
    warn "1Password CLI not signed in — skipping age identity fetch."
    warn "Run 'eval \$(op signin)' then 'op read op://Personal/age-omarchy/private > $AGE_ID && chmod 600 $AGE_ID'"
    warn "Then re-run: chezmoi apply"
  fi
else
  log "age identity already present at $AGE_ID"
fi

# --- Apply ---
log "running chezmoi init --apply akshaybapat6365/omarchy-personal"
exec chezmoi init --apply --verbose akshaybapat6365/omarchy-personal
