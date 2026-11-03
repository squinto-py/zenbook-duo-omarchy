# Zenbook Duo bottom OLED (Omarchy plugin)

Community plugin for the **ASUS Zenbook Duo UX8406CA** on Omarchy / Hyprland. It does two things with the bottom OLED (`eDP-2`):

- **Panel toggle.** The bottom panel stays off by default. A bar button turns it on and off. Off means compositor-disabled, so Hyprland treats the panel as unplugged.
- **Screen trackpad.** A rectangle at the bottom centre of the panel becomes a real touchpad, for when you type on an external keyboard and have no mouse. It works with the panel lit, or with the panel dark to save battery.

| SKU | Class | Notes |
|-----|-------|--------|
| UX8406CA | CA | Target. Dual OLED; bottom is `eDP-2`. |
| UX8406MA | MA | Same Duo chassis, different SoC. The panel toggle labels MA and still targets `eDP-2`. The trackpad's device names are CA values and are untested on MA. |
| other | generic | The panel toggle refuses if there is no second internal panel. |

## Requirements

The panel toggle needs nothing beyond Omarchy. The screen trackpad needs two things:

1. **python-evdev**

   ```
   omarchy pkg add python-evdev
   ```

2. **Access to the bottom touchscreen and to `/dev/uinput`.** The rule in `udev/` grants both to the logged-in seat user (`uaccess`), the same mechanism Steam and Solaar use. Nothing becomes world-writable.

   ```
   cd ~/.config/omarchy/plugins/squinto.zenbook-duo-bottom-oled
   sudo install -m 644 udev/70-zenbook-duo-screen-trackpad.rules /etc/udev/rules.d/
   sudo udevadm control --reload
   sudo udevadm trigger
   ```

Check both with:

```
~/.config/omarchy/plugins/squinto.zenbook-duo-bottom-oled/bin/zenbook-duo-screen-trackpad status
```

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

Restart the shell so the bar buttons and the trackpad overlay load (`omarchy restart shell`). The bar blinks once.

## Use

The bar gets two buttons after the tray:

- **Panel**: dual-display glyph = on, monitor-off glyph = off. Click to toggle, right-click to refresh status.
- **Trackpad**: touchpad glyph = on, dimmed touchpad-off glyph = off. Click to toggle.

The two toggles are independent and combine into four modes:

| Panel | Trackpad | Result |
|-------|----------|--------|
| on | off | Ordinary second screen. |
| on | on | Pad outlined at the bottom centre of the panel. Windows don't go under it. |
| off | on | **Dark trackpad.** The panel is black and out of reach of the cursor and windows; the pad still works. |
| off | off | Panel disabled. |

The touch sensor loses power with the panel, so the dark trackpad keeps the panel powered and shows only black, which an OLED renders with its pixels off. It uses more power than a disabled panel and much less than a lit one.

Gestures on the pad:

- One-finger move: pointer
- Tap: left click (fires about a quarter second late, while it waits for a second tap)
- Two quick taps: double click
- Tap, then touch and move: drag
- Two-finger tap: right click. Three-finger tap: middle click.
- Two-finger move: scroll

CLIs, both in `bin/`:

- `zenbook-duo-bottom-oled`: `status` · `on` · `off` · `toggle` · `apply`
- `zenbook-duo-screen-trackpad`: `status` · `toggle` · `on` · `dark` · `off` · `apply`

### Optional keybindings

The plugin does not touch your keybindings. To add them, put these in `~/.config/hypr/bindings.lua`:

```lua
-- Super+Alt+P toggles the screen trackpad
o.bind("SUPER + ALT + P", "Screen trackpad", "~/.config/omarchy/plugins/squinto.zenbook-duo-bottom-oled/bin/zenbook-duo-screen-trackpad toggle")

-- Brightness keys act on the focused panel, so the bottom OLED can be dimmed
-- on its own. Stock Omarchy always adjusts the top panel.
local duo_brightness = "~/.config/omarchy/plugins/squinto.zenbook-duo-bottom-oled/bin/zenbook-duo-brightness"
for _, b in ipairs({
  { "XF86MonBrightnessUp", "Brightness up", "+5%" },
  { "XF86MonBrightnessDown", "Brightness down", "5%-" },
  { "SHIFT + XF86MonBrightnessUp", "Brightness maximum", "100%" },
  { "SHIFT + XF86MonBrightnessDown", "Brightness minimum", "1%" },
  { "ALT + XF86MonBrightnessUp", "Brightness up precise", "+1%" },
  { "ALT + XF86MonBrightnessDown", "Brightness down precise", "1%-" },
}) do
  hl.unbind(b[1])
  o.bind(b[1], b[2], duo_brightness .. " " .. b[3], { locked = true, repeating = true })
end
```

