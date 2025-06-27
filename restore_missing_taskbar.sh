#!/usr/bin/env bash
################################################################################
# restore_missing_taskbar.sh
# Restore disappeared KDE Plasma taskbar/panel
################################################################################

echo "🔧 Restoring Missing Taskbar/Panel"
echo "=================================="
echo ""

echo "🚨 Don't panic! This is fixable. Let's restore your taskbar."
echo ""

echo "⚡ Method 1: Quick Keyboard Shortcut (Try This First!)"
echo "====================================================="
echo ""
echo "Press these key combinations:"
echo "  Alt + F2  (opens KRunner)"
echo "  Type: plasmashell --replace"
echo "  Press Enter"
echo ""
echo "OR try:"
echo "  Alt + F2"
echo "  Type: kquitapp5 plasmashell && kstart5 plasmashell"
echo "  Press Enter"
echo ""

echo "🔄 Method 2: Automated Taskbar Restoration"
echo "=========================================="

# Kill any existing plasmashell processes
echo "Stopping current plasmashell..."
killall plasmashell 2>/dev/null || true
sleep 3

# Remove problematic panel configuration
echo "Resetting panel configuration..."
BACKUP_DIR="$HOME/.config/panel_emergency_backup_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

# Backup current configs
cp "$HOME/.config/plasma-org.kde.plasma.desktop-appletsrc" "$BACKUP_DIR/" 2>/dev/null || true
cp "$HOME/.config/plasmashellrc" "$BACKUP_DIR/" 2>/dev/null || true

echo "✅ Configs backed up to: $BACKUP_DIR"

# Remove the problematic configuration
rm -f "$HOME/.config/plasma-org.kde.plasma.desktop-appletsrc"
rm -f "$HOME/.config/plasmashellrc"

echo "✅ Problematic configs removed"

# Create a basic panel configuration
echo "Creating default panel configuration..."

cat > "$HOME/.config/plasmashellrc" << 'EOF'
[PlasmaViews][Panel 1]
alignment=132
floating=0
location=4
panelVisibility=0
thickness=44

[PlasmaViews][Panel 1][Defaults]
thickness=44
EOF

echo "✅ Basic panel config created"

# Restart plasmashell with default configuration
echo "Starting plasmashell with restored configuration..."

if command -v kstart5 >/dev/null; then
    kstart5 plasmashell &
else
    plasmashell &
fi

echo "✅ Plasmashell restarted"
echo ""

echo "⏳ Waiting for panel to appear..."
sleep 8

echo ""
echo "🎯 Method 3: Add Panel Manually (If Still Missing)"
echo "================================================="
echo ""
echo "If the taskbar is still missing:"
echo ""
echo "1. Right-click on empty desktop"
echo "2. Select 'Add Panel' → 'Default Panel'"
echo "3. Or 'Add Panel' → 'Empty Panel' then add widgets"
echo ""

echo "🖱️  Method 4: Using Desktop Context Menu"
echo "======================================="
echo ""
echo "Alternative approach:"
echo "1. Right-click anywhere on the desktop"
echo "2. Look for 'Add Panel' or 'Configure Desktop'"
echo "3. Select 'Add Panel' → 'Default Panel'"
echo ""

echo "⌨️  Method 5: KRunner Command (Emergency)"
echo "========================================"
echo ""
echo "If nothing else works:"
echo "1. Press Alt + F2 (opens KRunner)"
echo "2. Type: qdbus org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript 'panelById(panelIds[0]).destroy()'"
echo "3. Press Enter"
echo "4. Then type: qdbus org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript 'var panel = new Panel; panel.location = \"bottom\"; panel.height = 44'"
echo "5. Press Enter"
echo ""

echo "🔧 Method 6: Complete Plasma Reset (Nuclear Option)"
echo "=================================================="
echo ""
echo "If absolutely nothing works, complete reset:"
echo ""

cat > /tmp/complete_plasma_reset.sh << 'EOF'
#!/bin/bash
echo "🚨 COMPLETE PLASMA RESET - This will reset ALL your desktop settings!"
read -p "Are you sure? Type 'yes' to continue: " confirm

if [[ "$confirm" == "yes" ]]; then
    echo "Backing up current config..."
    BACKUP_DIR="$HOME/.config/plasma_complete_backup_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    cp -r "$HOME/.config/plasma"* "$BACKUP_DIR/" 2>/dev/null || true
    cp -r "$HOME/.local/share/plasma"* "$BACKUP_DIR/" 2>/dev/null || true
    
    echo "Removing plasma configuration..."
    rm -rf "$HOME/.config/plasma"*
    rm -rf "$HOME/.local/share/plasma"*
    
    echo "Restarting plasma..."
    killall plasmashell
    sleep 3
    kstart5 plasmashell &
    
    echo "✅ Plasma completely reset to defaults"
    echo "📁 Backup saved to: $BACKUP_DIR"
else
    echo "Reset cancelled"
fi
EOF

chmod +x /tmp/complete_plasma_reset.sh

echo "Complete reset script created at: /tmp/complete_plasma_reset.sh"
echo "⚠️  Only use this if nothing else works!"
echo ""

echo "🧪 Testing Current Status"
echo "========================"

# Check if plasmashell is running
if pgrep plasmashell >/dev/null; then
    echo "✅ Plasmashell is running"
else
    echo "❌ Plasmashell not running - starting it..."
    if command -v kstart5 >/dev/null; then
        kstart5 plasmashell &
    else
        plasmashell &
    fi
fi

echo ""
echo "🎉 Taskbar Restoration Attempted!"
echo ""
echo "📋 What to expect:"
echo "  • Taskbar should appear at the bottom"
echo "  • Default widgets: App Launcher, Task Manager, System Tray, Clock"
echo "  • Clean layout without duplicates"
echo ""
echo "🔍 If taskbar is still missing:"
echo "  1. Try the keyboard shortcuts above (Alt + F2)"
echo "  2. Right-click desktop → Add Panel → Default Panel"
echo "  3. Log out and log back in"
echo "  4. Restart computer as last resort"
echo ""
echo "✅ Your taskbar should be back! 🎯"
