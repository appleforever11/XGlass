import AppKit
import SwiftUI

struct XGlassStartupWindowFrame {
    static let preferredWidth: CGFloat = 600
    static let preferredHeight: CGFloat = 1_059
    static let topInset: CGFloat = 46

    static var preferredSize: NSSize {
        NSSize(width: preferredWidth, height: preferredHeight)
    }

    static func frame(
        in screenFrame: NSRect,
        minimumSize: NSSize = NSSize(width: 520, height: 480)
    ) -> NSRect {
        let width = min(screenFrame.width, max(minimumSize.width, preferredWidth))
        let height = min(screenFrame.height, max(minimumSize.height, preferredHeight))
        let topAlignedY = screenFrame.maxY - topInset - height
        let maximumY = screenFrame.maxY - height
        let y = min(max(topAlignedY, screenFrame.minY), maximumY)

        return NSRect(
            x: screenFrame.minX,
            y: y,
            width: width,
            height: height
        )
    }
}

@MainActor
private enum XGlassWindowLaunchState {
    static var didApplyMainWindowFrame = false
}

/// Applies the requested launch frame once, then leaves ordinary window movement
/// and resizing to AppKit while keeping the custom glass chrome configured.
struct XGlassWindowSizingView: NSViewRepresentable {
    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeNSView(context: Context) -> NSView {
        let view = NSView(frame: .zero)
        view.setContentHuggingPriority(.defaultLow, for: .horizontal)
        view.setContentHuggingPriority(.defaultLow, for: .vertical)
        context.coordinator.attach(to: view)
        return view
    }

    func updateNSView(_ view: NSView, context: Context) {
        context.coordinator.configure(window: view.window)
        DispatchQueue.main.async { [weak view] in
            context.coordinator.configure(window: view?.window)
        }
    }

    static func dismantleNSView(_ view: NSView, coordinator: Coordinator) {
        coordinator.detach()
    }

    @MainActor
    final class Coordinator: NSObject {
        private weak var view: NSView?
        private weak var window: NSWindow?
        private var screenObserver: NSObjectProtocol?
        private weak var configuredScreen: NSScreen?

        func attach(to view: NSView) {
            self.view = view
            screenObserver = NotificationCenter.default.addObserver(
                forName: NSWindow.didChangeScreenNotification,
                object: nil,
                queue: .main
            ) { [weak self] notification in
                guard let changedWindow = notification.object as? NSWindow else { return }
                Task { @MainActor [weak self, weak changedWindow] in
                    guard let self, let changedWindow, changedWindow === self.window else { return }
                    self.configure(window: changedWindow)
                }
            }
        }

        func detach() {
            if let screenObserver {
                NotificationCenter.default.removeObserver(screenObserver)
            }
            screenObserver = nil
            view = nil
            window = nil
            configuredScreen = nil
        }

        func configure(window: NSWindow?) {
            guard let window,
                  let screen = window.screen ?? NSScreen.main else { return }

            self.window = window
            window.titleVisibility = .hidden
            window.titlebarAppearsTransparent = true
            window.styleMask.insert(.fullSizeContentView)
            window.isOpaque = false
            window.backgroundColor = .clear
            window.isMovableByWindowBackground = true

            let screenFrame = screen.frame
            guard screenFrame.width > 1, screenFrame.height > 1 else { return }

            let minimumWidth = min(600, max(520, screenFrame.width))
            let minimumHeight = min(480, max(400, screenFrame.height))
            window.minSize = NSSize(width: minimumWidth, height: minimumHeight)

            let screenChanged = configuredScreen !== screen
            configuredScreen = screen

            if !XGlassWindowLaunchState.didApplyMainWindowFrame {
                XGlassWindowLaunchState.didApplyMainWindowFrame = true
                let targetFrame = XGlassStartupWindowFrame.frame(
                    in: screenFrame,
                    minimumSize: window.minSize
                )
                window.setFrame(targetFrame, display: true, animate: false)
                return
            }

            guard screenChanged else { return }

            let visible = screen.visibleFrame
            let size = NSSize(
                width: min(max(window.frame.width, minimumWidth), visible.width),
                height: min(max(window.frame.height, minimumHeight), visible.height)
            )
            let origin = NSPoint(
                x: min(max(window.frame.minX, visible.minX), visible.maxX - size.width),
                y: min(max(window.frame.minY, visible.minY), visible.maxY - size.height)
            )

            window.setFrame(
                NSRect(origin: origin, size: size),
                display: true,
                animate: false
            )
        }
    }
}
