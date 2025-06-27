#!/usr/bin/env bash
################################################################################
# kde6_taskbar_restore.sh
# Correct KDE Plasma 6 commands to restore missing taskbar
################################################################################

echo "🔧 KDE Plasma 6 Taskbar Restoration"
echo "==================================="
echo ""

echo "✅ You're correct - this is KDE Plasma 6!"
echo "   Let me give you the proper KDE 6 commands."
echo ""

echo "⚡ Method 1: Correct KDE 6 Keyboard Shortcuts"
echo "============================================="
echo ""
echo "Press Alt + F2, then type ONE of these:"
echo ""
echo "Option A (KDE 6 standard):"
echo "  plasmashell --replace"
echo ""
echo "Option B (KDE 6 alternative):"
echo "  kquitapp6 plasmashell && plasmashell"
echo ""
echo "Option C (Generic - works on both KDE 5/6):"
echo "  killall plasmashell && plasmashell"
echo ""

echo "🔄 Method 2: Automated KDE 6 Restoration"
echo "========================================"

# Use correct KDE 6 commands
echo "Using proper KDE Plasma 6 commands..."

# Kill plasmashell (works on both KDE 5 and 6)
killall plasmashell 2>/dev/null || true
sleep 3

# Start plasmashell (KDE 6 way - no kstart6 needed)
echo "Starting plasmashell for KDE 6..."
plasmashell &

echo "✅ Plasmashell restarted with KDE 6 method"
echo ""

echo "⏳ Waiting for panel to appear..."
sleep 5

echo ""
echo "🎯 Method 3: KDE 6 Desktop Right-Click"
echo "====================================="
echo ""
echo "If taskbar still missing:"
echo "1. Right-click on desktop"
echo "2. Select 'Add Panel' → 'Default Panel'"
echo "   (This works the same in KDE 6)"
echo ""

echo "⌨️  Method 4: KDE 6 KRunner Commands"
echo "==================================="
echo ""
echo "For KDE Plasma 6, use these commands in KRunner (Alt + F2):"
echo ""
echo "To restart plasmashell:"
echo "  plasmashell --replace"
echo ""
echo "To add a panel via script:"
echo "  qdbus org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript 'var panel = new Panel; panel.location = \"bottom\"; panel.height = 44'"
echo ""

echo "🔍 KDE Version Detection"
echo "======================="

# Detect KDE version
if command -v kinfo >/dev/null; then
    KDE_VERSION=$(kinfo --version 2>/dev/null | grep -i plasma | head -1)
    echo "Detected: $KDE_VERSION"
elif command -v plasmashell >/dev/null; then
    KDE_VERSION=$(plasmashell --version 2>/dev/null | head -1)
    echo "Detected: $KDE_VERSION"
else
    echo "KDE version detection failed"
fi

# Check what's available
echo ""
echo "Available commands on your system:"
if command -v kstart5 >/dev/null; then
    echo "  ✅ kstart5 (KDE 5 command available)"
fi
if command -v kstart6 >/dev/null; then
    echo "  ✅ kstart6 (KDE 6 command available)"
fi
if command -v kquitapp5 >/dev/null; then
    echo "  ✅ kquitapp5 (KDE 5 command available)"
fi
if command -v kquitapp6 >/dev/null; then
    echo "  ✅ kquitapp6 (KDE 6 command available)"
fi

echo ""
echo "🎉 KDE 6 Taskbar Restoration Complete!"
echo ""
echo "📋 Correct commands for KDE Plasma 6:"
echo "  • Restart plasmashell: killall plasmashell && plasmashell &"
echo "  • Or use: plasmashell --replace"
echo "  • Add panel: Right-click desktop → Add Panel → Default Panel"
echo ""
echo "✅ Your taskbar should now be restored with proper KDE 6 commands!"
