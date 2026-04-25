import Foundation

enum ExtractError: LocalizedError {
    case unsupportedFormat(ArchiveFormat)
    case missingTool(String)
    case outputUnavailable(String)
    case commandFailed(String)

    var errorDescription: String? {
        switch self {
        case .unsupportedFormat(let format):
            "\(format.displayName) 当前环境暂不可用"
        case .missingTool(let tool):
            "缺少命令行工具：\(tool)"
        case .outputUnavailable(let message):
            message
        case .commandFailed(let message):
            message
        }
    }
}

struct ArchiveExtractor {
    func extract(sourceURL: URL, outputURL: URL, format: ArchiveFormat) async throws {
        try FileManager.default.createDirectory(at: outputURL, withIntermediateDirectories: true)

        switch format {
        case .zip:
            try await run(command: "/usr/bin/ditto", arguments: ["-x", "-k", sourceURL.path, outputURL.path])
        case .tar:
            try await run(command: "/usr/bin/tar", arguments: ["-xf", sourceURL.path, "-C", outputURL.path])
        case .gzip:
            if sourceURL.lastPathComponent.lowercased().hasSuffix(".tar.gz") || sourceURL.lastPathComponent.lowercased().hasSuffix(".tgz") {
                try await run(command: "/usr/bin/tar", arguments: ["-xzf", sourceURL.path, "-C", outputURL.path])
            } else {
                let destination = outputURL.appendingPathComponent(sourceURL.deletingPathExtension().lastPathComponent)
                try await runStreamingOutput(command: "/usr/bin/gzip", arguments: ["-dc", sourceURL.path], outputURL: destination)
            }
        case .bzip2:
            if sourceURL.lastPathComponent.lowercased().hasSuffix(".tar.bz2") || sourceURL.lastPathComponent.lowercased().hasSuffix(".tbz2") {
                try await run(command: "/usr/bin/tar", arguments: ["-xjf", sourceURL.path, "-C", outputURL.path])
            } else {
                let destination = outputURL.appendingPathComponent(sourceURL.deletingPathExtension().lastPathComponent)
                try await runStreamingOutput(command: "/usr/bin/bzip2", arguments: ["-dc", sourceURL.path], outputURL: destination)
            }
        case .xz:
            if sourceURL.lastPathComponent.lowercased().hasSuffix(".tar.xz") || sourceURL.lastPathComponent.lowercased().hasSuffix(".txz") {
                try await run(command: "/usr/bin/tar", arguments: ["-xJf", sourceURL.path, "-C", outputURL.path])
            } else {
                let destination = outputURL.appendingPathComponent(sourceURL.deletingPathExtension().lastPathComponent)
                try await runStreamingOutput(command: "/usr/bin/env", arguments: ["xz", "-dc", sourceURL.path], outputURL: destination)
            }
        case .sevenZip:
            let tool = try sevenZipTool()
            try await run(command: tool, arguments: ["x", "-y", "-o\(outputURL.path)", sourceURL.path])
        case .rar:
            if let unrar = firstExistingTool(["/usr/bin/unrar", "/opt/homebrew/bin/unrar", "/usr/local/bin/unrar"]) {
                try await run(command: unrar, arguments: ["x", "-y", sourceURL.path, outputURL.path])
            } else {
                let tool = try sevenZipTool()
                try await run(command: tool, arguments: ["x", "-y", "-o\(outputURL.path)", sourceURL.path])
            }
        case .unknown:
            throw ExtractError.unsupportedFormat(format)
        }
    }

    private func sevenZipTool() throws -> String {
        if let tool = firstExistingTool(["/opt/homebrew/bin/7zz", "/usr/local/bin/7zz", "/opt/homebrew/bin/7z", "/usr/local/bin/7z", "/usr/bin/7zz", "/usr/bin/7z"]) {
            return tool
        }
        throw ExtractError.missingTool("7zz 或 7z")
    }

    private func firstExistingTool(_ candidates: [String]) -> String? {
        candidates.first { FileManager.default.isExecutableFile(atPath: $0) }
    }

    private func run(command: String, arguments: [String]) async throws {
        try await Task.detached(priority: .userInitiated) {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: command)
            process.arguments = arguments

            let pipe = Pipe()
            process.standardError = pipe
            process.standardOutput = pipe

            try process.run()
            process.waitUntilExit()

            guard process.terminationStatus == 0 else {
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                let message = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
                throw ExtractError.commandFailed(message?.isEmpty == false ? message! : "解压命令执行失败")
            }
        }.value
    }

    private func runStreamingOutput(command: String, arguments: [String], outputURL: URL) async throws {
        try await Task.detached(priority: .userInitiated) {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: command)
            process.arguments = arguments

            _ = FileManager.default.createFile(atPath: outputURL.path, contents: nil)
            let outputHandle = try FileHandle(forWritingTo: outputURL)
            defer {
                try? outputHandle.close()
            }

            let errorPipe = Pipe()
            process.standardOutput = outputHandle
            process.standardError = errorPipe

            try process.run()
            process.waitUntilExit()

            guard process.terminationStatus == 0 else {
                let data = errorPipe.fileHandleForReading.readDataToEndOfFile()
                let message = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
                throw ExtractError.commandFailed(message?.isEmpty == false ? message! : "解压命令执行失败")
            }
        }.value
    }
}
