# onix — Modular NixOS Flake

Host: `onix`, user `manpreet` — Niri (Wayland) + Exo shell on Ignis + PipeWire, Btrfs, systemd-boot, nixpkgs **unstable**.

## Structure
- `flake.nix` — flake-parts; inputs: nixpkgs unstable, home-manager (master), sops-nix, disko, skein, nixvim, nix-index-database, nixcord, opencode
- `pkgs/` — in-tree packages (zen-browser, helium-browser) exposed via the `onix.core.overlay` overlay; bump with `./pkgs/update-browsers.sh`
- `hosts/onix/` — host entry (`onix.*` module toggles) + hardware-configuration.nix
- `hosts/common/` — shared settings (timezone, locale, stateVersion)
- `modules/nixos/` — system modules, auto-imported via import-tree; each is an `onix.<name>.enable` toggle
- `modules/home/` — HM modules (fish+tide, ghostty, nixvim, vscode, git, niri + exo/ignis shell) auto-imported via import-tree
- `homes/manpreet.nix` — HM user entry
- `disko/` — declarative disk skeleton (not active)
- `secrets/` + `.sops.yaml` — sops-nix age-encrypted secrets

## Usage
```bash
nh os switch          # build + activate (works from any directory)
nixos-rebuild test --flake .#onix   # safe test, no boot entry
nix flake update      # bump inputs, then rebuild
nix fmt               # format with alejandra
nix develop           # dev shell: alejandra, nixd, nil, nom, nh, sops, age, statix, deadnix
nix flake check       # runs statix + deadnix lints
```
Note: `system.autoUpgrade` runs as root against this repo path; interactive root git commands in this repo may need `git config --global --add safe.directory /home/manpreet/onix`.

## Secrets (sops-nix)
Age key: install it at `/var/lib/sops-nix/key.txt` (mode 600, dir 700, created by tmpfiles):
```bash
sudo install -d -m 700 /var/lib/sops-nix
sudo install -m 600 ~/.config/sops/age/keys.txt /var/lib/sops-nix/key.txt
```
sops-nix needs it at early boot, so it must live outside `/home`. Back it up somewhere safe.
Edit secrets:
```bash
sops secrets/secrets.yaml
```
Decrypted secrets land in `/run/secrets/` at activation. Declare new ones in `modules/nixos/security/sops.nix`.

## Snapshots
btrbk snapshots `/home` hourly into `/btrbk_snapshots` on the root subvolume (keep: 24h, 7d, 4w). To restore, stop using `/home`, then:
```bash
sudo btrfs subvolume snapshot /home /home.broken
sudo btrfs subvolume delete /home        # destructive; or rename instead
sudo btrfs subvolume snapshot /btrbk_snapshots/home.<timestamp> /home
```
Safer: do this from a live USB, and keep `/home.broken` until you're sure. btrbk is local-only — copy `/btrbk_snapshots` off-disk for disaster recovery.

## Theming
skein (wallpaper-driven) themes: ghostty, fish, fzf, btop, discord. The Exo shell + hyprlock theme via matugen (see `modules/home/desktop/exo.nix`; one compat patch for matugen 4). Tide prompt is static lean until skein grows a tide template. Static Nord where no live source exists: GTK (adw-gtk3-dark + Papirus + Bibata in `modules/home/desktop/theme.nix`), nixvim (`colorschemes.nord`), vscode (manual Nord extension), Qt (adwaita-dark). No stylix — deliberately removed, one theming system per surface.

## Disko
See `disko/onix.nix` — not enabled until you import + set device.
