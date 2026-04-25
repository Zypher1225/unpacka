import SwiftUI

@main
struct UnpackaApp: App {
    @StateObject private var viewModel = ExtractViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
                .frame(minWidth: 760, minHeight: 520)
        }
        .windowStyle(.hiddenTitleBar)

        Settings {
            SettingsView()
                .environmentObject(viewModel)
        }
    }
}

