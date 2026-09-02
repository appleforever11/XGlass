import AppKit
import Foundation
import XCTest
@testable import XGlass

final class XGlassRouteTests: XCTestCase {
    func testRouteMatchingRecognizesPrimaryDestinations() {
        XCTAssertEqual(XRoute.match(url: URL(string: "https://x.com/")!), .home)
        XCTAssertEqual(XRoute.match(url: URL(string: "https://x.com/explore/trending")!), .explore)
        XCTAssertEqual(XRoute.match(url: URL(string: "https://x.com/notifications")!), .notifications)
        XCTAssertEqual(XRoute.match(url: URL(string: "https://x.com/i/bookmarks")!), .bookmarks)
        XCTAssertEqual(XRoute.match(url: URL(string: "https://x.com/i/lists/123")!), .lists)
        XCTAssertEqual(XRoute.match(url: URL(string: "https://x.com/settings/account")!), .settings)
        XCTAssertEqual(XRoute.match(url: URL(string: "https://x.com/compose/post")!), .compose)
        XCTAssertEqual(XRoute.match(url: URL(string: "https://x.com/appleforever11/status/123")!), .profile)
    }

    func testMessagesRetainsBothKnownXPaths() {
        XCTAssertEqual(XRoute.messages.navigationPaths, ["/i/chat", "/messages"])
        XCTAssertEqual(XRoute.match(url: URL(string: "https://x.com/i/chat")!), .messages)
        XCTAssertEqual(XRoute.match(url: URL(string: "https://x.com/messages")!), .messages)
    }
}

@MainActor
final class XGlassSettingsStoreTests: XCTestCase {
    private let suiteName = "XGlassTests.\(UUID().uuidString)"

    private var defaults: UserDefaults {
        UserDefaults(suiteName: suiteName)!
    }

    func testDefaultsAreReleaseSafe() {
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let settings = XGlassSettingsStore(defaults: defaults)

        XCTAssertEqual(settings.theme, .tahoeTide)
        XCTAssertEqual(settings.backgroundGlow, 0.78, accuracy: 0.001)
        XCTAssertEqual(settings.glassIntensity, 0.82, accuracy: 0.001)
        XCTAssertTrue(settings.reduceMotion)
        XCTAssertTrue(settings.hidePromotedPosts)
        XCTAssertEqual(settings.feedWidth, .balanced)
        XCTAssertTrue(settings.showBrowserToolbar)
    }

    func testValuesClampAndPersist() {
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let settings = XGlassSettingsStore(defaults: defaults)
        settings.setBackgroundGlow(5)
        settings.setGlassIntensity(-1)
        settings.setTheme(.violetBloom)
        settings.setHidePromotedPosts(false)
        settings.setFeedWidth(.expansive)
        settings.setShowBrowserToolbar(false)

        let restored = XGlassSettingsStore(defaults: defaults)
        XCTAssertEqual(restored.backgroundGlow, 1.0, accuracy: 0.001)
        XCTAssertEqual(restored.glassIntensity, 0.25, accuracy: 0.001)
        XCTAssertEqual(restored.theme, .violetBloom)
        XCTAssertFalse(restored.hidePromotedPosts)
        XCTAssertEqual(restored.feedWidth, .expansive)
        XCTAssertFalse(restored.showBrowserToolbar)
    }

    func testJavaScriptPayloadsAreValidAndReflectSettings() throws {
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let settings = XGlassSettingsStore(defaults: defaults)
        settings.setTheme(.forestRadar)
        settings.setHidePromotedPosts(false)

        let themeObject = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(settings.javascriptThemePayload.utf8)) as? [String: String])
        settings.setFeedWidth(.focused)
        let preferenceObject = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(settings.javascriptPreferencesPayload.utf8)) as? [String: Any])

        XCTAssertEqual(themeObject["accent"], XGlassThemeFamily.forestRadar.colors.web.accent)
        XCTAssertEqual(preferenceObject["hidePromotedPosts"] as? Bool, false)
        XCTAssertEqual(preferenceObject["feedWidth"] as? Int, XGlassFeedWidth.focused.webPixels)
    }

    func testResetAppearanceRestoresReleaseDefaults() {
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let settings = XGlassSettingsStore(defaults: defaults)
        settings.setTheme(.roseQuartz)
        settings.setFeedWidth(.expansive)
        settings.setShowBrowserToolbar(false)
        settings.setCompactSidebar(true)

        settings.resetAppearance()

        XCTAssertEqual(settings.theme, .tahoeTide)
        XCTAssertEqual(settings.feedWidth, .balanced)
        XCTAssertTrue(settings.showBrowserToolbar)
        XCTAssertFalse(settings.compactSidebar)
        XCTAssertTrue(settings.reduceMotion)
    }
}

@MainActor
final class XGlassImageSaveCoordinatorTests: XCTestCase {
    func testImageFilenamePreservesExtensionAndIncludesUniqueSuffix() {
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        let uuid = UUID(uuidString: "12345678-1234-1234-1234-123456789ABC")!
        let url = URL(string: "https://pbs.twimg.com/media/example.PNG")!

        let filename = XImageSaveCoordinator.defaultFilename(for: url, now: date, uuid: uuid)

        XCTAssertTrue(filename.hasPrefix("XGlass Image "))
        XCTAssertTrue(filename.hasSuffix("-12345678.png"))
    }

