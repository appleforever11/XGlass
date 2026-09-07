import XCTest
import WebKit
@testable import XGlass

@MainActor
final class XGlassFindTests: XCTestCase {
    func testFindReportsMatchesAndClearsOnClose() async throws {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .nonPersistent()
        let view = WKWebView(frame: NSRect(x: 0, y: 0, width: 600, height: 400), configuration: configuration)
        view.loadHTMLString("<html><body><p>XGlass fixture needle</p></body></html>", baseURL: nil)
        for _ in 0..<50 {
            if (try? await view.evaluateJavaScript("document.body?.innerText.includes('fixture needle')")) as? Bool == true { break }
            try await Task.sleep(for: .milliseconds(100))
        }
        let browser = XBrowserModel()
        browser.webView = view
        browser.showsFindBar = true
        browser.findQuery = "fixture needle"
        browser.findInPage()
        for _ in 0..<30 {
            if browser.findMatch != nil { break }
            try await Task.sleep(for: .milliseconds(100))
        }
        XCTAssertEqual(browser.findMatch, true)
        browser.findQuery = "absent-search-term"
        browser.findInPage()
        for _ in 0..<30 {
            if browser.findMatch == false { break }
            try await Task.sleep(for: .milliseconds(100))
        }
        XCTAssertEqual(browser.findMatch, false)
        browser.closeFindBar()
        XCTAssertFalse(browser.showsFindBar)
        XCTAssertTrue(browser.findQuery.isEmpty)
    }
}
