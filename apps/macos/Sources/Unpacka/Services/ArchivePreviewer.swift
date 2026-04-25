import Foundation

struct ArchivePreviewer {
    private let detector = ArchiveDetector()
    private let toolResolver = BackendToolResolver()

    func preview(url: URL) async throws -> OpenedArchive {
        let format = detector.detect(url: url)
        let output = try await run(command: try toolResolver.sevenZipTool(), arguments: ["l", "-slt", url.path])
        let entries = parseSevenZipList(output)
        return OpenedArchive(url: url, format: format, entries: entries)
    }

    private func parseSevenZipList(_ output: String) -> [ArchiveEntry] {
        var entries: [ArchiveEntry] = []
        var current: [String: String] = [:]

        func flush() {
            guard let path = current["Path"], !path.isEmpty else {
                current.removeAll()
                return
            }
            let attributes = current["Attributes"] ?? ""
            let isDirectory = attributes.contains("D")
            let encrypted = (current["Encrypted"] ?? "-").lowercased() == "+"
            let size = Int64(current["Size"] ?? "")
            entries.append(ArchiveEntry(
                path: path,
                size: size,
                modifiedAt: current["Modified"],
                isDirectory: isDirectory,
                isEncrypted: encrypted
            ))
            current.removeAll()
        }

        for line in output.split(separator: "\n", omittingEmptySubsequences: false) {
            let text = String(line)
            if text.isEmpty {
                flush()
                continue
            }
            guard let separator = text.firstIndex(of: "=") else {
                continue
            }
            let key = text[..<separator].trimmingCharacters(in: .whitespaces)
            let value = text[text.index(after: separator)...].trimmingCharacters(in: .whitespaces)
            current[key] = value
        }
        flush()

        return entries.filter { $0.path != "." }
    }

    private func run(command: String, arguments: [String]) async throws -> String {
        try await Task.detached(priority: .userInitiated) {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: command)
            process.arguments = arguments

            let outputPipe = Pipe()
            let errorPipe = Pipe()
            process.standardOutput = outputPipe
            process.standardError = errorPipe

            try process.run()
            process.waitUntilExit()

            guard process.terminationStatus == 0 else {
                let data = errorPipe.fileHandleForReading.readDataToEndOfFile()
                let message = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
                throw ExtractError.commandFailed(message?.isEmpty == false ? message! : "读取压缩包内容失败")
            }

            let data = outputPipe.fileHandleForReading.readDataToEndOfFile()
            return String(data: data, encoding: .utf8) ?? ""
        }.value
    }
}

