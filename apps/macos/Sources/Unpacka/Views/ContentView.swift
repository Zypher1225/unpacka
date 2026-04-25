import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @EnvironmentObject private var viewModel: ExtractViewModel

    var body: some View {
        VStack(spacing: 0) {
            if let pendingExtraction = viewModel.pendingExtraction {
                ExtractionPromptView(pendingExtraction: pendingExtraction)
            } else {
                EmptyToolView()
            }

            if let message = viewModel.lastMessage {
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    .background(.bar)
            }
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .sheet(
            isPresented: Binding(
                get: { viewModel.compressionDraft != nil },
                set: { if !$0 { viewModel.compressionDraft = nil } }
            )
        ) {
            CompressionSheet()
                .environmentObject(viewModel)
        }
        .sheet(
            isPresented: Binding(
                get: { viewModel.passwordRetry != nil },
                set: { if !$0 { viewModel.passwordRetry = nil } }
            )
        ) {
            PasswordRetrySheet()
                .environmentObject(viewModel)
        }
    }
}

private struct ExtractionPromptView: View {
    @EnvironmentObject private var viewModel: ExtractViewModel
    let pendingExtraction: PendingExtraction

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 14) {
                AppIconMark()
                    .frame(width: 52, height: 52)

                VStack(alignment: .leading, spacing: 4) {
                    Text("解压压缩包")
                        .font(.title2.weight(.semibold))
                    Text(pendingExtraction.sourceURL.lastPathComponent)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }

                Spacer()

                Text(pendingExtraction.format.displayName)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 6))
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("解压位置")
                    .font(.headline)

                HStack(spacing: 10) {
                    Text(pendingExtraction.destinationURL.path)
                        .font(.callout)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Button {
                        viewModel.chooseExtractDestination()
                    } label: {
                        Label("选择路径", systemImage: "folder")
                    }
                }
                .padding(10)
                .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 8))
            }

            HStack {
                Button {
                    viewModel.pendingExtraction = nil
                } label: {
                    Label("取消", systemImage: "xmark")
                }

                Spacer()

                Button {
                    viewModel.extractToCurrentDirectory()
                } label: {
                    Label("解压到当前目录", systemImage: "arrow.down.doc")
                }

                Button {
                    viewModel.extractPendingArchive()
                } label: {
                    Label("解压到所选路径", systemImage: "arrow.down.circle.fill")
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(22)
    }
}

private struct EmptyToolView: View {
    @EnvironmentObject private var viewModel: ExtractViewModel

    var body: some View {
        VStack(spacing: 18) {
            AppIconMark()
                .frame(width: 72, height: 72)

            VStack(spacing: 6) {
                Text("解包鸭")
                    .font(.title.weight(.semibold))
                Text("拖入压缩包解压，拖入文件或文件夹压缩")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button {
                viewModel.chooseArchive()
            } label: {
                Label("选择压缩包", systemImage: "archivebox")
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(30)
        .onDrop(
            of: [UTType.fileURL.identifier],
            isTargeted: $viewModel.isDropTargeted,
            perform: viewModel.handleDrop(providers:)
        )
    }
}

private struct CompressionSheet: View {
    @EnvironmentObject private var viewModel: ExtractViewModel

    private var formatBinding: Binding<ArchiveFormat> {
        Binding(
            get: { viewModel.compressionDraft?.format ?? .zip },
            set: { viewModel.updateCompressionFormat($0) }
        )
    }

    private var passwordBinding: Binding<String> {
        Binding(
            get: { viewModel.compressionDraft?.password ?? "" },
            set: { viewModel.updateCompressionPassword($0) }
        )
    }

    private var isEncryptedBinding: Binding<Bool> {
        Binding(
            get: { viewModel.compressionDraft?.isEncrypted ?? false },
            set: { viewModel.updateCompressionEncryption($0) }
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("压缩设置")
                .font(.title3.weight(.semibold))

            if let draft = viewModel.compressionDraft {
                Text("\(draft.sourceURLs.count) 个项目")
                    .font(.callout)
                    .foregroundStyle(.secondary)

                Picker("格式", selection: formatBinding) {
                    ForEach([ArchiveFormat.zip, .sevenZip, .tar, .gzip, .bzip2, .xz], id: \.self) { format in
                        Text(format.displayName).tag(format)
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("保存位置")
                        .font(.headline)

                    HStack(spacing: 10) {
                        Text(draft.outputURL.path)
                            .font(.callout)
                            .lineLimit(1)
                            .truncationMode(.middle)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Button {
                            viewModel.chooseCompressionDestination()
                        } label: {
                            Label("选择路径", systemImage: "folder")
                        }
                    }
                    .padding(10)
                    .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 8))
                }

                if draft.format == .zip || draft.format == .sevenZip {
                    Toggle("需要加密", isOn: isEncryptedBinding)

                    if draft.isEncrypted {
                        SecureField("密码", text: passwordBinding)
                            .textFieldStyle(.roundedBorder)
                    }
                }

                HStack {
                    Button("取消") {
                        viewModel.compressionDraft = nil
                    }
                    Spacer()
                    Button {
                        viewModel.enqueueCompressionFromDraft()
                    } label: {
                        Label("开始压缩", systemImage: "archivebox.fill")
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .padding(22)
        .frame(width: 520)
    }
}

private struct PasswordRetrySheet: View {
    @EnvironmentObject private var viewModel: ExtractViewModel
    @State private var password = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("需要密码")
                .font(.title3.weight(.semibold))

            Text(viewModel.passwordRetry?.sourceURL.lastPathComponent ?? "加密压缩包")
                .font(.callout)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)

            SecureField("输入压缩包密码", text: $password)
                .textFieldStyle(.roundedBorder)

            HStack {
                Button("取消") {
                    viewModel.passwordRetry = nil
                }
                Spacer()
                Button {
                    viewModel.retryExtractionWithPassword(password)
                } label: {
                    Label("继续解压", systemImage: "lock.open.fill")
                }
                .buttonStyle(.borderedProminent)
                .disabled(password.isEmpty)
            }
        }
        .padding(22)
        .frame(width: 420)
    }
}

private struct AppIconMark: View {
    var body: some View {
        if let image = bundledIcon {
            Image(nsImage: image)
                .resizable()
                .scaledToFit()
        } else {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(.orange.gradient)
                Image(systemName: "archivebox.fill")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(.white)
            }
        }
    }

    private var bundledIcon: NSImage? {
        guard let url = Bundle.main.resourceURL?.appendingPathComponent("AppIcon.icns") else {
            return nil
        }
        return NSImage(contentsOf: url)
    }
}
