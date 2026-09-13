import WebKit
import XCTest
@testable import XGlass

@MainActor
final class XGlassStabilityStressTests: XCTestCase {
    func testTelemetryRejectsContentAndBoundsNumbers() {
        XCTAssertNil(XGlassLoadTelemetry.summary(["phase":"private content"]))
        let summary = XGlassLoadTelemetry.summary(["phase":"errors", "errors":Double.infinity, "scripts":9e20, "ms":-1.0, "url":"private", "message":"secret"])
        XCTAssertEqual(summary, "Web errors: 0ms; failed scripts 1000000, styles 0, images 0, JS errors 0")
    }

    func testPostsAndExternalSitesDoNotSelectProfile() {
        XCTAssertNil(XRoute.match(url: URL(string:"https://x.com/someone/status/123")!))
        XCTAssertNil(XRoute.match(url: URL(string:"https://example.com/person")!))
        XCTAssertEqual(XRoute.match(url: URL(string:"https://x.com/someone/media")!), .profile)
    }

    func testPresentationWaitsForContentAndTelemetryRemainsInstalled() async throws {
        let config = WKWebViewConfiguration()
        config.websiteDataStore = .nonPersistent()
        XGlassWebScriptInstaller.install(on: config.userContentController, themePayload:"{}", preferencesPayload:"{}")
        let view = WKWebView(frame: NSRect(x:0,y:0,width:600,height:600), configuration:config)
        view.loadHTMLString("<html><body><div>Loading</div></body></html>", baseURL:URL(string:"https://x.com/home"))
        try await Task.sleep(for:.seconds(1))
        let before = try await view.evaluateJavaScript("!!document.getElementById('xglass-layout-overrides')")
        XCTAssertEqual(before as? Bool, false)
        let metrics = try await view.evaluateJavaScript("window.__xglassLoadTelemetry === true")
        XCTAssertEqual(metrics as? Bool, true)
        _ = try await view.evaluateJavaScript("Object.defineProperty(document, 'hidden', {configurable:true, value:false}); document.body.innerHTML='<main><article>Fixture content</article></main>'; document.dispatchEvent(new Event('visibilitychange'))")
        try await Task.sleep(for:.seconds(1))
        let applied = try await view.evaluateJavaScript("typeof window.__xglassSetPreferences === 'function'")
        XCTAssertEqual(applied as? Bool, true)
    }

    func testDelayedScrollSaveStaysWithOriginalRoute() async throws {
        let config = WKWebViewConfiguration()
        config.websiteDataStore = .nonPersistent()
        let view = WKWebView(frame: NSRect(x:0,y:0,width:600,height:600), configuration:config)
        view.loadHTMLString("<html><body style='height:5000px'><main>Scroll fixture</main></body></html>", baseURL:URL(string:"https://x.com/home"))
        try await Task.sleep(for:.seconds(1))
        _ = try await view.evaluateJavaScript(XGlassScrollRestoration.source)
        _ = try await view.evaluateJavaScript("scrollTo(0,200); window.dispatchEvent(new Event('scroll')); history.pushState({}, '', '/explore');")
        try await Task.sleep(for:.milliseconds(600))
        let stored = try await view.evaluateJavaScript("sessionStorage.getItem('xglass-scroll:/home')")
        XCTAssertEqual(stored as? String,"200")
        let wrongRoute = try await view.evaluateJavaScript("sessionStorage.getItem('xglass-scroll:/explore') === null")
        XCTAssertEqual(wrongRoute as? Bool,true)
    }

    func testTwentyNavigationCyclesAndOfflineRecovery() async throws {
        let config = WKWebViewConfiguration()
        config.websiteDataStore = .nonPersistent()
        let view = WKWebView(frame:NSRect(x:0,y:0,width:600,height:600), configuration:config)
        let model = XBrowserModel()
        model.webView = view
        for cycle in 0..<20 {
            model.cancelPendingNavigation()
            view.loadHTMLString("<html><body><main><article id='cycle-\(cycle)'>Content</article></main></body></html>", baseURL:URL(string:"https://x.com/home"))
            for _ in 0..<40 {
                if (try? await view.evaluateJavaScript("!!document.getElementById('cycle-\(cycle)')")) as? Bool == true { break }
                try await Task.sleep(for:.milliseconds(50))
            }
            model.monitorPageReadiness(in:view)
            for _ in 0..<30 {
                if model.loadState == "Ready" { break }
                try await Task.sleep(for:.milliseconds(100))
            }
            XCTAssertEqual(model.loadState,"Ready", "cycle \(cycle)")
            XCTAssertFalse(model.canRetry)
            if cycle == 10 {
                _ = try await view.evaluateJavaScript("document.body.innerHTML='<main><div role=progressbar></div></main>'; 'ok'")
                model.webView(view, didFailProvisionalNavigation:nil, withError:URLError(.notConnectedToInternet))
                for _ in 0..<30 {
                    if model.loadState == "Offline" { break }
                    try await Task.sleep(for: .milliseconds(100))
                }
                XCTAssertEqual(model.loadState,"Offline")
                XCTAssertTrue(model.canRetry)
            }
        }
        XCTAssertLessThanOrEqual(model.diagnosticEvents.count,60)
        model.cancelPendingNavigation()
    }
}
