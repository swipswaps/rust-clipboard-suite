#!/usr/bin/env bash
################################################################################
# clipboard_usage_guide.sh
# Comprehensive guide to using the clipboard manager like Graphify
# Demonstrates all features for utilizing clipboard data comprehensively
################################################################################

set -euo pipefail
IFS=$'\n\t'

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

CLIPBOARD_TOOL="./target/release/clipboard_manager"

echo -e "${CYAN}📋 Comprehensive Clipboard Management - Like Graphify${NC}"
echo -e "${CYAN}=====================================================${NC}"
echo ""

# Check if tool exists
if [[ ! -f "$CLIPBOARD_TOOL" ]]; then
    echo -e "${RED}❌ Clipboard manager not found. Please build it first:${NC}"
    echo "   cd rust/clipboard_manager && cargo build --release"
    exit 1
fi

echo -e "${GREEN}✅ Clipboard manager found!${NC}"
echo ""

# Function to demonstrate a feature
demo_feature() {
    local title="$1"
    local description="$2"
    shift 2
    
    echo -e "${YELLOW}🔧 $title${NC}"
    echo -e "${BLUE}   $description${NC}"
    echo ""
    
    # Execute the command
    "$@"
    echo ""
    echo -e "${PURPLE}Press Enter to continue...${NC}"
    read -r
    echo ""
}

# 1. Basic Operations
demo_feature "Setting Clipboard Content" \
    "Store text in clipboard with persistence" \
    $CLIPBOARD_TOOL set "Hello from comprehensive clipboard manager! 🚀"

demo_feature "Getting Clipboard Content (Text Format)" \
    "Retrieve current clipboard content as plain text" \
    $CLIPBOARD_TOOL get

demo_feature "Getting Clipboard Content (JSON Format)" \
    "Retrieve clipboard with metadata in JSON format" \
    $CLIPBOARD_TOOL get --format json

demo_feature "Getting Clipboard Content (Base64 Format)" \
    "Retrieve clipboard content encoded in Base64" \
    $CLIPBOARD_TOOL get --format base64

# 2. Add some test data for history
echo -e "${YELLOW}📝 Adding test data to clipboard history...${NC}"
$CLIPBOARD_TOOL set "First test entry - configuration data"
sleep 1
$CLIPBOARD_TOOL set "Second entry - some code snippet: function test() { return 'hello'; }"
sleep 1
$CLIPBOARD_TOOL set "Third entry - a URL: https://example.com/api/v1/data"
sleep 1
$CLIPBOARD_TOOL set "Fourth entry - JSON data: {\"name\": \"test\", \"value\": 123}"
sleep 1
$CLIPBOARD_TOOL set "Final entry - multiline text:\nLine 1\nLine 2\nLine 3"

demo_feature "Viewing Clipboard History" \
    "Show recent clipboard entries with timestamps" \
    $CLIPBOARD_TOOL history

demo_feature "Viewing History (Limited)" \
    "Show only the 3 most recent entries" \
    $CLIPBOARD_TOOL history --limit 3

demo_feature "Viewing History (JSON Format)" \
    "Export history in structured JSON format" \
    $CLIPBOARD_TOOL history --format json --limit 2

# 3. Search functionality
demo_feature "Searching Clipboard History" \
    "Find entries containing 'test'" \
    $CLIPBOARD_TOOL search "test"

demo_feature "Case-Sensitive Search" \
    "Find entries with exact case matching" \
    $CLIPBOARD_TOOL search "JSON" --case-sensitive

# 4. Statistics
demo_feature "Clipboard Statistics" \
    "Show comprehensive usage statistics" \
    $CLIPBOARD_TOOL stats

# 5. Export/Import
demo_feature "Exporting History (JSON)" \
    "Export all clipboard history to a JSON file" \
    $CLIPBOARD_TOOL export --output /tmp/clipboard_backup.json --format json

