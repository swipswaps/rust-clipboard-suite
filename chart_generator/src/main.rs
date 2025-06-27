use anyhow::{Result, Context};
use arboard::Clipboard;
use chrono::{DateTime, Utc, NaiveDate};
use clap::{Parser, Subcommand};
use plotters::prelude::*;
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::fs;
use std::path::PathBuf;
use uuid::Uuid;

#[derive(Parser)]
#[command(name = "chart_generator")]
#[command(about = "Automatic chart generation from clipboard and data")]
struct Cli {
    #[command(subcommand)]
    command: Commands,
}

#[derive(Subcommand)]
enum Commands {
    /// Generate GANTT chart from clipboard data
    Gantt {
        /// Output file path
        #[arg(short, long, default_value = "gantt_chart.svg")]
        output: PathBuf,
        /// Chart title
        #[arg(short, long, default_value = "Project Timeline")]
        title: String,
    },
    /// Generate pie chart from clipboard data
    Pie {
        /// Output file path
        #[arg(short, long, default_value = "pie_chart.svg")]
        output: PathBuf,
        /// Chart title
        #[arg(short, long, default_value = "Data Distribution")]
        title: String,
    },
    /// Generate word cloud from clipboard text
    WordCloud {
        /// Output file path
        #[arg(short, long, default_value = "wordcloud.svg")]
        output: PathBuf,
        /// Maximum words to include
        #[arg(short, long, default_value = "50")]
        max_words: usize,
    },
    /// Generate bar chart from clipboard data
    Bar {
        /// Output file path
        #[arg(short, long, default_value = "bar_chart.svg")]
        output: PathBuf,
        /// Chart title
        #[arg(short, long, default_value = "Data Comparison")]
        title: String,
    },
    /// Generate line chart from clipboard data
    Line {
        /// Output file path
        #[arg(short, long, default_value = "line_chart.svg")]
        output: PathBuf,
        /// Chart title
        #[arg(short, long, default_value = "Trend Analysis")]
        title: String,
    },
    /// Auto-detect data type and generate appropriate chart
    Auto {
        /// Output directory
        #[arg(short, long, default_value = "charts")]
        output_dir: PathBuf,
    },
    /// Generate dashboard with multiple charts
    Dashboard {
        /// Output file path
        #[arg(short, long, default_value = "dashboard.html")]
        output: PathBuf,
    },
}

#[derive(Serialize, Deserialize, Debug)]
struct TaskData {
    name: String,
    start_date: String,
    end_date: String,
    progress: f32,
    category: Option<String>,
}

#[derive(Serialize, Deserialize, Debug)]
struct DataPoint {
    label: String,
    value: f64,
    category: Option<String>,
}

struct ChartGenerator {
    clipboard: Clipboard,
    output_dir: PathBuf,
}

impl ChartGenerator {
    fn new() -> Result<Self> {
        let clipboard = Clipboard::new().context("Failed to initialize clipboard")?;
        let output_dir = dirs::desktop_dir()
            .unwrap_or_else(|| PathBuf::from("."))
            .join("clipboard_charts");
        
        fs::create_dir_all(&output_dir).context("Failed to create output directory")?;
        
        Ok(Self {
            clipboard,
            output_dir,
        })
    }

    fn get_clipboard_data(&mut self) -> Result<String> {
        self.clipboard.get_text()
            .context("Failed to get clipboard content")
    }

    fn parse_csv_data(&self, content: &str) -> Result<Vec<DataPoint>> {
        let mut reader = csv::Reader::from_reader(content.as_bytes());
        let mut data = Vec::new();
        
        for result in reader.records() {
            let record = result?;
            if record.len() >= 2 {
                let label = record[0].to_string();
                let value: f64 = record[1].parse().unwrap_or(0.0);
                let category = if record.len() > 2 { Some(record[2].to_string()) } else { None };
                
                data.push(DataPoint { label, value, category });
            }
        }
        
        Ok(data)
    }

