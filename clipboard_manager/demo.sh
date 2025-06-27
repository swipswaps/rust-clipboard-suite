#!/usr/bin/env bash
################################################################################
# demo.sh - Comprehensive Clipboard Management Demo
# Shows how to use all clipboard data like Graphify
################################################################################

set -euo pipefail

TOOL="./target/release/clipboard_manager"
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🚀 Comprehensive Clipboard Management Demo${NC}"
echo -e "${BLUE}=========================================${NC}"
echo ""

# Function to show a step
show_step() {
    echo -e "${YELLOW}$1${NC}"
    echo -e "${BLUE}$2${NC}"
    echo ""
}

# Function to run command and show output
run_demo() {
    echo -e "${GREEN}$ $*${NC}"
    "$@"
    echo ""
}

show_step "📋 Step 1: Basic Clipboard Operations" \
    "Setting and getting clipboard content in different formats"

run_demo $TOOL set "Hello from comprehensive clipboard manager! 🚀"
run_demo $TOOL get
run_demo $TOOL get --format json
run_demo $TOOL get --format base64

show_step "📊 Step 2: Adding Various Content Types" \
    "Demonstrating different types of clipboard content"

run_demo $TOOL set "URL: https://github.com/rust-lang/rust"
run_demo $TOOL set "Code: function fibonacci(n) { return n <= 1 ? n : fibonacci(n-1) + fibonacci(n-2); }"
run_demo $TOOL set "JSON: {\"user\": \"developer\", \"tools\": [\"rust\", \"javascript\", \"python\"], \"active\": true}"
run_demo $TOOL set "Command: docker run -d -p 8080:80 nginx:latest"
run_demo $TOOL set "SQL: SELECT users.name, COUNT(orders.id) as order_count FROM users LEFT JOIN orders ON users.id = orders.user_id GROUP BY users.id;"

show_step "📈 Step 3: Viewing Statistics" \
    "See comprehensive usage statistics"

run_demo $TOOL stats

show_step "🔍 Step 4: Searching Content" \
    "Find specific content in clipboard history"

run_demo $TOOL search "function"
run_demo $TOOL search "JSON" --case-sensitive
run_demo $TOOL search "http"

show_step "📁 Step 5: Export/Import Functionality" \
    "Backup and restore clipboard data"

run_demo $TOOL export --output /tmp/clipboard_demo.json --format json
echo -e "${GREEN}📄 Exported JSON preview:${NC}"
head -20 /tmp/clipboard_demo.json
echo ""

run_demo $TOOL export --output /tmp/clipboard_demo.csv --format csv
echo -e "${GREEN}📊 Exported CSV preview:${NC}"
head -5 /tmp/clipboard_demo.csv
echo ""

show_step "🔄 Step 6: Advanced Usage Examples" \
    "Real-world usage patterns"

echo -e "${YELLOW}💡 Example: Find all URLs in clipboard history${NC}"
run_demo $TOOL search "http"

echo -e "${YELLOW}💡 Example: Find code snippets${NC}"
run_demo $TOOL search "function"

echo -e "${YELLOW}💡 Example: Get current content with full metadata${NC}"
run_demo $TOOL get --format json

echo -e "${GREEN}🎉 Demo Complete!${NC}"
echo ""
echo -e "${BLUE}📋 Your clipboard system now provides:${NC}"
echo "  ✅ Comprehensive content management"
echo "  ✅ Multiple output formats (text, JSON, base64)"
echo "  ✅ Persistent history with timestamps"
echo "  ✅ Powerful search capabilities"
echo "  ✅ Export/import in JSON and CSV"
echo "  ✅ Content deduplication"
echo "  ✅ Usage statistics and analytics"
echo ""
echo -e "${YELLOW}🚀 Just like Graphify, but for ALL clipboard data!${NC}"
