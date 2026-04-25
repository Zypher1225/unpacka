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
    @Published var pendingExtraction: PendingExtraction?
    @Published var compressionDraft: CompressionDraft?
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
                    self.open(urls: [url])
                }
            }
        }
        return true
    }

    func open(urls: [URL]) {
        urls.forEach { url in
            if detector.detect(url: url) == .unknown {
                lastMessage = "请选择压缩包文件"
            } else {
                prepareExtraction(url)
            }
        }
    }

    func prepareExtraction(_ url: URL) {
        let format = detector.detect(url: url)
        pendingExtraction = PendingExtraction(
            sourceURL: url,
            format: format,
            destinationURL: url.deletingLastPathComponent(),
            password: ""
        )
        lastMessage = "请选择 \(url.lastPathComponent) 的解压位置"
    }

    func extractToCurrentDirectory() {
        guard var pendingExtraction else {
            return
        }
        pendingExtraction.destinationURL = pendingExtraction.currentDirectoryURL
        self.pendingExtraction = pendingExtraction
        extractPendingArchive()
    }

    func extractPendingArchive() {
        guard let pendingExtraction else {
            return
        }
        enqueueExtraction(
            url: pendingExtraction.sourceURL,
            outputURL: pendingExtraction.destinationURL,
            format: pendingExtraction.format,
            password: pendingExtraction.password
        )
        self.pendingExtraction = nil
    }

    func chooseExtractDestination() {
        guard let pendingExtraction else {
            return
        }
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = true
        panel.allowsMultipleSelection = false
        panel.directoryURL = pendingExtraction.destinationURL
        panel.begin { [weak self] response in
            guard response == .OK, let url = panel.url else {
                return
            }
            Task { @MainActor in
                self?.setPendingExtractionDestination(url)
            }
        }
    }

    func setPendingExtractionPassword(_ password: String) {
        guard var pendingExtraction else {
            return
        }
        pendingExtraction.password = password
        self.pendingExtraction = pendingExtraction
    }

    private func setPendingExtractionDestination(_ url: URL) {
        guard var pendingExtraction else {
            return
        }
        pendingExtraction.destinationURL = url
        self.pendingExtraction = pendingExtraction
    }

    func enqueueExtraction(url: URL, outputURL: URL? = nil, format: ArchiveFormat? = nil, password: String = "") {
        let resolvedFormat = format ?? detector.detect(url: url)

        do {
            let resolvedOutputURL: URL
            if let outputURL {
                resolvedOutputURL = outputURL
            } else {
                resolvedOutputURL = try outputResolver.defaultOutputURL(
                    for: url,
                    location: outputLocation,
                    conflictPolicy: conflictPolicy
                )
            }
            var task = ExtractTask(sourceURL: url, outputURL: resolvedOutputURL, format: resolvedFormat, operation: .extract)
            tasks.insert(task, at: 0)
            let taskID = task.id

            task.status = .running
            task.progress = 0.18
            update(taskID: taskID, with: task)

            Task {
                await run(taskID: taskID, sourceURL: url, outputURL: resolvedOutputURL, format: resolvedFormat, password: password)
            }
        } catch {
            lastMessage = error.localizedDescription
        }
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
                await run(taskID: taskID, sourceURL: url, outputURL: outputURL, format: format, password: "")
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
                self?.open(urls: panel.urls)
            }
        }
    }

    func prepareCompression(urls: [URL]) {
        guard let first = urls.first else {
            return
        }

        let outputURL = defaultCompressedOutputURL(for: first, format: .zip)
        compressionDraft = CompressionDraft(sourceURLs: urls, format: .zip, outputURL: outputURL, password: "")
        lastMessage = "请选择压缩设置"
    }

    func chooseCompressionDestination() {
        guard var draft = compressionDraft else {
            return
        }

        let panel = NSSavePanel()
        panel.canCreateDirectories = true
        panel.nameFieldStringValue = draft.outputURL.lastPathComponent
        panel.directoryURL = draft.outputURL.deletingLastPathComponent()
        panel.begin { [weak self] response in
            guard response == .OK, let url = panel.url else {
                return
            }
            Task { @MainActor in
                draft.outputURL = url
                self?.compressionDraft = draft
            }
        }
    }

    func updateCompressionFormat(_ format: ArchiveFormat) {
        guard var draft = compressionDraft, let first = draft.sourceURLs.first else {
            return
        }
        draft.format = format
        draft.outputURL = defaultCompressedOutputURL(for: first, format: format)
        compressionDraft = draft
    }

    func updateCompressionPassword(_ password: String) {
        guard var draft = compressionDraft else {
            return
        }
        draft.password = password
        compressionDraft = draft
    }

    func enqueueCompressionFromDraft() {
        guard let draft = compressionDraft, let first = draft.sourceURLs.first else {
            return
        }

        var task = ExtractTask(sourceURL: first, outputURL: draft.outputURL, format: draft.format, operation: .compress)
        tasks.insert(task, at: 0)
        let taskID = task.id

        task.status = .running
        task.progress = 0.16
        update(taskID: taskID, with: task)
        compressionDraft = nil

        Task {
            await runCompression(
                taskID: taskID,
                sourceURLs: draft.sourceURLs,
                outputURL: draft.outputURL,
                format: draft.format,
                password: draft.password
            )
        }
    }

    private func runCompression(taskID: UUID, sourceURLs: [URL], outputURL: URL, format: ArchiveFormat, password: String) async {
        do {
            setProgress(taskID: taskID, progress: 0.45)
            try await compressor.compress(sourceURLs: sourceURLs, outputURL: outputURL, format: format, password: password)
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

    private func run(taskID: UUID, sourceURL: URL, outputURL: URL, format: ArchiveFormat, password: String) async {
        do {
            setProgress(taskID: taskID, progress: 0.42)
            try await extractor.extract(sourceURL: sourceURL, outputURL: outputURL, format: format, password: password)
            setStatus(taskID: taskID, status: .completed, progress: 1)
            lastMessage = "已解压到 \(outputURL.path)"
        } catch {
            setStatus(taskID: taskID, status: .failed(error.localizedDescription), progress: 1)
            lastMessage = error.localizedDescription
        }
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
