//
//  LanguagePicker.swift
//  TimeToSkill
//
//  Circular flag button and language sheet modeled on MedBioPhys.
//  The same control is overlaid in the top-trailing corner of Overview and
//  Options so both screens share AppLanguage.shared. Every language row has
//  a dedicated flag asset; "device language" uses a neutral icon.
//

import SwiftUI
#if os(macOS)
import AppKit
#else
import UIKit
#endif

/// Hit target and visible disc for the language control.
enum LanguageSelectorMetrics {
    static let discDiameter: CGFloat = 32
    static let hitSize: CGFloat = 44
}

struct LanguageSelectorButton: View {
    @ObservedObject private var language = AppLanguage.shared
    @State private var showingPicker = false

    var body: some View {
        Button {
            showingPicker = true
        } label: {
            // Disc is centered in the hit circle with no extra padding that
            // would shift the flag off-center inside the visible field.
            ZStack {
                LanguageFlag(option: indicatorOption, diameter: LanguageSelectorMetrics.discDiameter)
            }
            .frame(width: LanguageSelectorMetrics.hitSize, height: LanguageSelectorMetrics.hitSize)
            .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(accessibilityName))
        .accessibilityIdentifier("LanguageSelectorButton")
        .help(Text(LocalizedStringKey("language_picker_title")))
        .sheet(isPresented: $showingPicker) {
            LanguagePickerSheet()
                .macOSSheetMinSize(width: 420, height: 520)
        }
    }

    private var indicatorOption: LanguageFlag.Option {
        if language.resolved.followsDevice {
            return .device
        }
        if let script = language.resolved.script {
            return .interslavic(script)
        }
        return .bundle(language.resolved.bundleCode)
    }

    private var accessibilityName: String {
        let device = LanguageState.shared.string("language_device")
        if language.resolved.followsDevice {
            return "\(device), \(endonym(language.resolved.bundleCode))"
        }
        if let script = language.resolved.script {
            let family = LanguageState.shared.string("language_name_interslavic")
            return "\(family), \(scriptName(script))"
        }
        return endonym(language.resolved.bundleCode)
    }

    private func scriptName(_ script: InterslavicScript) -> String {
        switch script {
        case .latin: return LanguageState.shared.string("language_script_latin")
        case .cyrillic: return LanguageState.shared.string("language_script_cyrillic")
        case .glagolitic: return LanguageState.shared.string("language_script_glagolitic")
        }
    }

    private func endonym(_ code: String) -> String {
        LanguageName.endonym(for: code)
    }
}

struct LanguageFlag: View {
    enum Option: Equatable {
        case device
        case bundle(String)
        case interslavic(InterslavicScript)
    }

    var option: Option
    var diameter: CGFloat

    @Environment(\.colorScheme) private var colorScheme

    /// Flag artwork fills most of the disc while staying inside the stroke.
    private static let imageScale: CGFloat = 0.72

    var body: some View {
        let imageSide = diameter * Self.imageScale
        ZStack {
            Circle()
                .fill(.ultraThinMaterial)
            Circle()
                .fill(fillColor)
            flagImage
                .frame(width: imageSide, height: imageSide)
                .clipShape(Circle())
            Circle()
                .strokeBorder(strokeColor, lineWidth: 1)
        }
        .frame(width: diameter, height: diameter, alignment: .center)
        .accessibilityHidden(true)
    }

    private var fillColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.12) : Color.primary.opacity(0.08)
    }

    private var strokeColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.28) : Color.primary.opacity(0.28)
    }

    @ViewBuilder
    private var flagImage: some View {
        if let name = assetName, FlagAsset.image(named: name) != nil {
            FlagAsset(name: name)
        } else if case .device = option {
            Image(systemName: "desktopcomputer")
                .font(.system(size: diameter * 0.42, weight: .semibold))
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        } else {
            // Should not happen when assets are complete; keep a non-emoji glyph badge.
            Text(badge)
                .font(.system(size: diameter * 0.28, weight: .bold))
                .foregroundStyle(.primary.opacity(0.88))
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
    }

    private var assetName: String? {
        switch option {
        case .device:
            return "Lang_device"
        case .interslavic:
            return "Flag_of_Interslavic"
        case .bundle(let code):
            return LanguageFlagCatalog.assetName(for: code)
        }
    }

    private var badge: String {
        switch option {
        case .device:
            return "DEV"
        case .interslavic:
            return "ISV"
        case .bundle(let code):
            let letters = code.split(separator: "-").first.map(String.init) ?? code
            return String(letters.prefix(3)).uppercased()
        }
    }
}

