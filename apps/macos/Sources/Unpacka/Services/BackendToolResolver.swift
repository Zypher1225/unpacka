import Foundation

struct BackendToolResolver {
    func sevenZipTool() throws -> String {
        let candidates = bundledCandidates(named: "7zz") + [
            "/opt/homebrew/bin/7zz",
            "/usr/local/bin/7zz",
            "/opt/homebrew/bin/7z",
            "/usr/local/bin/7z",
            "/usr/bin/7zz",
            "/usr/bin/7z"
        ]

        if let tool = firstExecutable(candidates) {
            return tool
        }
        throw ExtractError.missingTool("7zz 或 7z")
    }

    func rarTool() -> String? {
        firstExecutable([
            "/opt/homebrew/bin/rar",
            "/usr/local/bin/rar",
            "/usr/bin/rar"
        ])
    }

    func unrarTool() -> String? {
        firstExecutable(bundledCandidates(named: "unrar") + [
            "/opt/homebrew/bin/unrar",
            "/usr/local/bin/unrar",
            "/usr/bin/unrar"
        ])
    }

    private func bundledCandidates(named name: String) -> [String] {
        [
            Bundle.main.resourceURL?.appendingPathComponent("bin/\(name)").path,
            Bundle.main.bundleURL.appendingPathComponent("Contents/Resources/bin/\(name)").path
        ].compactMap { $0 }
    }

    private func firstExecutable(_ candidates: [String]) -> String? {
        candidates.first { FileManager.default.isExecutableFile(atPath: $0) }
    }
}