## Tuning the trackpad

`config.json` holds the pad's geometry and tap rules. The overlay picks up changes on save; restart the daemon for the touch side:

```
systemctl --user restart zenbook-duo-screen-trackpad
```

| Key | Default | Meaning |
|-----|---------|---------|
| `widthMm`, `heightMm` | 120, 70 | Pad size |
| `bottomMm` | 4 | Gap between the pad and the panel's bottom edge |
| `clickMode` | `tap` | `tap`, or `doubletap` (a single tap does nothing; two taps click) |
| `tapMaxMs` | 180 | A tap must be shorter than this |
| `tapMaxMoveMm` | 1.5 | A tap must move less than this |
| `tapGapMs` | 250 | Window for a second tap or a tap-then-drag |
| `tapCooldownMs` | 150 | Taps this soon after a pan or scroll ends are ignored |

The daemon logs raw touch events to `$XDG_RUNTIME_DIR/zenbook-duo-screen-trackpad/raw.log` (memory-backed, rotated at 8 MB). When a click misfires, replay the last few seconds through the same logic to see which gesture produced it, and try other values without touching the live pad:

```
bin/screen-trackpad-replay --last 10
bin/screen-trackpad-replay --last 10 --set tapMaxMs=140 --set tapCooldownMs=250
```

## How the trackpad works

- `bin/screen-trackpadd` runs as the `zenbook-duo-screen-trackpad` systemd user service.
- **Exclusive grab:** it grabs the bottom touchscreen, so no raw touch reaches the compositor.
- **Pad touches:** contacts that start inside the pad are replayed onto a virtual multitouch touchpad. libinput handles motion, acceleration and scrolling.
- **Taps:** detected by the daemon and sent through a separate virtual button device. libinput's own tap-to-click misfires on this digitizer, which drops contacts mid-pan and staggers fingers at the start and end of a scroll.
- **Touches outside the pad:** go to a virtual touchscreen bound to `eDP-2`, so the rest of the panel stays a touchscreen.
- **Drawing:** `Trackpad.qml`, a shell service, draws the pad outline, or the black cover in dark mode.
- **Hyprland settings** live in a stub under `~/.local/state/omarchy/toggles/hypr/`, rewritten only when the plugin's copy changes:
  - each touchscreen is bound to its own panel; unbound, Hyprland sends touches to the monitor under the cursor
  - tap-to-click is off for the virtual pad
  - while the trackpad is on, the cursor isn't hidden on touch

## Keyboard (CA)

Each OLED also exposes a full-panel fake **touchpad** (`elan9008` top / `elan9009` bottom) plus a bottom **touchscreen**. Those are what jump the cursor while typing — not the folio Primax trackpad.

The helper disables both fake pads always, and the bottom digitizer with the panel. Do **not** run `omarchy toggle touchpad` (it matches the first ELAN node). Do not disable the folio trackpad.

## Remove

```
~/.config/omarchy/plugins/squinto.zenbook-duo-bottom-oled/bin/zenbook-duo-screen-trackpad off
systemctl --user disable --now zenbook-duo-screen-trackpad
rm ~/.config/systemd/user/zenbook-duo-screen-trackpad.service
omarchy plugin remove squinto.zenbook-duo-bottom-oled
```

Leftovers you can delete:

- `~/.local/state/omarchy/zenbook-duo-bottom-oled` and `~/.local/state/omarchy/zenbook-duo-screen-trackpad` (state)
- `zenbook-duo-bottom-oled.lua`, `zenbook-duo-screen-trackpad.lua` and `zenbook-duo-fake-touchpad.lua` under `~/.local/state/omarchy/toggles/hypr/`
- `/etc/udev/rules.d/70-zenbook-duo-screen-trackpad.rules`, if you installed it (needs `sudo`)
- the keybindings, if you added them

## What this does not do

- Folio-as-hide
- World-writable udev
- Edit `/usr/share/omarchy/` or your own config files
- Global DPMS (that blanks **both** panels)

## License

MIT. See `LICENSE`.
