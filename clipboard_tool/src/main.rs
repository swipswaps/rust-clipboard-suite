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
