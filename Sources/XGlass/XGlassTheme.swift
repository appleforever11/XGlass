import Foundation

enum XGlassSettingsKeys {
    static let theme = "XGlass.visualTheme"
    static let themeCustomization = "XGlass.themeCustomization"
    static let backgroundGlow = "XGlass.backgroundGlow"
    static let glassIntensity = "XGlass.glassIntensity"
    static let reduceMotion = "XGlass.reduceMotion"
    static let hidePromotedPosts = "XGlass.hidePromotedPosts"
    static let compactSidebar = "XGlass.compactSidebar"
    static let feedWidth = "XGlass.feedWidth"
    static let showBrowserToolbar = "XGlass.showBrowserToolbar"
    static let pageZoom = "XGlass.pageZoom"
    static let pauseMediaInBackground = "XGlass.pauseMediaInBackground"
    static let favoriteThemes = "XGlass.favoriteThemes"
}

enum XGlassThemeCollection: String, CaseIterable, Codable, Identifiable, Hashable {
    case all
    case vivid
    case calm
    case cool
    case warm
    case nature
    case minimal
    case macOS

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: "All environments"
        case .vivid: "Vivid"
        case .calm: "Calm"
        case .cool: "Cool"
        case .warm: "Warm"
        case .nature: "Nature"
        case .minimal: "Minimal"
        case .macOS: "macOS"
        }
    }
}

enum XGlassThemeFamily: String, CaseIterable, Codable, Identifiable, Hashable {
    case goldenGate
    case bigSur
    case mojave
    case sonoma
    case tahoeTide
    case violetBloom
    case arcticSignal
    case forestRadar
    case emberConsole
    case oceanDrive
    case roseQuartz
    case monochromeStudio

    var id: String { rawValue }

    var title: String {
        switch self {
        case .goldenGate: "Golden Gate"
        case .bigSur: "Big Sur"
        case .mojave: "Mojave Dusk"
        case .sonoma: "Sonoma Hills"
        case .tahoeTide: "Tahoe Tide"
        case .violetBloom: "Violet Bloom"
        case .arcticSignal: "Arctic Signal"
        case .forestRadar: "Forest Radar"
        case .emberConsole: "Ember Console"
        case .oceanDrive: "Ocean Drive"
        case .roseQuartz: "Rose Quartz"
        case .monochromeStudio: "Monochrome Studio"
        }
    }

    var subtitle: String {
        switch self {
        case .goldenGate: "Golden brown, bronze, and warm grey"
        case .bigSur: "Pacific blue and coastal peach"
        case .mojave: "Desert sand and twilight slate"
        case .sonoma: "Olive hills and late afternoon gold"
        case .tahoeTide: "Tahoe blue, teal, and mint glass"
        case .violetBloom: "Violet, orchid, and electric pink"
        case .arcticSignal: "Ice blue, silver, and cyan"
        case .forestRadar: "Pine, moss, and warm signal"
        case .emberConsole: "Orange, amber, and red glass"
        case .oceanDrive: "Pacific blue, foam, and sea glass"
        case .roseQuartz: "Blush, coral, and lavender"
        case .monochromeStudio: "Graphite, paper, and silver"
        }
    }

    var systemImage: String {
        switch self {
        case .goldenGate: "sun.horizon.fill"
        case .bigSur: "mountain.2.fill"
        case .mojave: "moon.stars.fill"
        case .sonoma: "sun.max.fill"
        case .tahoeTide: "water.waves"
        case .violetBloom: "sparkles"
        case .arcticSignal: "snowflake"
        case .forestRadar: "leaf.fill"
        case .emberConsole: "flame.fill"
        case .oceanDrive: "water.waves"
        case .roseQuartz: "heart.fill"
        case .monochromeStudio: "circle.lefthalf.filled.righthalf.striped.horizontal"
        }
    }

    var collection: XGlassThemeCollection {
        switch self {
        case .goldenGate, .bigSur, .mojave, .sonoma: .macOS
        case .tahoeTide, .arcticSignal, .oceanDrive: .cool
        case .violetBloom, .roseQuartz: .vivid
        case .forestRadar: .nature
        case .emberConsole: .warm
        case .monochromeStudio: .minimal
        }
    }

    var badgeTitle: String? {
        switch self {
        case .tahoeTide: "DEFAULT"
        case .violetBloom, .oceanDrive, .roseQuartz: "NEW"
        default: nil
        }
    }

}
