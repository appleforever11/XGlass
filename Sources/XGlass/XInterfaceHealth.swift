import Foundation

struct XInterfaceHealthCheck: Identifiable {
    let id: String
    let title: String
    let detail: String
    let passed: Bool
}

struct XInterfaceHealthReport: Identifiable {
    let id = UUID()
    let pagePath: String
    let checkedAt: Date
    let checks: [XInterfaceHealthCheck]

    var allPassed: Bool { checks.allSatisfy(\.passed) }
}

struct XInterfaceHealthPayload: Decodable {
    let pagePath: String
    let primaryColumn: Bool
    let customStyles: Bool
    let nativeSidebarSuppressed: Bool
    let themeBridge: Bool
    let preferenceBridge: Bool
    let interactiveControls: Bool
    let composerSurface: Bool
    let adFilterEnabled: Bool

    static func decode(json: String) throws -> Self {
        try JSONDecoder().decode(Self.self, from: Data(json.utf8))
    }
}

enum XInterfaceHealthReportBuilder {
    static func unavailable(checkedAt: Date) -> XInterfaceHealthReport {
        XInterfaceHealthReport(
            pagePath: "Unavailable",
            checkedAt: checkedAt,
            checks: [XInterfaceHealthCheck(
                id: "webView",
                title: "Web view responded",
                detail: "The X session is still starting",
                passed: false
            )]
        )
    }

    static func make(
        payload: XInterfaceHealthPayload,
        currentURL: URL,
        checkedAt: Date
    ) -> XInterfaceHealthReport {
        let recognizedRoute = XRoute.match(url: currentURL) != nil
        return XInterfaceHealthReport(
            pagePath: payload.pagePath,
            checkedAt: checkedAt,
            checks: [
                XInterfaceHealthCheck(
                    id: "route",
                    title: "Route recognized",
                    detail: recognizedRoute ? "Known X route" : "External or new X route",
                    passed: recognizedRoute
                ),
                XInterfaceHealthCheck(
                    id: "primary",
                    title: "Primary X column",
                    detail: payload.primaryColumn ? "Found" : "Not found",
                    passed: payload.primaryColumn
                ),
                XInterfaceHealthCheck(
                    id: "styles",
                    title: "XGlass styling active",
                    detail: payload.customStyles ? "Loaded" : "Missing",
                    passed: payload.customStyles
                ),
                XInterfaceHealthCheck(
                    id: "sidebar",
                    title: "Native sidebar suppressed",
                    detail: payload.nativeSidebarSuppressed ? "Hidden" : "Visible",
                    passed: payload.nativeSidebarSuppressed
                ),
                XInterfaceHealthCheck(
                    id: "theme",
                    title: "Theme bridge ready",
                    detail: payload.themeBridge ? "Ready" : "Missing",
                    passed: payload.themeBridge
                ),
                XInterfaceHealthCheck(
                    id: "preferences",
                    title: "Preference bridge ready",
                    detail: payload.preferenceBridge ? "Ready" : "Missing",
                    passed: payload.preferenceBridge
                ),
                XInterfaceHealthCheck(
                    id: "controls",
                    title: "Interactive controls",
                    detail: payload.interactiveControls ? "Found" : "Not found",
                    passed: payload.interactiveControls
                ),
                XInterfaceHealthCheck(
                    id: "composer",
                    title: "Composer surface",
                    detail: payload.composerSurface ? "Styled" : "Not present on this page",
                    passed: payload.composerSurface || !payload.primaryColumn
                ),
                XInterfaceHealthCheck(
                    id: "ads",
                    title: "Promoted-post filter",
                    detail: payload.adFilterEnabled ? "Enabled" : "Disabled",
                    passed: payload.adFilterEnabled
                )
            ]
        )
    }
}
