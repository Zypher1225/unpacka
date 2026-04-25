import Foundation

struct OutputPathResolver {
    func defaultOutputURL(for archiveURL: URL, location: OutputLocation, conflictPolicy: ConflictPolicy) throws -> URL {
        let baseDirectory: URL
        switch location {
        case .besideArchive, .askEveryTime:
            baseDirectory = archiveURL.deletingLastPathComponent()
        case .downloads:
            baseDirectory = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first
                ?? archiveURL.deletingLastPathComponent()
        }

        let folderName = archiveURL.deletingPathExtension().lastPathComponent
        let proposed = baseDirectory.appendingPathComponent(folderName, isDirectory: true)
        return try resolvedConflictFreeURL(proposed, policy: conflictPolicy)
    }

    private func resolvedConflictFreeURL(_ proposed: URL, policy: ConflictPolicy) throws -> URL {
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: proposed.path) else {
            return proposed
        }

        switch policy {
        case .overwrite, .ask:
            return proposed
        case .rename:
            let parent = proposed.deletingLastPathComponent()
            let base = proposed.lastPathComponent
            for index in 2..<10_000 {
                let candidate = parent.appendingPathComponent("\(base) \(index)", isDirectory: true)
                if !fileManager.fileExists(atPath: candidate.path) {
                    return candidate
                }
            }
            throw ExtractError.outputUnavailable("无法创建唯一输出文件夹")
        }
    }
}