echo -e "${GREEN}📁 Exported file contents:${NC}"
head -20 /tmp/clipboard_backup.json
echo ""

demo_feature "Exporting History (CSV)" \
    "Export clipboard history to CSV format" \
    $CLIPBOARD_TOOL export --output /tmp/clipboard_backup.csv --format csv

echo -e "${GREEN}📊 CSV file preview:${NC}"
head -5 /tmp/clipboard_backup.csv
echo ""

# 6. Advanced usage examples
echo -e "${CYAN}🚀 Advanced Usage Examples${NC}"
echo -e "${CYAN}=========================${NC}"
echo ""

echo -e "${YELLOW}💡 Example 1: Automated Backup${NC}"
echo -e "${BLUE}   Create daily clipboard backups${NC}"
echo ""
cat << 'EOF'
#!/bin/bash
# Daily clipboard backup script
DATE=$(date +%Y-%m-%d)
clipboard_manager export --output ~/clipboard_backups/clipboard_$DATE.json
echo "Clipboard backed up to ~/clipboard_backups/clipboard_$DATE.json"
EOF
echo ""

echo -e "${YELLOW}💡 Example 2: Search and Restore${NC}"
echo -e "${BLUE}   Find and restore specific clipboard content${NC}"
echo ""
cat << 'EOF'
#!/bin/bash
# Search for a URL and restore it to clipboard
SEARCH_TERM="https://"
RESULT=$(clipboard_manager search "$SEARCH_TERM" | head -1)
if [[ -n "$RESULT" ]]; then
    # Extract the URL and set it back to clipboard
    URL=$(echo "$RESULT" | grep -oP 'https://[^\s]+')
    clipboard_manager set "$URL"
    echo "Restored URL: $URL"
fi
EOF
echo ""

echo -e "${YELLOW}💡 Example 3: Content Analysis${NC}"
echo -e "${BLUE}   Analyze clipboard content types and patterns${NC}"
echo ""
cat << 'EOF'
#!/bin/bash
# Analyze clipboard patterns
echo "=== Clipboard Content Analysis ==="
clipboard_manager stats
echo ""
echo "=== Recent URLs ==="
clipboard_manager search "http" | head -5
echo ""
echo "=== Recent Code Snippets ==="
clipboard_manager search "function\|class\|def\|import" | head -5
EOF
echo ""

echo -e "${YELLOW}💡 Example 4: Watch Mode (Background Monitoring)${NC}"
echo -e "${BLUE}   Monitor clipboard changes in real-time${NC}"
echo ""
echo "To start watching clipboard changes:"
echo "   clipboard_manager watch --max-entries 1000"
echo ""
echo "This will:"
echo "  • Monitor clipboard for any changes"
echo "  • Automatically save text and image content"
echo "  • Maintain history with timestamps"
echo "  • Avoid duplicate entries"
echo "  • Keep up to 1000 entries"
echo ""

echo -e "${GREEN}🎉 Comprehensive Clipboard Management Complete!${NC}"
echo ""
echo -e "${CYAN}📋 Summary of Features:${NC}"
echo "  ✅ Get/Set clipboard content in multiple formats"
echo "  ✅ Automatic history tracking with timestamps"
echo "  ✅ Search through clipboard history"
echo "  ✅ Export/Import in JSON and CSV formats"
echo "  ✅ Real-time monitoring with watch mode"
echo "  ✅ Content deduplication and statistics"
echo "  ✅ Support for text, images, and other data types"
echo ""
echo -e "${YELLOW}🔧 Integration Tips:${NC}"
echo "  • Add to PATH: sudo cp $CLIPBOARD_TOOL /usr/local/bin/"
echo "  • Create aliases: alias cb='clipboard_manager'"
echo "  • Set up cron jobs for automated backups"
echo "  • Use in scripts for clipboard automation"
echo "  • Integrate with other tools via JSON output"
echo ""
echo -e "${GREEN}Your clipboard is now as powerful as Graphify! 🚀${NC}"
