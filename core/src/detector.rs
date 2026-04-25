#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ArchiveFormat {
    Zip,
    SevenZip,
    Rar,
    Tar,
    Gzip,
    Xz,
    Unknown,
}

pub fn detect_by_magic_bytes(bytes: &[u8]) -> ArchiveFormat {
    if bytes.starts_with(&[0x50, 0x4b]) {
        return ArchiveFormat::Zip;
    }
    if bytes.starts_with(&[0x37, 0x7a, 0xbc, 0xaf, 0x27, 0x1c]) {
        return ArchiveFormat::SevenZip;
    }
    if bytes.starts_with(b"Rar!") {
        return ArchiveFormat::Rar;
    }
    if bytes.starts_with(&[0x1f, 0x8b]) {
        return ArchiveFormat::Gzip;
    }
    if bytes.starts_with(&[0xfd, 0x37, 0x7a, 0x58, 0x5a, 0x00]) {
        return ArchiveFormat::Xz;
    }
    if bytes.len() >= 262 && &bytes[257..262] == b"ustar" {
        return ArchiveFormat::Tar;
    }
    ArchiveFormat::Unknown
}

