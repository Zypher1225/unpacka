import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @EnvironmentObject private var viewModel: ExtractViewModel

    var body: some View {
        VStack(spacing: 0) {
            header

            HStack(alignment: .top, spacing: 0) {
                Group {
                    if let archive = viewModel.openedArchive {
                        ArchivePreviewView(archive: archive)
                    } else {
                        dropZone
                    }
                }
                .frame(minWidth: 460, maxWidth: .infinity, maxHeight: .infinity)

                Divider()

                recentTasks
                    .frame(minWidth: 340, idealWidth: 340, maxWidth: 340, maxHeight: .infinity)
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
    }

    private var header: some View {
        HStack(spacing: 12) {
            AppIconMark()
                .frame(width: 40, height: 40)

            VStack(alignment: .leading, spacing: 2) {
                Text("解包鸭 Unpacka")
                    .font(.title3.weight(.semibold))
                Text("轻量、高速、智能编码修复解压工具")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Picker("压缩格式", selection: $viewModel.compressionFormat) {
                ForEach([ArchiveFormat.zip, .tar, .gzip, .bzip2, .xz, .sevenZip, .rar], id: \.self) { format in
                    Text(format.displayName).tag(format)
                }
            }
            .labelsHidden()
            .frame(width: 92)

            Button {
                viewModel.chooseFilesToCompress()
            } label: {
                Label("压缩", systemImage: "plus.rectangle.on.folder")
            }
            .buttonStyle(.bordered)

            Button {
                viewModel.chooseArchive()
            } label: {
                Label("解压", systemImage: "archivebox")
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(18)
        .background(.bar)
    }

    private var dropZone: some View {
        VStack(spacing: 18) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(viewModel.isDropTargeted ? Color.accentColor.opacity(0.14) : Color(nsColor: .controlBackgroundColor))
                    .strokeBorder(
                        viewModel.isDropTargeted ? Color.accentColor : Color.secondary.opacity(0.35),
                        style: StrokeStyle(lineWidth: 2, dash: [9, 7])
                    )

                VStack(spacing: 14) {
                    Image(systemName: "shippingbox")
                        .font(.system(size: 54, weight: .regular))
                        .foregroundStyle(Color.accentColor)

                    Text("拖入压缩包或文件到这里")
                        .font(.title2.weight(.semibold))

                    Text("压缩包会先预览内容，普通文件会进入压缩设置")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
                .padding(28)
            }
            .frame(maxWidth: 460, minHeight: 280, maxHeight: 320)
            .padding(26)
            .onDrop(
                of: [UTType.fileURL.identifier],
                isTargeted: $viewModel.isDropTargeted,
                perform: viewModel.handleDrop(providers:)
            )

            formatStrip
        }
    }

    private var formatStrip: some View {
        HStack(spacing: 10) {
            ForEach(["ZIP", "TAR", "GZ", "BZ2", "XZ", "7Z", "RAR"], id: \.self) { label in
                Text(label)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(minWidth: 42)
                    .padding(.vertical, 6)
                    .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 6))
            }
        }
        .padding(.bottom, 20)
    }

    private var recentTasks: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("最近任务")
                .font(.headline)
                .padding(.horizontal, 16)
                .padding(.top, 18)

            if viewModel.tasks.isEmpty {
                ContentUnavailableView("还没有任务", systemImage: "tray", description: Text("拖入压缩包后会显示在这里"))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(viewModel.tasks) { task in
                    TaskRow(task: task)
                        .listRowSeparator(.hidden)
                }
                .listStyle(.plain)
            }
        }
    }
}

