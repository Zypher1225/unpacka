use crate::detector::ArchiveFormat;

#[derive(Debug, Clone)]
pub struct ExtractOptions {
    pub source_path: String,
    pub output_path: String,
    pub password: Option<String>,
    pub overwrite: bool,
}

#[derive(Debug, Clone)]
pub struct ExtractResult {
    pub files_written: u64,
    pub format: ArchiveFormat,
}

pub fn extract(_options: ExtractOptions) -> Result<ExtractResult, String> {
    Err("Rust extraction backend is scaffolded but not implemented yet".to_string())
}