    fn parse_json_data(&self, content: &str) -> Result<Vec<DataPoint>> {
        let json_value: serde_json::Value = serde_json::from_str(content)?;
        let mut data = Vec::new();
        
        match json_value {
            serde_json::Value::Array(arr) => {
                for item in arr {
                    if let Some(obj) = item.as_object() {
                        let label = obj.get("name").or(obj.get("label"))
                            .and_then(|v| v.as_str())
                            .unwrap_or("Unknown").to_string();
                        let value = obj.get("value").or(obj.get("amount"))
                            .and_then(|v| v.as_f64())
                            .unwrap_or(0.0);
                        let category = obj.get("category")
                            .and_then(|v| v.as_str())
                            .map(|s| s.to_string());
                        
                        data.push(DataPoint { label, value, category });
                    }
                }
            }
            serde_json::Value::Object(obj) => {
                for (key, value) in obj {
                    let val = value.as_f64().unwrap_or(0.0);
                    data.push(DataPoint { 
                        label: key, 
                        value: val, 
                        category: None 
                    });
                }
            }
            _ => return Err(anyhow::anyhow!("Unsupported JSON format")),
        }
        
        Ok(data)
    }

    fn parse_gantt_data(&self, content: &str) -> Result<Vec<TaskData>> {
        let mut tasks = Vec::new();
        
        // Try JSON first
        if let Ok(json_value) = serde_json::from_str::<serde_json::Value>(content) {
            if let Some(arr) = json_value.as_array() {
                for item in arr {
                    if let Some(obj) = item.as_object() {
                        let name = obj.get("name").or(obj.get("task"))
                            .and_then(|v| v.as_str())
                            .unwrap_or("Task").to_string();
                        let start_date = obj.get("start").or(obj.get("start_date"))
                            .and_then(|v| v.as_str())
                            .unwrap_or("2024-01-01").to_string();
                        let end_date = obj.get("end").or(obj.get("end_date"))
                            .and_then(|v| v.as_str())
                            .unwrap_or("2024-01-31").to_string();
                        let progress = obj.get("progress")
                            .and_then(|v| v.as_f64())
                            .unwrap_or(0.0) as f32;
                        let category = obj.get("category")
                            .and_then(|v| v.as_str())
                            .map(|s| s.to_string());
                        
                        tasks.push(TaskData { name, start_date, end_date, progress, category });
                    }
                }
            }
        } else {
            // Try CSV format
            let mut reader = csv::Reader::from_reader(content.as_bytes());
            for result in reader.records() {
                let record = result?;
                if record.len() >= 3 {
                    let name = record[0].to_string();
                    let start_date = record[1].to_string();
                    let end_date = record[2].to_string();
                    let progress = if record.len() > 3 { 
                        record[3].parse().unwrap_or(0.0) 
                    } else { 
                        0.0 
                    };
                    let category = if record.len() > 4 { 
                        Some(record[4].to_string()) 
                    } else { 
                        None 
                    };
                    
                    tasks.push(TaskData { name, start_date, end_date, progress, category });
                }
            }
        }
        
        Ok(tasks)
    }

    fn generate_pie_chart(&self, data: Vec<DataPoint>, output: &PathBuf, title: &str) -> Result<()> {
        let root = SVGBackend::new(output, (800, 600)).into_drawing_area();
        root.fill(&WHITE)?;
        
        let mut chart = ChartBuilder::on(&root)
            .caption(title, ("Arial", 40))
            .margin(20)
            .build_cartesian_2d(-1.2f32..1.2f32, -1.2f32..1.2f32)?;
        
        let total: f64 = data.iter().map(|d| d.value).sum();
        let mut angle = 0.0;
        
        let colors = [&RED, &BLUE, &GREEN, &YELLOW, &MAGENTA, &CYAN];
        
        for (i, point) in data.iter().enumerate() {
            let slice_angle = (point.value / total) * 2.0 * std::f64::consts::PI;
            let color = colors[i % colors.len()];
            
            // Draw pie slice
            let points: Vec<(f32, f32)> = (0..=20)
                .map(|j| {
                    let a = angle + (j as f64 / 20.0) * slice_angle;
                    (a.cos() as f32, a.sin() as f32)
                })
                .collect();
            
            chart.draw_series(std::iter::once(Polygon::new(
                std::iter::once((0.0f32, 0.0f32)).chain(points.iter().cloned()),
                color.filled(),
            )))?;
            
            // Add label
            let label_angle = angle + slice_angle / 2.0;
            let label_x = (label_angle.cos() * 0.7) as f32;
            let label_y = (label_angle.sin() * 0.7) as f32;
            
            chart.draw_series(std::iter::once(Text::new(
                format!("{}: {:.1}%", point.label, (point.value / total) * 100.0),
                (label_x, label_y),
                ("Arial", 12),
            )))?;
            
            angle += slice_angle;
        }
        
        root.present()?;
        println!("✅ Pie chart generated: {}", output.display());
        Ok(())
    }

