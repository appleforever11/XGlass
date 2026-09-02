import SwiftUI

struct XGlassAmbientBackdrop: View {
    let colors: XGlassThemeColors
    let intensity: Double
    let reduceMotion: Bool

    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @State private var phase = 0.0

    private var motionPaused: Bool {
        reduceMotion || accessibilityReduceMotion || scenePhase != .active
    }

    var body: some View {
        GeometryReader { geometry in
            let width = max(geometry.size.width, 1)
            let height = max(geometry.size.height, 1)
            let amount = motionPaused ? 0.0 : phase
            let glow = min(max(intensity, 0.25), 1.0)

            ZStack {
                colors.window

                RadialGradient(
                    colors: [colors.primary.opacity(0.40 * glow), .clear],
                    center: UnitPoint(x: 0.12 + amount * 0.05, y: 0.10),
                    startRadius: 0,
                    endRadius: max(width, height) * 0.84
                )

                RadialGradient(
                    colors: [colors.secondary.opacity(0.34 * glow), .clear],
                    center: UnitPoint(x: 0.88 - amount * 0.04, y: 0.82),
                    startRadius: 0,
                    endRadius: max(width, height) * 0.78
                )

                RadialGradient(
                    colors: [colors.tertiary.opacity(0.22 * glow), .clear],
                    center: UnitPoint(x: 0.50, y: 0.48 + amount * 0.04),
                    startRadius: 0,
                    endRadius: max(width, height) * 0.62
                )

                LinearGradient(
                    colors: [Color.white.opacity(0.035), .clear, Color.black.opacity(0.16)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
        .onAppear {
            updateMotion(isPaused: motionPaused)
        }
        .onChange(of: motionPaused) { _, paused in
            updateMotion(isPaused: paused)
        }
        .allowsHitTesting(false)
    }

    private func updateMotion(isPaused: Bool) {
        if isPaused {
            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction) {
                phase = 0
            }
            return
        }

        guard phase == 0 else { return }
        withAnimation(.easeInOut(duration: 18).repeatForever(autoreverses: true)) {
            phase = 1
        }
    }
}
