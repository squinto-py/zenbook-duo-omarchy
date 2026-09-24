#!/usr/bin/env bash
# UX8406CA: disable the two full-OLED fake "touchpads" Hyprland treats as mice.
# Do NOT touch the folio Primax trackpad. Do NOT omarchy toggle touchpad.
# Live: hyprctl eval hl.device. Persist: static stub lua (written once).
set -euo pipefail

product=$(tr -d '\0' </sys/class/dmi/id/product_name 2>/dev/null || true)
board=$(tr -d '\0' </sys/class/dmi/id/board_name 2>/dev/null || true)
if [[ $product != *UX8406CA* && $board != *UX8406CA* ]]; then
  echo "skip fake-touchpad: not UX8406CA (product=$product board=$board)" >&2
  exit 0
fi

NAMES=(
  'elan9008:00-04f3:4447-touchpad'
  'elan9009:00-04f3:4448-touchpad'
)

TOGGLE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/omarchy/toggles/hypr"
STUB="$TOGGLE_DIR/zenbook-duo-fake-touchpad.lua"

stub_lua() {
  cat <<'EOF'
-- squinto.zenbook-duo-bottom-oled — CA fake OLED touchpads off.
-- Do not rewrite on toggle. Do not disable folio primax touchpad.
hl.device({ name = "elan9008:00-04f3:4447-touchpad", enabled = false })
hl.device({ name = "elan9009:00-04f3:4448-touchpad", enabled = false })
EOF
}

ensure_stub() {
  mkdir -p "$TOGGLE_DIR"
  umask 022
  if [[ -f $STUB ]]; then
    return 0
  fi
  local tmp
  tmp=$(mktemp "$TOGGLE_DIR/.zenbook-duo-fake-touchpad.lua.XXXXXX")
  stub_lua >"$tmp"
  chmod 644 "$tmp"
  mv -f "$tmp" "$STUB"
}

live() {
  local enabled=$1 name lua out
  for name in "${NAMES[@]}"; do
    lua="hl.device({ name = \"${name}\", enabled = ${enabled} })"
    out=$(hyprctl eval "$lua")
    if [[ $out != ok ]]; then
      echo "hyprctl eval failed for $name: $out" >&2
      exit 1
    fi
  done
}

usage() {
  echo "Usage: $0 {off|on|status|apply}" >&2
  exit 1
}

cmd=${1:-}
case "$cmd" in
  off)
    live false
    ensure_stub
    echo "fake OLED touchpads: live off (CA). folio trackpad untouched."
    ;;
  on)
    live true
    echo "fake OLED touchpads: live on (rollback). stub still disables at next login until you remove $STUB"
    ;;
  apply)
    live false
    ensure_stub
    echo "fake OLED touchpads: apply off + stub."
    ;;
  status)
    for name in "${NAMES[@]}"; do
      if hyprctl devices | grep -F "$name" >/dev/null; then
        echo "listed: $name"
      else
        echo "not listed: $name"
      fi
    done
    if [[ -f $STUB ]]; then echo "stub: $STUB"; else echo "stub: absent"; fi
    ;;
  *) usage ;;
esac
