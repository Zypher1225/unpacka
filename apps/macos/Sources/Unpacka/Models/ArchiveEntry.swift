import Foundation

struct ArchiveEntry: Identifiable, Equatable, Sendable {
    let id = UUID()
    var path: String
    var size: Int64?
    var modifiedAt: String?
    var isDirectory: Bool
    var isEncrypted: Bool

    var displaySize: String {
        guard let size else {
            return "-"
        }
        return ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }
}

struct OpenedArchive: Equatable, Sendable {
    var url: URL
    var format: ArchiveFormat
    var entries: [ArchiveEntry]

    var fileCount: Int {
        entries.filter { !$0.isDirectory }.count
    }

    var directoryCount: Int {
        entries.filter(\.isDirectory).count
    }

    var hasEncryptedEntries: Bool {
        entries.contains(where: \.isEncrypted)
    }
}

struct CompressionDraft: Equatable, Sendable {
    var sourceURLs: [URL]
    var format: ArchiveFormat
    var outputURL: URL
    var password: String
}
