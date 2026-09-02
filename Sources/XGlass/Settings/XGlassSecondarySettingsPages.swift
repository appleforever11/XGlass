import AppKit
import SwiftUI

struct XGlassNavigationSettingsPage: View {
    @EnvironmentObject private var browser: XBrowserModel
    @EnvironmentObject private var settings: XGlassSettingsStore

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            XGlassSettingsHeader(page: .navigation)

            XGlassSettingsGroup(
                title: "Quick routes",
                footer: "These buttons use the same normal X.com WebKit session as the main sidebar. They do not create API credentials or a second account session."
            ) {
                HStack(spacing: 10) {
                    XGlassSettingsRouteAction(
                        title: "Home",
                        systemImage: XRoute.home.systemImage,
                        action: { browser.navigate(to: .home) }
                    )
                    XGlassSettingsRouteAction(
                        title: "Your profile",
                        systemImage: XRoute.profile.systemImage,
                        action: browser.navigateToOwnProfile
                    )
                    XGlassSettingsRouteAction(
                        title: "Account settings",
                        systemImage: XRoute.settings.systemImage,
                        action: { browser.navigate(to: .settings) }
                    )
                }

                Divider()

                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .foregroundStyle(settings.colors.accent)
                    Text("Route recovery waits for X's SPA navigation to settle, retries once when needed, and leaves a visible Retry action instead of silently abandoning the page.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            XGlassSettingsGroup(
                title: "Desktop behavior",
                footer: "XGlass keeps a resizable native window with a compact layout threshold so the sidebar and feed remain usable on smaller displays."
            ) {
                XGlassSettingsValueRow(
                    title: "Window",
                    value: "Resizable",
                    systemImage: "macwindow",
                    accent: settings.colors.accent
                )
                XGlassSettingsValueRow(
                    title: "Minimum content",
                    value: "600 x 480",
                    systemImage: "arrow.down.right.and.arrow.up.left",
                    accent: settings.colors.accent
                )
                XGlassSettingsValueRow(
                    title: "External links",
                    value: "Open in default browser",
                    systemImage: "safari",
                    accent: settings.colors.accent
                )
            }
        }
    }
}

struct XGlassPrivacySettingsPage: View {
    @EnvironmentObject private var browser: XBrowserModel
    @EnvironmentObject private var settings: XGlassSettingsStore

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            XGlassSettingsHeader(page: .privacy)

            XGlassSettingsGroup(
                title: "Feed controls",
                footer: "Promoted-post filtering happens locally in the page presentation layer. It does not change your X account, preferences, follows, or ad settings."
            ) {
                Toggle("Hide promoted posts", isOn: Binding(
                    get: { settings.hidePromotedPosts },
                    set: { settings.setHidePromotedPosts($0) }
                ))
                XGlassSettingsValueRow(
                    title: "Account access",
                    value: "Normal X.com session",
                    systemImage: "person.crop.circle",
                    accent: settings.colors.accent
                )
                XGlassSettingsValueRow(
                    title: "API credentials",
                    value: "Not used by XGlass",
                    systemImage: "key.slash",
                    accent: settings.colors.accent
                )
                XGlassSettingsValueRow(
                    title: "Two-factor authentication",
                    value: "Handled by X.com",
                    systemImage: "lock.shield",
                    accent: settings.colors.accent
                )
            }

            XGlassSettingsGroup(
                title: "Privacy boundary",
                footer: "XGlass does not read or store your X password, two-factor codes, API keys, or private account tokens. WebKit owns the signed-in session and X remains responsible for sign-in and account security."
            ) {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "checkmark.shield.fill")
                        .foregroundStyle(.green)
                    Text("The app customizes presentation around the existing X web session. Sign-in, 2FA prompts, account settings, posting, and messaging remain inside X.com.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Button {
                    browser.openCurrentPageInBrowser()
                } label: {
                    Label("Open current page in browser", systemImage: "safari")
                }
                .buttonStyle(.bordered)
            }
        }
    }
}

struct XGlassDiagnosticsSettingsPage: View {
    @EnvironmentObject private var browser: XBrowserModel
    @EnvironmentObject private var settings: XGlassSettingsStore

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            XGlassSettingsHeader(page: .diagnostics)

            XGlassSettingsGroup(
                title: "Interface health check",
                footer: "The check inspects the current page without clicking posts, sending messages, changing account settings, or navigating through your account."
            ) {
                HStack(alignment: .center, spacing: 12) {
                    Button {
                        browser.runInterfaceHealthCheck()
                    } label: {
                        Label(
                            browser.isRunningHealthCheck ? "Checking..." : "Run health check",
                            systemImage: browser.isRunningHealthCheck ? "hourglass" : "stethoscope"
                        )
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(browser.isRunningHealthCheck)

                    if let report = browser.healthReport {
                        Label(
                            report.allPassed ? "All checks passed" : "Review failed checks",
                            systemImage: report.allPassed ? "checkmark.circle.fill" : "exclamationmark.triangle.fill"
                        )
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(report.allPassed ? .green : .orange)
                    }
                }

                if let report = browser.healthReport {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Current page: \(report.pagePath)")
                            .font(.caption.monospaced())
                            .foregroundStyle(.secondary)

                        ForEach(report.checks) { check in
                            HStack(spacing: 9) {
                                Image(systemName: check.passed ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .foregroundStyle(check.passed ? .green : .red)
                                Text(check.title)
                                    .font(.subheadline)
                                Spacer(minLength: 0)
                                Text(check.detail)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                        }
                    }
                    .padding(.top, 4)
                }
            }

            XGlassSettingsGroup(
                title: "Release route matrix",
                footer: "The matrix is intentionally descriptive. Use the main sidebar or Quick routes to open a page, then run the current-page check."
            ) {
                ForEach(XRoute.allCases) { route in
                    XGlassSettingsValueRow(
                        title: route.rawValue,
                        value: route.url.path,
                        systemImage: route.systemImage,
                        accent: settings.colors.accent
                    )
                }
            }
        }
    }
}

struct XGlassAboutSettingsPage: View {
    @EnvironmentObject private var settings: XGlassSettingsStore

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.0"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            XGlassSettingsHeader(page: .about)

            XGlassSettingsGroup(
                title: "XGlass",
                footer: "XGlass is a native macOS shell for X.com, using WebKit's normal site session instead of a separate API client."
            ) {
                HStack(spacing: 14) {
                    if let icon = NSImage(named: NSImage.Name("XGlass")) {
                        Image(nsImage: icon)
                            .resizable()
                            .frame(width: 64, height: 64)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    } else {
                        SettingsIconBadge(systemName: "xmark", tint: settings.colors.accent, size: 64)
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text("XGlass")
                            .font(.title2.weight(.bold))
                        Text("Version \(appVersion)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text("Apple Silicon · macOS 14+")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }

                Divider()

                HStack(spacing: 10) {
                    Button {
                        (NSApp.delegate as? XGlassAppDelegate)?.checkForUpdates()
                    } label: {
                        Label("Check for updates", systemImage: "arrow.down.circle")
                    }
                    .buttonStyle(.borderedProminent)

                    Button {
                        if let url = URL(string: "https://github.com/appleforever11/XGlass") {
                            NSWorkspace.shared.open(url)
                        }
                    } label: {
                        Label("GitHub", systemImage: "link")
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
    }
}
