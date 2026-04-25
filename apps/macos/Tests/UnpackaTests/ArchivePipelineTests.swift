import Foundation
import Testing
@testable import Unpacka

@Suite("Archive pipeline")
struct ArchivePipelineTests {
    @Test("detects ZIP magic bytes")
    func detectsZipMagicBytes() throws {
        let sandbox = try Sandbox()
        let archive = sandbox.url.appendingPathComponent("sample.zip")
        try Data([0x50, 0x4B, 0x03, 0x04]).write(to: archive)

        #expect(ArchiveDetector().detect(url: archive) == .zip)
    }

    @Test("extracts ZIP archive")
    func extractsZipArchive() async throws {
        let sandbox = try Sandbox()
        let sourceDirectory = sandbox.url.appendingPathComponent("source", isDirectory: true)
        let outputDirectory = sandbox.url.appendingPathComponent("output", isDirectory: true)
        try FileManager.default.createDirectory(at: sourceDirectory, withIntermediateDirectories: true)
        try "hello unpacka".write(
            to: sourceDirectory.appendingPathComponent("hello.txt"),
            atomically: true,
            encoding: .utf8
        )

        let archive = sandbox.url.appendingPathComponent("sample.zip")
        try run("/usr/bin/zip", arguments: ["-qr", archive.path, "."], currentDirectory: sourceDirectory)

        try await ArchiveExtractor().extract(sourceURL: archive, outputURL: outputDirectory, format: .zip)

        let extracted = try String(contentsOf: outputDirectory.appendingPathComponent("hello.txt"), encoding: .utf8)
        #expect(extracted == "hello unpacka")
    }

    @Test("extracts single-file GZ archive")
    func extractsSingleFileGzipArchive() async throws {
        let sandbox = try Sandbox()
        let source = sandbox.url.appendingPathComponent("note.txt")
        let outputDirectory = sandbox.url.appendingPathComponent("output", isDirectory: true)
        try "gzip works".write(to: source, atomically: true, encoding: .utf8)

        let archive = sandbox.url.appendingPathComponent("note.txt.gz")
        try run("/usr/bin/gzip", arguments: ["-c", source.path], outputURL: archive)

        try await ArchiveExtractor().extract(sourceURL: archive, outputURL: outputDirectory, format: .gzip)

        let extracted = try String(contentsOf: outputDirectory.appendingPathComponent("note.txt"), encoding: .utf8)
        #expect(extracted == "gzip works")
    }

    @Test("compresses ZIP archive")
    func compressesZipArchive() async throws {
        let sandbox = try Sandbox()
        let source = sandbox.url.appendingPathComponent("source", isDirectory: true)
        let output = sandbox.url.appendingPathComponent("bundle.zip")
        let extracted = sandbox.url.appendingPathComponent("extracted", isDirectory: true)
        try FileManager.default.createDirectory(at: source, withIntermediateDirectories: true)
        try "zip compress works".write(
            to: source.appendingPathComponent("note.txt"),
            atomically: true,
            encoding: .utf8
        )

        try await ArchiveCompressor().compress(sourceURLs: [source], outputURL: output, format: .zip)
        try await ArchiveExtractor().extract(sourceURL: output, outputURL: extracted, format: .zip)

        let content = try String(contentsOf: extracted.appendingPathComponent("source/note.txt"), encoding: .utf8)
        #expect(content == "zip compress works")
    }

    @Test("compresses and extracts TAR.BZ2 archive")
    func compressesTarBzip2Archive() async throws {
        let sandbox = try Sandbox()
        let source = sandbox.url.appendingPathComponent("source", isDirectory: true)
        let output = sandbox.url.appendingPathComponent("bundle.tar.bz2")
        let extracted = sandbox.url.appendingPathComponent("extracted", isDirectory: true)
        try FileManager.default.createDirectory(at: source, withIntermediateDirectories: true)
        try "bz2 compress works".write(
            to: source.appendingPathComponent("note.txt"),
            atomically: true,
            encoding: .utf8
        )

        try await ArchiveCompressor().compress(sourceURLs: [source], outputURL: output, format: .bzip2)
        try await ArchiveExtractor().extract(sourceURL: output, outputURL: extracted, format: .bzip2)

        let content = try String(contentsOf: extracted.appendingPathComponent("source/note.txt"), encoding: .utf8)
        #expect(content == "bz2 compress works")
    }

    @Test("compresses and extracts 7Z archive")
    func compressesSevenZipArchive() async throws {
        let sandbox = try Sandbox()
        let source = sandbox.url.appendingPathComponent("source", isDirectory: true)
        let output = sandbox.url.appendingPathComponent("bundle.7z")
        let extracted = sandbox.url.appendingPathComponent("extracted", isDirectory: true)
        try FileManager.default.createDirectory(at: source, withIntermediateDirectories: true)
        try "7z compress works".write(
            to: source.appendingPathComponent("note.txt"),
            atomically: true,
            encoding: .utf8
        )

        try await ArchiveCompressor().compress(sourceURLs: [source], outputURL: output, format: .sevenZip)
        try await ArchiveExtractor().extract(sourceURL: output, outputURL: extracted, format: .sevenZip)

        let content = try String(contentsOf: extracted.appendingPathComponent("source/note.txt"), encoding: .utf8)
        #expect(content == "7z compress works")
    }
}

private struct Sandbox {
    let url: URL

    init() throws {
        url = FileManager.default.temporaryDirectory
            .appendingPathComponent("unpacka-tests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    }
}

private func run(
    _ executable: String,
    arguments: [String],
    currentDirectory: URL? = nil,
    outputURL: URL? = nil
) throws {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: executable)
    process.arguments = arguments
    process.currentDirectoryURL = currentDirectory

    let errorPipe = Pipe()
    process.standardError = errorPipe

    var outputHandle: FileHandle?
    if let outputURL {
        _ = FileManager.default.createFile(atPath: outputURL.path, contents: nil)
        outputHandle = try FileHandle(forWritingTo: outputURL)
        process.standardOutput = outputHandle
    }

    try process.run()
    process.waitUntilExit()
    try outputHandle?.close()

    guard process.terminationStatus == 0 else {
        let data = errorPipe.fileHandleForReading.readDataToEndOfFile()
        let message = String(data: data, encoding: .utf8) ?? "command failed"
        throw NSError(domain: "UnpackaTests", code: Int(process.terminationStatus), userInfo: [
            NSLocalizedDescriptionKey: message
        ])
    }
}
