import XCTest
import WebKit
@testable import XGlass

@MainActor
final class XGlassUnreadTests: XCTestCase {
    final class Recorder: NSObject, WKScriptMessageHandler {
        var latest = XGlassUnreadState()
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            if let json = message.body as? String, let data = json.data(using: .utf8),
               let state = try? JSONDecoder().decode(XGlassUnreadState.self, from: data) { latest = state }
        }
    }

    func testLiveCountsAndNewPostsClearWhenXClearsThem() async throws {
        let config = WKWebViewConfiguration()
        config.websiteDataStore = .nonPersistent()
        let recorder = Recorder()
        config.userContentController.add(recorder, name: "xglassUnread")
        config.userContentController.addUserScript(WKUserScript(source: XGlassUnreadMonitor.source, injectionTime: .atDocumentStart, forMainFrameOnly: true))
        let view = WKWebView(frame: NSRect(x: 0, y: 0, width: 600, height: 600), configuration: config)
        view.loadHTMLString("<html><head><title>(5) Home / X</title></head><body><a href='/notifications' aria-label='Notifications, 5 unread items'><span>5</span></a><main></main></body></html>", baseURL: URL(string: "https://x.com/home"))
        for _ in 0..<30 {
            if recorder.latest.count == 5 { break }
            try await Task.sleep(for: .milliseconds(100))
        }
        XCTAssertEqual(recorder.latest.count, 5)
        try await run("document.title='Home / X'; document.querySelector('a').setAttribute('aria-label','Notifications'); document.querySelector('span').textContent=''; document.querySelector('main').innerHTML='<button aria-label=\"New posts are available. Push to load them.\">New posts</button>';", in: view)
        try await Task.sleep(for: .milliseconds(800))
        XCTAssertEqual(recorder.latest.count, 0)
        XCTAssertTrue(recorder.latest.newPosts)
        XCTAssertTrue(recorder.latest.isVisible)
        try await run("document.querySelector('main').innerHTML='';", in: view)
        try await Task.sleep(for: .milliseconds(800))
        XCTAssertFalse(recorder.latest.isVisible)

        // A stale title is not evidence that the bell still has unread notifications.
        try await run("document.title='(5) Notifications / X';", in: view)
        try await Task.sleep(for: .milliseconds(800))
        XCTAssertFalse(recorder.latest.isVisible)

        // X keeps accessibility-only new-post controls in the document.
        try await run("document.querySelector('main').innerHTML='<button aria-label=\"New posts are available. Push to load them.\" style=\"position:absolute;width:1px;height:1px;padding:0;border:0;clip:rect(1px,1px,1px,1px)\">New posts</button>';", in: view)
        try await Task.sleep(for: .milliseconds(800))
        XCTAssertFalse(recorder.latest.isVisible)

        // A genuinely visible prompt is live, including parent visibility changes.
        try await run("document.querySelector('button').removeAttribute('style');", in: view)
        try await Task.sleep(for: .milliseconds(800))
        XCTAssertTrue(recorder.latest.newPosts)
        try await run("document.querySelector('main').style.opacity='0';", in: view)
        try await Task.sleep(for: .milliseconds(800))
        XCTAssertFalse(recorder.latest.isVisible)
        try await run("document.querySelector('main').style.opacity='1';", in: view)
        try await Task.sleep(for: .milliseconds(800))
        XCTAssertTrue(recorder.latest.newPosts)

        // SPA navigation must stop Home's retained prompt from lighting the bell.
        try await run("history.pushState({}, '', '/notifications'); window.__xglassRefreshUnread();", in: view)
        try await Task.sleep(for: .milliseconds(800))
        XCTAssertFalse(recorder.latest.isVisible)
        try await run("document.querySelector('a').setAttribute('aria-label','Notifications, 2 unread items');", in: view)
        try await Task.sleep(for: .milliseconds(800))
        XCTAssertEqual(recorder.latest.count, 2, "Opening Notifications must not discard genuinely unread items")
        try await run("document.querySelector('a').setAttribute('aria-label','Notifications, 0 unread items');", in: view)
        try await Task.sleep(for: .milliseconds(800))
        XCTAssertFalse(recorder.latest.isVisible)
    }

    func testBadgeCapsLargeCountsAndExplainsDots() {
        XCTAssertEqual(XGlassUnreadState(count: 125).badgeText, "99+")
        XCTAssertNil(XGlassUnreadState(newPosts: true).badgeText)
        XCTAssertEqual(XGlassUnreadState(newPosts: true).accessibilityDescription, "New posts available")
    }

    private func run(_ script: String, in view: WKWebView) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            view.evaluateJavaScript(script) { _, error in
                if let error { continuation.resume(throwing: error) }
                else { continuation.resume() }
            }
        }
    }
}
