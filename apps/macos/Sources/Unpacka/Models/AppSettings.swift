import Foundation

enum OutputLocation: String, CaseIterable, Identifiable {
    case besideArchive
    case downloads
    case askEveryTime

    var id: String { rawValue }

    var label: String {
        switch self {
        case .besideArchive: "当前文件夹"
        case .downloads: "下载文件夹"
        case .askEveryTime: "每次询问"
        }
    }
}

enum ConflictPolicy: String, CaseIterable, Identifiable {
    case rename
    case overwrite
    case ask

    var id: String { rawValue }

    var label: String {
        switch self {
        case .rename: "自动重命名"
        case .overwrite: "覆盖"
        case .ask: "询问"
        }
    }
}

enum EncodingPolicy: String, CaseIterable, Identifiable {
    case automatic
    case utf8
    case gbk
    case shiftJIS

    var id: String { rawValue }

    var label: String {
        switch self {
        case .automatic: "自动检测"
        case .utf8: "UTF-8"
        case .gbk: "GBK"
        case .shiftJIS: "Shift-JIS"
        }
    }
}

enum PerformanceMode: String, CaseIterable, Identifiable {
    case automatic
    case efficient
    case highPerformance

    var id: String { rawValue }

    var label: String {
        switch self {
        case .automatic: "自动"
        case .efficient: "节能"
        case .highPerformance: "高性能"
        }
    }
}

