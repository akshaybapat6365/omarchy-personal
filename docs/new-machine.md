# Bootstrap a new Omarchy machine

## Prerequisites

1. **Fresh Omarchy install** — boot the Omarchy installer ISO, run through DHH's flow. ~5 min. https://learn.omacom.io
2. **Internet connection** — needed for cloning the repo and AUR builds
3. **1Password account** (for secrets) — sign in via app or `op signin` after first boot

## One-liner

```bash
sh -c "$(curl -fsLS https://raw.githubusercontent.com/akshaybapat6365/omarchy-personal/main/bootstrap.sh)"
```

What happens:

| Step | Duration | What it does |
|------|----------|--------------|
| 1 | ~5s | Installs `chezmoi` to `~/.local/bin` (no sudo) |
| 2 | ~30s | Installs `paru` via `makepkg -si` (sudo for `pacman` only) |
| 3 | ~10s | `chezmoi init` clones the repo, prompts for hostname/monitor/DPI/1P-use |
| 4 | ~20s | `run_once_before_*` installs `metapac`, `age`, `1password-cli` via paru |
| 5 | ~5s | Applies dotfile tree to `~/.config/` and `~/.local/bin/` |
| 6 | **5-20 min** | `metapac sync` installs ~237 pkgs (pacman + AUR). The bulk of bootstrap time. |
| 7 | ~60s | `mise install`, npm globals, cargo bins, pipx tools, uv tools |
| 8 | ~10s | `sudo systemctl enable --now` for 11 system services (avahi, bluetooth, cups, iwd, mullvad-daemon, power-profiles-daemon, sddm, tailscaled, thermald, ufw) |
| 9 | ~5s | `omarchy theme set aether`, font cache rebuild, 17 systemd-user services enabled |

## After bootstrap completes — identity bootstrap

The auto-bootstrap can't sign you into accounts. Run through **[identity-bootstrap.md](./identity-bootstrap.md)** for the interactive ~10 minutes of:

1. `eval $(op signin)` — 1Password CLI
2. `ssh-keygen` + `gh auth login` — GitHub access + SSH key upload
3. `mullvad account set <token>` — VPN (account # in 1P)
4. `sudo tailscale up` — Tailscale
5. `atuin login` — shell-history sync (optional)
6. GPG keys (optional, for signed commits)
7. Bluetooth re-pair + WiFi passwords
8. Brave + 1P browser extension

Then:
```bash
chezmoi apply              # Re-run if any 1P-gated secrets need to land (Phase 2)
sudo reboot                # Pick up systemd unit changes cleanly
```

## Sharp edges

- **Trackpad feel won't match exactly** until you run `trackpad-tune` once for your specific device. The per-device accel curve in `~/.config/hypr/input.conf` was tuned for the main machine.
- **AUR pkgs that fail to build**: if `metapac sync` fails on a specific AUR pkg (e.g., `brave-origin-beta-bin` needs upstream `git` checkout), comment it out in `metapac/groups/desktop.toml` and re-run `metapac sync`.
- **Mise tools**: Node 25.9.0 builds via prebuilt binaries — usually fast. If you change versions, re-run `mise install`.
- **GPU drivers**: For NVIDIA on Hyprland, see Omarchy docs for proprietary driver setup. This repo doesn't manage kernel modules.

## Re-bootstrap (existing machine)

`chezmoi update` pulls the latest, applies, and refreshes externals. Safe to run anytime.

```bash
chezmoi update --refresh-externals
```
