import Foundation

enum XGlassFeedWidth: String, CaseIterable, Codable, Identifiable {
    case focused
    case balanced
    case expansive

    var id: String { rawValue }

    var title: String {
        switch self {
        case .focused: "Focused"
        case .balanced: "Balanced"
        case .expansive: "Expansive"
        }
    }

    var subtitle: String {
        switch self {
        case .focused: "A narrow reading column"
        case .balanced: "Comfortable for most windows"
        case .expansive: "More room for media and messages"
        }
    }

    var systemImage: String {
        switch self {
        case .focused: "rectangle.compress.vertical"
        case .balanced: "rectangle.center.inset.filled"
        case .expansive: "rectangle.expand.vertical"
        }
    }

    var webPixels: Int {
        switch self {
        case .focused: 680
        case .balanced: 760
        case .expansive: 900
        }
    }
}
