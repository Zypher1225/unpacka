import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var viewModel: ExtractViewModel

    var body: some View {
        Form {
            Picker("默认解压位置", selection: $viewModel.outputLocation) {
                ForEach(OutputLocation.allCases) { option in
                    Text(option.label).tag(option)
                }
            }

            Picker("文件冲突", selection: $viewModel.conflictPolicy) {
                ForEach(ConflictPolicy.allCases) { option in
                    Text(option.label).tag(option)
                }
            }

            Picker("文件名编码", selection: $viewModel.encodingPolicy) {
                ForEach(EncodingPolicy.allCases) { option in
                    Text(option.label).tag(option)
                }
            }

            Picker("性能", selection: $viewModel.performanceMode) {
                ForEach(PerformanceMode.allCases) { option in
                    Text(option.label).tag(option)
                }
            }
        }
        .formStyle(.grouped)
        .padding(20)
        .frame(width: 420)
    }
}

