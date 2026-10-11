# Attribution — Onix shell (`quickshell-onix/`)

This directory is a Quickshell/QML port of **Exo** by debuggyo,
<https://github.com/debuggyo/Exo>, which is licensed **GPL-3.0**.
As a derivative work, everything in this directory is likewise GPL-3.0 —
see `LICENSE`. Upstream copyright belongs to its respective authors.

## Naming policy

Per project direction, every user-facing and code-facing instance of the
upstream name is rebranded: `Exo` → `Onix`, `exo-*` → `onix-*`
(`OnixTheme`, `OnixSettings`, `OnixNiri`, `onix-settings.json`, …).
The name "Exo" appears in this tree **only** where the license requires
honest provenance: this file, per-file source-credit headers, and the
changelog. No Exo branding, installer, defaults, or wallpaper ships here.

## Other inspirations (patterns studied, code written fresh)

- **iNiR** by snowarch (<https://github.com/snowarch/iNiR>, GPL-3.0) —
  the `Socket` + `SplitParser` + `Process niri msg -j` shape used by
  `OnixNiri.qml` for the Niri event-stream IPC client.
- **Niri IPC docs** (<https://github.com/niri-wm/niri/wiki/IPC>) — the
  authoritative protocol reference for event/request shapes.

## Deliberate divergences from upstream

- **Theming**: Matugen replaced by skein. `OnixTheme.qml` derives the full
  Material-3 role ladder from skein's eleven wallpaper tokens; nothing
  here shells out to `matugen`.
- **Compositor**: Niri only. Hyprland code paths were dropped during the
  port (compositor switch); `OnixNiri.qml` is the single compositor bridge.
- **Settings storage**: upstream's mutable `user_settings.json` becomes
  `~/.local/share/onix-shell/onix-settings.json` (same schema, Nix seeds
  defaults from `onix-settings.defaults.json` and never touches the live
  file).
- **Terminal**: upstream spawns `kitty`; the port spawns `ghostty -e`.
- **Dropped**: `exoinstall.py` (Nix is the installer), `matugen/` + `kitty/`
  configs, `exodefaults/`, and the `m3test` playground module.
- **Beyond upstream**: lock screen, screen corners, clipboard history, and
  the keybind cheatsheet have no upstream equivalent — they are original
  onix components (lock + clipboard logic descended from onix's own
  Hyprland shell, same license). The old per-panel views (sound mixer,
  calendar, system monitor) were retired with the port; quickcenter covers
  their ground.
