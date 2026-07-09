import Foundation

enum ImageOrientation: String, Codable {
    case portrait
    case landscape
}

struct ImageAsset: Codable, Identifiable, Hashable {
    let id: UUID
    let url: URL
    let width: Int
    let height: Int
    let orientation: ImageOrientation

    init(id: UUID = UUID(), url: URL, width: Int, height: Int) {
        self.id = id
        self.url = url
        self.width = width
        self.height = height
        self.orientation = height > width ? .portrait : .landscape
    }
}
