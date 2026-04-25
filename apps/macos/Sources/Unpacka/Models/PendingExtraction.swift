import Foundation

struct PendingExtraction: Equatable, Sendable {
    var sourceURL: URL
    var format: ArchiveFormat
    var destinationURL: URL
    var password: String

    var currentDirectoryURL: URL {
        sourceURL.deletingLastPathComponent()
    }
}

