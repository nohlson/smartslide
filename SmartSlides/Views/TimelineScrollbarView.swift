import SwiftUI

/// A YouTube-style horizontal seek bar for the whole timeline — click or drag anywhere along
/// it to jump straight there, which is far faster than dragging the filmstrip when there are
/// hundreds of scenes (or, with Rehash on Replay, no fixed end at all).
struct TimelineScrollbarView: View {
    let totalCount: Int
    let currentIndex: Int
    var onDragBegin: () -> Void
    var onScrub: (Int) -> Void

    @State private var pendingFraction: CGFloat?

    private let trackHeight: CGFloat = 4
    private let knobDiameter: CGFloat = 12

    var body: some View {
        GeometryReader { geo in
            let trackWidth = max(geo.size.width, 1)
            let fraction = pendingFraction ?? currentFraction
            let knobX = trackWidth * fraction

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.white.opacity(0.2))
                    .frame(height: trackHeight)
                Capsule()
                    .fill(Color.accentColor)
                    .frame(width: knobX, height: trackHeight)
                Circle()
                    .fill(Color.white)
                    .frame(width: knobDiameter, height: knobDiameter)
                    .shadow(color: .black.opacity(0.5), radius: 2)
                    .offset(x: knobX - knobDiameter / 2)
            }
            .frame(maxHeight: .infinity, alignment: .center)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        if pendingFraction == nil {
                            onDragBegin()
                        }
                        pendingFraction = min(max(value.location.x / trackWidth, 0), 1)
                    }
                    .onEnded { _ in
                        if let pendingFraction, totalCount > 1 {
                            let index = Int((pendingFraction * CGFloat(totalCount - 1)).rounded())
                            onScrub(index)
                        }
                        pendingFraction = nil
                    }
            )
        }
        .frame(height: 16)
    }

    private var currentFraction: CGFloat {
        guard totalCount > 1 else { return 0 }
        return CGFloat(currentIndex) / CGFloat(totalCount - 1)
    }
}
