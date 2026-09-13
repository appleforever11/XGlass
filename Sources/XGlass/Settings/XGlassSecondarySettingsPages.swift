import AppKit
import SwiftUI

struct XGlassNavigationSettingsPage: View {
    @EnvironmentObject private var settings: XGlassSettingsStore

    var body: some View {
        VStack(alignment: .leading, spacing: 26) {
            XGlassSettingsHeader(page: .navigation)
            XGlassSettingsGroup(title: "Reading", footer: nil) {
                HStack {
                    Label("Page size", systemImage: "textformat.size")
                    Spacer()
                    Text("\(Int((settings.pageZoom * 100).rounded()))%").monospacedDigit()
                    Button("Reset") { settings.setPageZoom(1) }.controlSize(.small)
                        .disabled(abs(settings.pageZoom - 1) < 0.01)
                }
                Slider(value: Binding(get: { settings.pageZoom }, set: { settings.setPageZoom($0) }), in: XGlassReadingScale.range, step: 0.05)
                    .accessibilityLabel("Page size")
                Picker("Feed width", selection: Binding(get: { settings.feedWidth }, set: { settings.setFeedWidth($0) })) {
                    ForEach(XGlassFeedWidth.allCases) { Text($0.title).tag($0) }
                }
                .pickerStyle(.segmented)
            }
            XGlassSettingsGroup(title: "Window", footer: nil) {
                Toggle("Show browser toolbar", isOn: Binding(get: { settings.showBrowserToolbar }, set: { settings.setShowBrowserToolbar($0) }))
                Toggle("Always use icon-only navigation", isOn: Binding(get: { settings.compactSidebar }, set: { settings.setCompactSidebar($0) }))
            }
            XGlassSettingsGroup(title: "Playback & Energy", footer: nil) {
                Toggle("Suspend media when the window is hidden", isOn: Binding(
                    get: { settings.pauseMediaInBackground }, set: { settings.setPauseMediaInBackground($0) }
                ))
                Toggle("Reduce ambient motion", isOn: Binding(get: { settings.reduceMotion }, set: { settings.setReduceMotion($0) }))
            }
        }
    }
}

struct XGlassPrivacySettingsPage: View {
    @EnvironmentObject private var browser: XBrowserModel
    @EnvironmentObject private var settings: XGlassSettingsStore

    var body: some View {
        VStack(alignment: .leading, spacing: 26) {
            XGlassSettingsHeader(page: .privacy)
            XGlassSettingsGroup(title: "Feed", footer: nil) {
                Toggle("Hide promoted posts", isOn: Binding(get: { settings.hidePromotedPosts }, set: { settings.setHidePromotedPosts($0) }))
            }
            XGlassSettingsGroup(title: "Account", footer: nil) {
                XGlassSettingsValueRow(title: "Sign-in", value: "X.com", systemImage: "lock.shield", accent: settings.colors.accent)
                Button("X Account Settings", systemImage: "person.crop.circle") { browser.navigate(to: .settings) }
                Button("Privacy and Safety", systemImage: "hand.raised") {
                    browser.navigate(to: URL(string: "https://x.com/settings/privacy_and_safety")!)
                }
                Button("Open in Browser", systemImage: "safari", action: browser.openCurrentPageInBrowser)
            }
        }
    }
}

struct XGlassDiagnosticsSettingsPage: View {
    @EnvironmentObject private var browser: XBrowserModel
    @EnvironmentObject private var settings: XGlassSettingsStore

    var body: some View {
        VStack(alignment: .leading, spacing: 26) {
            XGlassSettingsHeader(page: .diagnostics)
            XGlassSettingsGroup(title: "Interface", footer: nil) {
                HStack(spacing: 12) {
                    Button(browser.isRunningHealthCheck ? "Checking..." : "Run Health Check", systemImage: "stethoscope", action: browser.runInterfaceHealthCheck)
                        .buttonStyle(.borderedProminent).disabled(browser.isRunningHealthCheck)
                    if let report = browser.healthReport {
                        Label(report.allPassed ? "All checks passed" : "Needs attention", systemImage: report.allPassed ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                            .foregroundStyle(report.allPassed ? .green : .orange)
                            .font(.subheadline)
                    }
                }
                if let report = browser.healthReport {
                    Text(report.checkedAt, style: .time).font(.caption).foregroundStyle(.secondary)
                    ForEach(report.checks) { check in
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: check.passed ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                                .foregroundStyle(check.passed ? .green : .orange)
                            VStack(alignment: .leading, spacing: 3) {
                                Text(check.title).font(.subheadline)
                                Text(check.detail).font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer(minLength: 0)
                        }
                    }
                }
            }
            XGlassSettingsGroup(title: "Recovery", footer: nil) {
                Text("Page status: \(browser.loadState)")
                DisclosureGroup("Recent loading events") {
                    Text(browser.diagnosticEvents.suffix(16).joined(separator: "\n"))
                        .font(.system(size: 11, design: .monospaced))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                Button("Restart Web Session", action: browser.restartWebSession)
                Button("Copy Diagnostic Report", systemImage: "doc.on.doc", action: browser.copyDiagnosticReport)
                Toggle("Compatibility mode (applies on next reload)", isOn: $browser.compatibilityMode)
                Text("Uses X’s standard page appearance to help diagnose loading problems.").font(.caption).foregroundStyle(.secondary)
                HStack {
                    Button("Reload Page", systemImage: "arrow.clockwise", action: browser.reload)
                    Button("Return Home", systemImage: "house") { browser.navigate(to: .home) }
                }
                if let status = browser.statusMessage {
                    Text(status).font(.subheadline).foregroundStyle(.secondary)
                }
            }
        }
    }
}

struct XGlassAboutSettingsPage: View {
    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.0"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 28) {
            HStack(spacing: 18) {
                Image(nsImage: NSApplication.shared.applicationIconImage).resizable().frame(width: 82, height: 82)
                VStack(alignment: .leading, spacing: 5) {
                    Text("XGlass").font(.system(size: 26, weight: .bold))
                    Text("Version \(appVersion)").foregroundStyle(.secondary)
                    Text("macOS 14 or later").font(.caption).foregroundStyle(.secondary)
                }
            }
            XGlassSettingsGroup(title: "Updates", footer: nil) {
                Button("Check for Updates...", systemImage: "arrow.down.circle") {
                    (NSApp.delegate as? XGlassAppDelegate)?.checkForUpdates()
                }
                .buttonStyle(.borderedProminent)
            }
            XGlassSettingsGroup(title: "Project", footer: nil) {
                Link("GitHub", destination: URL(string: "https://github.com/appleforever11/XGlass")!)
                Link("Release Notes", destination: URL(string: "https://github.com/appleforever11/XGlass/releases")!)
                Link("Report an Issue", destination: URL(string: "https://github.com/appleforever11/XGlass/issues")!)
            }
        }
    }
}
