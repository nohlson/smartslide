import Foundation

struct SlideScene: Codable, Identifiable, Hashable {
    let id: UUID
    let layout: SlideLayout
    let imageURLs: [URL]

    init(id: UUID = UUID(), layout: SlideLayout, imageURLs: [URL]) {
        self.id = id
        self.layout = layout
        self.imageURLs = imageURLs
    }
}
