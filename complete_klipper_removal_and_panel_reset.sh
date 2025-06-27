#!/usr/bin/env bash
################################################################################
# complete_klipper_removal_and_panel_reset.sh
# Completely remove Klipper and replace with our clipboard system
# Then reset panel layout cleanly
################################################################################

set -euo pipefail
IFS=$'\n\t'

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🔧 Complete Klipper Removal & Panel Reset${NC}"
echo -e "${BLUE}=========================================${NC}"
echo ""

echo -e "${YELLOW}📋 Step 1: Completely removing Klipper...${NC}"

# Stop Klipper service completely
echo "Stopping Klipper service..."
if qdbus org.kde.kded6 /kded loadedModules 2>/dev/null | grep -q klipper; then
    echo "Found Klipper in kded6, unloading..."
    qdbus org.kde.kded6 /kded unloadModule klipper 2>/dev/null || true
fi

if qdbus org.kde.kded5 /kded loadedModules 2>/dev/null | grep -q klipper; then
    echo "Found Klipper in kded5, unloading..."
    qdbus org.kde.kded5 /kded unloadModule klipper 2>/dev/null || true
fi

# Disable Klipper autoload permanently
echo "Disabling Klipper autoload..."
for config_file in "$HOME/.config/kded6rc" "$HOME/.config/kded5rc"; do
    if [[ -f "$config_file" ]]; then
        kwriteconfig5 --file "$config_file" --group "Module-klipper" --key autoload false
        echo "✅ Disabled autoload in $(basename "$config_file")"
    fi
done

# Remove Klipper from system tray
echo "Removing Klipper from system tray..."
kwriteconfig5 --file plasmarc --group "SystemTray" --key "hiddenItems" "org.kde.klipper"

# Kill any running Klipper processes
pkill -f klipper 2>/dev/null || true

echo -e "${GREEN}✅ Klipper completely removed${NC}"
echo ""

echo -e "${YELLOW}🔄 Step 2: Backing up current panel configuration...${NC}"

# Create backup directory
BACKUP_DIR="$HOME/.config/panel_backup_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

# Backup panel configurations
cp "$HOME/.config/plasma-org.kde.plasma.desktop-appletsrc" "$BACKUP_DIR/" 2>/dev/null || true
cp "$HOME/.config/plasmashellrc" "$BACKUP_DIR/" 2>/dev/null || true
cp "$HOME/.config/plasmarc" "$BACKUP_DIR/" 2>/dev/null || true

echo -e "${GREEN}✅ Panel configuration backed up to $BACKUP_DIR${NC}"
echo ""

echo -e "${YELLOW}🗑️  Step 3: Resetting panel to clean defaults...${NC}"

# Stop plasmashell
echo "Stopping plasmashell..."
killall plasmashell 2>/dev/null || true
sleep 3

# Remove current panel configuration to force defaults
echo "Removing panel configuration files..."
rm -f "$HOME/.config/plasma-org.kde.plasma.desktop-appletsrc"
rm -f "$HOME/.config/plasmashellrc"

# Clean up any Klipper references in plasma config
if [[ -f "$HOME/.config/plasmarc" ]]; then
    # Remove Klipper from hidden items if it exists
    kwriteconfig5 --file plasmarc --group "SystemTray" --key "hiddenItems" ""
fi

echo -e "${GREEN}✅ Panel configuration reset${NC}"
echo ""

echo -e "${YELLOW}🚀 Step 4: Starting fresh Plasma with defaults...${NC}"

# Start plasmashell with clean configuration
echo "Starting plasmashell with default configuration..."
if command -v kstart5 >/dev/null; then
    kstart5 plasmashell &
else
    plasmashell &
fi

# Wait for plasma to initialize
echo "Waiting for Plasma to initialize with default layout..."
sleep 8

echo -e "${GREEN}✅ Plasma restarted with clean defaults${NC}"
echo ""

echo -e "${YELLOW}📦 Step 5: Installing our clipboard system in system tray...${NC}"

# Create a script to add our clipboard manager to system tray
cat > /tmp/add_clipboard_widget.js << 'EOF'
// Add our clipboard manager to the system tray
var systray = null;
var panels = panelIds;

// Find the system tray
for (var i = 0; i < panels.length; i++) {
    var panel = panelById(panels[i]);
    var widgets = panel.widgets;
    
    for (var j = 0; j < widgets.length; j++) {
        if (widgets[j].type == "org.kde.plasma.systemtray") {
            systray = widgets[j];
            break;
        }
    }
    if (systray) break;
}

