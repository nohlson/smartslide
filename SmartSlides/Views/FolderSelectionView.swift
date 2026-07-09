import SwiftUI

struct FolderSelectionView: View {
    @ObservedObject var viewModel: SettingsViewModel
    var onStart: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Folder")
                .font(.headline)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 8) {
                Text(viewModel.folderDisplayName)
                    .font(.system(size: 13, weight: .medium))
                    .lineLimit(2)
                    .truncationMode(.middle)

                if viewModel.needsFolderReselect {
                    Label("Folder unavailable — please reselect", systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }

                Button("Choose Folder…") {
                    viewModel.chooseFolder()
                }
            }

            Toggle("Include Subfolders", isOn: Binding(
                get: { viewModel.settings.includeSubfolders },
                set: { viewModel.toggleIncludeSubfolders($0) }
            ))
            .toggleStyle(.switch)

            Divider()

            VStack(alignment: .leading, spacing: 6) {
                Text("Images")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                statRow("Total", viewModel.totalCount)
                statRow("Portrait", viewModel.portraitCount)
                statRow("Landscape", viewModel.landscapeCount)
                if viewModel.skippedCount > 0 {
                    statRow("Skipped", viewModel.skippedCount, color: .orange)
                }
            }

            Spacer()

            Button(action: onStart) {
                Text("Start Slideshow")
                    .font(.system(size: 14, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }
            .buttonStyle(.borderedProminent)
            .disabled(!viewModel.canStartSlideshow)
        }
        .padding(20)
        .frame(width: 240)
        .frame(maxHeight: .infinity, alignment: .top)
        .background(Color(nsColor: .windowBackgroundColor).opacity(0.4))
    }

    private func statRow(_ label: String, _ value: Int, color: Color = .primary) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text("\(value)")
                .foregroundStyle(color)
                .monospacedDigit()
        }
        .font(.system(size: 12))
    }
}
