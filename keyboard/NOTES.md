# Keyboard (UX8406CA)

Each OLED exposes a full-panel fake touchpad (`elan9008` top / `elan9009` bottom) plus a bottom touchscreen. Those jump the cursor while typing — not the folio Primax trackpad.

`zenbook-duo-fake-touchpad.sh apply` disables both fake pads. Do not run `omarchy toggle touchpad` (it matches the first ELAN node). Do not disable the folio trackpad.

`ab-elan9009-touchpad.sh` is a session-only A/B for the bottom fake pad alone (`hyprctl reload` restores it).
