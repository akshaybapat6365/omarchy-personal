# Identity bootstrap — interactive steps on a new machine

`chezmoi apply` automates dotfiles + packages + services, but identity / auth state requires you to be present. This is the playbook.

Run these in order after `bootstrap.sh` finishes and you're sitting at the new machine's Hyprland desktop.

## 1. 1Password CLI (do this first — many later steps need secrets from 1P)

```bash
eval $(op signin)
# Browser opens for OAuth. Sign in with master password + 2FA.
op whoami    # should print your account email
```

If you don't have the 1Password desktop app installed yet:
```bash
1password &      # GUI sign-in; follow the wizard
# Wait for the app to be signed in
eval $(op signin --account my.1password.com)
```

## 2. SSH key

Generate a fresh ed25519 keypair (never reuse keys across machines):
```bash
ssh-keygen -t ed25519 -C "akshaybapat6365@$(hostname)" -f ~/.ssh/id_ed25519 -N ""
chmod 600 ~/.ssh/id_ed25519
chmod 644 ~/.ssh/id_ed25519.pub
```

Add the public key to GitHub (via gh CLI in next step), and optionally to other Git hosts.

## 3. GitHub CLI

```bash
gh auth login
# Interactive: pick GitHub.com → HTTPS → "Y" upload your SSH public key →
#              Login with web browser
```

This both authenticates `gh` for repo operations AND uploads your new SSH key to your GitHub account. After this, `git push` to private repos works.

## 4. Mullvad VPN

Your account number lives in 1Password. Find it:
```bash
op item get "Mullvad VPN" --fields account_number 2>/dev/null
# OR open the 1P app and search "Mullvad"
```

Then:
```bash
mullvad account set <ACCOUNT_NUMBER>
mullvad connect
mullvad status            # should show Connected
```

## 5. Tailscale

```bash
sudo tailscale up
# Opens a browser tab for first-time auth. Sign in with your Tailscale account.
tailscale status          # confirm device joined the tailnet
```

## 6. Atuin (shell history sync) — optional

If you want shell history synced across machines:
```bash
atuin login -u <username>
atuin sync
```

If you don't use Atuin sync, skip this — local history works fine.

## 7. GPG keys (optional, for signed commits)

GPG private keys are NOT in this repo (security). You have two options:

**Option A: Generate fresh keys on this machine** (cleanest, but you lose signing-history continuity):
```bash
gpg --full-generate-key
# Pick ed25519 → no expiry (or 1 year) → real name + email
# Upload public key:
gpg --armor --export <KEY_ID> | gh gpg-key add -
git config --global user.signingkey <KEY_ID>
git config --global commit.gpgsign true
```

**Option B: Import from 1Password** (if you previously exported):
```bash
op read "op://Personal/GPG/private" > /tmp/gpg-private.asc
gpg --import /tmp/gpg-private.asc
shred -u /tmp/gpg-private.asc
```

To get the export onto 1P from this main machine (one-time):
```bash
gpg --export-secret-keys --armor | op document create --title "GPG private keys" -
```

## 8. Bluetooth + WiFi re-pair

System-level state isn't dotfile-able. On first boot:
- WiFi: enter password via Hyprland's network applet (waybar/walker shortcut)
- Bluetooth: `bluetoothctl` → `power on` → `agent on` → `default-agent` → `scan on` → `pair <MAC>` for each device

## 9. Brave + 1Password browser extension

Open Brave (already installed by metapac):
```bash
brave-browser &
```

Sign in via the 1Password extension — bookmarks, history, saved logins all sync from 1P / Brave Sync.

## 10. Final check

```bash
~/.local/share/chezmoi/doctor   # all sections should be ✓
```

Anything yellow/red? Re-run the specific step or check the README troubleshooting.

---

## Total time estimate

| Step | Time |
|---|---|
| 1Password signin | 30s |
| SSH keygen + gh login | 90s |
| Mullvad | 30s |
| Tailscale | 30s |
| Atuin (skip if not using) | 30s |
| GPG (optional) | 2-5 min |
| Bluetooth re-pair (5 devices) | 5 min |
| WiFi enter passwords | 30s |
| **TOTAL** | **~10-15 minutes** |

Plus the `bootstrap.sh` time (~5-20 min for metapac sync), the whole new-machine setup is **~30 minutes** to "feels exactly like my main laptop."
