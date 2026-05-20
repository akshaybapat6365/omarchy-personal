#!/usr/bin/env bash
# Force SDDM greeter to render via X11 to eliminate a libseat seat0 race.
#
# Context: with DisplayServer=wayland, SDDM spawns a Hyprland greeter
# compositor that races the user-session Hyprland for libseat seat0
# ownership during crash recovery. Loser throws std::runtime_error from
# Aquamarine's CBackend::create() and dies. Reproduced 5x on 2026-05-18
# (boots -5 through -3 in journalctl), all with identical CCompositor::
# initServer backtrace.
#
# Switching the greeter to X11 removes the second Wayland compositor
# entirely. Actual sessions chosen via wayland-sessions/ stay full Wayland.
#
# Preconditions: xorg-server installed (metapac group should have it).
set -euo pipefail
log() { printf '[chezmoi/sddm-x11] %s\n' "$*"; }

if ! command -v Xorg >/dev/null 2>&1; then
  log "Xorg not installed (pacman -S xorg-server) — skipping; would leave greeter Wayland and the race intact"
  exit 0
fi

if [[ ! -d /etc/sddm.conf.d ]]; then
  log "/etc/sddm.conf.d missing — SDDM not installed? skipping"
  exit 0
fi

TARGET=/etc/sddm.conf.d/11-greeter-x11.conf

if [[ -f "$TARGET" ]] && grep -q "DisplayServer=x11" "$TARGET"; then
  log "$TARGET already configured — skipping"
  exit 0
fi

log "writing $TARGET"
sudo tee "$TARGET" > /dev/null <<'EOF'
# Force SDDM greeter to render via X11 instead of Wayland.
# Why: with DisplayServer=wayland the greeter spawns its own Hyprland,
# which races the user-session Hyprland for libseat seat0 ownership
# during crash recovery. Loser throws from Aquamarine CBackend::create().
# Switching the greeter to X11 eliminates the second Wayland compositor.
# Actual sessions (wayland-sessions/hyprland-uwsm.desktop) stay Wayland.
[General]
DisplayServer=x11

[X11]
ServerArguments=-nolisten tcp -dpi 144
EOF

log "complete. Effective on next SDDM restart (reboot or 'systemctl restart sddm')."
log "Rollback: sudo rm $TARGET (restores the bundled DisplayServer=wayland)."
