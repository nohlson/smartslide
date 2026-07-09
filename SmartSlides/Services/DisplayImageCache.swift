import AppKit
import ImageIO

/// Loads full-resolution playback images, capped to the display's native pixel size — no
/// visible quality loss (the screen can't show more pixels than it has), but avoids holding a
/// much larger decoded bitmap in memory than can ever actually be rendered.
///
/// Backed by `NSCache`, which is both count- and cost-bounded here and automatically evicts
/// under system memory pressure. That's the whole memory strategy: recently-shown images stay
/// around for instant re-display, everything else is dropped, and the cache can never grow
/// without bound no matter how long the slideshow runs.
@MainActor
final class DisplayImageCache {
    static let shared = DisplayImageCache()

    private let cache = NSCache<NSURL, NSImage>()
    private let maxPixelSize: CGFloat

    private init() {
        // Current scene + a couple of prefetched neighbors either side (2-image layouts need
        // up to 2 URLs per scene) — enough for instant switching without keeping the whole
        // library's full-resolution data resident.
        cache.countLimit = 10
        cache.totalCostLimit = 160 * 1024 * 1024 // ~160MB ceiling on decoded bitmap bytes

        let screen = NSScreen.main
        let scale = screen?.backingScaleFactor ?? 2
        let size = screen?.frame.size ?? CGSize(width: 1920, height: 1080)
        maxPixelSize = max(size.width, size.height) * scale
    }

    /// Synchronous cache check — used so already-loaded images (e.g. prefetched neighbors)
    /// display instantly with no async hop.
    func cachedImage(for url: URL) -> NSImage? {
        cache.object(forKey: url as NSURL)
    }

    /// Loads (decoding off the main thread) and caches the image. Safe to call repeatedly for
    /// the same URL — returns the cached instance if already loaded.
    @discardableResult
    func load(_ url: URL) async -> NSImage? {
        if let cached = cachedImage(for: url) { return cached }

        let cap = maxPixelSize
        let decoded = await Task.detached(priority: .userInitiated) { () -> (image: NSImage, cost: Int)? in
            guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
            let options: [CFString: Any] = [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceThumbnailMaxPixelSize: cap,
                kCGImageSourceCreateThumbnailWithTransform: true
            ]
            guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else { return nil }
            let image = NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
            let cost = cgImage.width * cgImage.height * 4
            return (image, cost)
        }.value

        guard let decoded else { return nil }
        cache.setObject(decoded.image, forKey: url as NSURL, cost: decoded.cost)
        return decoded.image
    }

    /// Best-effort background warm-up for scenes about to be shown — doesn't block or throw,
    /// just populates the cache ahead of time so playback transitions feel instant.
    func prefetch(_ urls: [URL]) async {
        for url in urls {
            _ = await load(url)
        }
    }
}
