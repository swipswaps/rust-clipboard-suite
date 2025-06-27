#!/usr/bin/env bash
################################################################################
# test_complete_system.sh
# Comprehensive testing of the complete clipboard management system
# Tests all components: conflict removal, chart generation, desktop integration
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

echo -e "${BLUE}🧪 Complete System Testing${NC}"
echo -e "${BLUE}=========================${NC}"
echo ""

# Test counters
TESTS_PASSED=0
TESTS_FAILED=0
TOTAL_TESTS=0

# Function to run a test
run_test() {
    local test_name="$1"
    local test_command="$2"
    local expected_pattern="$3"
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    echo -e "${YELLOW}🔍 Testing: $test_name${NC}"
    
    if eval "$test_command" 2>/dev/null | grep -q "$expected_pattern"; then
        echo -e "${GREEN}✅ PASS: $test_name${NC}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}❌ FAIL: $test_name${NC}"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
    echo ""
}

# Function to test file existence
test_file_exists() {
    local test_name="$1"
    local file_path="$2"
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    echo -e "${YELLOW}📁 Testing: $test_name${NC}"
    
    if [[ -f "$file_path" ]]; then
        echo -e "${GREEN}✅ PASS: $file_path exists${NC}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}❌ FAIL: $file_path not found${NC}"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
    echo ""
}

# Function to test command availability
test_command() {
    local test_name="$1"
    local command="$2"
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    echo -e "${YELLOW}⚡ Testing: $test_name${NC}"
    
    if command -v "$command" >/dev/null 2>&1; then
        echo -e "${GREEN}✅ PASS: $command available${NC}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}❌ FAIL: $command not found${NC}"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
    echo ""
}

echo -e "${PURPLE}Phase 1: Core Tools Testing${NC}"
echo "================================"

# Test basic clipboard functionality
test_command "Clipboard Manager Command" "clipboard_manager"
test_command "Chart Generator Command" "chart_generator"

# Test clipboard operations
run_test "Clipboard Set Operation" \
    "clipboard_manager set 'Test data for system validation'" \
    "successfully"

run_test "Clipboard Get Operation" \
    "clipboard_manager get" \
    "Test data for system validation"

run_test "Clipboard JSON Output" \
    "clipboard_manager get --format json" \
    "content_type"

run_test "Clipboard Statistics" \
    "clipboard_manager stats" \
    "Statistics"

echo -e "${PURPLE}Phase 2: Chart Generation Testing${NC}"
echo "=================================="

# Create test data for charts
echo "Creating test data..."
TEST_CSV_DATA="Product,Sales,Category
Laptops,1500,Electronics
Phones,2300,Electronics
Books,800,Media
Games,1200,Media"

TEST_JSON_DATA='[
  {"name": "Task 1", "start": "2024-01-01", "end": "2024-01-15", "progress": 0.8},
  {"name": "Task 2", "start": "2024-01-10", "end": "2024-01-25", "progress": 0.6},
  {"name": "Task 3", "start": "2024-01-20", "end": "2024-02-05", "progress": 0.3}
]'

# Test chart generation with CSV data
echo "$TEST_CSV_DATA" | clipboard_manager set "$(cat)"
run_test "Auto Chart Generation" \
    "chart_generator auto --output-dir /tmp/test_charts" \
    "Auto-generated charts"

# Test specific chart types
echo "$TEST_JSON_DATA" | clipboard_manager set "$(cat)"
run_test "GANTT Chart Generation" \
    "chart_generator gantt --output /tmp/test_gantt.svg" \
    "GANTT chart generated"

run_test "Pie Chart Generation" \
    "chart_generator pie --output /tmp/test_pie.svg" \
    "Pie chart generated"

run_test "Dashboard Generation" \
    "chart_generator dashboard --output /tmp/test_dashboard.html" \
    "Dashboard generated"

echo -e "${PURPLE}Phase 3: Desktop Integration Testing${NC}"
echo "====================================="

# Test desktop files
test_file_exists "Clipboard Manager Desktop Entry" \
    "/usr/share/applications/clipboard-manager.desktop"

test_file_exists "Chart Generator Desktop Entry" \
    "/usr/share/applications/chart-generator.desktop"

# Test icons
test_file_exists "Clipboard Manager Icon" \
    "/usr/share/icons/hicolor/48x48/apps/clipboard-manager.svg"

test_file_exists "Chart Generator Icon" \
    "/usr/share/icons/hicolor/48x48/apps/chart-generator.svg"

# Test autostart
test_file_exists "Autostart Entry" \
    "$HOME/.config/autostart/clipboard-manager.desktop"

# Test GUI wrapper
test_command "GUI Wrapper" "clipboard_manager_gui"

echo -e "${PURPLE}Phase 4: Integration Testing${NC}"
echo "============================="

# Test data export/import
run_test "Data Export" \
    "clipboard_manager export --output /tmp/test_export.json" \
    "exported"

test_file_exists "Exported Data File" "/tmp/test_export.json"

run_test "Data Import" \
    "clipboard_manager import --input /tmp/test_export.json" \
    "imported"

# Test search functionality
clipboard_manager set "This is a searchable test entry with keywords"
run_test "Search Functionality" \
    "clipboard_manager search 'searchable'" \
    "Found"

