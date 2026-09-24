# W1 quiet path (Hyprland 0.56.2 Lua)

SKU: UX8406CA (CA, not MA). Bottom OLED is `eDP-2`.

Live apply is `hyprctl eval` with Omarchy Lua `hl.monitor({ ... })`. The legacy keyword parser is rejected on this compositor. Do not force a compositor config reload. Mute desktop notify.

```
hyprctl eval 'hl.monitor({ output = "eDP-2", disabled = true })'
hyprctl eval 'hl.monitor({ output = "eDP-2", disabled = false, mode = "preferred", position = "auto-down", scale = 2 })'
```

Enable **must** include `disabled = false`. Omitting it returns `ok` and leaves eDP-2 off.

Persist (umask 022, mode 644) still under `~/.local/state/omarchy/toggles/hypr/` so the next compositor start matches. Default OFF. Folio is not the hide path.
