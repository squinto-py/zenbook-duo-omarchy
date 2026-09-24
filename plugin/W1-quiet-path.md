# W1 quiet path (FRIC-028)

SKU: UX8406CA (CA, not MA). Bottom OLED is `eDP-2`.

Live toggle is per-output DPMS:
  hl.dispatch(hl.dsp.dpms({ action = "off"|"on", monitor = "eDP-2" }))
Never omit monitor (global dpms blanks eDP-1).

Do **not** `disabled = true` on live off — that is `monitorremoved` and Omarchy
closes `omarchy-bar` / `omarchy-background` (top ribbon flash).

Login persist: static stub lua reads STATE_FILE; desired!=on => disabled=true
(lag-correct). Never rewrite `toggles/hypr` on toggle.

First ON after a disabled login still enables the output once (bar hitch that
once). Later off/on in the same session should be DPMS-only (no layer close).
