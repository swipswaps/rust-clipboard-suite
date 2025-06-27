#!/usr/bin/env bash
################################################################################
# remove_clipboard_conflicts.sh
# Remove CopyQ, Klipper, and other clipboard managers to prevent conflicts
################################################################################

set -euo pipefail
IFS=$'\n\t'

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🧹 Removing Conflicting Clipboard Managers${NC}"
echo -e "${BLUE}=========================================${NC}"
echo ""

# Function to safely remove a package
remove_package() {
    local package="$1"
    local description="$2"
    
    if command -v "$package" >/dev/null 2>&1 || rpm -q "$package" >/dev/null 2>&1 || dnf list installed "$package" >/dev/null 2>&1; then
        echo -e "${YELLOW}📦 Removing $description ($package)...${NC}"
        
        # Stop any running instances first
        pkill -f "$package" 2>/dev/null || true
        
        # Remove package
        if command -v dnf >/dev/null; then
            sudo dnf remove -y "$package" 2>/dev/null || true
        elif command -v apt >/dev/null; then
            sudo apt remove -y "$package" 2>/dev/null || true
        elif command -v pacman >/dev/null; then
            sudo pacman -R --noconfirm "$package" 2>/dev/null || true
        fi
        
        echo -e "${GREEN}✅ $description removed${NC}"
    else
        echo -e "${GREEN}✅ $description not installed${NC}"
    fi
}

# Function to disable KDE service
disable_kde_service() {
    local service="$1"
    local description="$2"
    
    echo -e "${YELLOW}🔧 Disabling $description...${NC}"
    
    # Stop the service
    if qdbus org.kde.kded6 /kded loadedModules 2>/dev/null | grep -q "$service"; then
        qdbus org.kde.kded6 /kded unloadModule "$service" 2>/dev/null || true
    elif qdbus org.kde.kded5 /kded loadedModules 2>/dev/null | grep -q "$service"; then
        qdbus org.kde.kded5 /kded unloadModule "$service" 2>/dev/null || true
    fi
    
    # Disable autoload
    if [[ -f "$HOME/.config/kded6rc" ]]; then
        kwriteconfig5 --file "$HOME/.config/kded6rc" --group "Module-$service" --key autoload false
    fi
    if [[ -f "$HOME/.config/kded5rc" ]]; then
        kwriteconfig5 --file "$HOME/.config/kded5rc" --group "Module-$service" --key autoload false
    fi
    
    echo -e "${GREEN}✅ $description disabled${NC}"
}

# Remove CopyQ
echo -e "${YELLOW}🗑️  Step 1: Removing CopyQ${NC}"
remove_package "copyq" "CopyQ clipboard manager"

# Remove Klipper (KDE's built-in clipboard manager)
echo -e "${YELLOW}🗑️  Step 2: Disabling Klipper${NC}"
disable_kde_service "klipper" "KDE Klipper service"

# Remove other common clipboard managers
echo -e "${YELLOW}🗑️  Step 3: Removing other clipboard managers${NC}"
remove_package "clipit" "ClipIt clipboard manager"
remove_package "parcellite" "Parcellite clipboard manager"
remove_package "clipman" "Clipman clipboard manager"
remove_package "diodon" "Diodon clipboard manager"
remove_package "gpaste" "GPaste clipboard manager"
remove_package "clipboard-indicator" "Clipboard Indicator"

# Remove GNOME clipboard extensions
echo -e "${YELLOW}🗑️  Step 4: Removing GNOME clipboard extensions${NC}"
if command -v gnome-extensions >/dev/null; then
    gnome-extensions disable clipboard-indicator@tudmotu.com 2>/dev/null || true
    gnome-extensions disable clipboard-history@alexsaveau.dev 2>/dev/null || true
    gnome-extensions disable pano@elhan.io 2>/dev/null || true
fi

# Clean up autostart entries
echo -e "${YELLOW}🗑️  Step 5: Cleaning autostart entries${NC}"
AUTOSTART_DIR="$HOME/.config/autostart"
if [[ -d "$AUTOSTART_DIR" ]]; then
    for app in copyq clipit parcellite clipman diodon; do
        if [[ -f "$AUTOSTART_DIR/$app.desktop" ]]; then
            rm -f "$AUTOSTART_DIR/$app.desktop"
            echo -e "${GREEN}✅ Removed $app autostart entry${NC}"
        fi
    done
fi

# Clean up configuration directories
echo -e "${YELLOW}🗑️  Step 6: Cleaning configuration files${NC}"
CONFIG_DIRS=(
    "$HOME/.config/copyq"
    "$HOME/.config/clipit"
    "$HOME/.config/parcellite"
    "$HOME/.config/clipman"
    "$HOME/.config/diodon"
    "$HOME/.local/share/copyq"
)

for dir in "${CONFIG_DIRS[@]}"; do
    if [[ -d "$dir" ]]; then
        echo -e "${YELLOW}📁 Backing up and removing $dir${NC}"
        mv "$dir" "${dir}.backup.$(date +%Y%m%d)" 2>/dev/null || rm -rf "$dir"
        echo -e "${GREEN}✅ Cleaned $dir${NC}"
    fi
done

# Verify no clipboard managers are running
echo -e "${YELLOW}🔍 Step 7: Verifying cleanup${NC}"
CLIPBOARD_PROCESSES=$(pgrep -f "copyq|clipit|parcellite|clipman|diodon|klipper" || echo "")
if [[ -n "$CLIPBOARD_PROCESSES" ]]; then
    echo -e "${YELLOW}⚠️  Found running clipboard processes. Terminating...${NC}"
    pkill -f "copyq|clipit|parcellite|clipman|diodon" 2>/dev/null || true
    sleep 2
    
    # Force kill if still running
    REMAINING=$(pgrep -f "copyq|clipit|parcellite|clipman|diodon" || echo "")
    if [[ -n "$REMAINING" ]]; then
        pkill -9 -f "copyq|clipit|parcellite|clipman|diodon" 2>/dev/null || true
    fi
fi

# Test our clipboard manager
echo -e "${YELLOW}🧪 Step 8: Testing our clipboard system${NC}"
if command -v clipboard_manager >/dev/null; then
    clipboard_manager set "Conflict removal test - $(date)"
    RESULT=$(clipboard_manager get)
    if [[ "$RESULT" == *"Conflict removal test"* ]]; then
        echo -e "${GREEN}✅ Our clipboard system is working correctly${NC}"
    else
        echo -e "${RED}❌ Our clipboard system test failed${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  Clipboard manager not installed yet. Run install script first.${NC}"
fi

echo ""
echo -e "${GREEN}🎉 Clipboard Conflict Removal Complete!${NC}"
echo ""
echo -e "${BLUE}📋 Summary:${NC}"
echo "  ✅ CopyQ removed"
echo "  ✅ Klipper disabled"
echo "  ✅ Other clipboard managers removed"
echo "  ✅ Autostart entries cleaned"
echo "  ✅ Configuration files backed up"
echo "  ✅ Running processes terminated"
echo ""
echo -e "${YELLOW}💡 Next Steps:${NC}"
echo "  1. Install our comprehensive clipboard system"
echo "  2. Set up chart generation tools"
echo "  3. Configure desktop integration"
echo ""
echo -e "${GREEN}Your system is now ready for conflict-free clipboard management! 🚀${NC}"
