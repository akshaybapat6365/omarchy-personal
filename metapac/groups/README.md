# metapac package groups

Each `*.toml` in this directory is a "group" — a logical bucket of packages.
On a new machine, `metapac sync` reads every group and installs whatever
is in any group but not yet on the system.

## Adding a package

Add it to the most appropriate group file under the right `[arch]` section
(or `[arch-paru]` for AUR-only packages). Use `"*"` as the version for
"any latest". Examples:

```toml
[arch]
ripgrep = "*"
fd      = "*"

[arch-paru]
brave-origin-beta-bin = "*"
```

## Removing a package

Delete the line from the group file. On next `metapac clean`, the package
will be flagged for removal. Run `metapac clean --dry-run` first.

## Per-host filtering

To make a package only install on certain hosts, prefix the group filename
with the hostname (e.g. `myhost-fonts.toml`). `hostname_groups_enabled=true`
in `metapac.toml` enables this.