    fn generate_bar_chart(&self, data: Vec<DataPoint>, output: &PathBuf, title: &str) -> Result<()> {
        let root = SVGBackend::new(output, (800, 600)).into_drawing_area();
        root.fill(&WHITE)?;
        
        let max_value = data.iter().map(|d| d.value).fold(0.0, f64::max);
        
        let mut chart = ChartBuilder::on(&root)
            .caption(title, ("Arial", 40))
            .margin(20)
            .x_label_area_size(60)
            .y_label_area_size(60)
            .build_cartesian_2d(0f32..(data.len() as f32), 0f64..max_value * 1.1)?;
        
        chart.configure_mesh().draw()?;
        
        chart.draw_series(
            data.iter().enumerate().map(|(i, point)| {
                Rectangle::new([(i as f32, 0.0), (i as f32 + 0.8, point.value)], BLUE.filled())
            })
        )?;
        
        // Add labels
        for (i, point) in data.iter().enumerate() {
            chart.draw_series(std::iter::once(Text::new(
                &point.label,
                (i as f32 + 0.4, -max_value * 0.05),
                ("Arial", 12).into_font().transform(FontTransform::Rotate90),
            )))?;
        }
        
        root.present()?;
        println!("✅ Bar chart generated: {}", output.display());
        Ok(())
    }

    fn generate_gantt_chart(&self, tasks: Vec<TaskData>, output: &PathBuf, title: &str) -> Result<()> {
        let root = SVGBackend::new(output, (1200, 600)).into_drawing_area();
        root.fill(&WHITE)?;

        let mut chart = ChartBuilder::on(&root)
            .caption(title, ("Arial", 40))
            .margin(20)
            .x_label_area_size(60)
            .y_label_area_size(150)
            .build_cartesian_2d(
                NaiveDate::from_ymd_opt(2024, 1, 1).unwrap()..NaiveDate::from_ymd_opt(2024, 12, 31).unwrap(),
                0f32..(tasks.len() as f32)
            )?;

        chart.configure_mesh().draw()?;

        for (i, task) in tasks.iter().enumerate() {
            let start = NaiveDate::parse_from_str(&task.start_date, "%Y-%m-%d")
                .unwrap_or_else(|_| NaiveDate::from_ymd_opt(2024, 1, 1).unwrap());
            let end = NaiveDate::parse_from_str(&task.end_date, "%Y-%m-%d")
                .unwrap_or_else(|_| NaiveDate::from_ymd_opt(2024, 1, 31).unwrap());

            // Draw task bar
            chart.draw_series(std::iter::once(Rectangle::new(
                [(start, i as f32), (end, i as f32 + 0.8)],
                BLUE.filled(),
            )))?;

            // Draw progress bar
            let progress_end = start + chrono::Duration::days(
                ((end - start).num_days() as f32 * task.progress) as i64
            );
            chart.draw_series(std::iter::once(Rectangle::new(
                [(start, i as f32), (progress_end, i as f32 + 0.8)],
                GREEN.filled(),
            )))?;

            // Add task name
            chart.draw_series(std::iter::once(Text::new(
                &task.name,
                (start, i as f32 + 0.4),
                ("Arial", 12),
            )))?;
        }

        root.present()?;
        println!("✅ GANTT chart generated: {}", output.display());
        Ok(())
    }

