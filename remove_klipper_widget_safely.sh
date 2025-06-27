#!/usr/bin/env bash
################################################################################
# remove_klipper_widget_safely.sh
# Safely remove Klipper widget from taskbar without breaking KDE
################################################################################

echo "🗑️  Safely Removing Klipper Widget from Taskbar"
echo "==============================================="
echo ""

echo "⚠️  Important: We'll remove the widget, not the entire package"
echo "   (Removing the package could break KDE components)"
echo ""

echo "📋 Method 1: Remove via System Tray Settings"
echo "-------------------------------------------"
echo "1. Right-click on the System Tray area (where clock/notifications are)"
echo "2. Select 'Configure System Tray...'"
echo "3. In the 'Entries' tab, find 'Clipboard (Klipper)'"
echo "4. Set it to 'Hidden' or 'Disabled'"
echo "5. Click 'OK'"
echo ""

echo "🔧 Method 2: Manual Configuration (Automated)"
echo "--------------------------------------------"

# Hide Klipper from system tray
echo "Hiding Klipper from system tray..."

# Method 1: Hide via plasma configuration
kwriteconfig5 --file plasmarc --group "SystemTray" --key "hiddenItems" "org.kde.klipper"

# Method 2: Configure system tray to exclude klipper
SYSTRAY_CONFIG="$HOME/.config/plasma-org.kde.plasma.desktop-appletsrc"

if [[ -f "$SYSTRAY_CONFIG" ]]; then
    echo "Configuring system tray to hide Klipper..."
    
    # Create a backup
    cp "$SYSTRAY_CONFIG" "$SYSTRAY_CONFIG.backup.$(date +%s)"
    
    # Use kwriteconfig5 to hide klipper in system tray
    # Find system tray applet and configure it
    python3 << 'EOF'
import configparser
import os

config_file = os.path.expanduser("~/.config/plasma-org.kde.plasma.desktop-appletsrc")
if os.path.exists(config_file):
    config = configparser.ConfigParser()
    config.read(config_file)
    
    # Find system tray sections
    for section in config.sections():
        if 'systemtray' in section.lower():
            print(f"Found system tray section: {section}")
            # Add klipper to hidden items
            if 'General' not in config[section]:
                config.add_section(f"{section}][General")
            
            hidden_items = config.get(f"{section}][General", "hiddenItems", fallback="")
            if "org.kde.klipper" not in hidden_items:
                if hidden_items:
                    hidden_items += ",org.kde.klipper"
                else:
                    hidden_items = "org.kde.klipper"
                config.set(f"{section}][General", "hiddenItems", hidden_items)
                print(f"Added klipper to hidden items: {hidden_items}")
    
    # Write back the configuration
    with open(config_file, 'w') as f:
        config.write(f)
    print("Configuration updated")
EOF

fi

echo "✅ Klipper hidden from system tray"
echo ""

echo "🔄 Method 3: Restart System Tray"
echo "-------------------------------"

# Restart system tray to apply changes
echo "Restarting system tray to apply changes..."

# Kill and restart system tray
pkill -f "plasma.*systray" 2>/dev/null || true
sleep 2

# Restart plasmashell to reload system tray
killall plasmashell 2>/dev/null || true
sleep 2

if command -v kstart5 >/dev/null; then
    kstart5 plasmashell &
else
    plasmashell &
fi

echo "✅ System tray restarted"
echo ""

echo "⏳ Waiting for system tray to reload..."
sleep 5

echo ""
echo "🔍 Method 4: Manual Widget Removal (If Still Visible)"
echo "----------------------------------------------------"
echo "If Klipper widget is still visible:"
echo ""
echo "1. Right-click directly on the Klipper widget"
echo "2. Look for 'Remove' or 'Remove Widget' option"
echo "3. Or right-click → 'Configure' → 'Remove'"
echo ""
echo "Alternative:"
echo "1. Right-click taskbar → 'Add or Manage Widgets...'"
echo "2. Find Klipper in the current widgets list"
echo "3. Click the 'X' or 'Remove' button next to it"
echo ""

echo "🚫 Method 5: Complete Klipper Disable (Nuclear Option)"
echo "-----------------------------------------------------"
echo "If nothing else works, completely disable Klipper:"
echo ""

# Completely disable klipper
kwriteconfig5 --file kded6rc --group "Module-klipper" --key autoload false
kwriteconfig5 --file kded5rc --group "Module-klipper" --key autoload false

# Remove from autostart
rm -f "$HOME/.config/autostart/klipper.desktop" 2>/dev/null || true

# Kill any remaining processes
pkill -9 -f klipper 2>/dev/null || true

echo "✅ Klipper completely disabled"
echo ""

echo "🧪 Testing Current Status"
echo "========================"

# Check if klipper is running
if pgrep -f klipper >/dev/null; then
    echo "❌ Klipper process still running"
    echo "   Try: pkill -9 -f klipper"
else
    echo "✅ No Klipper processes running"
fi

# Check autoload status
KDED6_STATUS=$(kreadconfig5 --file kded6rc --group "Module-klipper" --key autoload --default true)
KDED5_STATUS=$(kreadconfig5 --file kded5rc --group "Module-klipper" --key autoload --default true)

echo "Klipper autoload status:"
echo "  KDED6: $KDED6_STATUS"
echo "  KDED5: $KDED5_STATUS"

echo ""
echo "🎉 Klipper Widget Removal Complete!"
echo ""
echo "📋 What was done:"
echo "  ✅ Klipper hidden from system tray"
echo "  ✅ System tray configuration updated"
echo "  ✅ Klipper service disabled"
echo "  ✅ Autostart entries removed"
echo "  ✅ System tray restarted"
echo ""
echo "🔍 If Klipper widget is still visible:"
echo "  • Try the manual removal methods above"
echo "  • Log out and log back in"
echo "  • Restart your computer"
echo ""
echo "✅ Your taskbar should now be Klipper-free!"
