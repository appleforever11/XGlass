import Combine
import Foundation

@MainActor
final class XGlassSettingsStore: ObservableObject {
    @Published private(set) var theme: XGlassThemeFamily
    @Published private(set) var backgroundGlow: Double
    @Published private(set) var glassIntensity: Double
    @Published private(set) var reduceMotion: Bool
    @Published private(set) var hidePromotedPosts: Bool
    @Published private(set) var compactSidebar: Bool
    @Published private(set) var feedWidth: XGlassFeedWidth
    @Published private(set) var showBrowserToolbar: Bool

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        theme = XGlassThemeFamily(rawValue: defaults.string(forKey: XGlassSettingsKeys.theme) ?? "") ?? .tahoeTide
        backgroundGlow = Self.clamp(defaults.object(forKey: XGlassSettingsKeys.backgroundGlow) as? Double ?? 0.78, range: 0.35...1.0)
        glassIntensity = Self.clamp(defaults.object(forKey: XGlassSettingsKeys.glassIntensity) as? Double ?? 0.82, range: 0.25...1.0)
        // Keep the default idle footprint low; users can re-enable ambient motion in Appearance.
        reduceMotion = defaults.object(forKey: XGlassSettingsKeys.reduceMotion) as? Bool ?? true
        hidePromotedPosts = defaults.object(forKey: XGlassSettingsKeys.hidePromotedPosts) as? Bool ?? true
        compactSidebar = defaults.object(forKey: XGlassSettingsKeys.compactSidebar) as? Bool ?? false
        feedWidth = XGlassFeedWidth(
            rawValue: defaults.string(forKey: XGlassSettingsKeys.feedWidth) ?? ""
        ) ?? .balanced
        showBrowserToolbar = defaults.object(forKey: XGlassSettingsKeys.showBrowserToolbar) as? Bool ?? true
    }

    var colors: XGlassThemeColors { theme.colors }

    func setTheme(_ value: XGlassThemeFamily) {
        theme = value
        defaults.set(value.rawValue, forKey: XGlassSettingsKeys.theme)
    }

    func setBackgroundGlow(_ value: Double) {
        backgroundGlow = Self.clamp(value, range: 0.35...1.0)
        defaults.set(backgroundGlow, forKey: XGlassSettingsKeys.backgroundGlow)
    }

    func setGlassIntensity(_ value: Double) {
        glassIntensity = Self.clamp(value, range: 0.25...1.0)
        defaults.set(glassIntensity, forKey: XGlassSettingsKeys.glassIntensity)
    }

    func setReduceMotion(_ value: Bool) {
        reduceMotion = value
        defaults.set(value, forKey: XGlassSettingsKeys.reduceMotion)
    }

    func setHidePromotedPosts(_ value: Bool) {
        hidePromotedPosts = value
        defaults.set(value, forKey: XGlassSettingsKeys.hidePromotedPosts)
    }

    func setCompactSidebar(_ value: Bool) {
        compactSidebar = value
        defaults.set(value, forKey: XGlassSettingsKeys.compactSidebar)
    }

    func setFeedWidth(_ value: XGlassFeedWidth) {
        feedWidth = value
        defaults.set(value.rawValue, forKey: XGlassSettingsKeys.feedWidth)
    }

    func setShowBrowserToolbar(_ value: Bool) {
        showBrowserToolbar = value
        defaults.set(value, forKey: XGlassSettingsKeys.showBrowserToolbar)
    }

    func resetAppearance() {
        setTheme(.tahoeTide)
        setBackgroundGlow(0.78)
        setGlassIntensity(0.82)
        setReduceMotion(true)
        setCompactSidebar(false)
        setFeedWidth(.balanced)
        setShowBrowserToolbar(true)
    }

    var javascriptThemePayload: String {
        encode(colors.web)
    }

    var javascriptPreferencesPayload: String {
        encode(JavaScriptPreferences(
            hidePromotedPosts: hidePromotedPosts,
            feedWidth: feedWidth.webPixels
        ))
    }

    private func encode<T: Encodable>(_ value: T) -> String {
        guard let data = try? JSONEncoder().encode(value),
              let result = String(data: data, encoding: .utf8) else {
            return "{}"
        }
        return result
    }

    private static func clamp(_ value: Double, range: ClosedRange<Double>) -> Double {
        min(max(value, range.lowerBound), range.upperBound)
    }
}

private struct JavaScriptPreferences: Codable {
    let hidePromotedPosts: Bool
    let feedWidth: Int
}
