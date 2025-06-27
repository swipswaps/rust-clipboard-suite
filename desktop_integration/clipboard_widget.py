#!/usr/bin/env python3
"""
Clipboard Widget - Desktop integration for comprehensive clipboard management
Provides taskbar widget and system tray integration
"""

import sys
import subprocess
import json
import os
from pathlib import Path
from PyQt5.QtWidgets import (QApplication, QSystemTrayIcon, QMenu, QAction, 
                             QWidget, QVBoxLayout, QHBoxLayout, QLabel, 
                             QPushButton, QTextEdit, QComboBox, QMessageBox,
                             QListWidget, QListWidgetItem, QDialog, QDialogButtonBox)
from PyQt5.QtCore import QTimer, QThread, pyqtSignal, Qt
from PyQt5.QtGui import QIcon, QPixmap, QFont

class ClipboardWorker(QThread):
    """Background worker for clipboard monitoring"""
    clipboard_changed = pyqtSignal(str)
    
    def __init__(self):
        super().__init__()
        self.running = True
        self.last_content = ""
    
    def run(self):
        while self.running:
            try:
                result = subprocess.run(['clipboard_manager', 'get'], 
                                      capture_output=True, text=True, timeout=5)
                if result.returncode == 0:
                    content = result.stdout.strip()
                    if content != self.last_content:
                        self.clipboard_changed.emit(content)
                        self.last_content = content
            except Exception:
                pass
            self.msleep(1000)  # Check every second
    
    def stop(self):
        self.running = False

class ChartDialog(QDialog):
    """Dialog for chart generation options"""
    
    def __init__(self, parent=None):
        super().__init__(parent)
        self.setWindowTitle("Generate Charts")
        self.setFixedSize(400, 300)
        
        layout = QVBoxLayout()
        
        # Chart type selection
        layout.addWidget(QLabel("Select Chart Type:"))
        self.chart_type = QComboBox()
        self.chart_type.addItems([
            "Auto-detect", "Pie Chart", "Bar Chart", 
            "GANTT Chart", "Word Cloud", "Dashboard"
        ])
        layout.addWidget(self.chart_type)
        
        # Title input
        layout.addWidget(QLabel("Chart Title:"))
        self.title_input = QTextEdit()
        self.title_input.setMaximumHeight(60)
        self.title_input.setPlainText("Auto-Generated Chart")
        layout.addWidget(self.title_input)
        
        # Buttons
        buttons = QDialogButtonBox(QDialogButtonBox.Ok | QDialogButtonBox.Cancel)
        buttons.accepted.connect(self.accept)
        buttons.rejected.connect(self.reject)
        layout.addWidget(buttons)
        
        self.setLayout(layout)

class ClipboardHistoryDialog(QDialog):
    """Dialog for viewing clipboard history"""
    
    def __init__(self, parent=None):
        super().__init__(parent)
        self.setWindowTitle("Clipboard History")
        self.setFixedSize(600, 400)
        
        layout = QVBoxLayout()
        
        # History list
        self.history_list = QListWidget()
        layout.addWidget(self.history_list)
        
        # Buttons
        button_layout = QHBoxLayout()
        
        refresh_btn = QPushButton("Refresh")
        refresh_btn.clicked.connect(self.load_history)
        button_layout.addWidget(refresh_btn)
        
        restore_btn = QPushButton("Restore Selected")
        restore_btn.clicked.connect(self.restore_selected)
        button_layout.addWidget(restore_btn)
        
        search_btn = QPushButton("Search")
        search_btn.clicked.connect(self.search_history)
        button_layout.addWidget(search_btn)
        
        close_btn = QPushButton("Close")
        close_btn.clicked.connect(self.close)
        button_layout.addWidget(close_btn)
        
        layout.addLayout(button_layout)
        self.setLayout(layout)
        
        self.load_history()
    
    def load_history(self):
        """Load clipboard history"""
        try:
            result = subprocess.run(['clipboard_manager', 'history', '--limit', '20'], 
                                  capture_output=True, text=True)
            if result.returncode == 0:
                self.history_list.clear()
                lines = result.stdout.strip().split('\n')
                for line in lines:
                    if line.strip():
                        item = QListWidgetItem(line)
                        self.history_list.addItem(item)
        except Exception as e:
            QMessageBox.warning(self, "Error", f"Failed to load history: {e}")
    
    def restore_selected(self):
        """Restore selected clipboard entry"""
        current_item = self.history_list.currentItem()
        if current_item:
            # Extract content from the history line
            text = current_item.text()
            # Simple extraction - in real implementation, would parse properly
            if "   " in text:
                content = text.split("   ", 1)[1]
                try:
                    subprocess.run(['clipboard_manager', 'set', content], check=True)
                    QMessageBox.information(self, "Success", "Clipboard restored!")
                except Exception as e:
                    QMessageBox.warning(self, "Error", f"Failed to restore: {e}")
    
    def search_history(self):
        """Search clipboard history"""
        from PyQt5.QtWidgets import QInputDialog
        text, ok = QInputDialog.getText(self, 'Search', 'Enter search term:')
        if ok and text:
            try:
                result = subprocess.run(['clipboard_manager', 'search', text], 
                                      capture_output=True, text=True)
                if result.returncode == 0:
                    self.history_list.clear()
                    lines = result.stdout.strip().split('\n')
                    for line in lines:
                        if line.strip():
                            item = QListWidgetItem(line)
                            self.history_list.addItem(item)
            except Exception as e:
                QMessageBox.warning(self, "Error", f"Search failed: {e}")