private struct ArchivePreviewView: View {
    @EnvironmentObject private var viewModel: ExtractViewModel
    let archive: OpenedArchive

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    Image(systemName: "doc.zipper")
                        .font(.system(size: 34))
                        .foregroundStyle(Color.accentColor)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(archive.url.lastPathComponent)
                            .font(.title3.weight(.semibold))
                            .lineLimit(1)
                            .truncationMode(.middle)
                        Text("\(archive.format.displayName) · \(archive.fileCount) 个文件 · \(archive.directoryCount) 个文件夹")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    if archive.hasEncryptedEntries {
                        Label("需要密码", systemImage: "lock.fill")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.orange)
                    }
                }

                HStack(spacing: 10) {
                    Button {
                        viewModel.chooseExtractDestination()
                    } label: {
                        Label("选择位置", systemImage: "folder")
                    }

                    Text(viewModel.extractDestinationURL?.path ?? "未选择输出位置")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)

                    Spacer()
                }

                SecureField("密码（如需要）", text: $viewModel.archivePassword)
                    .textFieldStyle(.roundedBorder)

                HStack {
                    Button {
                        viewModel.openedArchive = nil
                    } label: {
                        Label("关闭", systemImage: "xmark")
                    }

                    Spacer()

                    Button {
                        viewModel.extractOpenedArchive()
                    } label: {
                        Label("解压全部", systemImage: "arrow.down.circle.fill")
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding(18)
            .background(.bar)

            if archive.entries.isEmpty {
                ContentUnavailableView("无法预览内容", systemImage: "doc.questionmark", description: Text("仍可输入密码后尝试解压"))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(archive.entries) { entry in
                    HStack(spacing: 10) {
                        Image(systemName: entry.isDirectory ? "folder.fill" : "doc")
                            .foregroundStyle(entry.isDirectory ? .blue : .secondary)
                            .frame(width: 20)
                        Text(entry.path)
                            .lineLimit(1)
                            .truncationMode(.middle)
                        Spacer()
                        if entry.isEncrypted {
                            Image(systemName: "lock.fill")
                                .foregroundStyle(.orange)
                        }
                        Text(entry.displaySize)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(width: 86, alignment: .trailing)
                    }
                    .padding(.vertical, 3)
                }
                .listStyle(.plain)
            }
        }
    }
}

private struct CompressionSheet: View {
    @EnvironmentObject private var viewModel: ExtractViewModel

    private var formatBinding: Binding<ArchiveFormat> {
        Binding(
            get: { viewModel.compressionDraft?.format ?? viewModel.compressionFormat },
            set: { viewModel.updateCompressionFormat($0) }
        )
    }

    private var passwordBinding: Binding<String> {
        Binding(
            get: { viewModel.compressionDraft?.password ?? "" },
            set: { value in
                guard var draft = viewModel.compressionDraft else {
                    return
                }
                draft.password = value
                viewModel.compressionDraft = draft
            }
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

                HStack {
                    Text("保存到")
                    Text(draft.outputURL.path)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    Spacer()
                    Button("更改") {
                        viewModel.chooseCompressionDestination()
                    }
                }

                SecureField("密码（仅 ZIP / 7Z）", text: passwordBinding)
                    .textFieldStyle(.roundedBorder)
                    .disabled(!(draft.format == .zip || draft.format == .sevenZip))

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

private struct TaskRow: View {
    let task: ExtractTask

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: iconName)
                    .foregroundStyle(iconColor)
                Text(task.sourceURL.lastPathComponent)
                    .font(.callout.weight(.medium))
                    .lineLimit(1)
                    .truncationMode(.middle)
                Spacer()
                Text(task.format.displayName)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            ProgressView(value: task.progress)
                .controlSize(.small)

            Text("\(task.operation.label)：\(statusText)")
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)
        }
        .padding(10)
        .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 8))
    }

    private var iconName: String {
        switch task.status {
        case .completed: "checkmark.circle.fill"
        case .failed: "exclamationmark.triangle.fill"
        case .running: task.operation == .extract ? "arrow.down.circle.fill" : "arrow.up.circle.fill"
        case .queued: "clock.fill"
        }
    }

    private var iconColor: Color {
        switch task.status {
        case .completed: .green
        case .failed: .orange
        case .running: .accentColor
        case .queued: .secondary
        }
    }

    private var statusText: String {
        switch task.status {
        case .queued: "等待中"
        case .running: task.operation == .extract ? "解压中" : "压缩中"
        case .completed: "已完成"
        case .failed(let message): message
        }
    }
}

private struct AppIconMark: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(.orange.gradient)
            Image(systemName: "shippingbox.fill")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(.white)
        }
    }
}
