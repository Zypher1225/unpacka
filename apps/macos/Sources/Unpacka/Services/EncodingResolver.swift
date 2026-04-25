import Foundation

struct EncodingResolver {
    func needsAttention(fileNames: [String]) -> Bool {
        fileNames.contains { name in
            name.contains("�") || name.contains("√") || name.contains("µ")
        }
    }
}

