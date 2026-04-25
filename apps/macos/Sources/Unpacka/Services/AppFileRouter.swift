import AppKit
import Foundation

extension Notification.Name {
    static let unpackaOpenURLs = Notification.Name("unpackaOpenURLs")
    static let unpackaCompressURLs = Notification.Name("unpackaCompressURLs")
}

final class AppFileRouter: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApplication.shared.servicesProvider = self
        NSUpdateDynamicServices()
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        NotificationCenter.default.post(name: .unpackaOpenURLs, object: urls)
    }

    @objc func extractService(_ pasteboard: NSPasteboard, userData: String?, error: AutoreleasingUnsafeMutablePointer<NSString?>) {
        guard let urls = fileURLs(from: pasteboard), !urls.isEmpty else {
            error.pointee = "没有找到可解压的文件"
            return
        }
        NotificationCenter.default.post(name: .unpackaOpenURLs, object: urls)
    }

    @objc func compressService(_ pasteboard: NSPasteboard, userData: String?, error: AutoreleasingUnsafeMutablePointer<NSString?>) {
        guard let urls = fileURLs(from: pasteboard), !urls.isEmpty else {
            error.pointee = "没有找到可压缩的文件"
            return
        }
        NotificationCenter.default.post(name: .unpackaCompressURLs, object: urls)
    }

    private func fileURLs(from pasteboard: NSPasteboard) -> [URL]? {
        if let urls = pasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL], !urls.isEmpty {
            return urls
        }

        let filenamesType = NSPasteboard.PasteboardType("NSFilenamesPboardType")
        if let paths = pasteboard.propertyList(forType: filenamesType) as? [String] {
            return paths.map { URL(fileURLWithPath: $0) }
        }

        return nil
    }
}
