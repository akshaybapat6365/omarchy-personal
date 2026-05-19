#!/usr/bin/env bash
# Install cargo-managed binary tools captured from main machine.
set -euo pipefail
log() { printf '[chezmoi/cargo] %s\n' "$*"; }

command -v cargo >/dev/null 2>&1 || { log "cargo not on PATH; skipping (install Rust via mise/rustup first)"; exit 0; }

BINS=(
  rmpc-theme-gen
  ytermusic
)

log "installing ${#BINS[@]} cargo binaries"
for b in "${BINS[@]}"; do
  cargo install --locked "$b" 2>&1 | tail -2 || log "cargo install $b failed; re-run manually"
done
