#!/usr/bin/env bash
################################################################################
# install_clipboard_system.sh
# Complete installation and setup for comprehensive clipboard management
# Makes clipboard data as accessible and useful as Graphify
################################################################################

set -euo pipefail
IFS=$'\n\t'

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}🚀 Installing Comprehensive Clipboard Management System${NC}"
echo -e "${BLUE}=====================================================${NC}"
echo ""

# Step 1: Build the tools
echo -e "${YELLOW}📦 Step 1: Building clipboard tools...${NC}"

# Build basic clipboard tool
if [[ -d "clipboard_tool" ]]; then
    echo "Building basic clipboard tool..."
    cd clipboard_tool
    cargo build --release
    cd ..
else
    echo -e "${RED}❌ clipboard_tool directory not found${NC}"
    exit 1
fi

# Build advanced clipboard manager
if [[ -d "clipboard_manager" ]]; then
    echo "Building advanced clipboard manager..."
    cd clipboard_manager
    cargo build --release
    cd ..
else
    echo -e "${RED}❌ clipboard_manager directory not found${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Tools built successfully!${NC}"
echo ""

# Step 2: Install to system
echo -e "${YELLOW}📦 Step 2: Installing to system...${NC}"

# Install basic tool
if [[ -f "clipboard_tool/target/release/clipboard_tool" ]]; then
    sudo cp clipboard_tool/target/release/clipboard_tool /usr/local/bin/
    sudo chmod +x /usr/local/bin/clipboard_tool
    echo "✅ clipboard_tool installed to /usr/local/bin/"
fi

# Install advanced manager
if [[ -f "clipboard_manager/target/release/clipboard_manager" ]]; then
    sudo cp clipboard_manager/target/release/clipboard_manager /usr/local/bin/
    sudo chmod +x /usr/local/bin/clipboard_manager
    echo "✅ clipboard_manager installed to /usr/local/bin/"
fi

echo ""

# Step 3: Create useful aliases
echo -e "${YELLOW}📦 Step 3: Setting up aliases...${NC}"

ALIAS_FILE="$HOME/.clipboard_aliases"
cat > "$ALIAS_FILE" << 'EOF'
# Clipboard Management Aliases - Like Graphify for all clipboard data
alias cb='clipboard_manager'
alias cbget='clipboard_manager get'
alias cbset='clipboard_manager set'
alias cbhistory='clipboard_manager history'
alias cbsearch='clipboard_manager search'
alias cbstats='clipboard_manager stats'
alias cbwatch='clipboard_manager watch'
alias cbexport='clipboard_manager export'
alias cbimport='clipboard_manager import'
alias cbclear='clipboard_manager clear'

# Advanced clipboard functions
cbfind() {
    clipboard_manager search "$1" | head -10
}

cbbackup() {
    local date=$(date +%Y-%m-%d_%H-%M-%S)
    local backup_dir="$HOME/.clipboard_backups"
    mkdir -p "$backup_dir"
    clipboard_manager export --output "$backup_dir/clipboard_$date.json"
    echo "Clipboard backed up to $backup_dir/clipboard_$date.json"
}

cbrestore() {
    if [[ -z "$1" ]]; then
        echo "Usage: cbrestore <backup_file>"
        return 1
    fi
    clipboard_manager import --input "$1"
    echo "Clipboard history restored from $1"
}

cburl() {
    clipboard_manager search "http" | head -5
}

cbcode() {
    clipboard_manager search "function\|class\|def\|import\|#include" | head -5
}
EOF

# Add to shell config
for shell_config in "$HOME/.bashrc" "$HOME/.zshrc"; do
    if [[ -f "$shell_config" ]]; then
        if ! grep -q "clipboard_aliases" "$shell_config"; then
            echo "" >> "$shell_config"
            echo "# Clipboard management aliases" >> "$shell_config"
            echo "source $ALIAS_FILE" >> "$shell_config"
            echo "✅ Added aliases to $shell_config"
        fi
    fi
done

echo ""

# Step 4: Create systemd service for watching (optional)
echo -e "${YELLOW}📦 Step 4: Creating systemd service for clipboard watching...${NC}"

SERVICE_FILE="$HOME/.config/systemd/user/clipboard-watcher.service"
mkdir -p "$(dirname "$SERVICE_FILE")"

cat > "$SERVICE_FILE" << EOF
[Unit]
Description=Clipboard Watcher Service
After=graphical-session.target

