import AppKit
import Foundation
import UniformTypeIdentifiers

@MainActor
final class ExtractViewModel: ObservableObject {
    @Published var tasks: [ExtractTask] = []
    @Published var isDropTargeted = false
    @Published var outputLocation: OutputLocation = .besideArchive
    @Published var conflictPolicy: ConflictPolicy = .rename
    @Published var encodingPolicy: EncodingPolicy = .automatic
    @Published var performanceMode: PerformanceMode = .automatic
    @Published var compressionFormat: ArchiveFormat = .zip
    @Published var lastMessage: String?

    private let detector = ArchiveDetector()
    private let extractor = ArchiveExtractor()
    private let compressor = ArchiveCompressor()
    private let outputResolver = OutputPathResolver()

    func handleDrop(providers: [NSItemProvider]) -> Bool {
        let fileProviders = providers.filter { $0.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) }
        guard !fileProviders.isEmpty else {
            return false
        }

        for provider in fileProviders {
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { [weak self] item, _ in
                guard let self, let data = item as? Data, let url = URL(dataRepresentation: data, relativeTo: nil) else {
                    return
                }
                Task { @MainActor in
                    self.enqueue(url: url)
                }
            }
        }
        return true
    }

    func enqueue(url: URL) {
        let format = detector.detect(url: url)

        do {
            let outputURL = try outputResolver.defaultOutputURL(
                for: url,
                location: outputLocation,
                conflictPolicy: conflictPolicy
            )
            var task = ExtractTask(sourceURL: url, outputURL: outputURL, format: format, operation: .extract)
            tasks.insert(task, at: 0)
            let taskID = task.id

            task.status = .running
            task.progress = 0.18
            update(taskID: taskID, with: task)

            Task {
                await run(taskID: taskID, sourceURL: url, outputURL: outputURL, format: format)
            }
        } catch {
            lastMessage = error.localizedDescription
        }
    }

    func chooseArchive() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.begin { [weak self] response in
            guard response == .OK else {
                return
            }
            Task { @MainActor in
                panel.urls.forEach { self?.enqueue(url: $0) }
            }
        }
    }

    func chooseFilesToCompress() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = true
        panel.canChooseFiles = true
        panel.begin { [weak self] response in
            guard response == .OK else {
                return
            }
            Task { @MainActor in
                self?.enqueueCompression(urls: panel.urls)
            }
        }
    }

    func enqueueCompression(urls: [URL]) {
        guard let first = urls.first else {
            return
        }

        let outputURL = defaultCompressedOutputURL(for: first, format: compressionFormat)
        var task = ExtractTask(sourceURL: first, outputURL: outputURL, format: compressionFormat, operation: .compress)
        tasks.insert(task, at: 0)
        let taskID = task.id

        task.status = .running
        task.progress = 0.16
        update(taskID: taskID, with: task)

        Task {
            await runCompression(taskID: taskID, sourceURLs: urls, outputURL: outputURL, format: compressionFormat)
        }
    }

    private func run(taskID: UUID, sourceURL: URL, outputURL: URL, format: ArchiveFormat) async {
        do {
            setProgress(taskID: taskID, progress: 0.42)
            try await extractor.extract(sourceURL: sourceURL, outputURL: outputURL, format: format)
            setStatus(taskID: taskID, status: .completed, progress: 1)
            lastMessage = "已解压到 \(outputURL.path)"
        } catch {
            setStatus(taskID: taskID, status: .failed(error.localizedDescription), progress: 1)
            lastMessage = error.localizedDescription
        }
    }

    private func runCompression(taskID: UUID, sourceURLs: [URL], outputURL: URL, format: ArchiveFormat) async {
        do {
            setProgress(taskID: taskID, progress: 0.45)
            try await compressor.compress(sourceURLs: sourceURLs, outputURL: outputURL, format: format)
            setStatus(taskID: taskID, status: .completed, progress: 1)
            lastMessage = "已压缩到 \(outputURL.path)"
        } catch {
            setStatus(taskID: taskID, status: .failed(error.localizedDescription), progress: 1)
            lastMessage = error.localizedDescription
        }
    }

    private func defaultCompressedOutputURL(for sourceURL: URL, format: ArchiveFormat) -> URL {
        let parent = sourceURL.deletingLastPathComponent()
        let stem = sourceURL.deletingPathExtension().lastPathComponent
        let fileName: String
        switch format {
        case .zip: fileName = "\(stem).zip"
        case .sevenZip: fileName = "\(stem).7z"
        case .rar: fileName = "\(stem).rar"
        case .tar: fileName = "\(stem).tar"
        case .gzip: fileName = "\(stem).tar.gz"
        case .bzip2: fileName = "\(stem).tar.bz2"
        case .xz: fileName = "\(stem).tar.xz"
        case .unknown: fileName = "\(stem).archive"
        }
        return parent.appendingPathComponent(fileName)
    }

    private func update(taskID: UUID, with task: ExtractTask) {
        guard let index = tasks.firstIndex(where: { $0.id == taskID }) else {
            return
        }
        tasks[index] = task
    }

    private func setProgress(taskID: UUID, progress: Double) {
        guard let index = tasks.firstIndex(where: { $0.id == taskID }) else {
            return
        }
        tasks[index].progress = progress
    }

    private func setStatus(taskID: UUID, status: ExtractStatus, progress: Double) {
        guard let index = tasks.firstIndex(where: { $0.id == taskID }) else {
            return
        }
        tasks[index].status = status
        tasks[index].progress = progress
    }
}