class ClipboardWidget(QWidget):
    """Main clipboard widget"""
    
    def __init__(self):
        super().__init__()
        self.init_ui()
        self.init_tray()
        self.init_worker()
    
    def init_ui(self):
        """Initialize the main UI"""
        self.setWindowTitle("Clipboard Manager")
        self.setFixedSize(400, 300)
        
        layout = QVBoxLayout()
        
        # Title
        title = QLabel("📋 Comprehensive Clipboard Manager")
        title.setFont(QFont("Arial", 14, QFont.Bold))
        title.setAlignment(Qt.AlignCenter)
        layout.addWidget(title)
        
        # Current clipboard content
        layout.addWidget(QLabel("Current Clipboard:"))
        self.content_display = QTextEdit()
        self.content_display.setMaximumHeight(100)
        self.content_display.setReadOnly(True)
        layout.addWidget(self.content_display)
        
        # Buttons
        button_layout = QVBoxLayout()
        
        # Chart generation
        chart_btn = QPushButton("📊 Generate Charts")
        chart_btn.clicked.connect(self.show_chart_dialog)
        button_layout.addWidget(chart_btn)
        
        # History
        history_btn = QPushButton("📜 View History")
        history_btn.clicked.connect(self.show_history)
        button_layout.addWidget(history_btn)
        
        # Statistics
        stats_btn = QPushButton("📈 Statistics")
        stats_btn.clicked.connect(self.show_stats)
        button_layout.addWidget(stats_btn)
        
        # Export
        export_btn = QPushButton("💾 Export Data")
        export_btn.clicked.connect(self.export_data)
        button_layout.addWidget(export_btn)
        
        layout.addLayout(button_layout)
        self.setLayout(layout)
        
        # Update current content
        self.update_content()
    
    def init_tray(self):
        """Initialize system tray icon"""
        self.tray_icon = QSystemTrayIcon(self)
        
        # Create icon (simple colored square for now)
        pixmap = QPixmap(16, 16)
        pixmap.fill(Qt.blue)
        icon = QIcon(pixmap)
        self.tray_icon.setIcon(icon)
        
        # Create tray menu
        tray_menu = QMenu()
        
        show_action = QAction("Show Clipboard Manager", self)
        show_action.triggered.connect(self.show)
        tray_menu.addAction(show_action)
        
        tray_menu.addSeparator()
        
        chart_action = QAction("📊 Generate Charts", self)
        chart_action.triggered.connect(self.show_chart_dialog)
        tray_menu.addAction(chart_action)
        
        history_action = QAction("📜 View History", self)
        history_action.triggered.connect(self.show_history)
        tray_menu.addAction(history_action)
        
        stats_action = QAction("📈 Statistics", self)
        stats_action.triggered.connect(self.show_stats)
        tray_menu.addAction(stats_action)
        
        tray_menu.addSeparator()
        
        quit_action = QAction("Quit", self)
        quit_action.triggered.connect(QApplication.quit)
        tray_menu.addAction(quit_action)
        
        self.tray_icon.setContextMenu(tray_menu)
        self.tray_icon.show()
        
        # Tray icon click
        self.tray_icon.activated.connect(self.tray_icon_activated)
    
    def init_worker(self):
        """Initialize background clipboard monitoring"""
        self.worker = ClipboardWorker()
        self.worker.clipboard_changed.connect(self.on_clipboard_changed)
        self.worker.start()
    
    def tray_icon_activated(self, reason):
        """Handle tray icon activation"""
        if reason == QSystemTrayIcon.DoubleClick:
            self.show()
    
    def on_clipboard_changed(self, content):
        """Handle clipboard content change"""
        self.content_display.setPlainText(content[:200] + "..." if len(content) > 200 else content)
        
        # Show notification
        self.tray_icon.showMessage(
            "Clipboard Updated",
            f"New content: {content[:50]}{'...' if len(content) > 50 else ''}",
            QSystemTrayIcon.Information,
            3000
        )
    
    def update_content(self):
        """Update current clipboard content display"""
        try:
            result = subprocess.run(['clipboard_manager', 'get'], 
                                  capture_output=True, text=True)
            if result.returncode == 0:
                content = result.stdout.strip()
                self.content_display.setPlainText(content[:200] + "..." if len(content) > 200 else content)
        except Exception:
            self.content_display.setPlainText("Error reading clipboard")
    
    def show_chart_dialog(self):
        """Show chart generation dialog"""
        dialog = ChartDialog(self)
        if dialog.exec_() == QDialog.Accepted:
            self.generate_chart(dialog.chart_type.currentText(), dialog.title_input.toPlainText())
    
    def generate_chart(self, chart_type, title):
        """Generate chart based on selection"""
        try:
            if chart_type == "Auto-detect":
                cmd = ['chart_generator', 'auto']
            elif chart_type == "Dashboard":
                cmd = ['chart_generator', 'dashboard']
            else:
                chart_map = {
                    "Pie Chart": "pie",
                    "Bar Chart": "bar", 
                    "GANTT Chart": "gantt",
                    "Word Cloud": "word-cloud"
                }
                cmd = ['chart_generator', chart_map.get(chart_type, 'auto')]
                if title and title != "Auto-Generated Chart":
                    cmd.extend(['--title', title])
            
            result = subprocess.run(cmd, capture_output=True, text=True)
            if result.returncode == 0:
                QMessageBox.information(self, "Success", f"Chart generated successfully!\n{result.stdout}")
            else:
                QMessageBox.warning(self, "Error", f"Chart generation failed:\n{result.stderr}")
        except Exception as e:
            QMessageBox.warning(self, "Error", f"Failed to generate chart: {e}")
    
    def show_history(self):
        """Show clipboard history dialog"""
        dialog = ClipboardHistoryDialog(self)
        dialog.exec_()
    
    def show_stats(self):
        """Show clipboard statistics"""
        try:
            result = subprocess.run(['clipboard_manager', 'stats'], 
                                  capture_output=True, text=True)
            if result.returncode == 0:
                QMessageBox.information(self, "Clipboard Statistics", result.stdout)
            else:
                QMessageBox.warning(self, "Error", "Failed to get statistics")
        except Exception as e:
            QMessageBox.warning(self, "Error", f"Failed to get statistics: {e}")
    
    def export_data(self):
        """Export clipboard data"""
        try:
            desktop = Path.home() / "Desktop"
            output_file = desktop / f"clipboard_export_{os.getpid()}.json"
            
            result = subprocess.run(['clipboard_manager', 'export', '--output', str(output_file)], 
                                  capture_output=True, text=True)
            if result.returncode == 0:
                QMessageBox.information(self, "Export Complete", f"Data exported to:\n{output_file}")
            else:
                QMessageBox.warning(self, "Error", "Export failed")
        except Exception as e:
            QMessageBox.warning(self, "Error", f"Export failed: {e}")
    
    def closeEvent(self, event):
        """Handle window close event"""
        event.ignore()
        self.hide()
        self.tray_icon.showMessage(
            "Clipboard Manager",
            "Application minimized to tray",
            QSystemTrayIcon.Information,
            2000
        )

def main():
    app = QApplication(sys.argv)
    
    # Check if system tray is available
    if not QSystemTrayIcon.isSystemTrayAvailable():
        QMessageBox.critical(None, "System Tray", 
                           "System tray is not available on this system.")
        sys.exit(1)
    
    # Prevent quit on last window closed (for tray functionality)
    app.setQuitOnLastWindowClosed(False)
    
    widget = ClipboardWidget()
    widget.show()
    
    sys.exit(app.exec_())

if __name__ == '__main__':
    main()
