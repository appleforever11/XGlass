import Foundation

struct XGlassUnreadState: Codable, Equatable {
    var count = 0
    var newPosts = false
    var unread = false

    var isVisible: Bool { count > 0 || newPosts || unread }
    var badgeText: String? { count > 0 ? (count > 99 ? "99+" : String(count)) : nil }
    var accessibilityDescription: String {
        var parts: [String] = []
        if count > 0 { parts.append("\(count) unread updates") }
        else if unread { parts.append("Unread notifications") }
        if newPosts { parts.append("New posts available") }
        return parts.joined(separator: ", ")
    }
}
