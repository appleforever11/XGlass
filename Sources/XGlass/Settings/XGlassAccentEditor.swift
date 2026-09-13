import SwiftUI

struct XGlassAccentEditor: View {
    @EnvironmentObject private var settings: XGlassSettingsStore

    @State private var draftAccentColor = Color.blue
    @State private var accentHexDraft = ""

    private static let quickAccentHexes = [
        "#22C7C9",
        "#8B5CF6",
        "#FF4D9A",
        "#FFB14A",
        "#63D7A5",
        "#4C8DFF"
    ]

    private var baseAccentHex: String {
        XGlassThemeCustomization.hex(for: settings.theme.colors.accent) ?? "#4C8DFF"
    }

    private var appliedAccentHex: String? {
        settings.themeCustomization.normalizedAccentHex
    }

    private var canApply: Bool {
        XGlassThemeCustomization.normalizeHex(accentHexDraft) != nil
    }

    var body: some View {
        XGlassSettingsGroup(
            title: "Accent editor",
            footer: nil
        ) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 12) {
                    Circle()
                        .fill(draftAccentColor)
                        .frame(width: 34, height: 34)
                        .overlay {
                            Circle().stroke(.quaternary, lineWidth: 1)
                        }

                    VStack(alignment: .leading, spacing: 3) {
                        Text(appliedAccentHex == nil ? "Environment accent" : "Custom accent")
                            .font(.subheadline.weight(.semibold))
                        Text(appliedAccentHex ?? "Using \(baseAccentHex)")
                            .font(.caption.monospaced())
                            .foregroundStyle(.secondary)
                    }

                    Spacer(minLength: 12)

                    ColorPicker("Accent color", selection: draftAccentColorBinding, supportsOpacity: false)
                        .controlSize(.small)
                }

                HStack(spacing: 10) {
                    Text("Hex")
                        .font(.subheadline.weight(.semibold))
                        .frame(width: 32, alignment: .leading)

                    TextField(baseAccentHex, text: $accentHexDraft)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 126)
                        .onSubmit(applyDraft)
                        .accessibilityLabel("Custom accent hex value")

                    Button {
                        applyDraft()
                    } label: {
                        Label("Apply", systemImage: "checkmark")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .disabled(!canApply)

                    Button {
                        settings.resetThemeCustomization()
                        synchronizeDraft()
                    } label: {
                        Label("Reset", systemImage: "arrow.counterclockwise")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .disabled(appliedAccentHex == nil)

                    Spacer(minLength: 0)
                }

                Divider()

                HStack(spacing: 10) {
                    Text("Quick accents")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)

                    ForEach(Self.quickAccentHexes, id: \.self) { hex in
                        Button {
                            chooseQuickAccent(hex)
                        } label: {
                            Circle()
                                .fill(XGlassThemeCustomization(accentHex: hex).accentColor ?? .accentColor)
                                .frame(width: 22, height: 22)
                                .overlay {
                                    Circle().stroke(.primary.opacity(0.16), lineWidth: 1)
                                }
                        }
                        .buttonStyle(.plain)
                        .help("Use \(hex)")
                        .accessibilityLabel("Choose accent \(hex)")
                    }

                    Spacer(minLength: 0)
                }
            }
        }
        .onAppear(perform: synchronizeDraft)
        .onChange(of: settings.theme) { _, _ in
            synchronizeDraft()
        }
        .onChange(of: settings.themeCustomization) { _, _ in
            synchronizeDraft()
        }
    }

    private var draftAccentColorBinding: Binding<Color> {
        Binding(
            get: { draftAccentColor },
            set: { newColor in
                draftAccentColor = newColor
                if let hex = XGlassThemeCustomization.hex(for: newColor) {
                    accentHexDraft = hex
                }
            }
        )
    }

    private func chooseQuickAccent(_ hex: String) {
        guard let normalized = XGlassThemeCustomization.normalizeHex(hex),
              let color = XGlassThemeCustomization(accentHex: normalized).accentColor else {
            return
        }
        accentHexDraft = normalized
        draftAccentColor = color
        settings.setThemeAccentHex(normalized)
    }

    private func applyDraft() {
        guard let normalized = XGlassThemeCustomization.normalizeHex(accentHexDraft) else { return }
        settings.setThemeAccentHex(normalized)
        accentHexDraft = normalized
    }

    private func synchronizeDraft() {
        draftAccentColor = settings.themeCustomization.accentColor ?? settings.theme.colors.accent
        accentHexDraft = settings.themeCustomization.normalizedAccentHex ?? ""
    }
}
