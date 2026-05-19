# omarchy-personal ISO

A bootable Arch Linux live ISO that auto-bootstraps your full omarchy-personal
environment on first login. Boot it on a new machine, connect to the internet,
and your entire dotfile stack installs itself.

## Overview

The ISO is built from an archiso `releng` base profile stored at
`~/.local/share/omarchy-personal-iso/profile/`. Key customisations:

- `profiledef.sh` — sets `iso_name=omarchy-personal`, custom label/publisher.
- `packages.x86_64` — adds `git`, `chezmoi`, `base-devel`, `wget`, `curl` on
  top of the standard releng package set so the bootstrap runs without needing
  a pacman update first.
- `airootfs/etc/skel/.bash_profile` — on first login (if `github.com` is
  reachable) runs:
  1. `curl -fsSL https://omacom.io/install | bash` — installs omarchy.
  2. `bootstrap.sh` from this repo — applies chezmoi dotfiles + secrets.
  3. Stamps `~/.omarchy-personal-bootstrapped` so it never re-runs.

## How to Build

Requires Docker (for a clean, reproducible Arch environment):

```bash
make iso
```

The ISO lands in `~/.local/share/omarchy-personal-iso/out/`.

Build time is roughly 10–20 minutes on a fast connection (downloads ~800 MB of
packages into the Docker layer).

## How to Test

Requires QEMU with KVM support:

```bash
make iso-test
```

This boots the latest ISO in a headless QEMU VM (2 GB RAM). Press `Ctrl-A X`
to quit. Verify the live environment starts and that `.bash_profile` is present
in `/etc/skel/`.

## Releasing to GitHub Releases

After a successful build, publish with `gh`:

```bash
VERSION=v$(date +%Y.%m.%d)
ISO=$(ls -t ~/.local/share/omarchy-personal-iso/out/*.iso | head -1)

gh release create "$VERSION" "$ISO" \
  --repo akshaybapat6365/omarchy-personal \
  --title "omarchy-personal $VERSION" \
  --notes "Automated ISO build — $(date +%Y-%m-%d)"
```

GitHub Releases supports files up to **2 GB**. A typical omarchy-personal ISO
is ~800 MB–1.2 GB (xz-compressed squashfs), well within that limit.

### If the ISO exceeds 2 GB

Options in order of preference:

1. **xz compression** (already enabled in `profiledef.sh` via
   `airootfs_image_tool_options`). This is the default — no action needed.
2. **Remove large optional packages** from `packages.x86_64` (e.g. firmware
   blobs for hardware you don't own).
3. **NAS / object storage hosting**: upload to Backblaze B2 or a self-hosted
   Nextcloud/Synology share and link from the GitHub Release notes.

## Maintenance

Rebuild the ISO when:

- Omarchy releases a new version that changes the base system substantially.
- `bootstrap.sh` changes in ways that require newer packages present on the
  live medium.
- The releng base profile diverges enough to warrant a refresh:
  ```bash
  cp -r /usr/share/archiso/configs/releng/* \
    ~/.local/share/omarchy-personal-iso/profile/
  # then re-apply the customisations in profiledef.sh and packages.x86_64
  ```
- At minimum, rebuild once every 6 months to stay on a recent Arch snapshot
  (older ISOs may require a full `pacman -Syu` before packages install cleanly).

## Profile Location

The archiso profile lives **outside** the chezmoi source tree to avoid
accidentally committing large generated artefacts:

```
~/.local/share/omarchy-personal-iso/
  profile/          ← archiso build profile (tracked manually / copied from releng)
  out/              ← built ISOs (gitignored, large)
  work/             ← mkarchiso work dir (gitignored, large)
```

The `Makefile` at the chezmoi repo root orchestrates the Docker build and
references these paths.
