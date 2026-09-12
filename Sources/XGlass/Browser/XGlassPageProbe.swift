import WebKit

/// A single reply gate bounds a probe even when WebKit never calls back.
@MainActor
final class XGlassPageProbe {
    private var continuation: CheckedContinuation<Bool?, Never>?
    init(_ continuation: CheckedContinuation<Bool?, Never>) { self.continuation = continuation }
    func finish(_ result: Bool?) {
        continuation?.resume(returning: result)
        continuation = nil
    }

    static func readiness(in webView: WKWebView) async -> Bool? {
        await run { reply in
            webView.evaluateJavaScript(XGlassLoadWatchdog.readinessScript) { result, error in
                reply(error == nil ? result as? Bool : nil)
            }
        }
    }

    static func run(timeout: Duration = .seconds(2),
                    start: (@escaping @MainActor (Bool?) -> Void) -> Void) async -> Bool? {
        await withCheckedContinuation { continuation in
            let gate = XGlassPageProbe(continuation)
            start { gate.finish($0) }
            Task { @MainActor in
                try? await Task.sleep(for: timeout)
                gate.finish(nil)
            }
        }
    }
}
