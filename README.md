# omarchy-personal

Personal Omarchy/Arch Linux setup as code. One curl-pipe-bash brings a fresh laptop to the exact state of this user's main machine.

## What this repo captures

- All `~/.config/` customizations (hyprland, waybar, alacritty, nvim, zed, opencode, tmux, fish, mako, walker, ghostty, kitty, foot, fontconfig, omarchy theme overrides)
- Every script in `~/.local/bin/` (~80 custom binaries: `omarchy-*`, `claude-*`, `waybar-*`, `music-*`, `trackpad-tune`, etc.)
- Package manifests (pacman + AUR via [metapac](https://github.com/ripytide/metapac))
- Tool manifests (npm globals, cargo bins, pipx, mise)
- Idempotent post-install hooks (font cache, systemd-user services, theme set)
- Per-machine variables (hostname, monitor, DPI, GPU) via [chezmoi](https://www.chezmoi.io/) templates
- Optional age-encrypted secrets via 1Password CLI

## What this repo does NOT capture

- Stock Omarchy itself — install [basecamp/omarchy](https://github.com/basecamp/omarchy) first (DHH's flow)
- AI CLI configs (Claude Code, Codex, OpenCode, Cursor, Gemini, claude-mem) — handled by [`akshaybapat6365/ai-config`](https://github.com/akshaybapat6365/ai-config), pulled automatically via `.chezmoiexternal.toml`
- SSH private keys, GPG keys, GitHub tokens — regenerate on each new machine
- Browser state (Brave/Chromium profiles) — handled by 1Password sync
- `~/.local/share/omarchy/` — never touch DHH's tree (overlay only)

## Bootstrap a new machine (one-liner)

```bash
sh -c "$(curl -fsLS https://raw.githubusercontent.com/akshaybapat6365/omarchy-personal/main/bootstrap.sh)"
```

What happens (idempotent, safe to re-run):
1. Installs `chezmoi` + `paru` if missing
2. `chezmoi init --apply akshaybapat6365/omarchy-personal` — clones the repo + prompts for hostname/monitor/DPI/1P-use
3. `run_once_before_*` — installs `metapac`, `age`, `1password-cli` via paru
4. Applies dotfiles to `~/`
5. `run_once_after_*` — `metapac sync` (~237 pkgs), `mise install`, npm/cargo/pipx tools, `omarchy theme set aether`
6. `run_onchange_after_*` — font cache, systemd-user enables

You then:
- `eval $(op signin)` to unlock 1Password
- `gh auth login` to restore GitHub access
- Reboot, log into Hyprland, enjoy

## Daily use

```bash
chezmoi edit ~/.config/waybar/config       # Edit through chezmoi (or edit the file directly)
chezmoi diff                                # See pending changes
chezmoi apply                               # Apply staged changes
chezmoi update                              # Pull latest from origin, apply, refresh externals
chezmoi cd && git status                    # Drop into source repo
```

## Health check

```bash
./doctor
```

## Repo structure

See [`docs/per-machine-vars.md`](docs/per-machine-vars.md) for the templating model and [`docs/secrets.md`](docs/secrets.md) for the age + 1Password flow.

## Related repos

- [`akshaybapat6365/ai-config`](https://github.com/akshaybapat6365/ai-config) — AI CLI configs (referenced via `.chezmoiexternal.toml`)
- [`basecamp/omarchy`](https://github.com/basecamp/omarchy) — the OS this overlays on
