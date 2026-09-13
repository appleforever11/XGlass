import AppKit

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

        return NSRect(x: screenFrame.minX, y: y, width: width, height: height)
    }
}

/// Owns the main window's launch policy at the AppKit lifecycle boundary.
/// SwiftUI view updates can run before a WindowGroup window exists, so applying
/// the policy from a representable is inherently racy. AppKit notifications
/// see the actual window and the bounded correction pass wins the restoration
/// race without affecting later user resizing.
@MainActor
final class XGlassWindowLaunchController: NSObject {
    private weak var mainWindow: NSWindow?
    private var didApplyLaunchFrame = false
    private var launchUserResizeStarted = false
    private var startupDeadline: Date?
    private var correctionTask: Task<Void, Never>?
    private var fullScreenExitTask: Task<Void, Never>?
    private var fullScreenExitRequested = false
    private var fullScreenExitAttempts = 0
    private var observers: [NSObjectProtocol] = []

    func start() {
        guard observers.isEmpty else { return }

        let center = NotificationCenter.default
        observe(NSWindow.didBecomeMainNotification, using: center)
        observe(NSWindow.didBecomeKeyNotification, using: center)
        observe(NSWindow.didChangeScreenNotification, using: center)
        observe(NSWindow.didExitFullScreenNotification, using: center)
        observe(NSWindow.willStartLiveResizeNotification, using: center)
        observe(NSWindow.didResizeNotification, using: center)

        scheduleStartupScans()
    }

    func stop() {
        observers.forEach(NotificationCenter.default.removeObserver)
        observers.removeAll()
        correctionTask?.cancel()
        correctionTask = nil
        fullScreenExitTask?.cancel()
        fullScreenExitTask = nil
        mainWindow = nil
        startupDeadline = nil
    }

    func refresh() {
        guard mainWindow == nil || !didApplyLaunchFrame else { return }
        scheduleStartupScans()
    }

