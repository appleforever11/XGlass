import SwiftUI
import XCTest
@testable import XGlass

@MainActor
final class XGlassRecoveryPanelTests: XCTestCase {
    func testRecoveryPanelFitsCompactWindow() throws {
        let model = XBrowserModel()
        model.canRetry = true
        model.statusMessage = "X is taking too long to show this page. Retry or open it in your browser."
        let renderer = ImageRenderer(content: XGlassStatusOverlay(browser: model, colors: XGlassThemeFamily.goldenGate.colors)
            .frame(width: 400).padding(16).environment(\.colorScheme, .dark))
        renderer.scale = 2
        let image = try XCTUnwrap(renderer.nsImage)
        XCTAssertEqual(image.size.width, 432)
        XCTAssertLessThan(image.size.height, 240, "Recovery actions must fit in the compact window")
        if ProcessInfo.processInfo.environment["XGLASS_RENDER_RECOVERY_PREVIEW"] == "1" {
            let bitmap = NSBitmapImageRep(data: try XCTUnwrap(image.tiffRepresentation))
            let png = try XCTUnwrap(bitmap?.representation(using: .png, properties: [:]))
            try png.write(to: URL(fileURLWithPath: "/tmp/xglass-sep12-recovery-preview.png"))
        }
    }
}
