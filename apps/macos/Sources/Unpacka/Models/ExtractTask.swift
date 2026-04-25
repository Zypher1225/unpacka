import Foundation

enum ExtractStatus: Equatable, Sendable {
    case queued
    case running
    case completed
    case failed(String)
}

enum ArchiveOperation: Equatable, Sendable {
    case extract
    case compress

    var label: String {
        switch self {
        case .extract: "解压"
        case .compress: "压缩"
        }
    }
}

struct ExtractTask: Identifiable, Equatable, Sendable {
    let id: UUID
    let sourceURL: URL
    let outputURL: URL
    let format: ArchiveFormat
    let operation: ArchiveOperation
    var status: ExtractStatus
    var progress: Double
    let createdAt: Date

    init(sourceURL: URL, outputURL: URL, format: ArchiveFormat, operation: ArchiveOperation) {
        self.id = UUID()
        self.sourceURL = sourceURL
        self.outputURL = outputURL
        self.format = format
        self.operation = operation
        self.status = .queued
        self.progress = 0
        self.createdAt = Date()
    }
}
