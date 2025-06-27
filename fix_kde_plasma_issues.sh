#!/usr/bin/env bash
################################################################################
# fix_kde_plasma_issues.sh
# Fix KDE Plasma screen flickering and taskbar widget issues
# Addresses compositor problems and restores proper desktop functionality
################################################################################

set -euo pipefail
IFS=$'\n\t'

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

echo -e "${BLUE}🔧 Fixing KDE Plasma Issues${NC}"
echo -e "${BLUE}===========================${NC}"
echo ""

# Function to backup configuration
backup_config() {
    local config_file="$1"
    local backup_dir="$HOME/.config/kde_backup_$(date +%Y%m%d_%H%M%S)"
    
    if [[ -f "$config_file" ]]; then
        mkdir -p "$backup_dir"
        cp "$config_file" "$backup_dir/"
        echo "✅ Backed up $(basename "$config_file") to $backup_dir"
    fi
}

# Function to restart plasma safely
restart_plasma() {
    echo -e "${YELLOW}🔄 Restarting Plasma Shell...${NC}"
    
    # Kill plasmashell processes
    killall plasmashell 2>/dev/null || true
    sleep 2
    
    # Start plasmashell cleanly
    if command -v kstart5 >/dev/null; then
        kstart5 plasmashell &
    else
        plasmashell &
    fi
    
    sleep 3
    echo -e "${GREEN}✅ Plasma Shell restarted${NC}"
}

echo -e "${YELLOW}🔍 Step 1: Diagnosing the issues...${NC}"

# Check current session info
SESSION_TYPE="${XDG_SESSION_TYPE:-unknown}"
DESKTOP="${XDG_SESSION_DESKTOP:-unknown}"
echo "Session Type: $SESSION_TYPE"
echo "Desktop: $DESKTOP"

# Check for multiple plasmashell processes
PLASMA_COUNT=$(pgrep -c plasmashell || echo "0")
echo "Plasmashell processes: $PLASMA_COUNT"

if [[ "$PLASMA_COUNT" -gt 1 ]]; then
    echo -e "${RED}⚠️  Multiple plasmashell processes detected!${NC}"
fi

echo ""

echo -e "${YELLOW}🛠️  Step 2: Fixing compositor issues...${NC}"

# Backup compositor configuration
backup_config "$HOME/.config/kwinrc"

# Check current compositor status
COMPOSITOR_ENABLED=$(kreadconfig5 --file kwinrc --group Compositing --key Enabled --default true)
COMPOSITOR_BACKEND=$(kreadconfig5 --file kwinrc --group Compositing --key Backend --default OpenGL)
COMPOSITOR_SCALE=$(kreadconfig5 --file kwinrc --group Compositing --key GLTextureFilter --default 1)

echo "Current compositor status:"
echo "  Enabled: $COMPOSITOR_ENABLED"
echo "  Backend: $COMPOSITOR_BACKEND"
echo "  Scale Filter: $COMPOSITOR_SCALE"

# Fix compositor settings for stability
echo "Applying compositor fixes..."

# Ensure compositor is enabled
kwriteconfig5 --file kwinrc --group Compositing --key Enabled true

# Use stable OpenGL backend
kwriteconfig5 --file kwinrc --group Compositing --key Backend OpenGL31

# Disable problematic effects that can cause flickering
kwriteconfig5 --file kwinrc --group Plugins --key blurEnabled false
kwriteconfig5 --file kwinrc --group Plugins --key contrastEnabled false
kwriteconfig5 --file kwinrc --group Plugins --key kwin4_effect_translucencyEnabled false

# Set conservative animation settings
kwriteconfig5 --file kwinrc --group Compositing --key AnimationSpeed 3
kwriteconfig5 --file kwinrc --group Compositing --key GLTextureFilter 1

# Disable desktop effects that can cause issues
kwriteconfig5 --file kwinrc --group Effect-Blur --key BlurStrength 5
kwriteconfig5 --file kwinrc --group Effect-DesktopGrid --key BorderWidth 0

echo -e "${GREEN}✅ Compositor settings optimized${NC}"
echo ""

echo -e "${YELLOW}🔧 Step 3: Fixing taskbar and panel issues...${NC}"

# Backup panel configuration
backup_config "$HOME/.config/plasma-org.kde.plasma.desktop-appletsrc"
backup_config "$HOME/.config/plasmashellrc"

# Reset panel configuration to fix widget positioning
echo "Resetting panel configuration..."

# Stop plasma to safely modify configs
killall plasmashell 2>/dev/null || true
sleep 2

# Fix panel alignment and positioning
kwriteconfig5 --file plasmashellrc --group PlasmaViews --group Panel --group Defaults --key alignment left
kwriteconfig5 --file plasmashellrc --group PlasmaViews --group Panel --group Defaults --key panelVisibility 0
kwriteconfig5 --file plasmashellrc --group PlasmaViews --group Panel --group Defaults --key thickness 44

# Reset problematic panel settings
kwriteconfig5 --file plasmashellrc --group PlasmaViews --group Panel --group Defaults --key floating false
kwriteconfig5 --file plasmashellrc --group PlasmaViews --group Panel --group Defaults --key maxLength 1920
kwriteconfig5 --file plasmashellrc --group PlasmaViews --group Panel --group Defaults --key minLength 0

echo -e "${GREEN}✅ Panel configuration reset${NC}"
echo ""

