# Per-machine variables

chezmoi prompts for these on `chezmoi init` and persists them in
`~/.config/chezmoi/chezmoi.toml` (machine-local; never committed).

| Variable | Default | Usage |
|---|---|---|
| `hostname` | `.chezmoi.hostname` | Used for hostname-keyed groups in metapac and per-host overrides |
| `primary_monitor` | `eDP-1` | Templated into `~/.config/hypr/monitors.conf` |
| `dpi` | `1` | Hyprland DPI scale (1 / 1.25 / 1.5 / 2) |
| `use_1password` | `true` | Whether to expect 1Password CLI for age key derivation |
| `gh_user` | `akshaybapat6365` | GitHub username for git config + gh auth |
| `gpu_vendor` | `intel` | One of: intel, amd, nvidia, none — gates GPU-specific config snippets |
| `machine_class` | `laptop` | One of: laptop, desktop, server — gates power-management bits |

## How to override

```bash
chezmoi edit-config        # opens ~/.config/chezmoi/chezmoi.toml in $EDITOR
chezmoi apply              # re-applies with new vars
```

## How to add a new variable

1. Add a `promptStringOnce`/`promptBoolOnce`/`promptChoiceOnce` to `.chezmoi.toml.tmpl`
2. Reference it in templates as `{{ .my_new_var }}`
3. On each machine, run `chezmoi init` to re-prompt (or edit `~/.config/chezmoi/chezmoi.toml` manually)

## Templates in this repo

Files ending in `.tmpl` use Go template syntax and get rendered to a non-`.tmpl` version on apply.

Currently templated:
- `.chezmoi.toml.tmpl` — the prompt definitions themselves
- `.chezmoiignore` — OS-conditional ignores
- `run_once_after_02-mise.sh.tmpl` — currently no templating, but available
- `run_onchange_after_fontconfig.sh.tmpl` — hash invalidation
- `run_onchange_after_systemd-user.sh.tmpl` — same

Future candidates:
- `dot_config/hypr/monitors.conf.tmpl` → uses `{{ .monitor.primary }}` and `{{ .dpi }}`
- `dot_config/hypr/input.conf.tmpl` → trackpad accel curve, only on `{{ if eq .machine_class "laptop" }}`
