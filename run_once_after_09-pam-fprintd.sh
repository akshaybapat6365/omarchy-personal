#!/usr/bin/env bash
# Idempotently wire `pam_fprintd.so` into `su` and `su-l` so that fingerprint
# OR password works for the `su` family — matching the behavior the rest of
# the auth stack (sddm, hyprlock, sudo, login, polkit-1) already has via
# system-auth on this machine.
#
# What system-auth already covers: SDDM login, hyprlock, sudo, polkit, login.
# What this script adds: su / su-l (which don't include system-auth at the
# auth stage; they call `pam_unix.so` directly).
#
# Why not just edit /etc/pam.d/* directly in chezmoi source: those files
# live under /etc (root-owned) and chezmoi runs as the user. A run-once
# hook with sudo is the right tool.
set -euo pipefail
log() { printf '[chezmoi/pam-fprintd] %s\n' "$*"; }

# Precondition 1: fprintd installed
if ! command -v fprintd-list >/dev/null 2>&1; then
  log "fprintd not installed; skipping (install via 'paru -S fprintd' first)"
  exit 0
fi

# Precondition 2: PAM module present at the expected path
if [[ ! -f /usr/lib/security/pam_fprintd.so ]]; then
  log "pam_fprintd.so not found at /usr/lib/security/; skipping"
  exit 0
fi

# Precondition 3: at least one finger enrolled for current user
USER_NAME="${USER:-$(id -un)}"
if ! fprintd-list "$USER_NAME" 2>/dev/null | grep -q "finger"; then
  log "no fingerprints enrolled for $USER_NAME; run 'fprintd-enroll' first, then re-run this hook"
  log "(continuing anyway — the PAM line is harmless when no fingers are enrolled, libfprint just no-ops)"
fi

FPRINTD_LINE='-auth           sufficient      pam_fprintd.so       timeout=10'

patch_file() {
  local pam_file="$1"
  if [[ ! -f "$pam_file" ]]; then
    log "$pam_file not present; skipping"
    return 0
  fi
  if grep -q 'pam_fprintd' "$pam_file"; then
    log "$pam_file already has pam_fprintd — skipping"
    return 0
  fi
  if ! grep -qE '^auth[[:space:]]+required[[:space:]]+pam_unix\.so' "$pam_file"; then
    log "$pam_file has unexpected structure (no 'auth required pam_unix.so' line) — refusing to patch"
    return 1
  fi
  local ts backup
  ts=$(date +%s)
  backup="${pam_file}.bak.${ts}"
  log "patching $pam_file (backup: $backup)"
  sudo cp -p "$pam_file" "$backup"
  sudo sed -i "/^auth[[:space:]]\+required[[:space:]]\+pam_unix\.so/i $FPRINTD_LINE" "$pam_file"
  log "  -> done"
}

patch_file /etc/pam.d/su
patch_file /etc/pam.d/su-l

log "complete. To rollback: sudo cp /etc/pam.d/su.bak.<TS> /etc/pam.d/su (likewise su-l)"
