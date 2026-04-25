#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum EncodingPolicy {
    Automatic,
    Utf8,
    Gbk,
    ShiftJis,
    Big5,
}

pub fn looks_mojibake(name: &str) -> bool {
    name.contains('\u{fffd}') || name.contains('√') || name.contains('µ')
}

