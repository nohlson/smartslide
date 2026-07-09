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
