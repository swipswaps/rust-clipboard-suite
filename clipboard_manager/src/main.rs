use arboard::{Clipboard, SetExtLinux, LinuxClipboardKind};
use anyhow::{Result, Context};
use base64::{Engine as _, engine::general_purpose};
use chrono::{DateTime, Utc};
use clap::{Parser, Subcommand};
use serde::{Deserialize, Serialize};
use sha2::{Sha256, Digest};
use std::collections::HashMap;
use std::fs;
use std::path::PathBuf;
use uuid::Uuid;

#[derive(Parser)]
#[command(name = "clipboard_manager")]
#[command(about = "Comprehensive clipboard management tool - like Graphify for all clipboard data")]
struct Cli {
    #[command(subcommand)]
    command: Commands,
}

#[derive(Subcommand)]
enum Commands {
    /// Get current clipboard content
    Get {
        /// Output format: text, json, base64
        #[arg(short, long, default_value = "text")]
        format: String,
    },
    /// Set clipboard content
    Set {
        /// Text to set in clipboard
        text: String,
    },
    /// Watch clipboard for changes and save history
    Watch {
        /// Maximum number of entries to keep
        #[arg(short, long, default_value = "1000")]
        max_entries: usize,
    },
    /// List clipboard history
    History {
        /// Number of recent entries to show
        #[arg(short, long, default_value = "10")]
        limit: usize,
        /// Output format: text, json
        #[arg(short, long, default_value = "text")]
        format: String,
    },
    /// Search clipboard history
    Search {
        /// Search query
        query: String,
        /// Case sensitive search
        #[arg(short, long)]
        case_sensitive: bool,
    },
    /// Export clipboard history
    Export {
        /// Output file path
        #[arg(short, long)]
        output: PathBuf,
        /// Export format: json, csv
        #[arg(short, long, default_value = "json")]
        format: String,
    },
    /// Import clipboard history
    Import {
        /// Input file path
        #[arg(short, long)]
        input: PathBuf,
    },
    /// Clear clipboard history
    Clear,
    /// Show statistics about clipboard usage
    Stats,
}

#[derive(Serialize, Deserialize, Clone, Debug)]
struct ClipboardEntry {
    id: String,
    timestamp: DateTime<Utc>,
    content_type: ContentType,
    content: String,
    content_hash: String,
    size_bytes: usize,
    source_app: Option<String>,
}

#[derive(Serialize, Deserialize, Clone, Debug)]
enum ContentType {
    Text,
    Image,
    Html,
    Rtf,
    Files,
    Unknown,
}

#[derive(Serialize, Deserialize, Default)]
struct ClipboardHistory {
    entries: Vec<ClipboardEntry>,
    metadata: HistoryMetadata,
}

#[derive(Serialize, Deserialize, Default)]
struct HistoryMetadata {
    total_entries: usize,
    created_at: Option<DateTime<Utc>>,
    last_updated: Option<DateTime<Utc>>,
    version: String,
}

struct ClipboardManager {
    clipboard: Clipboard,
    history_file: PathBuf,
}

impl ClipboardManager {
    fn new() -> Result<Self> {
        let clipboard = Clipboard::new().context("Failed to initialize clipboard")?;
        
        let mut history_file = dirs::data_dir()
            .unwrap_or_else(|| PathBuf::from("."))
            .join("clipboard_manager");
        
        fs::create_dir_all(&history_file).context("Failed to create data directory")?;
        history_file.push("history.json");
        
        Ok(Self {
            clipboard,
            history_file,
        })
    }

    fn get_current_content(&mut self, format: &str) -> Result<()> {
        // Try to get text first
        if let Ok(text) = self.clipboard.get_text() {
            match format {
                "json" => {
                    let entry = ClipboardEntry {
                        id: Uuid::new_v4().to_string(),
                        timestamp: Utc::now(),
                        content_type: ContentType::Text,
                        content: text.clone(),
                        content_hash: self.calculate_hash(&text),
                        size_bytes: text.len(),
                        source_app: None,
                    };
                    println!("{}", serde_json::to_string_pretty(&entry)?);
                }
                "base64" => {
                    let encoded = general_purpose::STANDARD.encode(text.as_bytes());
                    println!("{}", encoded);
                }
                _ => println!("{}", text),
            }
            return Ok(());
        }

        // Try to get image
        if let Ok(image) = self.clipboard.get_image() {
            let image_data = format!("Image: {}x{} pixels, {} bytes", 
                image.width, image.height, image.bytes.len());
            
            match format {
                "json" => {
                    let entry = ClipboardEntry {
                        id: Uuid::new_v4().to_string(),
                        timestamp: Utc::now(),
                        content_type: ContentType::Image,
                        content: general_purpose::STANDARD.encode(&image.bytes),
                        content_hash: self.calculate_hash(&format!("{:?}", image.bytes)),
                        size_bytes: image.bytes.len(),
                        source_app: None,
                    };
                    println!("{}", serde_json::to_string_pretty(&entry)?);
                }
                "base64" => {
                    println!("{}", general_purpose::STANDARD.encode(&image.bytes));
                }
                _ => println!("{}", image_data),
            }
            return Ok(());
        }

        println!("No clipboard content available");
        Ok(())
    }