    func testImageFilenameFallsBackToJPGAndDoesNotCollide() {
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        let url = URL(string: "https://pbs.twimg.com/media/example")!
        let first = XImageSaveCoordinator.defaultFilename(
            for: url,
            now: date,
            uuid: UUID(uuidString: "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA")!
        )
        let second = XImageSaveCoordinator.defaultFilename(
            for: url,
            now: date,
            uuid: UUID(uuidString: "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB")!
        )

        XCTAssertTrue(first.hasSuffix(".jpg"))
        XCTAssertNotEqual(first, second)
    }
}

final class XGlassShellLayoutTests: XCTestCase {
    func testShellAdaptsWithoutCrushingBrowserContent() {
        let narrow = XGlassShellLayout(windowWidth: 640, compactPreference: false)
        let standard = XGlassShellLayout(windowWidth: 900, compactPreference: false)
        let wide = XGlassShellLayout(windowWidth: 1280, compactPreference: false)

        XCTAssertEqual(narrow.railWidth, 58)
        XCTAssertTrue(narrow.isCompact)
        XCTAssertFalse(standard.showsRouteLabels)
        XCTAssertTrue(wide.showsRouteLabels)
        XCTAssertEqual(wide.railWidth, 178)
    }

    func testCompactPreferenceKeepsWideRailIconOnly() {
        let layout = XGlassShellLayout(windowWidth: 1280, compactPreference: true)

        XCTAssertFalse(layout.showsRouteLabels)
        XCTAssertEqual(layout.railWidth, 66)
    }
}

final class XGlassStartupWindowFrameTests: XCTestCase {
    func testFrameMatchesTheRequestedDesktopPlacement() {
        let screen = NSRect(x: 0, y: 0, width: 1_800, height: 1_169)

        let frame = XGlassStartupWindowFrame.frame(in: screen)

        XCTAssertEqual(frame, NSRect(x: 0, y: 64, width: 600, height: 1_059))
        XCTAssertEqual(screen.maxY - frame.maxY, 46)
    }

    func testFrameStaysInsideACompactDisplay() {
        let screen = NSRect(x: -560, y: 200, width: 560, height: 800)

        let frame = XGlassStartupWindowFrame.frame(in: screen)

        XCTAssertEqual(frame, screen)
        XCTAssertTrue(screen.contains(frame))
    }
}

final class XGlassThemeFilterTests: XCTestCase {
    func testMatchingUsesCollectionAndSearchText() {
        XCTAssertEqual(
            XGlassThemeFilter.matching(query: "  ORCHID  ", collection: .all),
            [.violetBloom]
        )
        XCTAssertEqual(
            XGlassThemeFilter.matching(query: "", collection: .cool),
            [.tahoeTide, .arcticSignal, .oceanDrive]
        )
    }

    func testMatchingReturnsEmptyStateForUnknownText() {
        XCTAssertTrue(
            XGlassThemeFilter.matching(query: "not a real environment", collection: .all).isEmpty
        )
    }
}

final class XGlassThemePaletteTests: XCTestCase {
    func testEveryThemeProvidesCompleteWebPalette() {
        for theme in XGlassThemeFamily.allCases {
            let web = theme.colors.web
            let values = [
                web.bandTop,
                web.bandBottom,
                web.accent,
                web.accentSoft,
                web.text,
                web.muted,
                web.border,
                web.incomingBubble,
                web.outgoingBubble
            ]

            XCTAssertFalse(theme.title.isEmpty)
            XCTAssertFalse(theme.subtitle.isEmpty)
            XCTAssertTrue(values.allSatisfy { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty })
        }
    }
}

final class XInterfaceHealthTests: XCTestCase {
    func testPayloadDecodesAndBuildsAHealthyReport() throws {
        let payload = try XInterfaceHealthPayload.decode(json: """
        {
          "pagePath": "/home",
          "primaryColumn": true,
          "customStyles": true,
          "nativeSidebarSuppressed": true,
          "themeBridge": true,
          "preferenceBridge": true,
          "interactiveControls": true,
          "composerSurface": true,
          "adFilterEnabled": true
        }
        """)

        let report = XInterfaceHealthReportBuilder.make(
            payload: payload,
            currentURL: XRoute.home.url,
            checkedAt: Date(timeIntervalSince1970: 1_700_000_000)
        )

        XCTAssertEqual(report.pagePath, "/home")
        XCTAssertEqual(report.checks.count, 9)
        XCTAssertTrue(report.allPassed)
    }

    func testUnavailableReportExplainsTheStartupBoundary() {
        let report = XInterfaceHealthReportBuilder.unavailable(
            checkedAt: Date(timeIntervalSince1970: 1_700_000_000)
        )

        XCTAssertEqual(report.pagePath, "Unavailable")
        XCTAssertFalse(report.allPassed)
        XCTAssertEqual(report.checks.first?.detail, "The X session is still starting")
    }
}

final class XGlassDOMScriptTests: XCTestCase {
    func testAssembledScriptRetainsBoundedSchedulingAndStyles() {
        let script = XGlassDOMScripts.chromeSuppression(minimumPaintInterval: 250)

        XCTAssertTrue(script.contains("const minimumPaintInterval = 250;"))
        XCTAssertTrue(script.contains("new MutationObserver((records) =>"))
        XCTAssertTrue(script.contains("xglass-layout-overrides"))
        XCTAssertFalse(script.contains("__XGLASS_BASE_STYLES__"))
        XCTAssertFalse(script.contains("__XGLASS_THEME_STYLES__"))
        XCTAssertFalse(script.contains("new MutationObserver(scheduleOverrides)"))
        XCTAssertFalse(script.contains("setInterval("))
    }
}
