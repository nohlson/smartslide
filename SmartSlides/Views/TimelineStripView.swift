import SwiftUI

/// A read-only, scrollable filmstrip showing a compressed thumbnail of every scene in the
/// generated timeline — purely for visual orientation on where the current slide sits.
struct TimelineStripView: View {
    let scenes: [SlideScene]
    let currentIndex: Int
    @ObservedObject var thumbnailStore: ThumbnailStore

    private let thumbHeight: CGFloat = 64

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
                                        height: thumbHeight
                                    )
                                    .id(scene.id)
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
    let height: CGFloat

    var body: some View {
        HStack(spacing: 1) {
            ForEach(scene.imageURLs, id: \.self) { url in
                thumbnailImage(for: url)
            }
        }
        .opacity(isPast || isCurrent ? 1.0 : 0.55)
        .overlay(
            RoundedRectangle(cornerRadius: 2)
                .stroke(isCurrent ? Color.white : Color.clear, lineWidth: 2)
        )
    }

    @ViewBuilder
    private func thumbnailImage(for url: URL) -> some View {
        if let image = thumbnails[url] {
            let aspect = image.size.height > 0 ? image.size.width / image.size.height : 1
            Image(nsImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: aspect * height, height: height)
        } else {
            Rectangle()
                .fill(Color.gray.opacity(0.25))
                .frame(width: height * 0.75, height: height)
        }
    }
}
