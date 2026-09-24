# zenbook-duo-omarchy

Omarchy / Hyprland patches for the **ASUS Zenbook Duo UX8406CA** (Lunar Lake, Arc 140V-class). **Not UX8406MA.** Not the Ourea vault.

## Slice 1 — bottom OLED community plugin

Stock Omarchy enables every connected panel via the catch-all `hl.monitor({ output = "" })`. `omarchy-hyprland-monitor-laptop` only returns the **first** internal output (`eDP-1`). Clamshell / folio attach therefore **does not** hide `eDP-2`. This plugin turns the bottom OLED **off by default** and gives the operator an explicit **on** toggle.

| SKU | Class | Notes |
|-----|-------|--------|
| UX8406CA | CA | Target. Dual OLED; bottom is `eDP-2`. |
| UX8406MA | MA | Same Duo chassis, different SoC. Script labels MA and still targets `eDP-2` if present. |
| other | generic | Refuses if there is no second internal panel. |

### Install (no root)

```bash
cd /home/squinto/src/zenbook-duo-omarchy
omarchy plugin validate ./plugin
./plugin/install.sh                 # copies plugin, applies eDP-2 OFF
# optional bar widget:
./plugin/install.sh --enable-widget
```

`omarchy plugin add <git-url>` is **not** used here: this repo is a multi-slice tree, so `manifest.json` lives under `plugin/` rather than the repo root.

### Toggle (off by default)

Desired state lives in `~/.local/state/omarchy/zenbook-duo-bottom-oled` (`on` / `off`). Missing file means **off**.

Hyprland persistence (sourced by Omarchy `default.hypr.toggles`, no extra process):

- off: `~/.local/state/omarchy/toggles/hypr/zenbook-duo-bottom-oled-disable.lua`
- on: `~/.local/state/omarchy/toggles/hypr/zenbook-duo-bottom-oled-enable.lua` (`position = "auto-down"`)

```bash
plugin/bin/zenbook-duo-bottom-oled status
plugin/bin/zenbook-duo-bottom-oled on       # operator: turn bottom OLED on
plugin/bin/zenbook-duo-bottom-oled off      # default
plugin/bin/zenbook-duo-bottom-oled toggle
plugin/bin/zenbook-duo-bottom-oled apply    # re-apply desired (default off)
```

Optional keybind in `~/.config/hypr/bindings.lua` (not shipped; do not bind folio attach):

```lua
o.bind("SUPER + CTRL + O", "Bottom OLED", "/home/squinto/src/zenbook-duo-omarchy/plugin/bin/zenbook-duo-bottom-oled toggle")
```

### Design constraints

- **Least privilege:** user-owned state + `hyprctl reload`. No udev, nothing world-writable, no extra compositor when the panel is off (`disabled = true` so Hyprland does not composite `eDP-2`).
- **Hide path:** Hyprland monitor disable, not folio/keyboard attach.
- Bar widget is optional. Enabling it is extra **shell** load, not extra **compositor** load for the off panel.

## Slice 2 (not this change)

Keyboard cursor-jump when the folio is attached. Do not block slice 1 on it.

## What this repo / this slice did **not** do

- hermes gateway
- `--yolo`
- `visudo` NOPASSWD ALL
- extra git worktree / clone of `/data/ourea`
- upstream post or public PR
- Hermes Desktop plugin
- world-writable udev rules
- editing `/usr/share/omarchy/`
