import Foundation

struct CompressionDraft: Equatable, Sendable {
    var sourceURLs: [URL]
    var format: ArchiveFormat
    var outputURL: URL
    var isEncrypted: Bool
    var password: String
}
