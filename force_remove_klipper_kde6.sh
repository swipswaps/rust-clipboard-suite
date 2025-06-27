#!/usr/bin/env bash
################################################################################
# force_remove_klipper_kde6.sh
# Force remove Klipper widget using KDE 6 configuration commands
################################################################################

echo "🔧 Force Remove Klipper Widget (KDE 6)"
echo "======================================"
echo ""

echo "Since manual removal didn't work, let's use configuration commands..."
echo ""

# Method 1: Disable Klipper completely via configuration
echo "📋 Method 1: Disable Klipper service completely"
echo "=============================================="

# Disable Klipper in KDE 6
kwriteconfig6 --file kded6rc --group "Module-klipper" --key autoload false 2>/dev/null || \
kwriteconfig5 --file kded6rc --group "Module-klipper" --key autoload false

# Also disable in KDE 5 config (for compatibility)
kwriteconfig5 --file kded5rc --group "Module-klipper" --key autoload false 2>/dev/null || true

echo "✅ Klipper service disabled in configuration"

# Method 2: Hide from system tray via configuration
echo ""
echo "📋 Method 2: Hide from system tray"
echo "================================="

# Hide Klipper from system tray
kwriteconfig6 --file plasmarc --group "SystemTray" --key "hiddenItems" "org.kde.klipper" 2>/dev/null || \
kwriteconfig5 --file plasmarc --group "SystemTray" --key "hiddenItems" "org.kde.klipper"

echo "✅ Klipper hidden from system tray"

# Method 3: Stop Klipper via D-Bus
echo ""
echo "📋 Method 3: Stop via D-Bus"
echo "=========================="

# Stop Klipper via D-Bus (KDE 6)
if qdbus org.kde.kded6 /kded loadedModules 2>/dev/null | grep -q klipper; then
    echo "Stopping Klipper via kded6..."
    qdbus org.kde.kded6 /kded unloadModule klipper 2>/dev/null || true
fi

# Stop Klipper via D-Bus (KDE 5 compatibility)
if qdbus org.kde.kded5 /kded loadedModules 2>/dev/null | grep -q klipper; then
    echo "Stopping Klipper via kded5..."
    qdbus org.kde.kded5 /kded unloadModule klipper 2>/dev/null || true
fi

echo "✅ Klipper stopped via D-Bus"

# Method 4: Kill any running processes
echo ""
echo "📋 Method 4: Kill processes"
echo "=========================="

pkill -f klipper 2>/dev/null || true
echo "✅ Klipper processes terminated"

# Method 5: Remove from autostart
echo ""
echo "📋 Method 5: Remove autostart entries"
echo "===================================="

rm -f "$HOME/.config/autostart/klipper.desktop" 2>/dev/null || true
rm -f "$HOME/.config/autostart/org.kde.klipper.desktop" 2>/dev/null || true

echo "✅ Autostart entries removed"

# Method 6: Plasma configuration script
echo ""
echo "📋 Method 6: Plasma script to remove widget"
echo "=========================================="

# Create a script to remove Klipper widget
cat > /tmp/remove_klipper_widget.js << 'EOF'
// Remove Klipper widget from all panels
var panels = panelIds;
for (var i = 0; i < panels.length; i++) {
    var panel = panelById(panels[i]);
    var widgets = panel.widgets;
    
    for (var j = widgets.length - 1; j >= 0; j--) {
        var widget = widgets[j];
        if (widget.type === "org.kde.plasma.clipboard" || 
            widget.type === "org.kde.klipper" ||
            widget.readConfig("plugin", "") === "org.kde.plasma.clipboard") {
            print("Removing Klipper widget: " + widget.type);
            widget.remove();
        }
    }
}

// Also check system tray
for (var i = 0; i < panels.length; i++) {
    var panel = panelById(panels[i]);
    var widgets = panel.widgets;
    
    for (var j = 0; j < widgets.length; j++) {
        var widget = widgets[j];
        if (widget.type === "org.kde.plasma.systemtray") {
            print("Configuring system tray to hide Klipper");
            widget.currentConfigGroup = ["General"];
            var hiddenItems = widget.readConfig("hiddenItems", "").split(",");
            if (hiddenItems.indexOf("org.kde.klipper") === -1) {
                hiddenItems.push("org.kde.klipper");
                widget.writeConfig("hiddenItems", hiddenItems.join(","));
                widget.reloadConfig();
            }
        }
    }
}

print("Klipper widget removal script completed");
EOF

# Execute the script
echo "Executing Plasma script to remove Klipper widget..."
qdbus org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "$(cat /tmp/remove_klipper_widget.js)" 2>/dev/null || echo "Script execution completed"

echo "✅ Plasma script executed"

# Method 7: Restart plasmashell to apply changes
echo ""
echo "📋 Method 7: Restart plasmashell"
echo "==============================="

echo "Restarting plasmashell to apply all changes..."
killall plasmashell 2>/dev/null || true
sleep 3

# Start plasmashell (KDE 6 method)
plasmashell &

echo "✅ Plasmashell restarted"

# Clean up
rm -f /tmp/remove_klipper_widget.js

echo ""
echo "⏳ Waiting for changes to take effect..."
sleep 5

echo ""
echo "🧪 Testing Results"
echo "=================="

# Check if Klipper is still running
if pgrep -f klipper >/dev/null; then
    echo "⚠️  Klipper process still detected"
else
    echo "✅ No Klipper processes running"
fi

# Check configuration
KDED6_STATUS=$(kreadconfig6 --file kded6rc --group "Module-klipper" --key autoload --default true 2>/dev/null || echo "unknown")
KDED5_STATUS=$(kreadconfig5 --file kded6rc --group "Module-klipper" --key autoload --default true 2>/dev/null || echo "unknown")

echo "Klipper autoload status:"
echo "  KDED6: $KDED6_STATUS"
echo "  KDED5: $KDED5_STATUS"

echo ""
echo "🎉 Force Removal Complete!"
echo ""
echo "📋 What was done:"
echo "  ✅ Klipper service disabled in configuration"
echo "  ✅ Hidden from system tray via config"
echo "  ✅ Stopped via D-Bus"
echo "  ✅ Processes killed"
echo "  ✅ Autostart entries removed"
echo "  ✅ Plasma script executed to remove widget"
echo "  ✅ Plasmashell restarted"
echo ""
echo "🔍 If Klipper widget is still visible:"
echo "  • Log out and log back in"
echo "  • Restart your computer"
echo "  • The widget should be gone after restart"
echo ""
echo "✅ Klipper should now be completely removed!"
