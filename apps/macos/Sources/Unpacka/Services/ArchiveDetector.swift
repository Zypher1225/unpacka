import Foundation

struct ArchiveDetector {
    func detect(url: URL) -> ArchiveFormat {
        if let format = detectByMagicBytes(url: url), format != .unknown {
            return format
        }
        return detectByExtension(url: url)
    }

    private func detectByExtension(url: URL) -> ArchiveFormat {
        let name = url.lastPathComponent.lowercased()
        if name.hasSuffix(".tar.gz") || name.hasSuffix(".tgz") {
            return .gzip
        }
        if name.hasSuffix(".tar.xz") || name.hasSuffix(".txz") {
            return .xz
        }
        if name.hasSuffix(".tar.bz2") || name.hasSuffix(".tbz2") {
            return .bzip2
        }

        switch url.pathExtension.lowercased() {
        case "zip": return ArchiveFormat.zip
        case "7z": return ArchiveFormat.sevenZip
        case "rar": return ArchiveFormat.rar
        case "tar": return ArchiveFormat.tar
        case "gz": return ArchiveFormat.gzip
        case "bz2": return ArchiveFormat.bzip2
        case "xz": return ArchiveFormat.xz
        default: return ArchiveFormat.unknown
        }
    }

    private func detectByMagicBytes(url: URL) -> ArchiveFormat? {
        guard let handle = try? FileHandle(forReadingFrom: url) else {
            return nil
        }
        defer {
            try? handle.close()
        }

        let data = handle.readData(ofLength: 265)
        let bytes = [UInt8](data)

        if bytes.starts(with: [0x50, 0x4B]) {
            return .zip
        }
        if bytes.starts(with: [0x37, 0x7A, 0xBC, 0xAF, 0x27, 0x1C]) {
            return .sevenZip
        }
        if bytes.starts(with: [0x52, 0x61, 0x72, 0x21]) {
            return .rar
        }
        if bytes.starts(with: [0x1F, 0x8B]) {
            return .gzip
        }
        if bytes.starts(with: [0x42, 0x5A, 0x68]) {
            return .bzip2
        }
        if bytes.starts(with: [0xFD, 0x37, 0x7A, 0x58, 0x5A, 0x00]) {
            return .xz
        }
        if bytes.count >= 262 {
            let marker = bytes[257..<262]
            if Array(marker) == [0x75, 0x73, 0x74, 0x61, 0x72] {
                return .tar
            }
        }

        return nil
    }
}
