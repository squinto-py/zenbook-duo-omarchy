# FR-206 W3 / FRIC-029 — keyboard glitch probes (cursor-jump class)

SKU label on every finding: **CA** = UX8406CA (this machine). **MA** = UX8406MA (not this SKU). **generic** = any dual-eDP / i8042 / Hyprland default.

Do not treat eDP-2 disable as a keyboard fix (screen plugin is a different branch). eDP-2 was already compositor-disabled at probe time; digitizers were still present.

## Symptoms asked

Operator: very glitchy keyboard experience, **cursor-jump class** (pointer teleports / focus follows phantom motion while typing).

## Machine (CA)

| Field | Value |
| --- | --- |
| `product_name` | `ASUS Zenbook Duo UX8406CA_UX8406CA` |
| `board_name` | `UX8406CA` |
| Probed | 2026-09-24T13:31:29-05:00 |
| Session | Hyprland 0.56.2, Omarchy |
| eDP-1 | Samsung 0x419D 2880x1800@120 scale 2, focused, enabled |
| eDP-2 | same panel class, `disabled: true`, at 0x900 — **not** used as a keyboard lever |

## Probes

### `hyprctl devices` (CA)

Mice / pointer:

- `elan9008:00-04f3:4447-touchpad` — **CA** top OLED extra HID collection (see udev)
- `elan9009:00-04f3:4448-touchpad` — **CA** bottom OLED extra HID collection
- `primax-electronics-ltd.-asus-zenbook-duo-keyboard-1`
- `primax-electronics-ltd.-asus-zenbook-duo-keyboard-mouse` — folio relative mouse (iface 5)
- `primax-electronics-ltd.-asus-zenbook-duo-keyboard-touchpad` — folio trackpad 128×72 mm (iface 5)

Keyboards:

- `primax-electronics-ltd.-asus-zenbook-duo-keyboard` (folio, USB iface 0)
- `primax-electronics-ltd.-asus-zenbook-duo-keyboard-2` (folio, USB iface 3, udev `ID_INPUT_KEY` only)
- `at-translated-set-2-keyboard` — **generic** i8042 stub (still enumerated with folio attached)
- `hl-virtual-keyboard-fcitx5` (Hyprland `main: yes`)
- plus video-bus / intel-hid / power-button / asus-wmi-hotkeys

Touch: `elan9008:00-04f3:4447` (eDP-1), `elan9009:00-04f3:4448` (eDP-2). Stylus on both.

### Folio USB vs 0b05:1b2c (CA)

`lsusb` is **not installed** (`usbutils` missing). Enumeration via sysfs:

| | VID:PID | Product |
| --- | --- | --- |
| **CA this box** | **`0b05:1bf2`** | Primax Electronics Ltd. `ASUS Zenbook Duo Keyboard` on `usb3/3-6` |
| Task named | `0b05:1b2c` | **not present**. Treat `1b2c` as **MA or older folio** until an MA box is probed. |

Six HID interfaces, all `usbhid`:

| iface | class/sub/proto | udev input | Role (CA) |
| --- | --- | --- | --- |
| 3-6:1.0 | 03/01/01 | event4 `ID_INPUT_KEYBOARD` | folio keys |
| 3-6:1.1 … 1.4 | 03/00/00 | (hidraw; event5 on 1.3 is `ID_INPUT_KEY`) | extra collections / consumer keys |
| 3-6:1.5 | 03/00/00 | event6 `ID_INPUT_MOUSE` + event7 `ID_INPUT_TOUCHPAD` 128×72 mm | **real** folio pointer + trackpad |

### Elan digitizers (CA, not USB)

I2C-HID, **not** on the folio:

| HID | Panel | Touchscreen | Extra “Touchpad” (smoking gun) |
| --- | --- | --- | --- |
| `04F3:4447` ELAN9008 | eDP-1 top **CA** | event16 `ID_INPUT_TOUCHSCREEN` | event20 `ID_INPUT_TOUCHPAD` **306×187 mm** (full panel) |
| `04F3:4448` ELAN9009 | eDP-2 bottom **CA** | event11 `ID_INPUT_TOUCHSCREEN` | event15 `ID_INPUT_TOUCHPAD` **306×187 mm** (full panel) |

