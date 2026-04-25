import Foundation

enum ArchiveFormat: String, CaseIterable, Sendable {
    case zip
    case sevenZip
    case rar
    case tar
    case gzip
    case bzip2
    case xz
    case unknown

    var displayName: String {
        switch self {
        case .zip: "ZIP"
        case .sevenZip: "7Z"
        case .rar: "RAR"
        case .tar: "TAR"
        case .gzip: "GZ"
        case .bzip2: "BZ2"
        case .xz: "XZ"
        case .unknown: "Unknown"
        }
    }

    var canExtractWithBundledTools: Bool {
        switch self {
        case .zip, .tar, .gzip, .bzip2, .xz:
            true
        case .sevenZip, .rar, .unknown:
            false
        }
    }

    var canCompressWithBundledTools: Bool {
        switch self {
        case .zip, .tar, .gzip, .bzip2, .xz, .sevenZip:
            true
        case .rar, .unknown:
            false
        }
    }
}
