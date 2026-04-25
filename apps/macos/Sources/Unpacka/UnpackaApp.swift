import SwiftUI

@main
struct UnpackaApp: App {
    @NSApplicationDelegateAdaptor(AppFileRouter.self) private var appFileRouter
    @StateObject private var viewModel = ExtractViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
                .frame(minWidth: 760, minHeight: 520)
                .onReceive(NotificationCenter.default.publisher(for: .unpackaOpenURLs)) { notification in
                    guard let urls = notification.object as? [URL] else {
                        return
                    }
                    viewModel.open(urls: urls)
                }
        }
        .windowStyle(.hiddenTitleBar)

        Settings {
            SettingsView()
                .environmentObject(viewModel)
        }
    }
}
