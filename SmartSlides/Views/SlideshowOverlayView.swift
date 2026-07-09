import SwiftUI

struct SlideshowOverlayView: View {
    @ObservedObject var player: SlideshowPlayerViewModel

    var body: some View {
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

            Text("\(player.currentIndex + 1) / \(player.totalCount)")
                .font(.caption)
                .monospacedDigit()
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 24)
        .padding(.vertical, 14)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal, 40)
    }
}
