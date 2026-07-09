import AppKit
import ImageIO

/// Generates and caches small downsampled thumbnails for timeline images.
/// Uses CGImageSource's thumbnail API so it doesn't fully decode each source image.
@MainActor
final class ThumbnailStore: ObservableObject {
    @Published private(set) var thumbnails: [URL: NSImage] = [:]
    @Published private(set) var isGenerating: Bool = false
    @Published private(set) var progress: Int = 0
    @Published private(set) var total: Int = 0

    private var currentTask: Task<Void, Never>?
    private nonisolated static let maxPixelSize: CGFloat = 200

    /// Generates thumbnails for any of the given URLs not already cached.
    /// Cancels any in-flight generation from a previous call (e.g. a new hash/folder/layout change).
    func generate(for urls: [URL]) {
        currentTask?.cancel()

        let missing = Array(Set(urls)).filter { thumbnails[$0] == nil }
        guard !missing.isEmpty else {
            isGenerating = false
            return
        }

        total = missing.count
        progress = 0
        isGenerating = true

        currentTask = Task {
            await withTaskGroup(of: (URL, NSImage?).self) { group in
                for url in missing {
                    group.addTask {
                        (url, Self.makeThumbnail(url: url))
                    }
                }
                for await (url, image) in group {
                    if Task.isCancelled { return }
                    if let image {
                        thumbnails[url] = image
                    }
                    progress += 1
                }
            }
            if !Task.isCancelled {
                isGenerating = false
            }
        }
    }

    nonisolated private static func makeThumbnail(url: URL) -> NSImage? {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize,
            kCGImageSourceCreateThumbnailWithTransform: true
        ]
        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else { return nil }
        return NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
    }
}
