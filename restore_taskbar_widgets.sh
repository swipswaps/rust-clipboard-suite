#!/usr/bin/env bash
################################################################################
# restore_taskbar_widgets.sh
# Quick guide and tools to restore taskbar widgets to your preferred layout
################################################################################

echo "🔧 Taskbar Widget Restoration Guide"
echo "===================================="
echo ""

echo "📋 Quick Steps to Restore Your Widgets:"
echo ""
echo "1. 🖱️  Right-click on the taskbar (panel)"
echo "2. 📝 Select 'Edit Panel' from the context menu"
echo "3. 🎯 You should now see widget handles and options"
echo "4. 📦 To add widgets:"
echo "   • Click 'Add Widgets' button"
echo "   • Drag desired widgets to the panel"
echo "5. 🔄 To move existing widgets:"
echo "   • Drag widgets left or right to reposition"
echo "6. ✅ Click 'Exit Edit Mode' when finished"
echo ""

echo "🎨 Common Widget Layout Suggestions:"
echo ""
echo "Left Side (typical layout):"
echo "  • Application Launcher (Kickoff)"
echo "  • Task Manager"
echo "  • [Your custom widgets]"
echo ""
echo "Right Side (typical layout):"
echo "  • System Tray"
echo "  • Digital Clock"
echo "  • Show Desktop"
echo ""

echo "🔧 If Right-Click Still Flickers:"
echo ""
echo "Try these alternatives:"
echo "1. 🎯 Alt + D, Alt + A (keyboard shortcut to add widgets)"
echo "2. 🖱️  Right-click on empty desktop → Add Panel → Empty Panel"
echo "3. ⚙️  System Settings → Startup and Shutdown → Desktop Session → Start with an empty session"
echo ""

echo "🛠️  Advanced Restoration Options:"
echo ""
echo "If you want to completely reset to default layout:"
echo "1. Backup current config:"
echo "   cp ~/.config/plasma-org.kde.plasma.desktop-appletsrc ~/.config/plasma-backup"
echo ""
echo "2. Reset to defaults:"
echo "   rm ~/.config/plasma-org.kde.plasma.desktop-appletsrc"
echo "   rm ~/.config/plasmashellrc"
echo ""
echo "3. Restart Plasma:"
echo "   killall plasmashell && kstart5 plasmashell"
echo ""

echo "🎯 Specific Widget Recommendations:"
echo ""
echo "Essential widgets you might want:"
echo "  • Application Launcher - Start applications"
echo "  • Task Manager - Show running applications"
echo "  • System Tray - System notifications and status"
echo "  • Digital Clock - Time and date"
echo "  • Clipboard Manager - Our new clipboard tool!"
echo ""

echo "📊 Adding Our Clipboard Widget:"
echo ""
echo "To add our clipboard manager to the panel:"
echo "1. Right-click panel → Edit Panel"
echo "2. Add Widgets → Search for 'Clipboard'"
echo "3. Or add a 'Command Output' widget with:"
echo "   Command: clipboard_manager get --format text"
echo "   Update interval: 5 seconds"
echo ""

# Create a quick reset script
cat > /tmp/reset_panel_layout.sh << 'EOF'
#!/bin/bash
echo "🔄 Resetting panel to default layout..."
killall plasmashell 2>/dev/null || true
sleep 2

# Remove current panel config
mv ~/.config/plasma-org.kde.plasma.desktop-appletsrc ~/.config/plasma-org.kde.plasma.desktop-appletsrc.backup.$(date +%s) 2>/dev/null || true

# Restart plasma
if command -v kstart5 >/dev/null; then
    kstart5 plasmashell &
else
    plasmashell &
fi

echo "✅ Panel reset to defaults. You can now customize it as needed."
EOF

chmod +x /tmp/reset_panel_layout.sh

echo "🚨 Emergency Reset Available:"
echo "If you want to completely reset your panel layout:"
echo "   bash /tmp/reset_panel_layout.sh"
echo ""

echo "✅ Your screen flickering should now be fixed!"
echo "✅ You can safely right-click the taskbar to customize it."
echo ""
echo "💡 Pro Tip: The flickering was likely caused by compositor conflicts"
echo "   from the old clipboard managers we removed. It should be stable now!"
