import WebKit
import XCTest
@testable import XGlass

@MainActor
final class XGlassWebPresentationTests: XCTestCase {
    private final class Loader: NSObject, WKNavigationDelegate {
        let loaded: XCTestExpectation
        init(_ loaded: XCTestExpectation) { self.loaded = loaded }
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) { loaded.fulfill() }
    }

    func testBootstrapReplacementPreservesLatestThemeWithoutAccumulatingScripts() {
        let controller = WKUserContentController()
        for value in 0..<12 {
            XGlassWebScriptInstaller.install(on: controller, themePayload: "{\"revision\":\(value)}", preferencesPayload: "{}")
        }
        XCTAssertEqual(controller.userScripts.count, 4)
        XCTAssertTrue(controller.userScripts[0].source.contains("\"revision\":11"))
    }

    func testReadinessProbeDistinguishesSplashFromContentAndAuthentication() async throws {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .nonPersistent()
        let webView = WKWebView(frame: CGRect(x: 0, y: 0, width: 600, height: 800), configuration: configuration)
        let loaded = expectation(description: "Readiness fixture loaded")
        let loader = Loader(loaded)
        webView.navigationDelegate = loader
        webView.loadHTMLString("<html><body><div id='placeholder'>X</div></body></html>", baseURL: nil)
        await fulfillment(of: [loaded], timeout: 15)
        func ready() async throws -> String {
            try await evaluate("String(\(XGlassLoadWatchdog.readinessScript.dropLast()))", in: webView)
        }
        let splash = try await ready()
        XCTAssertEqual(splash, "false")
        _ = try await evaluate("document.body.innerHTML = '<input type=password aria-label=Password>'; 'ok'", in: webView)
        let authentication = try await ready()
        XCTAssertEqual(authentication, "true")
        _ = try await evaluate("document.body.innerHTML = '<main><article>A post</article></main>'; 'ok'", in: webView)
        let timeline = try await ready()
        XCTAssertEqual(timeline, "true")
        _ = try await evaluate("document.body.innerHTML = '<main><div role=progressbar></div></main>'; 'ok'", in: webView)
        let spinner = try await ready()
        XCTAssertEqual(spinner, "false")

        _ = try await evaluate("document.body.innerHTML = '<input aria-label=Search><main><div role=progressbar></div></main>'; 'ok'", in: webView)
        let searchWithSpinner = try await ready()
        XCTAssertEqual(searchWithSpinner, "false", "Search chrome must not satisfy content readiness")
        _ = try await evaluate("document.body.innerHTML = '<textarea>Unsent message</textarea>'; 'ok'", in: webView)
        let draft = try await evaluate("String(\(XBrowserModel.draftScript.dropLast()))", in: webView)
        XCTAssertEqual(draft, "true")
        let focusedEmptyEditor = try await evaluate("""
        const editor = document.querySelector('textarea');
        editor.value = '';
        editor.focus();
        String(\(XBrowserModel.draftScript.dropLast()));
        """, in: webView)
        XCTAssertEqual(focusedEmptyEditor, "true", "An active editor must block an interrupting reload")
        _ = try await evaluate("document.body.innerHTML = '<main><div role=progressbar></div></main>'; 'ok'", in: webView)

        let watchdog = XGlassLoadWatchdog(probeDelay: .milliseconds(50))
        let stalled = expectation(description: "Stalled page offers recovery")
        watchdog.start(in: webView) { stalled.fulfill() }
        await fulfillment(of: [stalled], timeout: 3)

        let cancelled = expectation(description: "Cancelled navigation cannot report a stale failure")
        cancelled.isInverted = true
        watchdog.start(in: webView) { cancelled.fulfill() }
        watchdog.cancel()
        await fulfillment(of: [cancelled], timeout: 0.3)
    }

    func testPostReadinessRequiresTheRequestedPost() async throws {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .nonPersistent()
        let webView = WKWebView(frame: CGRect(x: 0, y: 0, width: 600, height: 800), configuration: configuration)
        let loaded = expectation(description: "Post destination fixture")
        let loader = Loader(loaded)
        webView.navigationDelegate = loader
        webView.loadHTMLString("<main><input aria-label=Search><article><a href='/person/status/456'>Old post</a><img src='data:image/gif;base64,R0lGODlhAQABAAD/ACwAAAAAAQABAAACADs='></article></main>", baseURL: URL(string: "https://x.com/person/status/123"))
        await fulfillment(of: [loaded], timeout: 15)
        let wrongPost = try await evaluate("String(\(XGlassLoadWatchdog.readinessScript.dropLast()))", in: webView)
        XCTAssertEqual(wrongPost, "false")
        _ = try await evaluate("document.querySelector('article a').href = '/person/status/123'; 'ok'", in: webView)
        let correctPost = try await evaluate("String(\(XGlassLoadWatchdog.readinessScript.dropLast()))", in: webView)
        XCTAssertEqual(correctPost, "true")
    }

    func testPhotoLightboxReadinessDoesNotRequirePostLink() async throws {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .nonPersistent()
        let webView = WKWebView(frame: CGRect(x: 0, y: 0, width: 600, height: 800), configuration: configuration)
        let loaded = expectation(description: "Photo lightbox fixture")
        let loader = Loader(loaded)
        webView.navigationDelegate = loader
        webView.loadHTMLString("""
        <html><body>
          <div role="dialog" aria-modal="true">
            <div role="img" aria-label="Post image" style="width: 240px; height: 240px;"></div>
            <button aria-label="Close">Close</button>
          </div>
        </body></html>
        """, baseURL: URL(string: "https://x.com/person/status/123/photo/1"))
        await fulfillment(of: [loaded], timeout: 15)
        let result = try await evaluate("String(\(XGlassLoadWatchdog.readinessScript.dropLast()))", in: webView)
        XCTAssertEqual(result, "true")
    }

    func testFullPageMediaReadinessAcceptsRenderedSurfaceWithoutModalRole() async throws {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .nonPersistent()
        let webView = WKWebView(frame: CGRect(x: 0, y: 0, width: 600, height: 800), configuration: configuration)
        let loaded = expectation(description: "Full-page media fixture")
        let loader = Loader(loaded)
        webView.navigationDelegate = loader
        webView.loadHTMLString("""
        <html><body>
          <section style="width: 480px; height: 600px;">
            <h1>Goodbye Orange Legend</h1>
            <p>Photo details and post controls are rendered.</p>
            <button aria-label="Close">Close</button>
          </section>
        </body></html>
        """, baseURL: URL(string: "https://x.com/person/status/123/photo/1"))
        await fulfillment(of: [loaded], timeout: 15)
        let result = try await evaluate("String(\(XGlassLoadWatchdog.readinessScript.dropLast()))", in: webView)
        XCTAssertEqual(result, "true")

        _ = try await evaluate("document.body.innerHTML = '<div role=progressbar>Loading</div><p>Photo details and post controls are rendered.</p><button>Close</button>'; 'ok'", in: webView)
        let loading = try await evaluate("String(\(XGlassLoadWatchdog.readinessScript.dropLast()))", in: webView)
        XCTAssertEqual(loading, "false")
    }

    func testNotificationUnreadBackgroundSurvivesAndClearsWithXState() async throws {
        let config = WKWebViewConfiguration()
        config.websiteDataStore = .nonPersistent()
        config.userContentController.addUserScript(WKUserScript(
            source: XGlassDOMScripts.chromeSuppression(minimumPaintInterval: 250),
            injectionTime: .atDocumentEnd, forMainFrameOnly: true))
        let view = WKWebView(frame: CGRect(x: 0, y: 0, width: 760, height: 800), configuration: config)
        let loaded = expectation(description: "Notification fixture loaded")
        let loader = Loader(loaded)
        view.navigationDelegate = loader
        view.loadHTMLString("""
        <html><body><main role="main"><div data-testid="primaryColumn" style="width:700px">
        <div><div><div role="tablist" style="height:50px"><button role="tab">All</button></div>
        <div data-testid="cellInnerDiv"><div id="unread" role="button"
        style="height:100px;background-color:rgba(29,155,240,0.15)"
        onclick="this.style.backgroundColor='transparent'">New post notifications for someone</div></div>
        <div data-testid="cellInnerDiv"><div id="read" style="height:100px;background:transparent">Older notification</div></div>
        </div></div></div></main></body></html>
        """, baseURL: URL(string: "https://x.com/notifications"))
        await fulfillment(of: [loaded], timeout: 15)
        try await Task.sleep(for: .milliseconds(600))
        let before = try await evaluate("getComputedStyle(document.getElementById('unread')).backgroundColor", in: view)
        XCTAssertEqual(before, "rgba(29, 155, 240, 0.15)")
        _ = try await evaluate("document.getElementById('unread').click(); 'ok'", in: view)
        let after = try await evaluate("getComputedStyle(document.getElementById('unread')).backgroundColor", in: view)
        XCTAssertEqual(after, "rgba(0, 0, 0, 0)")
        let read = try await evaluate("getComputedStyle(document.getElementById('read')).backgroundColor", in: view)
        XCTAssertEqual(read, "rgba(0, 0, 0, 0)")
    }

    func testSearchOverlayMasksFeedAndRestoresOriginalPositioning() async throws {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .nonPersistent()
        // Export only the narrow paint entry point in the test fixture, never in the app.
        let script = XGlassDOMScripts.chromeSuppression(minimumPaintInterval: 250)
            .replacingOccurrences(of: "  scheduleOverrides(paintFull);\n})();", with: """
              window.testPaint = () => paintSearchOverlay(findPrimaryColumn());
              window.testAds = () => hidePromotedContent(findPrimaryColumn(), [], true);
              window.testSticky = () => paintStickyHeaders(findPrimaryColumn());
              applyOverrides(paintFull);
            })();
            """)
        configuration.userContentController.addUserScript(WKUserScript(source: script, injectionTime: .atDocumentEnd, forMainFrameOnly: true))
        let webView = WKWebView(frame: CGRect(x: 0, y: 0, width: 760, height: 900), configuration: configuration)
        let loaded = expectation(description: "Local search fixture loaded")
        let loader = Loader(loaded)
        webView.navigationDelegate = loader
        webView.loadHTMLString("""
        <html><head><style>
        body { margin: 0; } main { width: 700px; } #primary { width:700px; min-height:800px; }
        #search { width:600px;height:44px; } #list { width:600px;height:180px; }
        #feed { margin-top:200px; height:500px; }
        </style></head><body><main role="main"><div id="primary" data-testid="primaryColumn">
        <div id="search" role="combobox" aria-expanded="true" aria-controls="list"><input aria-label="Search"></div>
        <div id="list" role="list" style="position:absolute;z-index:4;top:50px;background:rgb(10,10,10)">
          <h2>Recent</h2><button>saved query</button>
        </div>
        <div id="feed"><article><span>Underlying timeline</span></article></div>
        <div id="promotion" data-testid="placementTracking">Promoted placement</div>
        <div id="explorePromotion"><a href="/advertiser">Internet offer Promoted by Example</a><button>More</button></div>
        <div id="sticky" style="position:sticky;top:0;height:50px;background:transparent">
          <div role="tablist"><button role="tab">For you</button></div>
        </div>
        </div></main></body></html>
        """, baseURL: URL(string: "https://x.com/explore"))
        await fulfillment(of: [loaded], timeout: 15)
        let expanded = try await evaluate("""
        window.testPaint();
        JSON.stringify({
          hidden: getComputedStyle(document.getElementById('feed')).visibility,
          panel: getComputedStyle(document.getElementById('list')).visibility,
          masked: document.querySelectorAll('#feed[data-xglass-search-hidden="true"], #feed [data-xglass-search-hidden="true"]').length
        });
        """, in: webView)
        let data = try XCTUnwrap(expanded.data(using: .utf8))
        let state = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        XCTAssertEqual(state["hidden"] as? String, "hidden")
        XCTAssertEqual(state["panel"] as? String, "visible")
        XCTAssertEqual(state["masked"] as? Int, 1)

        let collapsed = try await evaluate("""
        document.getElementById('search').setAttribute('aria-expanded','false');
        window.testPaint();
        JSON.stringify({
          hidden: getComputedStyle(document.getElementById('feed')).visibility,
          position: document.getElementById('list').style.position,
          zIndex: document.getElementById('list').style.zIndex
        });
        """, in: webView)
        let restored = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(collapsed.utf8)) as? [String: String])
        XCTAssertEqual(restored["hidden"], "visible")
        XCTAssertEqual(restored["position"], "absolute")
        XCTAssertEqual(restored["zIndex"], "4")

        let filtered = try await evaluate("""
        window.testAds();
        getComputedStyle(document.getElementById('promotion')).display;
        """, in: webView)
        XCTAssertEqual(filtered, "none")
        let explorePromotion = try await evaluate("getComputedStyle(document.getElementById('explorePromotion')).display", in: webView)
        XCTAssertEqual(explorePromotion, "none")
        let unfiltered = try await evaluate("""
        window.__xglassPreferences.hidePromotedPosts = false;
        window.testAds();
        getComputedStyle(document.getElementById('promotion')).display;
        """, in: webView)
        XCTAssertEqual(unfiltered, "block")

        let sticky = try await evaluate("""
        document.documentElement.style.setProperty('--xglass-surface', '#253540');
        window.testSticky();
        getComputedStyle(document.getElementById('sticky')).backgroundColor;
        """, in: webView)
        XCTAssertEqual(sticky, "rgb(37, 53, 64)")
    }

    private func evaluate(_ source: String, in webView: WKWebView) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            webView.evaluateJavaScript(source) { result, error in
                if let error { continuation.resume(throwing: error) }
                else { continuation.resume(returning: result as? String ?? "") }
            }
        }
    }
}
