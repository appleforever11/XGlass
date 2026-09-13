import XCTest
import WebKit
@testable import XGlass

@MainActor
final class XGlassReliabilityTests: XCTestCase {
    func testCompatibilityModeRemovesOptionalPresentationScripts() {
        let controller = WKUserContentController()
        XGlassWebScriptInstaller.install(on: controller, themePayload: "{}", preferencesPayload: "{}", compatibilityMode: true)
        XCTAssertEqual(controller.userScripts.count, 2)
        XCTAssertFalse(controller.userScripts.contains { $0.source.contains("function applyOverrides(") })
    }

    func testGoldenGateUsesExistingStudioPalette() {
        let theme = XGlassThemeFamily.goldenGate.colors.webPresentation
        XCTAssertEqual(theme.accent, "#E3A955")
        XCTAssertEqual(theme.text, "#FFF7E9")
        XCTAssertEqual(XGlassThemeFamily.goldenGate.collection, .macOS)
    }

    func testDiagnosticHistoryIsBoundedAndCancellationInvalidatesRecovery() {
        let browser = XBrowserModel()
        for _ in 0..<100 { browser.recordLoadEvent("Loading") }
        XCTAssertEqual(browser.diagnosticEvents.count, 60)
        let generation = browser.loadGeneration
        browser.cancelPendingNavigation()
        XCTAssertNotEqual(generation, browser.loadGeneration)
    }
}
