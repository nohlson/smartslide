import SwiftUI

/// A draggable filmstrip shown in the fullscreen overlay: the current scene stays centered
/// under a fixed white playhead, with neighboring scenes visible on either side. Dragging
/// scrolls the strip under the playhead — a big drag moves many slides, a small drag moves
/// one — and only commits (changing the displayed slide + restarting the timer) when the
/// drag is released, at whichever scene is under the playhead. While dragging, that pending
/// scene gets a dashed outline so it's clear where playback will pick up. Clicking any
/// visible cell jumps straight to it immediately.
struct PlayerTimelineScrubberView: View {
    let scenes: [SlideScene]
    let currentIndex: Int
    /// Index in `scenes` where the current generation begins (0 if there's no kept-around
    /// previous generation) — draws a delineator there.
    let segmentBoundaryIndex: Int
    /// Shows dashed "more coming" placeholder cells at the tail when Rehash on Replay is on.
    let showRehashPlaceholders: Bool
    @ObservedObject var thumbnailStore: ThumbnailStore
    var onDragBegin: () -> Void
    var onScrub: (Int) -> Void

    @State private var dragOffset: CGFloat = 0
    @State private var pendingIndex: Int?

    private let cellHeight: CGFloat = 54
    private let spacing: CGFloat = 4
    private let delineatorWidth: CGFloat = 16

    private var cellAspect: CGFloat {
        let size = NSScreen.main?.frame.size ?? CGSize(width: 16, height: 10)
        return size.width / size.height
    }
    private var cellWidth: CGFloat { cellHeight * cellAspect }
    private var stride: CGFloat { cellWidth + spacing }

    /// Extra width inserted before `currentIndex` by the delineator, if it sits before it.
    private var delineatorOffsetForCurrent: CGFloat {
        (segmentBoundaryIndex > 0 && currentIndex >= segmentBoundaryIndex) ? (delineatorWidth + spacing) : 0
    }

    var body: some View {
        GeometryReader { geo in
            let centerX = geo.size.width / 2
            let baseOffset = centerX - (CGFloat(currentIndex) * stride + cellWidth / 2 + delineatorOffsetForCurrent)

            ZStack {
                HStack(spacing: spacing) {
                    ForEach(Array(scenes.enumerated()), id: \.element.id) { index, scene in
                        if index == segmentBoundaryIndex && segmentBoundaryIndex > 0 {
                            RehashDelineatorView(height: cellHeight)
                        }
                        let isCurrent = index == currentIndex
                        let isPending = !isCurrent && pendingIndex == index
                        ScrubberCell(
                            scene: scene,
                            isCurrent: isCurrent,
                            isPending: isPending,
                            thumbnails: thumbnailStore.thumbnails,
                            cellSize: CGSize(width: cellWidth, height: cellHeight)
                        )
                        .onTapGesture {
                            onScrub(index)
                        }
                    }

                    if showRehashPlaceholders {
                        ForEach(0..<TimelineConstants.rehashLookaheadCount, id: \.self) { _ in
                            RehashPlaceholderCell(cellSize: CGSize(width: cellWidth, height: cellHeight))
                        }
                    }
                }
                .offset(x: baseOffset + dragOffset)

                // Fixed playhead marking the center — whatever scene sits under it is what
                // plays next once the drag is released.
                Rectangle()
                    .fill(Color.white)
                    .frame(width: 2)
                    .shadow(color: .black.opacity(0.6), radius: 2)
            }
            .frame(width: geo.size.width, height: cellHeight, alignment: .leading)
            .contentShape(Rectangle())
            .clipped()
            .gesture(
                DragGesture(minimumDistance: 4)
                    .onChanged { value in
                        let count = scenes.count
                        guard count > 0 else { return }

                        if pendingIndex == nil {
                            onDragBegin()
                        }
                        dragOffset = value.translation.width

                        let delta = Int((-dragOffset / stride).rounded())
                        pendingIndex = ((currentIndex + delta) % count + count) % count
                    }
                    .onEnded { _ in
                        if let pendingIndex {
                            onScrub(pendingIndex)
                        }
                        dragOffset = 0
                        pendingIndex = nil
                    }
            )
        }
        .frame(height: cellHeight)
    }
}

private struct ScrubberCell: View {
    let scene: SlideScene
    let isCurrent: Bool
    let isPending: Bool
    let thumbnails: [URL: NSImage]
    let cellSize: CGSize

    var body: some View {
        ZStack {
            Color.black
            content
        }
        .frame(width: cellSize.width, height: cellSize.height)
        .clipped()
        .opacity(isCurrent || isPending ? 1.0 : 0.6)
        .overlay(
            RoundedRectangle(cornerRadius: 2)
                .stroke(Color.white, lineWidth: isCurrent ? 2 : 0)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 2)
                .stroke(style: StrokeStyle(lineWidth: 2, dash: [4, 3]))
                .foregroundStyle(Color.white)
                .opacity(isPending ? 1 : 0)
        )
    }

    @ViewBuilder
    private var content: some View {
        if scene.imageURLs.count >= 2 {
            let leftAspect = aspectRatio(of: thumbnails[scene.imageURLs[0]])
            let rightAspect = aspectRatio(of: thumbnails[scene.imageURLs[1]])
            let combinedHeight = min(cellSize.height, cellSize.width / (leftAspect + rightAspect))

            HStack(spacing: 0) {
                thumbnailImage(for: scene.imageURLs[0])
                    .frame(width: leftAspect * combinedHeight, height: combinedHeight)
                thumbnailImage(for: scene.imageURLs[1])
                    .frame(width: rightAspect * combinedHeight, height: combinedHeight)
            }
        } else {
            thumbnailImage(for: scene.imageURLs.first)
                .frame(width: cellSize.width, height: cellSize.height)
        }
    }

    private func aspectRatio(of image: NSImage?) -> CGFloat {
        guard let image, image.size.height > 0 else { return 1 }
        return image.size.width / image.size.height
    }

    @ViewBuilder
    private func thumbnailImage(for url: URL?) -> some View {
        if let url, let image = thumbnails[url] {
            Image(nsImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
        } else {
            Color.gray.opacity(0.25)
        }
    }
}
