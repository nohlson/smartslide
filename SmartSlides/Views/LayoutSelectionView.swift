import SwiftUI

struct LayoutSelectionView: View {
    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Layouts")
                .font(.headline)
                .foregroundStyle(.secondary)

            ForEach(SlideLayout.allCases, id: \.self) { layout in
                Toggle(layout.displayName, isOn: Binding(
                    get: { viewModel.settings.enabledLayouts.contains(layout) },
                    set: { viewModel.toggleLayout(layout, enabled: $0) }
                ))
                .toggleStyle(.checkbox)
            }

            if viewModel.settings.enabledLayouts.isEmpty {
                Label("Enable at least one layout", systemImage: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }

            Spacer()
        }
        .padding(20)
        .frame(width: 220)
        .frame(maxHeight: .infinity, alignment: .top)
        .background(Color(nsColor: .windowBackgroundColor).opacity(0.4))
    }
}
