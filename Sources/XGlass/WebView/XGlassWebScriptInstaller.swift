import WebKit

@MainActor
enum XGlassWebScriptInstaller {
    static func install(on controller: WKUserContentController, themePayload: String, preferencesPayload: String, compatibilityMode: Bool = false) {
        // Replace the bootstrap as preferences change so full navigations retain the current theme.
        controller.removeAllUserScripts()
        let sources: [(String, WKUserScriptInjectionTime)] = [
            ("window.__xglassTheme = \(themePayload); window.__xglassPreferences = \(preferencesPayload);", .atDocumentStart),
            (XGlassDOMScripts.bootstrap, .atDocumentStart),
            (XGlassLoadTelemetry.source + "\n" + XGlassDOMScripts.contextMenu + "\n" + XGlassScrollRestoration.source + "\n" + XGlassDraftMonitor.source + "\n" + XGlassUnreadMonitor.source, .atDocumentStart),
            (XGlassDeferredPresentation.wrap(XGlassDOMScripts.chromeSuppression(minimumPaintInterval: 250)), .atDocumentEnd)
        ]
        for (index, entry) in sources.enumerated() {
            if compatibilityMode && (index == 1 || index == 3) { continue }
            let (source, time) = entry
            controller.addUserScript(WKUserScript(source: source, injectionTime: time, forMainFrameOnly: true))
        }
    }
}
