# Secrets handling — age + 1Password CLI

This repo never commits unencrypted secrets. All sensitive content is encrypted with [age](https://age-encryption.org/) using a key derived from 1Password.

## Threat model

- Repo is **private** on GitHub, but treat it as if it were public. Encrypt anything you wouldn't want a teammate to read.
- 1Password vault is the root of trust. Lose access → re-key everything.

## First-time setup (one machine only)

Completed on omarchy (2026-05-19). Commands actually run:

```bash
# 1. Generate the age identity locally
age-keygen -o ~/.config/chezmoi/age-identity.txt
chmod 600 ~/.config/chezmoi/age-identity.txt
# Public key: age1y4x7y07dtz7n26j3fgw79anjehw84gnx8nujqcl9hp235mgyjg8qqzqayp

# 2. Update .chezmoi.toml.tmpl with the real recipient (done — hardcoded above)

# 3. Add [age] block to live ~/.config/chezmoi/chezmoi.toml (done)

# 4. Encrypt wallhaven.json
chezmoi add --encrypt ~/.config/aether/wallhaven.json
# Source-side file: dot_config/aether/encrypted_wallhaven.json.age

# 5. Store the identity in 1Password (PENDING — 1P not signed in at setup time)
#    Run when 1P is available:
eval $(op signin)
op item create \
  --category="Secure Note" \
  --title="age-omarchy" \
  --vault=Personal \
  "private[password]=$(cat ~/.config/chezmoi/age-identity.txt)" \
  "recipient[text]=age1y4x7y07dtz7n26j3fgw79anjehw84gnx8nujqcl9hp235mgyjg8qqzqayp"
```

## On a new machine

```bash
# Unlock 1Password CLI
eval $(op signin)

# Pull the age identity from 1Password into the expected location
op read "op://Personal/age-omarchy/private" > ~/.config/chezmoi/age-identity.txt
chmod 600 ~/.config/chezmoi/age-identity.txt

# Now chezmoi can decrypt encrypted_* files on apply
chezmoi apply
```

## Encrypting a new file

```bash
chezmoi add --encrypt ~/.ssh/config
# Source-side filename becomes: private_dot_ssh/encrypted_config.age
```

## What's currently encrypted

- (Nothing yet — repo skeleton only. Add secrets as you accumulate them.)

## Rotation

If the age key is compromised:
1. Generate a new identity (`age-keygen`)
2. Re-encrypt every `encrypted_*` file with the new recipient
3. Update 1Password secure note + `.chezmoi.toml.tmpl`
4. Commit + push
5. On each machine, pull the new identity from 1Password and `chezmoi apply`
