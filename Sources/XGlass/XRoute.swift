import Foundation

enum XRoute: String, CaseIterable, Identifiable {
    case home = "Home"
    case explore = "Explore"
    case notifications = "Notifications"
    case messages = "Messages"
    case bookmarks = "Bookmarks"
    case lists = "Lists"
    case profile = "Profile"
    case settings = "Settings"
    case compose = "Post"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .home: "house"
        case .explore: "magnifyingglass"
        case .notifications: "bell"
        case .messages: "envelope"
        case .bookmarks: "bookmark"
        case .lists: "list.bullet.rectangle"
        case .profile: "person.crop.circle"
        case .settings: "gearshape"
        case .compose: "square.and.pencil"
        }
    }

    var url: URL {
        switch self {
        case .home:
            URL(string: "https://x.com/?utm_source=xglass&utm_medium=mac_app")!
        case .explore:
            URL(string: "https://x.com/explore")!
        case .notifications:
            URL(string: "https://x.com/notifications")!
        case .messages:
            URL(string: "https://x.com/i/chat")!
        case .bookmarks:
            URL(string: "https://x.com/i/bookmarks")!
        case .lists:
            URL(string: "https://x.com/i/lists")!
        case .profile:
            URL(string: "https://x.com/home")!
        case .settings:
            URL(string: "https://x.com/settings/account")!
        case .compose:
            URL(string: "https://x.com/compose/post")!
        }
    }

    var navigationPaths: [String] {
        switch self {
        case .messages: ["/i/chat", "/messages"]
        case .home: ["/home", "/"]
        default: [url.path]
        }
    }

    static func match(url: URL) -> XRoute? {
        guard let host = url.host?.lowercased(), ["x.com", "www.x.com", "twitter.com", "www.twitter.com"].contains(host) else { return nil }
        let path = url.path.lowercased()
        if path.split(separator: "/").contains("status") { return nil }

        if path.hasPrefix("/explore") || path == "/search" {
            return .explore
        }
        if path.hasPrefix("/notifications") {
            return .notifications
        }
        if path.hasPrefix("/messages") || path.hasPrefix("/i/chat") {
            return .messages
        }
        if path.hasPrefix("/i/bookmarks") {
            return .bookmarks
        }
        if path.hasPrefix("/i/lists") ||
            (path.split(separator: "/").count == 2 && path.hasSuffix("/lists")) {
            return .lists
        }
        if path.hasPrefix("/settings") {
            return .settings
        }
        if path.hasPrefix("/compose") {
            return .compose
        }
        if path == "/" || path.hasPrefix("/home") {
            return .home
        }
        if isProfilePath(path) {
            return .profile
        }

        return nil
    }

    private static func isProfilePath(_ path: String) -> Bool {
        let reservedPrefixes = [
            "/compose",
            "/explore",
            "/home",
            "/i/",
            "/messages",
            "/notifications",
            "/search",
            "/settings"
        ]

        guard path.hasPrefix("/") else { return false }
        if reservedPrefixes.contains(where: { path.hasPrefix($0) }) {
            return false
        }

        let components = path.split(separator: "/").map(String.init)
        guard let first = components.first, !first.isEmpty else { return false }
        guard first != "intent", first.range(of: "^[a-z0-9_]{1,15}$", options: .regularExpression) != nil else { return false }
        return components.count == 1 || (components.count == 2 && ["with_replies", "media", "likes", "highlights", "articles"].contains(components[1]))
    }
}
