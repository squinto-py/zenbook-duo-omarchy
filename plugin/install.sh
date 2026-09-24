#!/usr/bin/env bash
# Install the bottom-OLED community plugin into the user Omarchy plugins dir.
# No root, no udev, no visudo, no extra compositor.
set -euo pipefail

ROOT=$(cd "$(dirname "$0")" && pwd)
ID=$(jq -r .id "$ROOT/manifest.json")
DEST="${XDG_CONFIG_HOME:-$HOME/.config}/omarchy/plugins/$ID"
ENABLE_WIDGET=0

for arg in "$@"; do
  case "$arg" in
    --enable-widget) ENABLE_WIDGET=1 ;;
    -h | --help)
      echo "Usage: $0 [--enable-widget]"
      exit 0
      ;;
    *)
      echo "unknown argument: $arg" >&2
      exit 1
      ;;
  esac
done

omarchy plugin validate "$ROOT"

mkdir -p "$(dirname "$DEST")"
rm -rf "$DEST"
mkdir -p "$DEST"
umask 022
cp -a "$ROOT/." "$DEST/"
chmod 755 "$DEST/bin/zenbook-duo-bottom-oled" "$DEST/install.sh"

"$DEST/bin/zenbook-duo-bottom-oled" apply

echo "Installed $ID at $DEST"
echo "eDP-2 default OFF applied via Hyprland toggle Lua (no folio hide path)."
echo "Toggle: $DEST/bin/zenbook-duo-bottom-oled {on|off|toggle|status}"

if (( ENABLE_WIDGET )); then
  omarchy-shell shell rescanPlugins >/dev/null 2>&1 || true
  # Telegram lives on the top bar as a StatusNotifierItem inside omarchy.tray
  # (right section of ~/.config/omarchy/shell.json). Place this widget next to it.
  omarchy plugin enable "$ID" --after omarchy.tray
  echo "Bar widget enabled next to omarchy.tray (Telegram tray icon)."
else
  echo "Bar widget not enabled (least extra shell load). Optional:"
  echo "  omarchy plugin enable $ID --after omarchy.tray"
fi
