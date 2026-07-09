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
                scenes: viewModel.displayTimeline,
                currentIndex: viewModel.settings.currentTimelineIndex,
                segmentBoundaryIndex: viewModel.settings.previousTimeline.count,
                showRehashPlaceholders: viewModel.settings.rehashOnReplay,
                thumbnailStore: viewModel.thumbnailStore,
                onSelect: { viewModel.updateCurrentIndex($0) }
            )
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .frame(minWidth: 820, minHeight: 560)
        .preferredColorScheme(.dark)
    }
}
