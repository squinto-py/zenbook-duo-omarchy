# Zenbook Duo bottom OLED

Omarchy / Hyprland plugin for the ASUS Zenbook Duo UX8406CA.

The bottom OLED (`eDP-2`) stays off until you turn it on from the bar. Clipping the folio does not hide that panel. Stock Omarchy does not hide `eDP-2` when the keyboard is clipped.

| SKU | Class | Notes |
|-----|-------|--------|
| UX8406CA | CA | Target. Dual OLED. Bottom panel is `eDP-2`. |
| UX8406MA | MA | Same chassis, different SoC. The script labels MA and still targets `eDP-2` if that panel exists. |
| other | generic | Refuses if there is no second internal panel. |

## Install

```
omarchy plugin add https://github.com/squinto-py/zenbook-duo-omarchy.git --enable
omarchy plugin enable squinto.zenbook-duo-bottom-oled --after omarchy.tray
```

`omarchy plugin add` does not run install hooks, including `install.sh`. Run apply once:

```
~/.config/omarchy/plugins/squinto.zenbook-duo-bottom-oled/bin/zenbook-duo-bottom-oled apply
~/.config/omarchy/plugins/squinto.zenbook-duo-bottom-oled/keyboard/zenbook-duo-fake-touchpad.sh apply
```

`install.sh` is an optional same-user helper if you cloned the tree by hand. It copies into `~/.config/omarchy/plugins/` and runs the same apply commands.

Restart the shell so the bar glyph loads:

```
omarchy-restart-shell
```

The bar blinks once.

## Use

- Bar button next to the tray. Dual-display glyph means on. Monitor-off glyph means off.
- CLI, same dest `bin/zenbook-duo-bottom-oled`: `status`, `on`, `off`, `toggle`, `apply`

A missing state file means off. Live off is per-output DPMS on `eDP-2` only. The top panel stays up. Login persist still compositor-disables `eDP-2` so a cold start is lag-correct. The first on after that disable hitches once. Later in-session toggles do not tear the Omarchy bar.

Typing does not relight the bottom panel. While the bottom is desired-off, the plugin pins Omarchy `key_press_enables_dpms` and `mouse_move_enables_dpms` to false, then restores them on enable.

## Keyboard (CA)

Each OLED also exposes a full-panel fake touchpad (`elan9008` top, `elan9009` bottom) plus a bottom touchscreen. Those jump the cursor while you type. The folio Primax trackpad does not.

The helper disables both fake pads always, and the bottom digitizer with the panel. Do not run `omarchy toggle touchpad`. It matches the first ELAN node. Do not disable the folio trackpad.

## Remove

```
omarchy plugin remove squinto.zenbook-duo-bottom-oled
```

Optional leftover state:

- `~/.local/state/omarchy/zenbook-duo-bottom-oled`
- `~/.local/state/omarchy/toggles/hypr/zenbook-duo-bottom-oled.lua`
- `~/.local/state/omarchy/toggles/hypr/zenbook-duo-fake-touchpad.lua`

## What this does not do

- Folio-as-hide
- World-writable udev
- Editing `/usr/share/omarchy/`
- Global DPMS (that blanks both panels)

## License

MIT. See `LICENSE`.