Hyprland therefore sees two **internal** full-OLED “touchpads” as mice. `omarchy-hw-touchpad` returns `elan9008:00-04f3:4447-touchpad` (first `touchpad` match) — **not** the folio trackpad. Do not `omarchy toggle touchpad`; it would persist-disable the wrong node.

### `libinput list-devices`

**generic tooling gap:** `libinput` 1.31.3 is the library + udev helpers only; **no** `libinput` CLI. Command produced empty output. udev `ID_INPUT_*` used instead.

### Hyprland input options (generic Omarchy defaults unless noted)

| option | live | `set` |
| --- | --- | --- |
| `input:kb_options` | `compose:caps,shift:both_capslock_cancel` | true |
| `input:follow_mouse` | `1` | true (Omarchy default) |
| `input:mouse_refocus` | `true` | false (Hyprland default) |
| `input:kb_layout` | `us` | true |
| `input:repeat_rate` / `delay` | 40 / 250 | true |
| `~/.config/hypr/input.lua` | comments only — no personal device rules | |

`follow_mouse=1` + phantom full-panel touchpad motion is the cursor-jump amplifier (**generic** compositor behavior, **CA** device topology).

Evdev idle capture was **not** run: `/dev/input/event*` is `EACCES` without extra privilege. Did not sudo / visudo.

## Hypotheses (ranked)

1. **CA — H1 (applied A/B):** ELAN9009 (`04F3:4448`) bottom-OLED extra collection is an internal 306×187 mm touchpad that stays live while eDP-2 is compositor-disabled. Folio sits on/near that glass → palm/ghost ABS motion → cursor jump + `follow_mouse` focus. Same class as H2 but physically under the keyboard.
2. **CA — H2 (not applied; next A/B):** ELAN9008 (`04F3:4447`) top-OLED extra collection, same fake-touchpad shape. Palm on the *used* screen.
3. **CA folio + generic Hypr — H3 (not applied):** Folio `0b05:1bf2` iface 5 mouse, or `follow_mouse=1` / `mouse_refocus=true` on any of the five pointer nodes. Dual Primax keyboards + i8042 `AT Translated Set 2` are more “double key / weird mods” than cursor-jump.

`0b05:1b2c` vs keyboard: **not this SKU**. Folio **is** the keyboard (`1bf2`), composite HID, not a separate dongle.

## What we tried (one live A/B)

**Change:** disable **only** `elan9009:00-04f3:4448-touchpad` via live Lua. Touchscreen `elan9009:00-04f3:4448` left enabled. Folio keys/trackpad untouched. eDP-2 state untouched.

**Snapshot (prior):** no per-device override (`hyprctl getoption device[…]:enabled` → `no such option`). Hyprland default **enabled = true**.

**Apply (session only, not persisted):**

```bash
hyprctl eval 'hl.device({ name = "elan9009:00-04f3:4448-touchpad", enabled = false })'
# → ok, configerrors empty. Device still listed under mice (disable does not unplug).
```

Helper: `plugin/keyboard/ab-elan9009-touchpad.sh {status|off|on}`.

**Did not persist:** no `~/.local/state/omarchy/toggles/hypr/*-disabled-name`, no `~/.config/hypr` edit, no kernel cmdline, no `hyprctl reload`.

**Operator check:** type on the folio. If jumps stop, H1 holds. If not, rollback then try H2 (ELAN9008 touchpad) the same way — still one change at a time.

## Rollback

Live (restores H1 A/B):

```bash
hyprctl eval 'hl.device({ name = "elan9009:00-04f3:4448-touchpad", enabled = true })'
# or: plugin/keyboard/ab-elan9009-touchpad.sh on
# or: hyprctl reload  — restores defaults because this A/B was not written to disk
```

Do **not** `omarchy refresh` / `omarchy reinstall` for this.

## What we did not do

- Persist kernel cmdline; visudo `NOPASSWD: ALL`; sudo
- Disable eDP-2 as a keyboard fix; edit screen plugin / `plugin/bin/zenbook-duo-bottom-oled` / BarWidget.qml / install.sh / README.md
- Touch main, w1, w2 trees; `omarchy reinstall` configs; `hyprctl reload` loops
- Push, post, hermes gateway, clone `/data/ourea`
- `omarchy toggle touchpad` (would persist-disable ELAN9008 fake pad, not folio)
