import AppKit
import XCTest
@testable import XGlass

@MainActor
final class XGlassTrafficLightTests: XCTestCase {
    func testNativeWindowButtonsStayInsideRailAcrossResizeBreakpoints() throws {
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 600, height: 600),
                              styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
                              backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        defer { window.close() }
        for width: CGFloat in [600, 719, 720, 819, 820, 1179, 1180, 1280] {
            window.setContentSize(NSSize(width: width, height: 600))
            window.contentView?.layoutSubtreeIfNeeded()
            for compact in [false, true] {
                let layout = XGlassShellLayout(windowWidth: width, compactPreference: compact)
                for type: NSWindow.ButtonType in [.closeButton, .miniaturizeButton, .zoomButton] {
                    let button = try XCTUnwrap(window.standardWindowButton(type))
                    let frame = button.convert(button.bounds, to: nil)
                    XCTAssertGreaterThanOrEqual(frame.minX, 0)
                    XCTAssertLessThanOrEqual(frame.maxX + 8, layout.railWidth,
                                             "Window control crosses sidebar at width \(width)")
                }
            }
        }
    }
}
