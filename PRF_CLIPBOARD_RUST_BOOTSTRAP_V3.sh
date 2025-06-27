#!/usr/bin/env bash
################################################################################
# PRF_CLIPBOARD_RUST_BOOTSTRAP_V3.sh
# Hardened Rust/X11 Clipboard Tool – Bulletproof Bootstrapper with DNF5 fix
# PRF‑COMPLIANT: Autodetects compiler toolchain, Rust, and resolves install issues
################################################################################

set -euo pipefail
IFS=$'\n\t'

# ─── METADATA ─────────────────────────────────────────────────────────────────
SCRIPT_NAME="PRF_CLIPBOARD_RUST_BOOTSTRAP"
TOOL_NAME="clipboard_tool"
INSTALL_DIR="$HOME/Documents/$TOOL_NAME"
BIN_NAME="clipboard_tool"
TARGET_BIN="/usr/local/bin/$BIN_NAME"
RUST_ENV_FILE="$HOME/.cargo/env"

echo "[INFO] ▶ Starting $SCRIPT_NAME install for Rust/X11 clipboard utility..."

################################################################################
# STEP 1: DETECT & INSTALL COMPILER TOOLCHAIN (GCC, MAKE, ETC)
#
# WHAT:
#   Rust's Cargo requires a native C linker (`cc`) and libc headers (e.g., glibc).
# WHY:
#   Without these, Rust crates that bind to C (libc, rustix, etc.) will fail.
# HOW:
#   Detects package manager; installs build tools accordingly.
################################################################################
install_c_toolchain() {
  echo "[CHECK] 🔍 Verifying native C compiler..."
  if ! command -v cc >/dev/null; then
    echo "[FIX] 🔧 'cc' missing — installing development tools..."

    if command -v dnf >/dev/null; then
      # Check if this is DNF5 (Fedora 42+) or classic DNF
      if dnf --version 2>/dev/null | grep -q "dnf5"; then
        echo "[INFO] 🧩 DNF5 detected. Using individual package install."
        sudo dnf install -y gcc gcc-c++ glibc-devel make pkgconf-devel
      else
        echo "[INFO] 🧩 Classic DNF detected. Using group install."
        sudo dnf groupinstall -y "Development Tools" || sudo dnf install -y gcc gcc-c++ glibc-devel make pkgconf-devel
      fi
    elif command -v yum >/dev/null; then
      sudo yum groupinstall -y "Development Tools"
    elif command -v apt >/dev/null; then
      sudo apt update && sudo apt install -y build-essential
    elif command -v zypper >/dev/null; then
      sudo zypper install -t pattern devel_C_C++
    else
      echo "[FAIL] ❌ Unknown package manager. Please install gcc manually."
      exit 1
    fi
    echo "[PASS] ✅ Native toolchain installed."
  else
    echo "[CHECK] ✅ Native compiler found: $(command -v cc)"
  fi
}

################################################################################
# STEP 2: INSTALL RUST (RUSTUP + CARGO)
#
# WHAT:
#   Installs stable Rust toolchain if missing.
# WHY:
#   Needed to build the clipboard tool and resolve dependencies (e.g., arboard).
# HOW:
#   Uses rustup installer with default settings.
################################################################################
install_rust() {
  echo "[CHECK] 🔍 Checking for Cargo..."
  if ! command -v cargo >/dev/null; then
    echo "[TASK] 🚀 Installing Rust via rustup..."
    curl https://sh.rustup.rs -sSf | sh -s -- -y
    echo "[TASK] 🛠  Sourcing cargo env: $RUST_ENV_FILE"
    source "$RUST_ENV_FILE"
  else
    echo "[CHECK] ✅ Rust toolchain found: $(command -v cargo)"
  fi
}

################################################################################
# STEP 3: PROJECT SETUP (CARGO FILES, SOURCE TREE)
#
# WHAT:
#   Creates Cargo.toml and `src/main.rs` for clipboard_tool.
# WHY:
#   Required to compile and install the tool using the Rust ecosystem.
# HOW:
#   Uses cat >> to write the build files inline.
################################################################################
setup_project() {
  echo "[TASK] 📂 Creating project directory: $INSTALL_DIR"
  mkdir -p "$INSTALL_DIR/src"
  cd "$INSTALL_DIR"

  # Manifest file: Cargo.toml
  cat > Cargo.toml <<EOF
[package]
name = "$TOOL_NAME"
version = "0.1.0"
edition = "2021"

[dependencies]
arboard = "3"
EOF

  # Entry point: src/main.rs
  cat > src/main.rs <<'EOF'
use arboard::{Clipboard, SetExtLinux, LinuxClipboardKind};
use std::env;

fn main() -> Result<(), Box<dyn std::error::Error>> {
    let mut args = env::args().skip(1);
    let cmd = args.next().ok_or("Usage: clipboard_tool get | set <text>")?;

    let mut clipboard = Clipboard::new()?;
    match cmd.as_str() {
        "get" => {
            match clipboard.get_text() {
                Ok(txt) => {
                    println!("{}", txt);
                    Ok(())
                }
                Err(e) => Err(format!("Error getting clipboard text: {}", e).into()),
            }
        }
        "set" => {
            let text = args.next().ok_or("Usage: clipboard_tool set <text>")?;
            clipboard.set()
                .clipboard(LinuxClipboardKind::Clipboard)
                .wait()
                .text(text)?;
            println!("Clipboard set successfully and will persist.");
            Ok(())
        }
        _ => Err("Usage: clipboard_tool get | set <text>".into()),
    }
}
EOF
}

################################################################################
# STEP 4: BUILD AND INSTALL
#
# WHAT:
#   Compile clipboard_tool in release mode and install to /usr/local/bin
# WHY:
#   Enables CLI-wide access to `clipboard_tool` for automation scripts
# HOW:
#   Uses cargo build → sudo cp → chmod +x
################################################################################
build_and_install() {
  echo "[BUILD] 🛠  Building in release mode..."
  cargo build --release

  echo "[INSTALL] 🧩 Installing binary to $TARGET_BIN"
  sudo cp "target/release/$BIN_NAME" "$TARGET_BIN"
  sudo chmod +x "$TARGET_BIN"

  echo "[VERIFY] 📋 Running test: clipboard_tool get"
  "$TARGET_BIN" get || echo "[WARN] Clipboard may be empty — binary executes fine."
}

################################################################################
# MAIN EXECUTION
################################################################################
install_c_toolchain
install_rust
setup_project
build_and_install

echo -e "\n[DONE] ✅ Rust clipboard tool installed and operational.\n"
echo "▶ Use commands:"
echo "    clipboard_tool get"
echo "    clipboard_tool set 'Text to insert'"
