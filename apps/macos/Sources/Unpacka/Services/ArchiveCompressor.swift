import Foundation

struct ArchiveCompressor {
    func compress(sourceURLs: [URL], outputURL: URL, format: ArchiveFormat) async throws {
        guard let firstSource = sourceURLs.first else {
            throw ExtractError.outputUnavailable("没有选择要压缩的文件")
        }

        try FileManager.default.createDirectory(
            at: outputURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )

        switch format {
        case .zip:
            try await runInParent(command: "/usr/bin/zip", arguments: ["-qry", outputURL.path] + sourceURLs.map(\.lastPathComponent), parent: firstSource.deletingLastPathComponent())
        case .tar:
            try await runInParent(command: "/usr/bin/tar", arguments: ["-cf", outputURL.path] + sourceURLs.map(\.lastPathComponent), parent: firstSource.deletingLastPathComponent())
        case .gzip:
            if sourceURLs.count == 1, !isDirectory(firstSource) {
                try await runStreamingInput(command: "/usr/bin/gzip", arguments: ["-c", firstSource.path], outputURL: outputURL)
            } else {
                try await runInParent(command: "/usr/bin/tar", arguments: ["-czf", outputURL.path] + sourceURLs.map(\.lastPathComponent), parent: firstSource.deletingLastPathComponent())
            }
        case .bzip2:
            if sourceURLs.count == 1, !isDirectory(firstSource) {
                try await runStreamingInput(command: "/usr/bin/bzip2", arguments: ["-c", firstSource.path], outputURL: outputURL)
            } else {
                try await runInParent(command: "/usr/bin/tar", arguments: ["-cjf", outputURL.path] + sourceURLs.map(\.lastPathComponent), parent: firstSource.deletingLastPathComponent())
            }
        case .xz:
            if sourceURLs.count == 1, !isDirectory(firstSource) {
                try await runStreamingInput(command: "/usr/bin/env", arguments: ["xz", "-c", firstSource.path], outputURL: outputURL)
            } else {
                try await runInParent(command: "/usr/bin/tar", arguments: ["-cJf", outputURL.path] + sourceURLs.map(\.lastPathComponent), parent: firstSource.deletingLastPathComponent())
            }
        case .sevenZip:
            let tool = try sevenZipTool()
            try await runInParent(command: tool, arguments: ["a", "-t7z", outputURL.path] + sourceURLs.map(\.lastPathComponent), parent: firstSource.deletingLastPathComponent())
        case .rar:
            if let rar = firstExistingTool(["/opt/homebrew/bin/rar", "/usr/local/bin/rar", "/usr/bin/rar"]) {
                try await runInParent(command: rar, arguments: ["a", "-r", outputURL.path] + sourceURLs.map(\.lastPathComponent), parent: firstSource.deletingLastPathComponent())
            } else {
                throw ExtractError.missingTool("rar")
            }
        case .unknown:
            throw ExtractError.unsupportedFormat(format)
        }
    }

    private func isDirectory(_ url: URL) -> Bool {
        var isDirectory: ObjCBool = false
        FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory)
        return isDirectory.boolValue
    }

    private func runInParent(command: String, arguments: [String], parent: URL) async throws {
        try await Task.detached(priority: .userInitiated) {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: command)
            process.arguments = arguments
            process.currentDirectoryURL = parent

            let pipe = Pipe()
            process.standardError = pipe
            process.standardOutput = pipe

            try process.run()
            process.waitUntilExit()

            guard process.terminationStatus == 0 else {
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                let message = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
                throw ExtractError.commandFailed(message?.isEmpty == false ? message! : "压缩命令执行失败")
            }
        }.value
    }

    private func runStreamingInput(command: String, arguments: [String], outputURL: URL) async throws {
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
                throw ExtractError.commandFailed(message?.isEmpty == false ? message! : "压缩命令执行失败")
            }
        }.value
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
}

