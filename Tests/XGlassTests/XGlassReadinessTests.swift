import XCTest
import WebKit
@testable import XGlass

@MainActor
final class XGlassReadinessTests: XCTestCase {
    func testLateContentClearsSlowStatusWithoutReloading() async throws {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .nonPersistent()
        let view = WKWebView(frame: NSRect(x: 0, y: 0, width: 600, height: 400), configuration: configuration)
        view.loadHTMLString("<html><body><main id='content'></main></body></html>", baseURL: URL(string: "https://x.com/home"))
        for _ in 0..<30 {
            if (try? await view.evaluateJavaScript("!!document.getElementById('content')")) as? Bool == true { break }
            try await Task.sleep(for: .milliseconds(100))
        }
        let browser = XBrowserModel()
        browser.monitorPageReadiness(in: view)
        browser.loadState = "Slow"
        browser.canRetry = true
        browser.statusMessage = "Waiting for content"
        _ = try await view.evaluateJavaScript("window.fixtureMarker = 42; document.querySelector('main').innerHTML='<article>Late content</article>'")
        for _ in 0..<30 {
            if browser.loadState == "Ready" { break }
            try await Task.sleep(for: .milliseconds(100))
        }
        XCTAssertEqual(browser.loadState, "Ready")
        XCTAssertFalse(browser.canRetry)
        XCTAssertNil(browser.statusMessage)
        let marker = try await view.evaluateJavaScript("window.fixtureMarker")
        XCTAssertEqual(marker as? Int, 42, "Recovery must not replace the loaded document")
        browser.cancelPendingNavigation()
    }
}
