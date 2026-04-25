import AppKit
import Foundation

extension Notification.Name {
    static let unpackaOpenURLs = Notification.Name("unpackaOpenURLs")
}

final class AppFileRouter: NSObject, NSApplicationDelegate {
    func application(_ application: NSApplication, open urls: [URL]) {
        NotificationCenter.default.post(name: .unpackaOpenURLs, object: urls)
    }
}