    fn set_content(&mut self, text: &str) -> Result<()> {
        self.clipboard.set()
            .clipboard(LinuxClipboardKind::Clipboard)
            .wait()
            .text(text.to_string())
            .context("Failed to set clipboard content")?;
        
        println!("Clipboard content set successfully");
        Ok(())
    }

    fn calculate_hash(&self, content: &str) -> String {
        let mut hasher = Sha256::new();
        hasher.update(content.as_bytes());
        format!("{:x}", hasher.finalize())
    }

    fn load_history(&self) -> Result<ClipboardHistory> {
        if !self.history_file.exists() {
            return Ok(ClipboardHistory::default());
        }
        
        let content = fs::read_to_string(&self.history_file)
            .context("Failed to read history file")?;
        
        serde_json::from_str(&content)
            .context("Failed to parse history file")
    }

    fn save_history(&self, history: &ClipboardHistory) -> Result<()> {
        let content = serde_json::to_string_pretty(history)
            .context("Failed to serialize history")?;
        
        fs::write(&self.history_file, content)
            .context("Failed to write history file")
    }

    fn add_to_history(&mut self, entry: ClipboardEntry, max_entries: usize) -> Result<()> {
        let mut history = self.load_history()?;

        // Check if this content already exists (avoid duplicates)
        if !history.entries.iter().any(|e| e.content_hash == entry.content_hash) {
            history.entries.insert(0, entry);

            // Trim to max entries
            if history.entries.len() > max_entries {
                history.entries.truncate(max_entries);
            }

            history.metadata.total_entries = history.entries.len();
            history.metadata.last_updated = Some(Utc::now());
            if history.metadata.created_at.is_none() {
                history.metadata.created_at = Some(Utc::now());
            }
            history.metadata.version = "1.0".to_string();

            self.save_history(&history)?;
        }

        Ok(())
    }

    fn show_history(&self, limit: usize, format: &str) -> Result<()> {
        let history = self.load_history()?;
        let entries: Vec<_> = history.entries.iter().take(limit).collect();

        match format {
            "json" => {
                println!("{}", serde_json::to_string_pretty(&entries)?);
            }
            _ => {
                for (i, entry) in entries.iter().enumerate() {
                    println!("{}. [{}] {} - {} bytes",
                        i + 1,
                        entry.timestamp.format("%Y-%m-%d %H:%M:%S"),
                        match entry.content_type {
                            ContentType::Text => "Text",
                            ContentType::Image => "Image",
                            ContentType::Html => "HTML",
                            ContentType::Rtf => "RTF",
                            ContentType::Files => "Files",
                            ContentType::Unknown => "Unknown",
                        },
                        entry.size_bytes
                    );

                    let preview = if entry.content.len() > 100 {
                        format!("{}...", &entry.content[..100])
                    } else {
                        entry.content.clone()
                    };
                    println!("   {}\n", preview);
                }
            }
        }

        Ok(())
    }

    fn search_history(&self, query: &str, case_sensitive: bool) -> Result<()> {
        let history = self.load_history()?;
        let search_query = if case_sensitive { query.to_string() } else { query.to_lowercase() };

        let matches: Vec<_> = history.entries.iter()
            .filter(|entry| {
                let content = if case_sensitive {
                    entry.content.clone()
                } else {
                    entry.content.to_lowercase()
                };
                content.contains(&search_query)
            })
            .collect();

        println!("Found {} matches for '{}':\n", matches.len(), query);

        for (i, entry) in matches.iter().enumerate() {
            println!("{}. [{}] {} - {} bytes",
                i + 1,
                entry.timestamp.format("%Y-%m-%d %H:%M:%S"),
                match entry.content_type {
                    ContentType::Text => "Text",
                    ContentType::Image => "Image",
                    ContentType::Html => "HTML",
                    ContentType::Rtf => "RTF",
                    ContentType::Files => "Files",
                    ContentType::Unknown => "Unknown",
                },
                entry.size_bytes
            );

            let preview = if entry.content.len() > 100 {
                format!("{}...", &entry.content[..100])
            } else {
                entry.content.clone()
            };
            println!("   {}\n", preview);
        }

        Ok(())
    }

    fn export_history(&self, output: &PathBuf, format: &str) -> Result<()> {
        let history = self.load_history()?;

        match format {
            "csv" => {
                let mut csv_content = String::from("id,timestamp,content_type,content_hash,size_bytes,content\n");
                for entry in &history.entries {
                    csv_content.push_str(&format!(
                        "{},{},{:?},{},{},\"{}\"\n",
                        entry.id,
                        entry.timestamp.to_rfc3339(),
                        entry.content_type,
                        entry.content_hash,
                        entry.size_bytes,
                        entry.content.replace("\"", "\"\"")
                    ));
                }
                fs::write(output, csv_content)?;
            }
            _ => {
                let json_content = serde_json::to_string_pretty(&history)?;
                fs::write(output, json_content)?;
            }
        }

        println!("History exported to: {}", output.display());
        Ok(())
    }