enum LanguageFlagCatalog {
    /// Every bundled UI language maps to a PNG under Resources/Flags.
    static func assetName(for code: String) -> String {
        switch code {
        case "pl": return "Flag_of_Poland"
        case "es": return "Flag_of_Spain"
        case "eo": return "Flag_of_Esperanto"
        case "en": return "English_language"
        case "isv": return "Flag_of_Interslavic"
        default:
            return "Lang_\(code)"
        }
    }

    static func hasAsset(for code: String) -> Bool {
        FlagAsset.image(named: assetName(for: code)) != nil
    }

    static var requiredCodes: [String] {
        [
            "ar", "ca", "cs", "da", "de", "el",
            "en", "en-AU", "en-CA", "en-GB", "en-IN",
            "eo", "es", "es-419", "fi", "fr", "fr-CA",
            "he", "hi", "hr", "hu", "id", "isv", "it", "ja", "ko",
            "ms", "nb", "nl", "pl", "pt-BR", "pt-PT",
            "ro", "ru", "sk", "sv", "th", "tr", "uk", "vi",
            "zh-Hans", "zh-Hant"
        ]
    }
}

/// Pins the shared language button to the top-trailing corner of a detail
/// panel's working area (not the whole screen / window chrome).
struct LanguageSelectorCorner: ViewModifier {
    var top: CGFloat = 10
    var trailing: CGFloat = 14

    func body(content: Content) -> some View {
        content.overlay(alignment: .topTrailing) {
            LanguageSelectorButton()
                .padding(.top, top)
                .padding(.trailing, trailing)
        }
    }
}

extension View {
    /// Same corner placement on Overview and Options.
    func languageSelectorCorner(top: CGFloat = 10, trailing: CGFloat = 14) -> some View {
        modifier(LanguageSelectorCorner(top: top, trailing: trailing))
    }
}

private struct FlagAsset: View {
    let name: String

    var body: some View {
        if let image = Self.image(named: name) {
            image
                .resizable()
                // Fill the circular crop so non-square PNGs stay centered.
                .scaledToFill()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        } else {
            Color.clear
        }
    }

    static func image(named name: String) -> Image? {
        let url = Bundle.main.url(forResource: name, withExtension: "png", subdirectory: "Flags")
            ?? Bundle.main.url(forResource: name, withExtension: "png")
        guard let url else { return nil }
        #if os(macOS)
        guard let picture = NSImage(contentsOf: url) else { return nil }
        return Image(nsImage: picture)
        #else
        guard let picture = UIImage(contentsOfFile: url.path) else { return nil }
        return Image(uiImage: picture)
        #endif
    }
}

struct LanguagePickerSheet: View {
    @ObservedObject private var language = AppLanguage.shared
    @Environment(\.dismiss) private var dismiss
    @State private var scriptsVisible = false

