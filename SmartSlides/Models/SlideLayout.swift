import Foundation

enum SlideLayout: String, Codable, CaseIterable, Hashable {
    case onePortrait
    case oneLandscape
    case twoPortraitsSideBySide
    case twoLandscapesSideBySide

    var displayName: String {
        switch self {
        case .onePortrait: return "1 Portrait"
        case .oneLandscape: return "1 Landscape"
        case .twoPortraitsSideBySide: return "2 Portraits Side by Side"
        case .twoLandscapesSideBySide: return "2 Landscapes Side by Side"
        }
    }

    var imageCount: Int {
        switch self {
        case .onePortrait, .oneLandscape: return 1
        case .twoPortraitsSideBySide, .twoLandscapesSideBySide: return 2
        }
    }

    var orientation: ImageOrientation {
        switch self {
        case .onePortrait, .twoPortraitsSideBySide: return .portrait
        case .oneLandscape, .twoLandscapesSideBySide: return .landscape
        }
    }
}
