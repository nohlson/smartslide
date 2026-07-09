import SwiftUI

/// Marks the boundary between a kept-around previous generation and the current one in a
/// timeline strip — "this is where a rehash happened."
struct RehashDelineatorView: View {
    let height: CGFloat

    var body: some View {
        VStack(spacing: 3) {
            Image(systemName: "arrow.triangle.2.circlepath")
                .font(.system(size: 8, weight: .bold))
                .foregroundStyle(Color.accentColor)
            Rectangle()
                .fill(Color.accentColor)
                .frame(width: 2)
        }
        .frame(width: 16, height: height)
        .background(Color.accentColor.opacity(0.12))
    }
}

/// A dashed placeholder cell shown at the tail of a timeline when Rehash on Replay is on,
/// signaling "a new shuffle will be generated to continue here."
struct RehashPlaceholderCell: View {
    let cellSize: CGSize

    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
            .foregroundStyle(Color.white.opacity(0.3))
            .background(Color.white.opacity(0.03))
            .overlay(
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: min(cellSize.width, cellSize.height) * 0.28, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.35))
            )
            .frame(width: cellSize.width, height: cellSize.height)
    }
}

/// A brief, unobtrusive heads-up shown in the fullscreen slideshow when Rehash on Replay is
/// about to splice in a fresh shuffle — shown regardless of the controls overlay's own
/// visibility, so it's seen even if the user isn't interacting.
struct RehashToastView: View {
    var body: some View {
        Label("Shuffling in more photos…", systemImage: "arrow.triangle.2.circlepath")
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial, in: Capsule())
    }
}
