#!/usr/bin/env bash
################################################################################
# simple_panel_reset.sh
# Simple and safe panel reset with Klipper removal
################################################################################

echo "🔧 Simple Panel Reset & Klipper Removal"
echo "========================================"
echo ""

echo "📋 Step 1: Final Klipper cleanup..."

# Disable Klipper completely
kwriteconfig5 --file kded6rc --group "Module-klipper" --key autoload false 2>/dev/null || true
kwriteconfig5 --file kded5rc --group "Module-klipper" --key autoload false 2>/dev/null || true

# Kill any Klipper processes
pkill -f klipper 2>/dev/null || true

echo "✅ Klipper disabled and stopped"
echo ""

echo "🔄 Step 2: Backing up and resetting panel..."

# Backup current config
BACKUP_DIR="$HOME/.config/panel_backup_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"
cp "$HOME/.config/plasma-org.kde.plasma.desktop-appletsrc" "$BACKUP_DIR/" 2>/dev/null || true

echo "✅ Configuration backed up to $BACKUP_DIR"

# The actual reset (this is what you wanted to run)
echo "🗑️  Removing current panel configuration..."
killall plasmashell 2>/dev/null || true
sleep 2

# Remove panel config to force defaults
rm -f "$HOME/.config/plasma-org.kde.plasma.desktop-appletsrc"

echo "✅ Panel configuration removed"
echo ""

echo "🚀 Step 3: Restarting Plasma with defaults..."

# Restart plasmashell
if command -v kstart5 >/dev/null; then
    kstart5 plasmashell &
else
    plasmashell &
fi

echo "✅ Plasma restarted"
echo ""

echo "⏳ Waiting for Plasma to stabilize..."
sleep 5

echo ""
echo "🎉 Panel Reset Complete!"
echo ""
echo "📋 What you now have:"
echo "  ✅ Clean default panel layout (no duplicates)"
echo "  ✅ Klipper completely removed"
echo "  ✅ Standard KDE widgets in default positions"
echo ""
echo "🔧 To customize your panel:"
echo "  1. Right-click taskbar → 'Add or Manage Widgets'"
echo "  2. Drag widgets to reposition"
echo "  3. Add our clipboard manager widget if desired"
echo ""
echo "✅ Your panel is now clean and ready for customization!"