    fn import_history(&mut self, input: &PathBuf) -> Result<()> {
        let content = fs::read_to_string(input)
            .context("Failed to read import file")?;

        let imported_history: ClipboardHistory = serde_json::from_str(&content)
            .context("Failed to parse import file")?;

        let mut current_history = self.load_history()?;

        // Merge histories, avoiding duplicates
        for entry in imported_history.entries {
            if !current_history.entries.iter().any(|e| e.content_hash == entry.content_hash) {
                current_history.entries.push(entry);
            }
        }

        // Sort by timestamp (newest first)
        current_history.entries.sort_by(|a, b| b.timestamp.cmp(&a.timestamp));

        current_history.metadata.total_entries = current_history.entries.len();
        current_history.metadata.last_updated = Some(Utc::now());

        self.save_history(&current_history)?;

        println!("History imported successfully. Total entries: {}", current_history.entries.len());
        Ok(())
    }

    fn clear_history(&self) -> Result<()> {
        let empty_history = ClipboardHistory::default();
        self.save_history(&empty_history)?;
        println!("Clipboard history cleared");
        Ok(())
    }

    fn show_stats(&self) -> Result<()> {
        let history = self.load_history()?;

        let mut type_counts = HashMap::new();
        let mut total_size = 0;
        let mut largest_entry = 0;

        for entry in &history.entries {
            *type_counts.entry(format!("{:?}", entry.content_type)).or_insert(0) += 1;
            total_size += entry.size_bytes;
            if entry.size_bytes > largest_entry {
                largest_entry = entry.size_bytes;
            }
        }

        println!("📊 Clipboard Statistics");
        println!("========================");
        println!("Total entries: {}", history.entries.len());
        println!("Total size: {} bytes ({:.2} KB)", total_size, total_size as f64 / 1024.0);
        println!("Largest entry: {} bytes", largest_entry);

        if let Some(created) = history.metadata.created_at {
            println!("History created: {}", created.format("%Y-%m-%d %H:%M:%S"));
        }

        if let Some(updated) = history.metadata.last_updated {
            println!("Last updated: {}", updated.format("%Y-%m-%d %H:%M:%S"));
        }

        println!("\nContent types:");
        for (content_type, count) in type_counts {
            println!("  {}: {}", content_type, count);
        }

        Ok(())
    }

    fn watch_clipboard(&mut self, max_entries: usize) -> Result<()> {
        println!("👀 Watching clipboard for changes... Press Ctrl+C to stop");

        let mut last_hash = String::new();

        loop {
            // Check for text content
            if let Ok(text) = self.clipboard.get_text() {
                let current_hash = self.calculate_hash(&text);

                if current_hash != last_hash && !text.trim().is_empty() {
                    let entry = ClipboardEntry {
                        id: Uuid::new_v4().to_string(),
                        timestamp: Utc::now(),
                        content_type: ContentType::Text,
                        content: text.clone(),
                        content_hash: current_hash.clone(),
                        size_bytes: text.len(),
                        source_app: None,
                    };

                    self.add_to_history(entry, max_entries)?;
                    println!("📋 Saved: {} bytes of text", text.len());
                    last_hash = current_hash;
                }
            }

            // Check for image content
            if let Ok(image) = self.clipboard.get_image() {
                let image_content = format!("{:?}", image.bytes);
                let current_hash = self.calculate_hash(&image_content);

                if current_hash != last_hash {
                    let entry = ClipboardEntry {
                        id: Uuid::new_v4().to_string(),
                        timestamp: Utc::now(),
                        content_type: ContentType::Image,
                        content: general_purpose::STANDARD.encode(&image.bytes),
                        content_hash: current_hash.clone(),
                        size_bytes: image.bytes.len(),
                        source_app: None,
                    };

                    self.add_to_history(entry, max_entries)?;
                    println!("🖼️  Saved: {}x{} image ({} bytes)",
                        image.width, image.height, image.bytes.len());
                    last_hash = current_hash;
                }
            }

            std::thread::sleep(std::time::Duration::from_millis(500));
        }
    }
}

fn main() -> Result<()> {
    let cli = Cli::parse();
    let mut manager = ClipboardManager::new()?;

    match cli.command {
        Commands::Get { format } => {
            manager.get_current_content(&format)?;
        }
        Commands::Set { text } => {
            manager.set_content(&text)?;
        }
        Commands::Watch { max_entries } => {
            manager.watch_clipboard(max_entries)?;
        }
        Commands::History { limit, format } => {
            manager.show_history(limit, &format)?;
        }
        Commands::Search { query, case_sensitive } => {
            manager.search_history(&query, case_sensitive)?;
        }
        Commands::Export { output, format } => {
            manager.export_history(&output, &format)?;
        }
        Commands::Import { input } => {
            manager.import_history(&input)?;
        }
        Commands::Clear => {
            manager.clear_history()?;
        }
        Commands::Stats => {
            manager.show_stats()?;
        }
    }

    Ok(())
}
