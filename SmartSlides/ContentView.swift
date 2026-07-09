import SwiftUI

struct ContentView: View {
    @ObservedObject var viewModel: SettingsViewModel
    var onStartSlideshow: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                FolderSelectionView(viewModel: viewModel, onStart: onStartSlideshow)
                Divider()
                TimingSettingsView(viewModel: viewModel)
                Divider()
                LayoutSelectionView(viewModel: viewModel)
            }

            Divider()

            TimelineStripView(
                scenes: viewModel.settings.timeline,
                currentIndex: viewModel.settings.currentTimelineIndex,
                thumbnailStore: viewModel.thumbnailStore
            )
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .frame(minWidth: 820, minHeight: 560)
        .preferredColorScheme(.dark)
    }
}
