# onix — Modular NixOS Flake

Host: `onix` (was `nixos`), user `manpreet` — GNOME + PipeWire, Btrfs, systemd-boot.

## Structure
- `flake.nix` — flake-parts + import-tree, inputs: nixpkgs 26.05, unstable, home-manager, sops-nix, disko
- `hosts/onix/` — host entry + hardware-configuration.nix
- `hosts/common/` — shared settings
- `modules/nixos/` — system modules (core, desktop, hardware, networking, etc.) auto-imported via import-tree
- `modules/home/` — HM modules (fish+starship, ghostty/foot, nvim, vscode, git, gnome)
- `homes/manpreet@onix.nix` — HM user entry
- `overlays/` — unstable overlay
- `disko/` — declarative disk skeleton (not active)
- `secrets/` — sops-nix placeholder

## Usage
```bash
# first bootstrap (flakes not yet enabled in /etc)
nix --extra-experimental-features "nix-command flakes" flake check
nix --extra-experimental-features "nix-command flakes" run nixpkgs#nh -- os switch .#onix

# after first rebuild
nh os switch
# or
nixos-rebuild switch --flake .#onix
nixos-rebuild test --flake .#onix   # safe test
nixos-rebuild boot --flake .#onix
```

## Fish best experience
fish + starship + fzf + zoxide + eza + bat + carapace + direnv + atuin + ripgrep/fd

## Terminal
ghostty (Wayland, unstable fallback) + foot — ghostty is current community standard; foot as lightweight backup.

## Editors
nvim (HM, treesitter + lsp) + vscode (extensions). nano removed.

## Git
Configured for Manpreet113 <manpreet10542@gmail.com>, delta, gh, lazygit.

## Secrets
See `modules/nixos/security/sops.nix` — generate age key:
```bash
age-keygen -o ~/.config/sops/age/keys.txt
# add pubkey to .sops.yaml, then `sops secrets/secrets.yaml`
```

## Disko
See `disko/onix.nix` — not enabled until you import + set device.
