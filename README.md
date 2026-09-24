# Zenbook Duo bottom OLED (Omarchy plugin)

Community plugin for the **ASUS Zenbook Duo UX8406CA** on Omarchy / Hyprland.

The bottom OLED (`eDP-2`) stays **off by default**. A bar button (right cluster, after the system tray) turns it on. Folio attach is **not** the hide path — stock Omarchy does not hide `eDP-2` when the keyboard is clipped.

| SKU | Class | Notes |
|-----|-------|--------|
| UX8406CA | CA | Target. Dual OLED; bottom is `eDP-2`. |
| UX8406MA | MA | Same Duo chassis, different SoC. Script labels MA and still targets `eDP-2` if present. |
| other | generic | Refuses if there is no second internal panel. |

## Install

```
omarchy plugin add https://github.com/squinto-py/zenbook-duo-omarchy.git --enable
omarchy plugin enable squinto.zenbook-duo-bottom-oled --after omarchy.tray
```

Then apply once (Omarchy does not run install hooks):

```
~/.config/omarchy/plugins/squinto.zenbook-duo-bottom-oled/bin/zenbook-duo-bottom-oled apply
~/.config/omarchy/plugins/squinto.zenbook-duo-bottom-oled/keyboard/zenbook-duo-fake-touchpad.sh apply
```

Restart the shell so the bar glyph loads (`omarchy-restart-shell`). The bar blinks once.

## Use

- Bar button next to the tray: dual-display glyph = on, monitor-off glyph = off.
- CLI (same dest `bin/zenbook-duo-bottom-oled`): `status` · `on` · `off` · `toggle` · `apply`

Missing state file = **off**. Live off is per-output DPMS on `eDP-2` only (the top panel stays up). Login persist still compositor-disables `eDP-2` so a cold start is lag-correct. The first **on** after that disable hitchs once; later in-session toggles do not tear the Omarchy bar.

Typing does not relight the bottom panel (the plugin pins Omarchy `key_press_enables_dpms` / `mouse_move_enables_dpms` false while the bottom is desired-off, and restores them on enable).

## Keyboard (CA)

Each OLED also exposes a full-panel fake **touchpad** (`elan9008` top / `elan9009` bottom) plus a bottom **touchscreen**. Those are what jump the cursor while typing — not the folio Primax trackpad.

The helper disables both fake pads always, and the bottom digitizer with the panel. Do **not** run `omarchy toggle touchpad` (it matches the first ELAN node). Do not disable the folio trackpad.

## Remove

```
omarchy plugin remove squinto.zenbook-duo-bottom-oled
```

Optional leftover state: `~/.local/state/omarchy/zenbook-duo-bottom-oled` and the two static lua stubs under `~/.local/state/omarchy/toggles/hypr/` (`zenbook-duo-bottom-oled.lua`, `zenbook-duo-fake-touchpad.lua`).

## What this does not do

- Folio-as-hide
- World-writable udev
- Editing `/usr/share/omarchy/`
- Global DPMS (that blanks **both** panels)

## License

MIT. See `LICENSE`.
