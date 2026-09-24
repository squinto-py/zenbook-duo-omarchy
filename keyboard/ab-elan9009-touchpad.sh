#!/usr/bin/env bash
# Reversible live A/B for the UX8406CA bottom OLED fake touchpad.
# Disables only the bottom OLED extra HID collection that Hyprland treats as a
# touchpad. Session-only: does not write Omarchy toggle files or hypr configs.
# hyprctl reload restores enabled=true.
set -euo pipefail

NAME='elan9009:00-04f3:4448-touchpad'
# Snapshot: no per-device override; Hyprland default enabled=true.

usage() {
  echo "Usage: $0 {status|off|on}" >&2
  echo "  off  — A/B: disable ${NAME} (live)" >&2
  echo "  on   — rollback: enable ${NAME} (live)" >&2
  echo "  status — print whether Hyprland still lists the device" >&2
  exit 1
}

apply() {
  local enabled=$1
  hyprctl eval "hl.device({ name = \"${NAME}\", enabled = ${enabled} })"
}

listed() {
  hyprctl devices | grep -F "$NAME" >/dev/null
}

cmd="${1:-}"
case "$cmd" in
  off) apply false ;;
  on) apply true ;;
  status)
    if listed; then
      echo "listed: ${NAME} (Hyprland still enumerates it; enabled=false does not unplug)"
    else
      echo "not listed: ${NAME}"
    fi
    ;;
  *) usage ;;
esac
