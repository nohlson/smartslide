import SwiftUI

/// A scrollable filmstrip showing a compressed thumbnail of every scene in the generated
/// timeline. Shows where the current slide sits, and lets the user click a scene to set it
/// as the slideshow's starting point.
struct TimelineStripView: View {
    let scenes: [SlideScene]
    let currentIndex: Int
    @ObservedObject var thumbnailStore: ThumbnailStore
    var onSelect: (Int) -> Void

    private let thumbHeight: CGFloat = 64

    /// Every cell is sized to this aspect ratio (the target screen's) so a single portrait
    /// and a two-landscape pair render as the same size — a small mock of the actual
    /// fullscreen frame, letterboxed/pillarboxed just like real playback.
    private var cellAspect: CGFloat {
        let size = NSScreen.main?.frame.size ?? CGSize(width: 16, height: 10)
        return size.width / size.height
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Timeline")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Spacer()
                if !scenes.isEmpty {
                    Text("\(min(currentIndex + 1, scenes.count)) / \(scenes.count)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
            }

            Group {
                if thumbnailStore.isGenerating {
                    HStack(spacing: 8) {
                        ProgressView()
                            .controlSize(.small)
                        Text("Generating thumbnails… (\(thumbnailStore.progress)/\(thumbnailStore.total))")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                    .frame(height: thumbHeight)
                } else if scenes.isEmpty {
                    Rectangle()
                        .fill(Color.black.opacity(0.15))
                        .frame(height: thumbHeight)
                } else {
                    ScrollViewReader { proxy in
                        ScrollView(.horizontal, showsIndicators: true) {
                            HStack(spacing: 3) {
                                ForEach(Array(scenes.enumerated()), id: \.element.id) { index, scene in
                                    SceneThumbnailCell(
                                        scene: scene,
                                        isCurrent: index == currentIndex,
                                        isPast: index < currentIndex,
                                        thumbnails: thumbnailStore.thumbnails,
                                        cellSize: CGSize(width: thumbHeight * cellAspect, height: thumbHeight)
                                    )
                                    .id(scene.id)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        onSelect(index)
                                    }
                                    .help("Start slideshow from here")
                                }
                            }
                        }
                        .onChange(of: currentIndex) { _, newValue in
                            guard scenes.indices.contains(newValue) else { return }
                            withAnimation {
                                proxy.scrollTo(scenes[newValue].id, anchor: .center)
                            }
                        }
                    }
                    .frame(height: thumbHeight)
                }
            }
            .background(Color.black.opacity(0.25))
            .clipShape(RoundedRectangle(cornerRadius: 4))
        }
    }
}

private struct SceneThumbnailCell: View {
    let scene: SlideScene
    let isCurrent: Bool
    let isPast: Bool
    let thumbnails: [URL: NSImage]
    let cellSize: CGSize

    var body: some View {
        ZStack {
            Color.black
            content
        }
        .frame(width: cellSize.width, height: cellSize.height)
        .clipped()
        .opacity(isPast || isCurrent ? 1.0 : 0.55)
        .overlay(
            RoundedRectangle(cornerRadius: 2)
                .stroke(isCurrent ? Color.white : Color.clear, lineWidth: 2)
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