    private func scheduleStartupScans() {
        startupDeadline = Date().addingTimeInterval(5)
        // WindowGroup can finish constructing its window after activation. A
        // bounded set of scans and resize notifications covers that hand-off
        // without continuously polling or touching later user resizes.
        for delay in [0.0, 0.1, 0.35, 0.8, 1.5, 3.0, 5.0] {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                self?.scanForMainWindow()
            }
        }
    }

    private func observe(_ name: Notification.Name, using center: NotificationCenter) {
        let observer = center.addObserver(forName: name, object: nil, queue: .main) { [weak self] notification in
            guard let window = notification.object as? NSWindow else { return }
            Task { @MainActor [weak self, weak window] in
                guard let self, let window else { return }
                self.handle(window: window, notification: name)
            }
        }
        observers.append(observer)
    }

    private func scanForMainWindow() {
        let candidates = NSApp.windows.filter(isMainWindowCandidate)
        let window = candidates.first(where: { $0.isMainWindow }) ??
            candidates.first(where: { $0.isKeyWindow }) ??
            candidates.max { lhs, rhs in
                (lhs.frame.width * lhs.frame.height) < (rhs.frame.width * rhs.frame.height)
            }
        guard let window else { return }
        handle(window: window, notification: nil)
    }

    private func handle(window: NSWindow, notification: Notification.Name?) {
        guard isMainWindowCandidate(window) else { return }
        if notification != nil,
           mainWindow !== window,
           !window.isMainWindow,
           !window.isKeyWindow {
            return
        }

        if mainWindow !== window {
            correctionTask?.cancel()
            correctionTask = nil
            mainWindow = window
            didApplyLaunchFrame = false
            launchUserResizeStarted = false
            fullScreenExitRequested = false
            fullScreenExitAttempts = 0
        }

        if notification == NSWindow.willStartLiveResizeNotification {
            launchUserResizeStarted = true
        }

        configure(window: window)
    }

    private func isMainWindowCandidate(_ window: NSWindow) -> Bool {
        guard !(window is NSPanel), window.sheetParent == nil else { return false }
        // SwiftUI and Sparkle can create short-lived titlebar/helper windows.
        // The main XGlass surface is never this small, even during its initial
        // 500-point placeholder frame.
        guard window.frame.width >= 400, window.frame.height >= 300 else { return false }
        let title = window.title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard title.caseInsensitiveCompare("XGlass Settings") != .orderedSame else { return false }
        return true
    }

    private func configure(window: NSWindow) {
        let isWithinStartupWindow = startupDeadline.map { Date() < $0 } ?? false
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.styleMask.insert(.fullSizeContentView)
        window.isOpaque = false
        window.backgroundColor = .clear
        window.isMovableByWindowBackground = true
        window.isRestorable = false
        window.restorationClass = nil

        if window.styleMask.contains(.fullScreen) {
            // A user may enter full screen during a session. Only unwind a
            // restored full-screen state before the first launch frame lands.
            guard !didApplyLaunchFrame || isWithinStartupWindow else { return }
            requestExitFullScreen(window)
            return
        }

        guard let screen = window.screen ?? NSScreen.main else { return }
        let screenFrame = screen.frame
        guard screenFrame.width > 1, screenFrame.height > 1 else { return }

        let minimumWidth = min(XGlassStartupWindowFrame.preferredWidth, max(520, screenFrame.width))
        let minimumHeight = min(XGlassStartupWindowFrame.preferredHeight, max(400, screenFrame.height))
        window.minSize = NSSize(width: minimumWidth, height: minimumHeight)

        if window.isZoomed {
            window.zoom(nil)
        }

        guard !didApplyLaunchFrame || isWithinStartupWindow else { return }
        didApplyLaunchFrame = true
        let target = XGlassStartupWindowFrame.frame(
            in: screenFrame,
            minimumSize: window.minSize
        )
        window.setFrame(target, display: true, animate: false)
        scheduleRestorationCorrections(for: window)
    }

    private func scheduleRestorationCorrections(for window: NSWindow) {
        correctionTask?.cancel()
        correctionTask = Task { @MainActor [weak self, weak window] in
            // SwiftUI/AppKit can restore the old frame after the first window
            // notification. Two delayed checks are enough to cover that race.
            for delay in [0.15, 0.55] {
                try? await Task.sleep(for: .seconds(delay))
                guard !Task.isCancelled, let self, let window else { return }
                guard !self.launchUserResizeStarted else { return }
                guard !window.styleMask.contains(.fullScreen) else { return }
                guard let screen = window.screen ?? NSScreen.main else { return }
                let expected = XGlassStartupWindowFrame.frame(
                    in: screen.frame,
                    minimumSize: window.minSize
                )
                if abs(window.frame.width - expected.width) > 1 ||
                    abs(window.frame.height - expected.height) > 1 ||
                    abs(window.frame.minX - expected.minX) > 1 ||
                    abs(window.frame.minY - expected.minY) > 1 {
                    window.setFrame(expected, display: true, animate: false)
                }
            }
            self?.correctionTask = nil
        }
    }

    private func requestExitFullScreen(_ window: NSWindow) {
        guard !fullScreenExitRequested, fullScreenExitAttempts < 2 else { return }
        fullScreenExitRequested = true
        fullScreenExitAttempts += 1
        window.toggleFullScreen(nil)

        fullScreenExitTask?.cancel()
        fullScreenExitTask = Task { @MainActor [weak self, weak window] in
            try? await Task.sleep(for: .seconds(1.5))
            guard !Task.isCancelled, let self, let window else { return }
            self.fullScreenExitTask = nil
            if window.styleMask.contains(.fullScreen) {
                self.fullScreenExitRequested = false
                self.configure(window: window)
            } else {
                self.fullScreenExitRequested = false
                self.fullScreenExitAttempts = 0
                self.didApplyLaunchFrame = false
                self.configure(window: window)
            }
        }
    }
}
