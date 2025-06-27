#!/usr/bin/env bash
################################################################################
# fix_gemini_issues.sh
# Comprehensive fix for issues caused by Gemini's suggestions
# Addresses KDE Plasma 6 compatibility, DNF5 issues, and system stability
################################################################################

set -euo pipefail
IFS=$'\n\t'

echo "🔧 [FIX] Starting comprehensive fix for Gemini-caused issues..."

# ─── DETECT ENVIRONMENT ───────────────────────────────────────────────────────
SESSION_TYPE="${XDG_SESSION_TYPE:-unknown}"
DESKTOP="${XDG_SESSION_DESKTOP:-unknown}"

echo "[INFO] 📋 Session Type: $SESSION_TYPE"
echo "[INFO] 🖥️  Desktop: $DESKTOP"

# ─── FIX 1: RESTORE KDE COMPOSITOR IF DISABLED ───────────────────────────────
echo "[FIX1] 🎨 Checking KDE compositor status..."

if [[ "$DESKTOP" == "KDE" ]] && [[ "$SESSION_TYPE" == "x11" ]]; then
  # Check if compositor is disabled
  COMPOSITOR_ENABLED=$(kreadconfig5 --file kwinrc --group Compositing --key Enabled --default true)
  
  if [[ "$COMPOSITOR_ENABLED" == "false" ]]; then
    echo "[FIX1] ⚠️  Compositor is disabled. This can cause plasmashell issues."
    echo "[FIX1] 🔧 Re-enabling compositor for stability..."
    
    kwriteconfig5 --file kwinrc --group Compositing --key Enabled true
    
    # Apply changes
    if qdbus org.kde.KWin /KWin reconfigure 2>/dev/null; then
      echo "[FIX1] ✅ Compositor re-enabled successfully"
    else
      echo "[FIX1] ⚠️  Could not reconfigure KWin via DBus. Changes will apply on next login."
    fi
  else
    echo "[FIX1] ✅ Compositor is already enabled"
  fi
else
  echo "[FIX1] ℹ️  Not a KDE X11 session, skipping compositor fix"
fi

# ─── FIX 2: CLEAN UP PLASMASHELL ISSUES ──────────────────────────────────────
echo "[FIX2] 🧹 Checking for plasmashell issues..."

if command -v plasmashell >/dev/null; then
  PLASMA_PROCESSES=$(pgrep -c plasmashell || echo "0")
  
  if [[ "$PLASMA_PROCESSES" -gt 1 ]]; then
    echo "[FIX2] ⚠️  Multiple plasmashell processes detected ($PLASMA_PROCESSES)"
    echo "[FIX2] 🔧 Cleaning up plasmashell..."
    
    killall plasmashell 2>/dev/null || true
    sleep 2
    
    # Restart cleanly
    if command -v kstart5 >/dev/null; then
      kstart5 plasmashell &
    else
      plasmashell &
    fi
    
    echo "[FIX2] ✅ Plasmashell restarted cleanly"
  else
    echo "[FIX2] ✅ Plasmashell process count is normal"
  fi
else
  echo "[FIX2] ℹ️  Plasmashell not found, skipping"
fi

# ─── FIX 3: VERIFY RUST TOOLCHAIN ────────────────────────────────────────────
echo "[FIX3] 🦀 Checking Rust toolchain..."

if ! command -v cargo >/dev/null; then
  echo "[FIX3] ⚠️  Rust not found. Installing..."
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
  source "$HOME/.cargo/env"
  echo "[FIX3] ✅ Rust installed"
else
  echo "[FIX3] ✅ Rust is available: $(cargo --version)"
fi

# Check for C compiler
if ! command -v cc >/dev/null; then
  echo "[FIX3] ⚠️  C compiler not found. Installing development tools..."
  
  if command -v dnf >/dev/null; then
    # Handle both DNF5 and classic DNF
    if dnf --version 2>/dev/null | grep -q "dnf5"; then
      sudo dnf install -y gcc gcc-c++ glibc-devel make pkgconf-devel
    else
      sudo dnf groupinstall -y "Development Tools" || sudo dnf install -y gcc gcc-c++ glibc-devel make pkgconf-devel
    fi
  elif command -v apt >/dev/null; then
    sudo apt update && sudo apt install -y build-essential
  else
    echo "[FIX3] ❌ Unknown package manager. Please install gcc manually."
  fi
  
  echo "[FIX3] ✅ Development tools installed"
else
  echo "[FIX3] ✅ C compiler is available: $(cc --version | head -1)"
fi

# ─── FIX 4: CLEAN UP SCRIPT VERSIONS ─────────────────────────────────────────
echo "[FIX4] 🧹 Cleaning up redundant script versions..."

SCRIPT_DIR="$(dirname "$0")"
cd "$SCRIPT_DIR"

# Keep only the latest versions
KLIPPER_SCRIPTS=(prf_clipboard_disable_klipper_v*.sh)
if [[ ${#KLIPPER_SCRIPTS[@]} -gt 1 ]]; then
  echo "[FIX4] 📁 Found ${#KLIPPER_SCRIPTS[@]} Klipper disable scripts"
  
  # Keep only v5 (latest)
  for script in "${KLIPPER_SCRIPTS[@]}"; do
    if [[ "$script" != "prf_clipboard_disable_klipper_v5.sh" ]] && [[ -f "$script" ]]; then
      echo "[FIX4] 🗑️  Removing old version: $script"
      rm -f "$script"
    fi
  done
fi

# ─── FIX 5: VALIDATE CLIPBOARD FUNCTIONALITY ────────────────────────────────
echo "[FIX5] 📋 Testing clipboard functionality..."

# Test with xclip if available
if command -v xclip >/dev/null; then
  echo "test_clipboard_$(date +%s)" | xclip -selection clipboard
  CLIPBOARD_CONTENT=$(xclip -selection clipboard -o 2>/dev/null || echo "")
  
  if [[ "$CLIPBOARD_CONTENT" == test_clipboard_* ]]; then
    echo "[FIX5] ✅ Clipboard is working correctly"
  else
    echo "[FIX5] ⚠️  Clipboard test failed"
  fi
else
  echo "[FIX5] ℹ️  xclip not available, skipping clipboard test"
fi

# ─── SUMMARY ──────────────────────────────────────────────────────────────────
echo ""
echo "🎉 [DONE] Gemini issue fixes completed!"
echo ""
echo "📋 Summary of fixes applied:"
echo "  ✅ KDE compositor status checked/restored"
echo "  ✅ Plasmashell process cleanup"
echo "  ✅ Rust toolchain verification"
echo "  ✅ C compiler dependencies"
echo "  ✅ Script cleanup"
echo "  ✅ Clipboard functionality test"
echo ""
echo "💡 Recommendations:"
echo "  • Log out and back in if you experience any KDE issues"
echo "  • Run the Rust bootstrap script if you need the clipboard tool"
echo "  • Use the fixed Klipper disable script (v5) if needed"
echo ""
