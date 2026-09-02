import SwiftUI

struct XGlassWebTheme: Codable, Equatable {
    let bandTop: String
    let bandBottom: String
    let accent: String
    let accentSoft: String
    let text: String
    let muted: String
    let border: String
    let incomingBubble: String
    let outgoingBubble: String
}

struct XGlassThemeColors {
    let window: Color
    let sidebar: Color
    let content: Color
    let card: Color
    let selected: Color
    let stroke: Color
    let text: Color
    let secondaryText: Color
    let primary: Color
    let secondary: Color
    let tertiary: Color
    let accent: Color
    let web: XGlassWebTheme
}

extension XGlassThemeFamily {
    var colors: XGlassThemeColors {
        switch self {
        case .tahoeTide:
            XGlassThemeColors(
                window: rgb(0.035, 0.055, 0.075),
                sidebar: rgb(0.035, 0.235, 0.305),
                content: rgb(0.040, 0.145, 0.185),
                card: rgb(0.075, 0.205, 0.250),
                selected: rgb(0.370, 0.770, 0.790).opacity(0.32),
                stroke: rgb(0.520, 0.850, 0.850).opacity(0.22),
                text: rgb(0.950, 0.985, 0.985),
                secondaryText: rgb(0.720, 0.870, 0.870).opacity(0.78),
                primary: rgb(0.190, 0.720, 0.760),
                secondary: rgb(0.430, 0.560, 0.980),
                tertiary: rgb(0.430, 0.900, 0.770),
                accent: rgb(0.420, 0.900, 0.860),
                web: .init(
                    bandTop: "rgba(40, 111, 117, 0.46)",
                    bandBottom: "rgba(24, 86, 95, 0.38)",
                    accent: "rgb(120, 228, 225)",
                    accentSoft: "rgba(120, 228, 225, 0.15)",
                    text: "rgba(245, 252, 251, 0.96)",
                    muted: "rgba(232, 247, 246, 0.76)",
                    border: "rgba(190, 235, 231, 0.16)",
                    incomingBubble: "rgba(240, 249, 248, 0.16)",
                    outgoingBubble: "rgba(48, 156, 161, 0.50)"
                )
            )
        case .violetBloom:
            XGlassThemeColors(
                window: rgb(0.065, 0.035, 0.115),
                sidebar: rgb(0.190, 0.075, 0.265),
                content: rgb(0.135, 0.050, 0.220),
                card: rgb(0.250, 0.095, 0.310),
                selected: rgb(0.790, 0.350, 0.920).opacity(0.34),
                stroke: rgb(0.940, 0.590, 1.000).opacity(0.24),
                text: rgb(0.985, 0.960, 1.000),
                secondaryText: rgb(0.875, 0.780, 0.970).opacity(0.78),
                primary: rgb(0.800, 0.330, 0.980),
                secondary: rgb(0.980, 0.250, 0.690),
                tertiary: rgb(0.400, 0.650, 1.000),
                accent: rgb(0.850, 0.560, 1.000),
                web: .init(
                    bandTop: "rgba(110, 50, 155, 0.46)",
                    bandBottom: "rgba(75, 30, 120, 0.40)",
                    accent: "rgb(215, 155, 255)",
                    accentSoft: "rgba(215, 155, 255, 0.16)",
                    text: "rgba(250, 246, 255, 0.97)",
                    muted: "rgba(240, 220, 255, 0.78)",
                    border: "rgba(235, 190, 255, 0.18)",
                    incomingBubble: "rgba(248, 233, 255, 0.16)",
                    outgoingBubble: "rgba(145, 72, 190, 0.54)"
                )
            )
        case .arcticSignal:
            XGlassThemeColors(
                window: rgb(0.025, 0.065, 0.115),
                sidebar: rgb(0.055, 0.220, 0.355),
                content: rgb(0.040, 0.145, 0.255),
                card: rgb(0.075, 0.220, 0.350),
                selected: rgb(0.260, 0.700, 1.000).opacity(0.34),
                stroke: rgb(0.540, 0.850, 1.000).opacity(0.24),
                text: rgb(0.945, 0.980, 1.000),
                secondaryText: rgb(0.720, 0.860, 0.980).opacity(0.78),
                primary: rgb(0.180, 0.620, 1.000),
                secondary: rgb(0.330, 0.900, 0.940),
                tertiary: rgb(0.550, 0.570, 1.000),
                accent: rgb(0.480, 0.820, 1.000),
                web: .init(
                    bandTop: "rgba(50, 125, 170, 0.46)",
                    bandBottom: "rgba(30, 80, 140, 0.38)",
                    accent: "rgb(135, 220, 255)",
                    accentSoft: "rgba(135, 220, 255, 0.16)",
                    text: "rgba(244, 251, 255, 0.97)",
                    muted: "rgba(220, 240, 255, 0.78)",
                    border: "rgba(190, 230, 255, 0.18)",
                    incomingBubble: "rgba(225, 245, 255, 0.16)",
                    outgoingBubble: "rgba(45, 125, 190, 0.52)"
                )
            )
        case .forestRadar:
            XGlassThemeColors(
                window: rgb(0.025, 0.070, 0.050),
                sidebar: rgb(0.040, 0.260, 0.205),
                content: rgb(0.030, 0.165, 0.145),
                card: rgb(0.070, 0.235, 0.180),
                selected: rgb(0.250, 0.780, 0.430).opacity(0.32),
                stroke: rgb(0.480, 0.900, 0.620).opacity(0.22),
                text: rgb(0.940, 1.000, 0.950),
                secondaryText: rgb(0.730, 0.900, 0.780).opacity(0.78),
                primary: rgb(0.170, 0.780, 0.400),
                secondary: rgb(0.700, 0.840, 0.200),
                tertiary: rgb(0.200, 0.820, 0.720),
                accent: rgb(0.400, 0.900, 0.570),
                web: .init(
                    bandTop: "rgba(40, 125, 93, 0.46)",
                    bandBottom: "rgba(24, 88, 70, 0.38)",
                    accent: "rgb(125, 238, 165)",
                    accentSoft: "rgba(125, 238, 165, 0.15)",
                    text: "rgba(243, 253, 246, 0.97)",
                    muted: "rgba(220, 246, 228, 0.78)",
                    border: "rgba(185, 240, 205, 0.17)",
                    incomingBubble: "rgba(225, 250, 232, 0.15)",
                    outgoingBubble: "rgba(38, 145, 104, 0.52)"
                )
            )
        case .emberConsole:
            XGlassThemeColors(
                window: rgb(0.105, 0.040, 0.025),
                sidebar: rgb(0.330, 0.120, 0.060),
                content: rgb(0.220, 0.080, 0.035),
                card: rgb(0.340, 0.135, 0.055),
                selected: rgb(1.000, 0.500, 0.130).opacity(0.30),
                stroke: rgb(1.000, 0.720, 0.380).opacity(0.22),
                text: rgb(1.000, 0.960, 0.900),
                secondaryText: rgb(0.960, 0.790, 0.640).opacity(0.78),
                primary: rgb(1.000, 0.350, 0.070),
                secondary: rgb(1.000, 0.680, 0.080),
                tertiary: rgb(0.920, 0.190, 0.170),
                accent: rgb(1.000, 0.580, 0.190),
                web: .init(
                    bandTop: "rgba(150, 75, 36, 0.48)",
                    bandBottom: "rgba(105, 45, 26, 0.40)",
                    accent: "rgb(255, 190, 105)",
                    accentSoft: "rgba(255, 190, 105, 0.16)",
                    text: "rgba(255, 249, 240, 0.98)",
                    muted: "rgba(255, 231, 205, 0.78)",
                    border: "rgba(255, 220, 175, 0.18)",
                    incomingBubble: "rgba(255, 241, 220, 0.15)",
                    outgoingBubble: "rgba(190, 90, 40, 0.54)"
                )
            )
        case .oceanDrive:
            XGlassThemeColors(
                window: rgb(0.015, 0.070, 0.120),
                sidebar: rgb(0.025, 0.245, 0.355),
                content: rgb(0.020, 0.155, 0.235),
                card: rgb(0.055, 0.240, 0.315),
                selected: rgb(0.100, 0.750, 0.900).opacity(0.34),
                stroke: rgb(0.450, 0.940, 0.950).opacity(0.23),
                text: rgb(0.930, 0.995, 1.000),
                secondaryText: rgb(0.700, 0.890, 0.950).opacity(0.78),
                primary: rgb(0.060, 0.720, 0.900),
                secondary: rgb(0.200, 0.450, 1.000),
                tertiary: rgb(0.260, 0.900, 0.780),
                accent: rgb(0.240, 0.860, 0.940),
                web: .init(
                    bandTop: "rgba(28, 137, 154, 0.46)",
                    bandBottom: "rgba(20, 85, 120, 0.38)",
                    accent: "rgb(110, 235, 242)",
                    accentSoft: "rgba(110, 235, 242, 0.15)",
                    text: "rgba(242, 253, 255, 0.97)",
                    muted: "rgba(211, 245, 250, 0.78)",
                    border: "rgba(175, 238, 245, 0.18)",
                    incomingBubble: "rgba(220, 249, 255, 0.15)",
                    outgoingBubble: "rgba(30, 145, 170, 0.52)"
                )
            )
        case .roseQuartz:
            XGlassThemeColors(
                window: rgb(0.100, 0.035, 0.075),
                sidebar: rgb(0.340, 0.100, 0.220),
                content: rgb(0.230, 0.070, 0.170),
                card: rgb(0.360, 0.115, 0.245),
                selected: rgb(1.000, 0.330, 0.650).opacity(0.30),
                stroke: rgb(1.000, 0.620, 0.800).opacity(0.22),
                text: rgb(1.000, 0.950, 0.980),
                secondaryText: rgb(0.960, 0.770, 0.870).opacity(0.78),
                primary: rgb(1.000, 0.280, 0.620),
                secondary: rgb(0.650, 0.360, 1.000),
                tertiary: rgb(1.000, 0.470, 0.380),
                accent: rgb(1.000, 0.480, 0.750),
                web: .init(
                    bandTop: "rgba(160, 62, 112, 0.46)",
                    bandBottom: "rgba(110, 35, 82, 0.40)",
                    accent: "rgb(255, 155, 205)",
                    accentSoft: "rgba(255, 155, 205, 0.16)",
                    text: "rgba(255, 247, 252, 0.98)",
                    muted: "rgba(255, 224, 240, 0.78)",
                    border: "rgba(255, 205, 230, 0.18)",
                    incomingBubble: "rgba(255, 235, 246, 0.15)",
                    outgoingBubble: "rgba(185, 62, 125, 0.54)"
                )
            )
        case .monochromeStudio:
            XGlassThemeColors(
                window: rgb(0.045, 0.050, 0.060),
                sidebar: rgb(0.150, 0.165, 0.185),
                content: rgb(0.105, 0.115, 0.130),
                card: rgb(0.190, 0.205, 0.230),
                selected: rgb(0.750, 0.800, 0.880).opacity(0.28),
                stroke: rgb(0.880, 0.910, 0.960).opacity(0.20),
                text: rgb(0.960, 0.970, 0.990),
                secondaryText: rgb(0.760, 0.790, 0.850).opacity(0.78),
                primary: rgb(0.740, 0.800, 0.920),
                secondary: rgb(0.520, 0.650, 0.820),
                tertiary: rgb(0.680, 0.720, 0.780),
                accent: rgb(0.780, 0.850, 0.980),
                web: .init(
                    bandTop: "rgba(100, 110, 125, 0.44)",
                    bandBottom: "rgba(65, 75, 90, 0.38)",
                    accent: "rgb(220, 232, 255)",
                    accentSoft: "rgba(220, 232, 255, 0.15)",
                    text: "rgba(248, 250, 255, 0.97)",
                    muted: "rgba(226, 232, 245, 0.76)",
                    border: "rgba(230, 238, 255, 0.16)",
                    incomingBubble: "rgba(245, 248, 255, 0.14)",
                    outgoingBubble: "rgba(110, 125, 155, 0.52)"
                )
            )
        }
    }
}

private func rgb(_ red: Double, _ green: Double, _ blue: Double) -> Color {
    Color(red: red, green: green, blue: blue)
}
