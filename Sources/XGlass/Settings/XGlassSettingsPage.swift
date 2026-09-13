import SwiftUI

enum XGlassSettingsPage: String, CaseIterable, Identifiable {
    case appearance
    case navigation
    case privacy
    case diagnostics
    case about

    var id: String { rawValue }

    var title: String {
        switch self {
        case .appearance: "Appearance"
        case .navigation: "Reading & Layout"
        case .privacy: "Privacy"
        case .diagnostics: "Diagnostics"
        case .about: "About XGlass"
        }
    }

    var subtitle: String {
        switch self {
        case .appearance: "Themes, glass, and motion"
        case .navigation: "Page size, window, and playback"
        case .privacy: "Feed and account"
        case .diagnostics: "Interface health"
        case .about: "Version and release details"
        }
    }

    var systemImage: String {
        switch self {
        case .appearance: "paintbrush.pointed.fill"
        case .navigation: "textformat.size"
        case .privacy: "hand.raised.fill"
        case .diagnostics: "stethoscope"
        case .about: "info.circle.fill"
        }
    }

    var tint: Color {
        switch self {
        case .appearance: .purple
        case .navigation: .blue
        case .privacy: .green
        case .diagnostics: .orange
        case .about: .teal
        }
    }
}
