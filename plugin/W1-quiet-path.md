# W1 quiet path (FRIC-028)

SKU: UX8406CA (CA, not MA). Bottom OLED is `eDP-2`.

Live apply is `hyprctl eval` with Omarchy Lua `hl.monitor({ ... })`.

**Do not** rewrite files under `~/.local/state/omarchy/toggles/hypr/` on every
on/off. Omarchy `default.hypr.toggles` require()'s that dir; Hyprland
`misc:disable_autoreload` is false, so a write triggers config reload.
`omarchy-hyprland-monitor-watch recover_modeless` also `hyprctl reload`s on
monitoradded/removed (enable/disable eDP-2). Together that is the command spam.

Quiet path:
1. Persist desired state only in `~/.local/state/omarchy/zenbook-duo-bottom-oled`.
2. Write a **static** stub lua once (`zenbook-duo-bottom-oled.lua`) that reads
   the state file at compositor start. Never rewrite it on toggle.
3. Hold Omarchy's clamshell + modeless flock locks across eval+settle so
   monitor-watch cannot reload.
4. No `omarchy-notification-send`. No `hyprctl keyword` (Lua parser). No
   `hyprctl reload` fallback.

Enable must include `disabled = false`. Folio is not the hide path.
