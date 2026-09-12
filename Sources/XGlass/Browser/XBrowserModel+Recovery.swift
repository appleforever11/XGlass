import AppKit
import WebKit

@MainActor
extension XBrowserModel {
    static let draftScript = #"""
    (() => {
      const isEditable = node => node && (
        node.isContentEditable ||
        node.matches('textarea, input:not([type="hidden"])')
      );
      if (isEditable(document.activeElement)) return true;
      return Array.from(document.querySelectorAll('[contenteditable="true"], textarea, input[type="file"]'))
        .some(node => node.isContentEditable ? node.innerText.trim().length > 0 :
          node.type === 'file' ? node.files.length > 0 : node.value.trim().length > 0);
    })();
    """#

    func recordLoadEvent(_ event: String) {
        diagnosticEvents.append("\(Date().formatted(date: .omitted, time: .standard)) \(event)")
        if diagnosticEvents.count > 60 { diagnosticEvents.removeFirst(diagnosticEvents.count - 60) }
    }

    func monitorPageReadiness(in webView: WKWebView) {
        guard networkAvailable else { return }
        readinessTask?.cancel()
        loadGeneration = UUID()
        let generation = loadGeneration
        loadState = "Loading"
        canRetry = false
        statusMessage = nil
        loadStartedAt = Date()
        recordLoadEvent("Loading")
        loadWatchdog.start(in: webView, ready: { [weak self] in
            guard let self, self.loadGeneration == generation else { return }
            self.readinessTask?.cancel()
            self.loadState = "Ready"
            self.canRetry = false
            self.statusMessage = nil
            self.recordLoadEvent("Content ready at final probe")
        }) { [weak self] in
            guard let self, self.loadGeneration == generation else { return }
            self.loadState = "Slow"
            self.recordLoadEvent("Content deadline exceeded")
            let draftNotice = self.hasUnsavedDraft == true
                ? " Your unfinished writing was left untouched."
                : ""
            self.statusMessage = "X is taking too long to show this page. Retry or open it in your browser." + draftNotice
            self.canRetry = true
            // A timeout never authorizes a reload. The user can inspect the page
            // and choose Retry, which runs the same draft-protection check as Reload.
            self.recordLoadEvent("Manual retry required")
        }
        readinessTask = Task { @MainActor [weak self, weak webView] in
            let deadline = ContinuousClock.now.advanced(by: .seconds(60))
            while ContinuousClock.now < deadline {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled, let self, let webView, self.loadGeneration == generation else { return }
                let result = await XGlassPageProbe.readiness(in: webView)
                guard !Task.isCancelled, self.loadGeneration == generation else { return }
                if result == true && !webView.isLoading {
                    self.loadWatchdog.cancel()
                    self.loadState = "Ready"
                    self.statusMessage = nil
                    self.canRetry = false
                    self.recordLoadEvent("Ready after \(String(format: "%.1f", Date().timeIntervalSince(self.loadStartedAt)))s")
                    return
                }
            }
        }
    }

    func protectDraft(in webView: WKWebView, action: @escaping @MainActor () -> Void) {
        let id = UUID()
        draftCheckID = id
        let destination = webView.url
        let finish: @MainActor (Bool) -> Void = { [weak self, weak webView] safe in
            guard let self, self.draftCheckID == id, webView?.url == destination else { return }
            self.draftCheckID = nil
            if safe { action(); return }
            let alert = NSAlert()
            alert.messageText = "Reload this page?"
            alert.informativeText = "There may be an unfinished post, message, or attachment. Reloading can discard it."
            alert.addButton(withTitle: "Keep Editing")
            alert.addButton(withTitle: "Reload")
            if alert.runModal() == .alertSecondButtonReturn { action() }
            else { self.statusMessage = "Reload cancelled to preserve your work." }
        }
        webView.evaluateJavaScript(Self.draftScript) { result, error in
            finish(error == nil && result as? Bool == false)
        }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(3))
            finish(false)
        }
    }

    func installLifecycleMonitoring() {
        guard lifecycleObservers.isEmpty else { return }
        networkMonitor.pathUpdateHandler = { [weak self] path in
            let available = path.status == .satisfied
            Task { @MainActor in
                guard let self else { return }
                let restored = !self.networkAvailable && available
                self.networkAvailable = available
                if !available {
                    self.cancelPendingNavigation()
                    self.loadState = "Offline"
                    self.statusMessage = "You’re offline. Your current page remains open."
                    self.canRetry = true
                    self.recordLoadEvent("Offline")
                } else if restored, let webView = self.webView {
                    self.recoveryAttempts = 0
                    self.monitorPageReadiness(in: webView)
                }
            }
        }
        networkMonitor.start(queue: DispatchQueue(label: "XGlass.connectivity"))
        lifecycleObservers.append(NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification, object: nil, queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                guard let self, let webView = self.webView else { return }
                self.recoveryAttempts = 0
                self.monitorPageReadiness(in: webView)
            }
        })
    }

    func copyDiagnosticReport() {
        webView?.evaluateJavaScript("JSON.stringify(window.__xglassPerformance || {})") { [weak self] result, _ in
            guard let self, let value = result as? String,
                  let data = value.data(using: .utf8),
                  let metrics = try? JSONSerialization.jsonObject(with: data) as? [String: Double] else { return }
            self.recordLoadEvent("Layout: \(Int(metrics["paints"] ?? 0)) passes, max \(String(format: "%.2f", metrics["maxMs"] ?? 0))ms")
            self.writeDiagnosticReport()
        }
        writeDiagnosticReport()
    }

    private func writeDiagnosticReport() {
        let report = """
        XGlass loading diagnostics
        macOS: \(ProcessInfo.processInfo.operatingSystemVersionString)
        Version: \(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "development")
        State: \(loadState)
        Compatibility mode: \(compatibilityMode)
        Retries: \(recoveryAttempts)
        \(diagnosticEvents.joined(separator: "\n"))
        """
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(report, forType: .string)
        statusMessage = "Diagnostics copied. No page URLs, messages, or account content included."
    }
}
