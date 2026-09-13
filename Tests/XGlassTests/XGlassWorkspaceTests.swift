import AppKit
import XCTest
@testable import XGlass

final class XGlassQuickActionTests: XCTestCase {
    func testSearchEscapesQueryWithoutChangingItsMeaning() throws {
        let url = try XCTUnwrap(XGlassQuickAction.searchURL(for: "  from:someone cats & dogs #photos  "))
        let components = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: false))
        XCTAssertEqual(components.host, "x.com")
        XCTAssertEqual(components.path, "/search")
        XCTAssertEqual(components.queryItems?.first(where: { $0.name == "q" })?.value, "from:someone cats & dogs #photos")
        XCTAssertNil(XGlassQuickAction.searchURL(for: " \n "))
        XCTAssertEqual(XRoute.match(url: url), .explore)
    }

    func testQuickActionsFindDMsAndDistinguishSettingsDestinations() {
        XCTAssertEqual(XGlassQuickAction.matching("dm"), [.messages])
        XCTAssertEqual(XGlassQuickAction.matching("xglass settings"), [.settings])
        XCTAssertEqual(XGlassQuickAction.matching("account settings"), [.account])
        XCTAssertTrue(XGlassQuickAction.matching("unmatched query").isEmpty)
        XCTAssertEqual(XGlassQuickAction.account.route, .settings)
        XCTAssertNil(XGlassQuickAction.settings.route)
    }
}

@MainActor
final class XGlassReadingPreferencesTests: XCTestCase {
    func testReadingPreferencesAndFavoritesSurviveRelaunch() {
        let name = "XGlassTests.\(UUID())"
        let defaults = UserDefaults(suiteName: name)!
        defer { defaults.removePersistentDomain(forName: name) }
        let settings = XGlassSettingsStore(defaults: defaults)
        settings.setPageZoom(1.25)
        settings.setPauseMediaInBackground(false)
        settings.toggleFavorite(.forestRadar)
        settings.toggleFavorite(.roseQuartz)
        settings.toggleFavorite(.roseQuartz)
        let restored = XGlassSettingsStore(defaults: defaults)
        XCTAssertEqual(restored.pageZoom, 1.25)
        XCTAssertFalse(restored.pauseMediaInBackground)
        XCTAssertEqual(restored.favoriteThemes, [.forestRadar])
        restored.resetAppearance()
        XCTAssertEqual(restored.pageZoom, 1)
        XCTAssertEqual(restored.favoriteThemes, [.forestRadar])
    }

    func testCorruptZoomPreferencesCannotBreakTheWebView() {
        XCTAssertEqual(XGlassReadingScale.clamped(.nan), 1)
        XCTAssertEqual(XGlassReadingScale.clamped(.infinity), 1)
        XCTAssertEqual(XGlassReadingScale.clamped(-1), 0.8)
        XCTAssertEqual(XGlassReadingScale.clamped(9), 1.4)
    }

    func testButtonTextAdaptsToBothDarkAndLightAccents() {
        let light = XGlassThemeFamily.tahoeTide.colors.applying(.init(accentHex: "#FFFFFF"))
        let dark = XGlassThemeFamily.tahoeTide.colors.applying(.init(accentHex: "#000000"))
        XCTAssertEqual(light.webPresentation.accentForeground, "#000000")
        XCTAssertEqual(dark.webPresentation.accentForeground, "#FFFFFF")
        XCTAssertEqual(light.webPresentation.surface, dark.webPresentation.surface)
    }
}