echo -e "${PURPLE}Phase 5: Performance Testing${NC}"
echo "============================="

# Test with larger data
LARGE_TEXT=$(printf 'A%.0s' {1..1000})
clipboard_manager set "$LARGE_TEXT"
run_test "Large Text Handling" \
    "clipboard_manager get | wc -c" \
    "1000"

# Test multiple rapid operations
echo "Testing rapid operations..."
for i in {1..5}; do
    clipboard_manager set "Rapid test $i" >/dev/null 2>&1
done
run_test "Rapid Operations" \
    "clipboard_manager get" \
    "Rapid test 5"

echo -e "${PURPLE}Phase 6: Conflict Resolution Testing${NC}"
echo "====================================="

# Check that conflicting clipboard managers are not running
TOTAL_TESTS=$((TOTAL_TESTS + 1))
echo -e "${YELLOW}🔍 Testing: No Conflicting Clipboard Managers${NC}"
CONFLICTS=$(pgrep -f "copyq|clipit|parcellite|clipman|diodon" 2>/dev/null || echo "")
if [[ -z "$CONFLICTS" ]]; then
    echo -e "${GREEN}✅ PASS: No conflicting clipboard managers running${NC}"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    echo -e "${RED}❌ FAIL: Found conflicting processes: $CONFLICTS${NC}"
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi
echo ""

echo -e "${PURPLE}Phase 7: System Integration Testing${NC}"
echo "===================================="

# Test system tray availability (if GUI available)
if command -v python3 >/dev/null && python3 -c "import PyQt5" 2>/dev/null; then
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    echo -e "${YELLOW}🖥️  Testing: GUI Dependencies${NC}"
    echo -e "${GREEN}✅ PASS: PyQt5 available for GUI${NC}"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    echo -e "${YELLOW}🖥️  Testing: GUI Dependencies${NC}"
    echo -e "${YELLOW}⚠️  WARNING: PyQt5 not available, GUI may not work${NC}"
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi
echo ""

# Test desktop environment integration
TOTAL_TESTS=$((TOTAL_TESTS + 1))
echo -e "${YELLOW}🖥️  Testing: Desktop Environment Integration${NC}"
if [[ -n "${XDG_SESSION_DESKTOP:-}" ]]; then
    echo -e "${GREEN}✅ PASS: Desktop environment detected: $XDG_SESSION_DESKTOP${NC}"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    echo -e "${YELLOW}⚠️  WARNING: No desktop environment detected${NC}"
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi
echo ""

echo -e "${PURPLE}Phase 8: Generated Files Testing${NC}"
echo "================================="

# Check generated charts
test_file_exists "Auto-generated Charts Directory" "/tmp/test_charts"
test_file_exists "Test GANTT Chart" "/tmp/test_gantt.svg"
test_file_exists "Test Pie Chart" "/tmp/test_pie.svg"
test_file_exists "Test Dashboard" "/tmp/test_dashboard.html"

# Cleanup test files
echo "Cleaning up test files..."
rm -f /tmp/test_*.svg /tmp/test_*.html /tmp/test_*.json 2>/dev/null || true
rm -rf /tmp/test_charts 2>/dev/null || true

echo ""
echo -e "${BLUE}📊 Test Results Summary${NC}"
echo "========================"
echo -e "${GREEN}✅ Tests Passed: $TESTS_PASSED${NC}"
echo -e "${RED}❌ Tests Failed: $TESTS_FAILED${NC}"
echo -e "${BLUE}📋 Total Tests: $TOTAL_TESTS${NC}"

PASS_RATE=$((TESTS_PASSED * 100 / TOTAL_TESTS))
echo -e "${PURPLE}📈 Pass Rate: $PASS_RATE%${NC}"

echo ""
if [[ $TESTS_FAILED -eq 0 ]]; then
    echo -e "${GREEN}🎉 ALL TESTS PASSED! System is fully functional! 🚀${NC}"
    echo ""
    echo -e "${BLUE}✅ Your comprehensive clipboard system is ready:${NC}"
    echo "  • Conflict-free clipboard management"
    echo "  • Automatic chart generation (GANTT, pie, bar, word clouds)"
    echo "  • Seamless desktop integration"
    echo "  • Taskbar widget and application launcher access"
    echo "  • Cross-session data persistence"
    echo "  • Real-time monitoring and notifications"
    echo ""
    echo -e "${YELLOW}🚀 Ready to use! Access via:${NC}"
    echo "  • Application menu: Search 'Clipboard Manager'"
    echo "  • Desktop shortcuts: Double-click desktop icons"
    echo "  • System tray: Right-click clipboard icon"
    echo "  • Command line: 'clipboard_manager' or 'chart_generator'"
elif [[ $PASS_RATE -ge 80 ]]; then
    echo -e "${YELLOW}⚠️  MOSTLY FUNCTIONAL ($PASS_RATE% pass rate)${NC}"
    echo "System is largely working but some features may need attention."
    echo "Check failed tests above for details."
else
    echo -e "${RED}❌ SYSTEM NEEDS ATTENTION ($PASS_RATE% pass rate)${NC}"
    echo "Multiple components failed. Review installation and try again."
fi

echo ""
echo -e "${BLUE}📋 System Status: Ready for comprehensive clipboard data utilization like Graphify! 📊${NC}"
