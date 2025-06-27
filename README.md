# 🦀 Rust Clipboard Suite

🚀 **Advanced clipboard management system for KDE Plasma** - A complete Rust-based replacement for Klipper with enhanced features, web visualization, and desktop integration.

## ✨ Features

### **🔧 Core Clipboard Management**
- **High-performance Rust backend** for clipboard operations
- **Unlimited clipboard history** with SQLite database storage
- **Real-time clipboard monitoring** and synchronization
- **Cross-application compatibility** with all Linux desktop environments

### **📊 Advanced Analytics & Visualization**
- **Web-based clipboard visualizer** with real-time charts
- **Usage analytics** and clipboard pattern analysis
- **Chart generation** for clipboard statistics
- **Professional dashboard** with responsive design

### **🖥️ Desktop Integration**
- **KDE6 panel widget** integration
- **Desktop application entries** (.desktop files)
- **System tray integration** with notifications
- **Keyboard shortcuts** and hotkey support

### **🛠️ System Management**
- **Automated Klipper removal** and conflict resolution
- **Panel restoration** and widget management
- **Configuration backup/restore** functionality
- **Professional installation scripts**

## 🏗️ Architecture

```
rust-clipboard-suite/
├── clipboard_manager/      # Core Rust clipboard manager
├── clipboard_tool/         # CLI interface tool
├── chart_generator/        # Analytics and chart generation
├── clipboard_visualizer/   # Web interface (Node.js/Vite)
├── desktop_integration/    # KDE integration files
├── target/                 # Compiled Rust binaries
└── install_scripts/        # Automated installation
```

## 🚀 Quick Start

### **Prerequisites**
```bash
# Install Rust toolchain
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source ~/.cargo/env

# Install Node.js for web visualizer
sudo dnf install nodejs npm  # Fedora
sudo apt install nodejs npm  # Ubuntu/Debian

# Install system dependencies
sudo dnf install sqlite-dev libx11-dev  # Fedora
sudo apt install libsqlite3-dev libx11-dev  # Ubuntu/Debian
```

### **Installation**
```bash
# Clone the repository
git clone https://github.com/swipswaps/rust-clipboard-suite.git
cd rust-clipboard-suite

# Run automated installation
chmod +x install_clipboard_system.sh
./install_clipboard_system.sh

# Install desktop integration
chmod +x install_desktop_integration.sh
./install_desktop_integration.sh
```

### **Quick Demo**
```bash
# Start the clipboard manager
./target/release/clipboard_manager

# Launch web visualizer
cd clipboard_visualizer
npm install && npm run dev

# Test CLI tool
./target/release/clipboard_tool --help
```

## 📋 Usage Examples

### **Basic Clipboard Operations**
```bash
# Start clipboard monitoring
clipboard_manager --daemon

# Get clipboard history
clipboard_tool --history --limit 10

# Search clipboard content
clipboard_tool --search "important text"

# Clear clipboard history
clipboard_tool --clear
```

### **Web Visualization**
```bash
# Start web interface
cd clipboard_visualizer
npm run dev
# Open http://localhost:3000
```

### **KDE Integration**
```bash
# Add to KDE panel
./add_our_clipboard_to_panel.sh

# Remove Klipper conflicts
./complete_klipper_removal_and_panel_reset.sh

# Restore panel if needed
./restore_missing_taskbar.sh
```

## 🎯 Key Benefits

- **🚀 Performance**: Rust-based backend for maximum speed and efficiency
- **💾 Unlimited Storage**: SQLite database with no history limits
- **📊 Analytics**: Comprehensive usage statistics and visualizations
- **🔧 Professional Tools**: Complete system management and automation
- **🖥️ Desktop Integration**: Native KDE6 panel widget support
- **🛡️ Reliability**: Automated conflict resolution and system restoration

## 🔧 Advanced Configuration

### **Clipboard Manager Settings**
```toml
# ~/.config/rust-clipboard/config.toml
[clipboard]
max_history = 10000
auto_cleanup_days = 30
enable_analytics = true

[database]
path = "~/.local/share/rust-clipboard/history.db"
backup_interval = 3600
```

### **Web Interface Customization**
```javascript
// clipboard_visualizer/src/config.js
export const config = {
  refreshInterval: 1000,
  maxDisplayItems: 100,
  enableCharts: true
};
```

## 🧪 Testing & Verification

The suite includes comprehensive testing scripts:
```bash
# Run complete system test
chmod +x test_complete_system.sh
./test_complete_system.sh

# Test individual components
cd clipboard_manager && cargo test
cd clipboard_tool && cargo test
cd chart_generator && cargo test
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🔗 Related Projects

- [kde-memory-guardian](https://github.com/swipswaps/kde-memory-guardian) - KDE memory management
- [performance-monitoring-suite](https://github.com/swipswaps/performance-monitoring-suite) - System performance tools

## 📞 Support

For issues, questions, or contributions, please open an issue on GitHub.

---

**Built with ❤️ and 🦀 Rust for the Linux desktop community**
