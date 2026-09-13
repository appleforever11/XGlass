import WebKit

/// A single reply gate bounds a probe even when WebKit never calls back.
@MainActor
final class XGlassPageProbe {
    private var continuation: CheckedContinuation<Bool?, Never>?
    private var timeoutTask: Task<Void, Never>?

    init(_ continuation: CheckedContinuation<Bool?, Never>) { self.continuation = continuation }

    func finish(_ result: Bool?) {
        guard continuation != nil else { return }
        timeoutTask?.cancel()
        timeoutTask = nil
        continuation?.resume(returning: result)
        continuation = nil
    }

    func arm(timeout: Duration) {
        timeoutTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: timeout)
            guard !Task.isCancelled else { return }
            self?.finish(nil)
        }
    }

    deinit { timeoutTask?.cancel() }

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
            gate.arm(timeout: timeout)
            start { gate.finish($0) }
        }
    }
}