    var body: some View {
        NavigationStack {
            List {
                deviceRow
                featuredRows
                otherRows
            }
            .navigationTitle(Text(LocalizedStringKey("language_picker_title")))
            .inlineNavigationBarTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(LocalizedStringKey("close")) { dismiss() }
                }
            }
        }
        .onAppear {
            scriptsVisible = language.resolved.script != nil
        }
    }

    private var deviceRow: some View {
        Button {
            choose(LanguageCatalog.systemKey)
        } label: {
            HStack(spacing: 12) {
                LanguageFlag(option: .device, diameter: 32)
                VStack(alignment: .leading, spacing: 2) {
                    Text(LocalizedStringKey("language_device"))
                    Text(LocalizedStringKey("language_device_detail"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 8)
                if language.resolved.followsDevice {
                    Image(systemName: "checkmark")
                        .accessibilityHidden(true)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(language.resolved.followsDevice ? .isSelected : [])
    }

    @ViewBuilder
    private var featuredRows: some View {
        languageRow(code: "pl", title: LocalizedStringKey("language_name_polish"))
        languageRow(code: "en", title: LocalizedStringKey("language_name_english"))
        languageRow(code: "es", title: LocalizedStringKey("language_name_spanish"))
        interslavicSection
        languageRow(code: "eo", title: LocalizedStringKey("language_name_esperanto"))
    }

    private var otherRows: some View {
        let featured: Set<String> = ["pl", "en", "es", "eo", "isv"]
        let codes = AppLanguage.bundledCodes()
            .subtracting(featured)
            .filter { $0 != "Base" }
            .sorted { LanguageName.endonym(for: $0).localizedCaseInsensitiveCompare(LanguageName.endonym(for: $1)) == .orderedAscending }
        return ForEach(codes, id: \.self) { code in
            languageRow(code: code, title: LocalizedStringKey(stringLiteral: LanguageName.endonym(for: code)))
        }
    }

    private func languageRow(code: String, title: LocalizedStringKey) -> some View {
        Button {
            choose(code)
        } label: {
            HStack(spacing: 12) {
                LanguageFlag(option: .bundle(code), diameter: 32)
                Text(title)
                Spacer(minLength: 8)
                if language.resolved.preferenceKey == code {
                    Image(systemName: "checkmark")
                        .accessibilityHidden(true)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(language.resolved.preferenceKey == code ? .isSelected : [])
    }

    private var interslavicSection: some View {
        let selected = language.resolved.script
        return VStack(alignment: .leading, spacing: 0) {
            Button {
                // Restore the last script immediately, then reveal the three variants.
                language.selectInterslavicRestoringScript()
                withAnimation(.easeInOut(duration: 0.2)) {
                    scriptsVisible = true
                }
            } label: {
                HStack(spacing: 12) {
                    LanguageFlag(option: .interslavic(language.savedInterslavicScript), diameter: 32)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(LocalizedStringKey("language_name_interslavic"))
                        Text(scriptTitle(selected ?? language.savedInterslavicScript))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 8)
                    if selected != nil {
                        Image(systemName: "checkmark")
                            .accessibilityHidden(true)
                    }
                    Image(systemName: scriptsVisible ? "chevron.up" : "chevron.down")
                        .foregroundStyle(.secondary)
                        .accessibilityHidden(true)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(LocalizedStringKey("language_name_interslavic")))
            .accessibilityAddTraits(selected != nil ? .isSelected : [])

            if scriptsVisible {
                ForEach(InterslavicScript.allCases, id: \.storageKey) { script in
                    Button {
                        choose(script.storageKey)
                    } label: {
                        HStack {
                            Text("\(scriptTitle(script)) (\(scriptSample(script)))")
                            Spacer(minLength: 8)
                            if selected == script || (selected == nil && language.savedInterslavicScript == script) {
                                Image(systemName: "checkmark")
                                    .accessibilityHidden(true)
                            }
                        }
                        .padding(.leading, 44)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Text(scriptTitle(script)))
                    .accessibilityAddTraits(
                        (selected == script || (selected == nil && language.savedInterslavicScript == script))
                            ? .isSelected : []
                    )
                }
            }
        }
    }

    private func choose(_ key: String) {
        language.select(key)
        dismiss()
    }

    private func scriptTitle(_ script: InterslavicScript) -> String {
        switch script {
        case .latin: return LanguageState.shared.string("language_script_latin")
        case .cyrillic: return LanguageState.shared.string("language_script_cyrillic")
        case .glagolitic: return LanguageState.shared.string("language_script_glagolitic")
        }
    }

    private func scriptSample(_ script: InterslavicScript) -> String {
        switch script {
        case .latin: return "A B C"
        case .cyrillic: return "А Б В"
        case .glagolitic: return "Ⰰ Ⰱ Ⰲ"
        }
    }
}

enum LanguageName {
    static func endonym(for code: String) -> String {
        let locale = Locale(identifier: code)
        if code.contains("-"), let name = locale.localizedString(forIdentifier: code), !name.isEmpty {
            return name
        }
        let language = String(code.prefix(while: { $0 != "-" }))
        if let name = locale.localizedString(forLanguageCode: language), !name.isEmpty {
            return name.prefix(1).uppercased(with: locale) + name.dropFirst()
        }
        return code
    }
}

extension InterslavicScript: CaseIterable {
    static var allCases: [InterslavicScript] { [.latin, .cyrillic, .glagolitic] }
}
