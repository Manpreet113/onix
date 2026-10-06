# onix — Modular NixOS Flake

Host: `onix`, user `manpreet` — Hyprland (Wayland) + PipeWire, Btrfs, systemd-boot, nixpkgs **unstable**.

## Structure
- `flake.nix` — flake-parts; inputs: nixpkgs unstable, home-manager (master), sops-nix, disko, nix-flatpak, stylix, nixvim, nix-index-database, opencode
- `hosts/onix/` — host entry (`onix.*` module toggles) + hardware-configuration.nix
- `hosts/common/` — shared settings (timezone, locale, stateVersion)
- `modules/nixos/` — system modules, auto-imported via import-tree; each is an `onix.<name>.enable` toggle
- `modules/home/` — HM modules (fish+starship, ghostty, nixvim, vscode, git, hyprland stack) auto-imported via import-tree
- `homes/manpreet.nix` — HM user entry
- `disko/` — declarative disk skeleton (not active)
- `secrets/` + `.sops.yaml` — sops-nix age-encrypted secrets

## Usage
```bash
nh os switch          # build + activate (works from any directory)
nixos-rebuild test --flake .#onix   # safe test, no boot entry
nix flake update      # bump inputs, then rebuild
nix fmt               # format with alejandra
nix develop           # dev shell: alejandra, nixd, nil, nom, nh, sops, age
```

## Secrets (sops-nix)
Age key lives at `~/.config/sops/age/keys.txt` (back it up!). Edit secrets:
```bash
sops secrets/secrets.yaml
```
Decrypted secrets land in `/run/secrets/` at activation. Declare new ones in `modules/nixos/security/sops.nix`.

## Snapshots
btrbk snapshots `/home` hourly into `/btrbk_snapshots` (keep: 24h, 7d, 4w). Restore:
```bash
sudo btrfs subvolume snapshot /btrbk_snapshots/home.<timestamp> /home
```

## Theming
stylix with the **nord** base16 scheme themes hyprland, waybar, mako, wofi, ghostty, bat, fzf, fish, opencode. GTK stays on adw-gtk3 + Papirus + Bibata (theme.nix). starship uses a hand-ported nord palette. nixvim uses `colorschemes.nord`.

## Disko
See `disko/onix.nix` — not enabled until you import + set device.