[Service]
Type=simple
ExecStart=/usr/local/bin/clipboard_manager watch --max-entries 1000
Restart=always
RestartSec=5
Environment=DISPLAY=:0

[Install]
WantedBy=default.target
EOF

echo "✅ Systemd service created at $SERVICE_FILE"
echo "   To enable: systemctl --user enable clipboard-watcher.service"
echo "   To start:  systemctl --user start clipboard-watcher.service"
echo ""

# Step 5: Create backup directory and cron job
echo -e "${YELLOW}📦 Step 5: Setting up automated backups...${NC}"

BACKUP_DIR="$HOME/.clipboard_backups"
mkdir -p "$BACKUP_DIR"

# Create backup script
BACKUP_SCRIPT="$HOME/.local/bin/clipboard_backup.sh"
mkdir -p "$(dirname "$BACKUP_SCRIPT")"

cat > "$BACKUP_SCRIPT" << 'EOF'
#!/bin/bash
# Automated clipboard backup script
DATE=$(date +%Y-%m-%d)
BACKUP_DIR="$HOME/.clipboard_backups"
clipboard_manager export --output "$BACKUP_DIR/clipboard_$DATE.json" --format json
# Keep only last 30 days of backups
find "$BACKUP_DIR" -name "clipboard_*.json" -mtime +30 -delete
EOF

chmod +x "$BACKUP_SCRIPT"

echo "✅ Backup script created at $BACKUP_SCRIPT"
echo "   To add daily backup cron job:"
echo "   crontab -e"
echo "   Add: 0 23 * * * $BACKUP_SCRIPT"
echo ""

# Step 6: Test installation
echo -e "${YELLOW}📦 Step 6: Testing installation...${NC}"

echo "Testing basic clipboard tool..."
if command -v clipboard_tool >/dev/null; then
    clipboard_tool set "Installation test - basic tool"
    RESULT=$(clipboard_tool get)
    if [[ "$RESULT" == "Installation test - basic tool" ]]; then
        echo "✅ Basic clipboard tool working"
    else
        echo "❌ Basic clipboard tool test failed"
    fi
else
    echo "❌ clipboard_tool not found in PATH"
fi

echo "Testing advanced clipboard manager..."
if command -v clipboard_manager >/dev/null; then
    clipboard_manager set "Installation test - advanced manager"
    RESULT=$(clipboard_manager get)
    if [[ "$RESULT" == "Installation test - advanced manager" ]]; then
        echo "✅ Advanced clipboard manager working"
    else
        echo "❌ Advanced clipboard manager test failed"
    fi
else
    echo "❌ clipboard_manager not found in PATH"
fi

echo ""

# Step 7: Show usage summary
echo -e "${GREEN}🎉 Installation Complete!${NC}"
echo ""
echo -e "${BLUE}📋 Your clipboard system is now as powerful as Graphify!${NC}"
echo ""
echo -e "${YELLOW}Quick Start:${NC}"
echo "  cb set 'Hello World'           # Set clipboard content"
echo "  cb get                         # Get current content"
echo "  cb history                     # View clipboard history"
echo "  cb search 'keyword'            # Search through history"
echo "  cb stats                       # Show usage statistics"
echo "  cb watch                       # Start monitoring clipboard"
echo ""
echo -e "${YELLOW}Advanced Features:${NC}"
echo "  cb get --format json           # Get content with metadata"
echo "  cb export --output backup.json # Export history"
echo "  cb import --input backup.json  # Import history"
echo "  cbbackup                       # Quick backup function"
echo "  cbfind 'text'                  # Quick search function"
echo "  cburl                          # Find recent URLs"
echo "  cbcode                         # Find recent code snippets"
echo ""
echo -e "${YELLOW}Files Created:${NC}"
echo "  • /usr/local/bin/clipboard_tool"
echo "  • /usr/local/bin/clipboard_manager"
echo "  • $ALIAS_FILE"
echo "  • $SERVICE_FILE"
echo "  • $BACKUP_SCRIPT"
echo "  • $BACKUP_DIR/"
echo ""
echo -e "${BLUE}💡 Next Steps:${NC}"
echo "  1. Restart your terminal or run: source ~/.bashrc"
echo "  2. Try: cb set 'Test message' && cb get"
echo "  3. Start clipboard monitoring: cb watch"
echo "  4. Enable auto-start: systemctl --user enable clipboard-watcher.service"
echo "  5. Set up daily backups with cron"
echo ""
echo -e "${GREEN}Enjoy your comprehensive clipboard management system! 🚀${NC}"
