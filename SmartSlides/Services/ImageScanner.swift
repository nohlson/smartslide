import Foundation
import ImageIO
import UniformTypeIdentifiers

struct ScanResult {
    var assets: [ImageAsset] = []
    var totalCount: Int { assets.count }
    var portraitCount: Int { assets.filter { $0.orientation == .portrait }.count }
    var landscapeCount: Int { assets.filter { $0.orientation == .landscape }.count }
}

enum ImageScanner {
    static let supportedExtensions: Set<String> = ["jpg", "jpeg", "png", "heic", "tiff", "tif", "gif"]

    static func scan(folder: URL, includeSubfolders: Bool) -> ScanResult {
        let fm = FileManager.default
        var urls: [URL] = []

        if includeSubfolders {
            if let enumerator = fm.enumerator(
                at: folder,
                includingPropertiesForKeys: [.isRegularFileKey],
                options: [.skipsHiddenFiles, .skipsPackageDescendants]
            ) {
                for case let url as URL in enumerator {
                    if supportedExtensions.contains(url.pathExtension.lowercased()) {
                        urls.append(url)
                    }
                }
            }
        } else {
            if let contents = try? fm.contentsOfDirectory(
                at: folder,
                includingPropertiesForKeys: [.isRegularFileKey],
                options: [.skipsHiddenFiles]
            ) {
                urls = contents.filter { supportedExtensions.contains($0.pathExtension.lowercased()) }
            }
        }

        var assets: [ImageAsset] = []
        for url in urls {
            if let dims = dimensions(of: url) {
                assets.append(ImageAsset(url: url, width: dims.width, height: dims.height))
            }
        }
        return ScanResult(assets: assets)
    }

    /// Reads image dimensions from metadata without decoding the full image.
    private static func dimensions(of url: URL) -> (width: Int, height: Int)? {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any]
        else { return nil }

        guard var width = properties[kCGImagePropertyPixelWidth] as? Int,
              var height = properties[kCGImagePropertyPixelHeight] as? Int
        else { return nil }

        // Account for EXIF orientation values that imply a 90-degree rotation.
        if let orientation = properties[kCGImagePropertyOrientation] as? Int, [5, 6, 7, 8].contains(orientation) {
            swap(&width, &height)
        }

        return (width, height)
    }
}
