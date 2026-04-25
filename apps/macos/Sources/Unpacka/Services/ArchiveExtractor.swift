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
    private let toolResolver = BackendToolResolver()

    func extract(sourceURL: URL, outputURL: URL, format: ArchiveFormat, password: String? = nil) async throws {
        try FileManager.default.createDirectory(at: outputURL, withIntermediateDirectories: true)
        let passwordArguments = password.map { $0.isEmpty ? [] : ["-p\($0)"] } ?? []

        switch format {
        case .zip:
            if passwordArguments.isEmpty {
                try await run(command: "/usr/bin/ditto", arguments: ["-x", "-k", sourceURL.path, outputURL.path])
            } else {
                let tool = try toolResolver.sevenZipTool()
                try await run(command: tool, arguments: ["x", "-y"] + passwordArguments + ["-o\(outputURL.path)", sourceURL.path])
            }
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
            let tool = try toolResolver.sevenZipTool()
            try await run(command: tool, arguments: ["x", "-y"] + passwordArguments + ["-o\(outputURL.path)", sourceURL.path])
        case .rar:
            if let unrar = toolResolver.unrarTool() {
                let unrarPassword = password.map { $0.isEmpty ? [] : ["-p\($0)"] } ?? []
                try await run(command: unrar, arguments: ["x", "-y"] + unrarPassword + [sourceURL.path, outputURL.path])
            } else {
                let tool = try toolResolver.sevenZipTool()
                try await run(command: tool, arguments: ["x", "-y"] + passwordArguments + ["-o\(outputURL.path)", sourceURL.path])
            }
        case .unknown:
            throw ExtractError.unsupportedFormat(format)
        }
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