    fn generate_word_cloud(&self, text: &str, output: &PathBuf, max_words: usize) -> Result<()> {
        // Simple word frequency analysis
        let words: HashMap<String, usize> = text
            .to_lowercase()
            .split_whitespace()
            .filter(|word| word.len() > 3)
            .filter(|word| !["this", "that", "with", "have", "will", "from", "they", "been", "were", "said", "each", "which", "their", "time", "would", "there", "could", "other", "more", "very", "what", "know", "just", "first", "into", "over", "think", "also", "your", "work", "life", "only", "can", "still", "should", "after", "being", "now", "made", "before", "here", "through", "when", "where", "much", "some", "these", "many", "then", "them", "well", "were"].contains(word))
            .fold(HashMap::new(), |mut acc, word| {
                *acc.entry(word.to_string()).or_insert(0) += 1;
                acc
            });

        let mut word_vec: Vec<_> = words.into_iter().collect();
        word_vec.sort_by(|a, b| b.1.cmp(&a.1));
        word_vec.truncate(max_words);

        let root = SVGBackend::new(output, (800, 600)).into_drawing_area();
        root.fill(&WHITE)?;

        let mut chart = ChartBuilder::on(&root)
            .caption("Word Cloud", ("Arial", 40))
            .margin(20)
            .build_cartesian_2d(0f32..800f32, 0f32..600f32)?;

        // Simple word cloud layout
        let mut x = 50.0;
        let mut y = 100.0;

        for (word, count) in word_vec.iter().take(max_words) {
            let font_size = (12 + (count * 2).min(48)) as i32;

            chart.draw_series(std::iter::once(Text::new(
                word,
                (x, y),
                ("Arial", font_size),
            )))?;

            x += (word.len() as f32 * font_size as f32 * 0.6) + 20.0;
            if x > 700.0 {
                x = 50.0;
                y += font_size as f32 + 10.0;
            }
        }

        root.present()?;
        println!("✅ Word cloud generated: {}", output.display());
        Ok(())
    }

    fn auto_detect_and_generate(&mut self, output_dir: &PathBuf) -> Result<()> {
        let content = self.get_clipboard_data()?;

        fs::create_dir_all(output_dir)?;

        // Try to detect data format and generate appropriate charts
        if content.trim().starts_with('[') || content.trim().starts_with('{') {
            // JSON data
            if let Ok(data) = self.parse_json_data(&content) {
                let pie_output = output_dir.join("auto_pie_chart.svg");
                let bar_output = output_dir.join("auto_bar_chart.svg");

                self.generate_pie_chart(data.clone(), &pie_output, "Auto-Generated Pie Chart")?;
                self.generate_bar_chart(data, &bar_output, "Auto-Generated Bar Chart")?;
            }

            if let Ok(tasks) = self.parse_gantt_data(&content) {
                let gantt_output = output_dir.join("auto_gantt_chart.svg");
                self.generate_gantt_chart(tasks, &gantt_output, "Auto-Generated GANTT Chart")?;
            }
        } else if content.contains(',') && content.lines().count() > 1 {
            // CSV data
            if let Ok(data) = self.parse_csv_data(&content) {
                let pie_output = output_dir.join("auto_pie_chart.svg");
                let bar_output = output_dir.join("auto_bar_chart.svg");

                self.generate_pie_chart(data.clone(), &pie_output, "Auto-Generated Pie Chart")?;
                self.generate_bar_chart(data, &bar_output, "Auto-Generated Bar Chart")?;
            }
        } else {
            // Text data - generate word cloud
            let wordcloud_output = output_dir.join("auto_wordcloud.svg");
            self.generate_word_cloud(&content, &wordcloud_output, 50)?;
        }

        println!("✅ Auto-generated charts in: {}", output_dir.display());
        Ok(())
    }

