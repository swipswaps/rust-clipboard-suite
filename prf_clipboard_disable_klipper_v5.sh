#!/usr/bin/env bash
################################################################################
# PRF_CLIPBOARD_DISABLE_KLIPPER_V5.sh
# Fully disables KDE Klipper: tray, panel, D-Bus, autoload, widget config
# PRF-COMPLIANT: Plasma 5/6 compatible, prevents respawn, persistent kill loop
################################################################################

set -euo pipefail
IFS=$'\n\t'

echo "[INFO] 🚫 Disabling Klipper completely..."

# ─── Detect Session and Plasma Version ────────────────────────────────────────
SESSION_TYPE="${XDG_SESSION_TYPE:-unknown}"
[[ "$SESSION_TYPE" != "x11" ]] && echo "[FAIL] ❌ Only X11 supported. Found: $SESSION_TYPE" && exit 1

if ! pgrep -x plasmashell >/dev/null; then
  echo "[FAIL] ❌ KDE not running (plasmashell missing)"
  exit 1
fi

DBUS_DAEMON=""
CONFIG_FILE=""

if qdbus 2>/dev/null | grep -q org.kde.kded6; then
  DBUS_DAEMON="org.kde.kded6"
  CONFIG_FILE="$HOME/.config/kded6rc"
elif qdbus 2>/dev/null | grep -q org.kde.kded5; then
  DBUS_DAEMON="org.kde.kded5"
  CONFIG_FILE="$HOME/.config/kded5rc"
else
  echo "[WARN] ⚠️ No kded service found. Proceeding with config-only disable."
  DBUS_DAEMON=""
  CONFIG_FILE="$HOME/.config/kded6rc"  # Default to newer format
fi

echo "[INFO] 📋 Using DBus: $DBUS_DAEMON"
echo "[INFO] 📁 Config file: $CONFIG_FILE"

# ─── Unload D-Bus Module ──────────────────────────────────────────────────────
if [[ -n "$DBUS_DAEMON" ]]; then
  echo "[ACTION] 🔧 Unloading Klipper from $DBUS_DAEMON..."
  if qdbus "$DBUS_DAEMON" /kded loadedModules 2>/dev/null | grep -q klipper; then
    qdbus "$DBUS_DAEMON" /kded unloadModule klipper || echo "[WARN] ⚠️ Failed to unload via DBus"
  else
    echo "[INFO] ✅ Klipper not currently loaded in $DBUS_DAEMON"
  fi
fi

# ─── Disable autoload flag ────────────────────────────────────────────────────
echo "[ACTION] 🔧 Disabling Klipper autoload in $CONFIG_FILE..."
kwriteconfig5 --file "$CONFIG_FILE" --group "Module-klipper" --key autoload false

# ─── Kill Klipper and Prevent Respawn ─────────────────────────────────────────
echo "[ACTION] 🔪 Killing all klipper instances..."
pkill -x klipper || true
pkill -f '[k]lipper' || true
for _ in {1..5}; do
  sleep 1
  pkill -x klipper >/dev/null 2>&1 || true
done

# ─── Override User Autostart ──────────────────────────────────────────────────
USER_AUTOSTART="$HOME/.config/autostart/klipper.desktop"
echo "[ACTION] 🚫 Overriding autostart with Hidden=true..."
mkdir -p "$HOME/.config/autostart"
cat > "$USER_AUTOSTART" <<EOF
[Desktop Entry]
Type=Application
Name=Klipper
Exec=klipper
Hidden=true
NoDisplay=true
X-GNOME-Autostart-enabled=false
X-KDE-autostart-after=panel
EOF

# ─── Remove Plasma Panel References ───────────────────────────────────────────
APPLETSRC="$HOME/.config/plasma-org.kde.plasma.desktop-appletsrc"
echo "[ACTION] 🧼 Removing Klipper entries from: $APPLETSRC"
sed -i '/Klipper/d' "$APPLETSRC" || true

# ─── Remove Saved Session (in case of restore) ────────────────────────────────
echo "[ACTION] 🧼 Cleaning saved session..."
rm -f "$HOME/.config/session/klipper_*" 2>/dev/null || true

# ─── Final Verification ───────────────────────────────────────────────────────
echo "[VERIFY] 🔁 D-Bus check post-disable:"
qdbus "$DBUS_DAEMON" /kded loadedModules | grep -q klipper \
  && echo "[WARN] ⚠ Still present!" || echo "[SUCCESS] ✅ Not loaded."

echo "[INFO] 🔁 Restart plasmashell for full effect:"
echo "       killall plasmashell && kstart5 plasmashell"

echo "[DONE] 🎉 Klipper disabled: D-Bus, tray, config, widget, autostart, saved session."

exit 0
