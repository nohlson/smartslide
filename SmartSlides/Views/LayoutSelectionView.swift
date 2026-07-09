import SwiftUI

struct LayoutSelectionView: View {
    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 6) {
                Image(systemName: "square.grid.2x2")
                    .font(.system(size: 12, weight: .semibold))
                Text("Layouts to Use")
                    .font(.system(size: 11, weight: .semibold))
                    .kerning(0.6)
            }
            .foregroundStyle(.secondary)

            VStack(spacing: 10) {
                ForEach(SlideLayout.allCases, id: \.self) { layout in
                    LayoutRow(
                        layout: layout,
                        isEnabled: viewModel.settings.enabledLayouts.contains(layout),
                        onToggle: { viewModel.toggleLayout(layout, enabled: $0) }
                    )
                }
            }

            if viewModel.settings.enabledLayouts.isEmpty {
                Label("Enable at least one layout", systemImage: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }

            Spacer()
        }
        .padding(20)
        .frame(width: 260)
        .frame(maxHeight: .infinity, alignment: .top)
        .background(Color(nsColor: .windowBackgroundColor).opacity(0.4))
    }
}

private struct LayoutRow: View {
    let layout: SlideLayout
    let isEnabled: Bool
    let onToggle: (Bool) -> Void

    var body: some View {
        Button {
            onToggle(!isEnabled)
        } label: {
            HStack(spacing: 12) {
                LayoutIconView(layout: layout)

                Text(layout.displayName)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 8)

                ZStack {
                    Circle()
                        .fill(isEnabled ? Color.accentColor : Color.clear)
                    Circle()
                        .stroke(Color.secondary.opacity(isEnabled ? 0 : 0.5), lineWidth: 1)
                    if isEnabled {
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
                .frame(width: 20, height: 20)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white.opacity(isEnabled ? 0.06 : 0.02))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.accentColor.opacity(isEnabled ? 0.55 : 0.15), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

/// Small preview icon of the layout's image composition — filled blocks on a dark tile.
private struct LayoutIconView: View {
    let layout: SlideLayout

    private let boxSize = CGSize(width: 54, height: 42)

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.black.opacity(0.55))
            blocks
        }
        .frame(width: boxSize.width, height: boxSize.height)
    }

    @ViewBuilder
    private var blocks: some View {
        switch layout {
        case .twoPortraitsSideBySide:
            HStack(spacing: 3) {
                block(width: 14, height: 32)
                block(width: 14, height: 32)
            }
        case .twoLandscapesSideBySide:
            HStack(spacing: 3) {
                block(width: 20, height: 26)
                block(width: 20, height: 26)
            }
        case .onePortrait:
            block(width: 14, height: 32)
        case .oneLandscape:
            block(width: 42, height: 26)
        }
    }

    private func block(width: CGFloat, height: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 3)
            .fill(Color.accentColor)
            .frame(width: width, height: height)
    }
}