    fn generate_dashboard(&mut self, output: &PathBuf) -> Result<()> {
        let content = self.get_clipboard_data()?;

        // Generate multiple charts
        let chart_dir = output.parent().unwrap_or(&PathBuf::from(".")).join("dashboard_charts");
        fs::create_dir_all(&chart_dir)?;

        self.auto_detect_and_generate(&chart_dir)?;

        // Create HTML dashboard
        let html_content = format!(r#"
<!DOCTYPE html>
<html>
<head>
    <title>Clipboard Data Dashboard</title>
    <style>
        body {{ font-family: Arial, sans-serif; margin: 20px; }}
        .chart {{ margin: 20px; text-align: center; }}
        .chart img {{ max-width: 100%; height: auto; border: 1px solid #ddd; }}
        .grid {{ display: grid; grid-template-columns: repeat(auto-fit, minmax(400px, 1fr)); gap: 20px; }}
        h1 {{ text-align: center; color: #333; }}
        .timestamp {{ text-align: center; color: #666; font-size: 14px; }}
    </style>
</head>
<body>
    <h1>📊 Clipboard Data Dashboard</h1>
    <div class="timestamp">Generated: {}</div>

    <div class="grid">
        <div class="chart">
            <h3>📈 Bar Chart</h3>
            <img src="dashboard_charts/auto_bar_chart.svg" alt="Bar Chart" />
        </div>

        <div class="chart">
            <h3>🥧 Pie Chart</h3>
            <img src="dashboard_charts/auto_pie_chart.svg" alt="Pie Chart" />
        </div>

        <div class="chart">
            <h3>📅 GANTT Chart</h3>
            <img src="dashboard_charts/auto_gantt_chart.svg" alt="GANTT Chart" />
        </div>

        <div class="chart">
            <h3>☁️ Word Cloud</h3>
            <img src="dashboard_charts/auto_wordcloud.svg" alt="Word Cloud" />
        </div>
    </div>

    <div style="margin-top: 40px; padding: 20px; background: #f5f5f5; border-radius: 5px;">
        <h3>📋 Source Data</h3>
        <pre style="white-space: pre-wrap; word-wrap: break-word;">{}</pre>
    </div>
</body>
</html>
        "#, Utc::now().format("%Y-%m-%d %H:%M:%S UTC"), content);

        fs::write(output, html_content)?;
        println!("✅ Dashboard generated: {}", output.display());
        Ok(())
    }
}

fn main() -> Result<()> {
    let cli = Cli::parse();
    let mut generator = ChartGenerator::new()?;

    match cli.command {
        Commands::Pie { output, title } => {
            let content = generator.get_clipboard_data()?;
            let data = if content.trim().starts_with('[') || content.trim().starts_with('{') {
                generator.parse_json_data(&content)?
            } else {
                generator.parse_csv_data(&content)?
            };
            generator.generate_pie_chart(data, &output, &title)?;
        }
        Commands::Bar { output, title } => {
            let content = generator.get_clipboard_data()?;
            let data = if content.trim().starts_with('[') || content.trim().starts_with('{') {
                generator.parse_json_data(&content)?
            } else {
                generator.parse_csv_data(&content)?
            };
            generator.generate_bar_chart(data, &output, &title)?;
        }
        Commands::Gantt { output, title } => {
            let content = generator.get_clipboard_data()?;
            let tasks = generator.parse_gantt_data(&content)?;
            generator.generate_gantt_chart(tasks, &output, &title)?;
        }
        Commands::WordCloud { output, max_words } => {
            let content = generator.get_clipboard_data()?;
            generator.generate_word_cloud(&content, &output, max_words)?;
        }
        Commands::Line { output, title } => {
            // For now, use bar chart logic for line charts
            let content = generator.get_clipboard_data()?;
            let data = if content.trim().starts_with('[') || content.trim().starts_with('{') {
                generator.parse_json_data(&content)?
            } else {
                generator.parse_csv_data(&content)?
            };
            generator.generate_bar_chart(data, &output, &title)?;
        }
        Commands::Auto { output_dir } => {
            generator.auto_detect_and_generate(&output_dir)?;
        }
        Commands::Dashboard { output } => {
            generator.generate_dashboard(&output)?;
        }
    }

    Ok(())
}