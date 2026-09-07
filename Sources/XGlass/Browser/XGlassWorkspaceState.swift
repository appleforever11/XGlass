import Combine
import Foundation

@MainActor
final class XGlassWorkspaceState: ObservableObject {
    @Published var showsQuickSwitcher = false
    @Published var isFocused = false
}

enum XGlassReadingScale {
    static let range = 0.8...1.4

    static func clamped(_ value: Double) -> Double {
        guard value.isFinite else { return 1 }
        return min(max(value, range.lowerBound), range.upperBound)
    }
}

enum XGlassQuickAction: String, CaseIterable, Identifiable {
    case home, explore, notifications, messages, bookmarks, lists, profile, compose
    case focus, copyLink, reload, settings, account

    var id: String { rawValue }

    var title: String {
        switch self {
        case .home: "Home"
        case .explore: "Explore"
        case .notifications: "Notifications"
        case .messages: "Messages"
        case .bookmarks: "Bookmarks"
        case .lists: "Lists"
        case .profile: "Your profile"
        case .compose: "New post"
        case .focus: "Toggle focus mode"
        case .copyLink: "Copy page link"
        case .reload: "Reload page"
        case .settings: "XGlass Settings"
        case .account: "X account settings"
        }
    }

    var route: XRoute? {
        switch self {
        case .home: .home
        case .explore: .explore
        case .notifications: .notifications
        case .messages: .messages
        case .bookmarks: .bookmarks
        case .lists: .lists
        case .profile: .profile
        case .compose: .compose
        case .account: .settings
        default: nil
        }
    }

    var symbol: String {
        if let route { return route.systemImage }
        switch self {
        case .focus: return "rectangle.inset.filled"
        case .copyLink: return "link"
        case .reload: return "arrow.clockwise"
        default: return "gearshape"
        }
    }

    static func matching(_ query: String) -> [Self] {
        let words = query.split(whereSeparator: \.isWhitespace)
        return allCases.filter { action in
            let keywords = action.title + " " + action.rawValue + (action == .messages ? " DM chat inbox" : "")
            return words.allSatisfy { keywords.localizedCaseInsensitiveContains(String($0)) }
        }
    }

    static func searchURL(for query: String) -> URL? {
        let query = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return nil }
        var components = URLComponents(string: "https://x.com/search")!
        components.queryItems = [URLQueryItem(name: "q", value: query), URLQueryItem(name: "src", value: "typed_query")]
        return components.url
    }
}
