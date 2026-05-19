# Secrets handling — age + 1Password CLI

This repo never commits unencrypted secrets. All sensitive content is encrypted with [age](https://age-encryption.org/) using a key derived from 1Password.

## Threat model

- Repo is **private** on GitHub, but treat it as if it were public. Encrypt anything you wouldn't want a teammate to read.
- 1Password vault is the root of trust. Lose access → re-key everything.

## First-time setup (one machine only)

```bash
# 1. Generate the age identity locally
age-keygen -o ~/.config/chezmoi/age-identity.txt

# 2. Note the public recipient (starts with age1...)
cat ~/.config/chezmoi/age-identity.txt | grep -oE 'age1[a-z0-9]+'

# 3. Store the IDENTITY (private key) in 1Password as a Secure Note
#    Name: "age-omarchy"
#    Field "private": paste the entire file content (incl. comment lines)
#    Field "recipient": paste just the age1... public string

# 4. Update ~/.local/share/chezmoi/.chezmoi.toml.tmpl with the real recipient
#    Replace REPLACE_AFTER_FIRST_AGE_KEYGEN with your age1... public string
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
