use std::ffi::{c_char, CStr, CString};

use crate::extractor::{extract, ExtractOptions};

#[no_mangle]
pub extern "C" fn unpacka_extract(source: *const c_char, output: *const c_char) -> *mut c_char {
    let source_path = unsafe { c_string_to_string(source) };
    let output_path = unsafe { c_string_to_string(output) };

    let result = match (source_path, output_path) {
        (Some(source_path), Some(output_path)) => extract(ExtractOptions {
            source_path,
            output_path,
            password: None,
            overwrite: false,
        })
        .map(|_| "ok".to_string())
        .unwrap_or_else(|error| error),
        _ => "invalid path".to_string(),
    };

    CString::new(result).unwrap().into_raw()
}

#[no_mangle]
pub extern "C" fn unpacka_string_free(value: *mut c_char) {
    if value.is_null() {
        return;
    }
    unsafe {
        let _ = CString::from_raw(value);
    }
}

unsafe fn c_string_to_string(value: *const c_char) -> Option<String> {
    if value.is_null() {
        return None;
    }
    CStr::from_ptr(value).to_str().ok().map(ToOwned::to_owned)
}