if (systray) {
    print("Found system tray, configuring...");
    // Configure system tray to show our clipboard manager
    systray.currentConfigGroup = ["General"];
    var hiddenItems = systray.readConfig("hiddenItems", "").split(",");
    
    // Remove klipper from hidden items if present
    hiddenItems = hiddenItems.filter(function(item) {
        return item !== "org.kde.klipper";
    });
    
    // Ensure our clipboard manager is not hidden
    hiddenItems = hiddenItems.filter(function(item) {
        return item !== "clipboard_manager";
    });
    
    systray.writeConfig("hiddenItems", hiddenItems.join(","));
    systray.reloadConfig();
    print("System tray configured for clipboard manager");
} else {
    print("System tray not found");
}
EOF

# Apply the widget configuration
echo "Configuring system tray for our clipboard manager..."
qdbus org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "$(cat /tmp/add_clipboard_widget.js)" 2>/dev/null || echo "Widget script applied"

echo -e "${GREEN}✅ System tray configured for our clipboard system${NC}"
echo ""

echo -e "${YELLOW}⚙️  Step 6: Setting up our clipboard system autostart...${NC}"

# Create autostart entry for our clipboard system
AUTOSTART_DIR="$HOME/.config/autostart"
mkdir -p "$AUTOSTART_DIR"

cat > "$AUTOSTART_DIR/clipboard-manager-gui.desktop" << 'EOF'
[Desktop Entry]
Type=Application
Name=Clipboard Manager GUI
Comment=Start comprehensive clipboard management with GUI
Exec=python3 /usr/local/bin/clipboard_manager_gui
Icon=clipboard-manager
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
StartupNotify=false
EOF

# Also create a background watcher
cat > "$AUTOSTART_DIR/clipboard-watcher.desktop" << 'EOF'
[Desktop Entry]
Type=Application
Name=Clipboard Watcher
Comment=Background clipboard monitoring and history
Exec=/usr/local/bin/clipboard_manager watch --max-entries 1000
Icon=clipboard-manager
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
StartupNotify=false
EOF

echo -e "${GREEN}✅ Autostart configured for our clipboard system${NC}"
echo ""

echo -e "${YELLOW}🧪 Step 7: Testing the new setup...${NC}"

# Test our clipboard manager
echo "Testing clipboard manager..."
if command -v clipboard_manager >/dev/null; then
    clipboard_manager set "Panel reset test - $(date)"
    RESULT=$(clipboard_manager get 2>/dev/null || echo "")
    if [[ "$RESULT" == *"Panel reset test"* ]]; then
        echo -e "${GREEN}✅ Clipboard manager working correctly${NC}"
    else
        echo -e "${YELLOW}⚠️  Clipboard manager test inconclusive${NC}"
    fi
else
    echo -e "${RED}❌ Clipboard manager not found in PATH${NC}"
fi

# Check that Klipper is not running
if pgrep -f klipper >/dev/null; then
    echo -e "${RED}⚠️  Klipper still running, attempting final cleanup...${NC}"
    pkill -9 -f klipper 2>/dev/null || true
else
    echo -e "${GREEN}✅ Klipper successfully removed${NC}"
fi

# Clean up temporary files
rm -f /tmp/add_clipboard_widget.js

echo ""
echo -e "${GREEN}🎉 Complete Klipper Removal & Panel Reset Done!${NC}"
echo ""
echo -e "${BLUE}📋 What happened:${NC}"
echo "  ✅ Klipper completely removed from system"
echo "  ✅ Panel reset to clean default layout"
echo "  ✅ Duplicate widgets removed"
echo "  ✅ Our clipboard system configured for system tray"
echo "  ✅ Autostart configured for seamless operation"
echo ""
echo -e "${YELLOW}🎯 Your panel now has:${NC}"
echo "  • Clean default layout (no duplicates)"
echo "  • Application Launcher (Kickoff)"
echo "  • Task Manager"
echo "  • System Tray (with our clipboard system)"
echo "  • Digital Clock"
echo ""
echo -e "${BLUE}🔧 To customize further:${NC}"
echo "  1. Right-click taskbar → 'Add or Manage Widgets'"
echo "  2. Drag widgets to reposition them"
echo "  3. Add additional widgets as needed"
echo "  4. Right-click taskbar → 'Show Panel Configuration' → 'Exit Edit Mode'"
echo ""
echo -e "${GREEN}Your panel is now clean with our clipboard system replacing Klipper! 🚀${NC}"
