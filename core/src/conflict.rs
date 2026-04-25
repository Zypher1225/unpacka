use std::path::PathBuf;

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ConflictPolicy {
    Skip,
    Overwrite,
    Rename,
    Ask,
}

pub fn renamed_candidate(path: PathBuf, index: usize) -> PathBuf {
    let parent = path.parent().map(PathBuf::from).unwrap_or_default();
    let stem = path.file_stem().and_then(|s| s.to_str()).unwrap_or("file");
    let extension = path.extension().and_then(|s| s.to_str());

    let name = match extension {
        Some(ext) => format!("{stem} {index}.{ext}"),
        None => format!("{stem} {index}"),
    };
    parent.join(name)
}

