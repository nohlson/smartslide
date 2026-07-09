import SwiftUI

struct SlideshowOverlayView: View {
    @ObservedObject var player: SlideshowPlayerViewModel
    @ObservedObject var thumbnailStore: ThumbnailStore
    var onDragBegin: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 20) {
                Button(action: { player.togglePause() }) {
                    Image(systemName: player.isPaused ? "play.fill" : "pause.fill")
                        .font(.system(size: 16))
                }
                .buttonStyle(.plain)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Display: \(String(format: "%.1f", player.displayDuration))s")
                        .font(.caption)
                    Slider(
                        value: Binding(
                            get: { player.displayDuration },
                            set: { player.setDisplayDuration($0) }
                        ),
                        in: 2...20
                    )
                    .frame(width: 160)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Transition: \(String(format: "%.1f", player.transitionDuration))s")
                        .font(.caption)
                    Slider(
                        value: Binding(
                            get: { player.transitionDuration },
                            set: { player.setTransitionDuration($0) }
                        ),
                        in: 0.2...5
                    )
                    .frame(width: 160)
                }

                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(player.currentIndex + 1) / \(player.totalCount)")
                        .font(.caption)
                        .monospacedDigit()
                    Text("\(formatTime(player.totalElapsed)) / \(formatTime(player.totalDuration)) · \(formatTime(max(player.totalDuration - player.totalElapsed, 0))) left")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
            }

            PlayerTimelineScrubberView(
                scenes: player.timeline,
                currentIndex: player.currentIndex,
                thumbnailStore: thumbnailStore,
                onDragBegin: onDragBegin,
                onScrub: { player.scrub(to: $0) }
            )
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 24)
        .padding(.vertical, 14)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal, 40)
    }

    private func formatTime(_ seconds: TimeInterval) -> String {
        let total = Int(seconds.rounded())
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let secs = total % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        }
        return String(format: "%d:%02d", minutes, secs)
    }
}