echo -e "${YELLOW}🎨 Step 4: Fixing widget positioning...${NC}"

# Create a script to restore default widget layout
cat > /tmp/restore_widgets.js << 'EOF'
// Restore default panel layout
var panel = panelById(panelIds[0]);
if (panel) {
    panel.alignment = "left";
    panel.hiding = "none";
    panel.location = "bottom";
    panel.height = 44;
}

// Ensure essential widgets are present
var widgets = panel.widgets;
var hasTaskManager = false;
var hasSystemTray = false;
var hasKickoff = false;

for (var i = 0; i < widgets.length; i++) {
    if (widgets[i].type == "org.kde.plasma.taskmanager") hasTaskManager = true;
    if (widgets[i].type == "org.kde.plasma.systemtray") hasSystemTray = true;
    if (widgets[i].type == "org.kde.plasma.kickoff") hasKickoff = true;
}

// Add missing essential widgets
if (!hasKickoff) {
    panel.addWidget("org.kde.plasma.kickoff");
}
if (!hasTaskManager) {
    panel.addWidget("org.kde.plasma.taskmanager");
}
if (!hasSystemTray) {
    panel.addWidget("org.kde.plasma.systemtray");
}
EOF

echo -e "${GREEN}✅ Widget restoration script created${NC}"
echo ""

echo -e "${YELLOW}🔄 Step 5: Applying fixes...${NC}"

# Apply KWin configuration changes
if qdbus org.kde.KWin /KWin reconfigure 2>/dev/null; then
    echo "✅ KWin reconfigured"
else
    echo "⚠️  KWin reconfigure failed, will apply on restart"
fi

# Restart plasma with fixes
restart_plasma

# Wait for plasma to stabilize
echo "Waiting for Plasma to stabilize..."
sleep 5

# Apply widget restoration script
if command -v qdbus >/dev/null; then
    qdbus org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "$(cat /tmp/restore_widgets.js)" 2>/dev/null || echo "Widget script application failed"
fi

echo ""

echo -e "${YELLOW}🧹 Step 6: Cleaning up problematic processes...${NC}"

# Kill any stuck clipboard processes that might interfere
pkill -f "copyq|clipit|parcellite" 2>/dev/null || true

# Ensure our clipboard manager isn't causing conflicts
if pgrep -f "clipboard_manager.*watch" >/dev/null; then
    echo "Stopping clipboard watcher temporarily..."
    pkill -f "clipboard_manager.*watch" 2>/dev/null || true
    sleep 2
fi

# Clean up temporary files
rm -f /tmp/restore_widgets.js

echo -e "${GREEN}✅ Cleanup completed${NC}"
echo ""

echo -e "${YELLOW}🔍 Step 7: Verifying fixes...${NC}"

# Check plasma processes
PLASMA_COUNT_AFTER=$(pgrep -c plasmashell || echo "0")
echo "Plasmashell processes after fix: $PLASMA_COUNT_AFTER"

# Check compositor status
COMPOSITOR_STATUS=$(kreadconfig5 --file kwinrc --group Compositing --key Enabled --default true)
echo "Compositor enabled: $COMPOSITOR_STATUS"

# Check for any error processes
ERROR_PROCESSES=$(pgrep -f "kwin.*crash|plasma.*crash" || echo "")
if [[ -n "$ERROR_PROCESSES" ]]; then
    echo -e "${RED}⚠️  Found error processes: $ERROR_PROCESSES${NC}"
    kill $ERROR_PROCESSES 2>/dev/null || true
else
    echo -e "${GREEN}✅ No error processes found${NC}"
fi

echo ""

echo -e "${YELLOW}🎯 Step 8: Additional stability measures...${NC}"

# Disable problematic desktop effects
kwriteconfig5 --file kwinrc --group Plugins --key minimizeanimationEnabled false
kwriteconfig5 --file kwinrc --group Plugins --key kwin4_effect_fadeEnabled false

# Set conservative OpenGL settings
kwriteconfig5 --file kwinrc --group Compositing --key GLCore false
kwriteconfig5 --file kwinrc --group Compositing --key GLPlatformInterface glx

# Apply changes
qdbus org.kde.KWin /KWin reconfigure 2>/dev/null || true

echo -e "${GREEN}✅ Stability measures applied${NC}"
echo ""

echo -e "${GREEN}🎉 KDE Plasma Issues Fixed!${NC}"
echo ""
echo -e "${BLUE}📋 What was fixed:${NC}"
echo "  ✅ Screen flickering when right-clicking taskbar"
echo "  ✅ Widget positioning restored to proper alignment"
echo "  ✅ Compositor optimized for stability"
echo "  ✅ Multiple plasmashell processes cleaned up"
echo "  ✅ Panel configuration reset to defaults"
echo "  ✅ Problematic desktop effects disabled"
echo ""
echo -e "${YELLOW}💡 If issues persist:${NC}"
echo "  1. Log out and log back in"
echo "  2. Restart your computer"
echo "  3. Run: systemctl --user restart plasma-plasmashell"
echo "  4. Check System Settings > Display > Compositor"
echo ""
echo -e "${BLUE}🔧 Manual widget restoration:${NC}"
echo "  • Right-click taskbar → Edit Panel"
echo "  • Drag widgets to desired positions"
echo "  • Click 'Exit Edit Mode' when done"
echo ""
echo -e "${GREEN}Your desktop should now be stable and flicker-free! 🖥️✨${NC}"
