import XCTest
import WebKit
@testable import XGlass

@MainActor
final class XGlassRecoveryBoundaryTests: XCTestCase {
    func testHungProbeTimesOutAndLateReplyIsIgnored() async {
        var late: (@MainActor (Bool?) -> Void)?
        let result = await XGlassPageProbe.run(timeout: .milliseconds(25)) { late = $0 }
        XCTAssertNil(result)
        late?(true)
        late?(false)
    }

    func testProbeAcceptsOnlyFirstReply() async {
        let result = await XGlassPageProbe.run(timeout: .milliseconds(25)) { reply in
            reply(true)
            reply(false)
        }
        XCTAssertEqual(result, true)
    }

    func testRecoveryRequestBypassesLocalCacheAndIsBounded() {
        let url = URL(string: "https://x.com/home")!
        let request = XBrowserModel.recoveryRequest(for: url)
        XCTAssertEqual(request.url, url)
        XCTAssertEqual(request.cachePolicy, .reloadIgnoringLocalCacheData)
        XCTAssertEqual(request.timeoutInterval, 30)
    }

    func testStopLeavesAnExplicitRecoverableState() {
        let model = XBrowserModel()
        model.loadState = "Loading"
        model.stopLoading()
        XCTAssertEqual(model.loadState, "Stopped")
        XCTAssertTrue(model.canRetry)
    }

    func testReadinessRejectsHiddenAndWrongPostContent() async throws {
        let config = WKWebViewConfiguration()
        config.websiteDataStore = .nonPersistent()
        let view = WKWebView(frame: NSRect(x: 0, y: 0, width: 600, height: 600), configuration: config)
        view.loadHTMLString("<html><body><main><article><a href='/person/status/1234'>Wrong post</a></article></main></body></html>", baseURL: URL(string: "https://x.com/person/status/123"))
        for _ in 0..<30 {
            if (try? await view.evaluateJavaScript("!!document.querySelector('article')")) as? Bool == true { break }
            try await Task.sleep(for: .milliseconds(100))
        }
        let wrong = try await view.evaluateJavaScript(XGlassLoadWatchdog.readinessScript)
        XCTAssertEqual(wrong as? Bool, false)
        _ = try await view.evaluateJavaScript("document.querySelector('a').href='/person/status/123'; document.querySelector('main').style.visibility='hidden'")
        let hidden = try await view.evaluateJavaScript(XGlassLoadWatchdog.readinessScript)
        XCTAssertEqual(hidden as? Bool, false)
        _ = try await view.evaluateJavaScript("document.querySelector('main').style.visibility='visible'")
        let ready = try await view.evaluateJavaScript(XGlassLoadWatchdog.readinessScript)
        XCTAssertEqual(ready as? Bool, true)
    }

    func testNavigationFailureKeepsAlreadyRenderedDocument() async throws {
        let config = WKWebViewConfiguration()
        config.websiteDataStore = .nonPersistent()
        let view = WKWebView(frame: NSRect(x: 0, y: 0, width: 600, height: 600), configuration: config)
        view.loadHTMLString("<main><article>Rendered content that should remain visible</article></main>", baseURL: URL(string: "https://x.com/home"))
        for _ in 0..<30 {
            if (try? await view.evaluateJavaScript("!!document.querySelector('article')")) as? Bool == true { break }
            try await Task.sleep(for: .milliseconds(100))
        }

        let model = XBrowserModel()
        model.webView = view
        model.loadState = "Loading"
        model.webView(view, didFail: nil, withError: URLError(.cannotConnectToHost))
        for _ in 0..<30 {
            if model.loadState == "Ready" { break }
            try await Task.sleep(for: .milliseconds(100))
        }
        XCTAssertEqual(model.loadState, "Ready")
        XCTAssertNil(model.statusMessage)
        XCTAssertFalse(model.canRetry)
    }

    func testNavigationFailureShowsRecoveryForUnrenderedDocument() async throws {
        let config = WKWebViewConfiguration()
        config.websiteDataStore = .nonPersistent()
        let view = WKWebView(frame: NSRect(x: 0, y: 0, width: 600, height: 600), configuration: config)
        view.loadHTMLString("<main><div role='progressbar'></div></main>", baseURL: URL(string: "https://x.com/home"))
        for _ in 0..<30 {
            if (try? await view.evaluateJavaScript("!!document.querySelector('[role=progressbar]')")) as? Bool == true { break }
            try await Task.sleep(for: .milliseconds(100))
        }

        let model = XBrowserModel()
        model.webView = view
        model.loadState = "Loading"
        model.webView(view, didFailProvisionalNavigation: nil, withError: URLError(.notConnectedToInternet))
        for _ in 0..<30 {
            if model.loadState == "Offline" { break }
            try await Task.sleep(for: .milliseconds(100))
        }
        XCTAssertEqual(model.loadState, "Offline")
        XCTAssertTrue(model.canRetry)
    }
}
