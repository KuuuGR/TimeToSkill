//
//  AppLanguage.swift
//  TimeToSkill
//
//  In-app language preference, separate from the language actually shown.
//  "system" stays stored as the phone-language choice. Interslavic Cyrillic
//  and Glagolitic are produced from the Latin strings with the same letter
//  map MedBioPhys uses. There is no separate font file in that app.
//

import Foundation
import CoreText
import SwiftUI
#if canImport(ObjectiveC)
import ObjectiveC
#endif

enum InterslavicScript: String, Equatable {
    case latin
    case cyrillic
    case glagolitic

    var storageKey: String {
        switch self {
        case .latin: return "isv-Latn"
        case .cyrillic: return "isv-Cyrl"
        case .glagolitic: return "isv-Glag"
        }
    }

    static func from(storageKey: String) -> InterslavicScript? {
        switch storageKey {
        case "isv-Latn": return .latin
        case "isv-Cyrl": return .cyrillic
        case "isv-Glag": return .glagolitic
        default: return nil
        }
    }
}

struct ResolvedLanguage: Equatable {
    /// What the user chose. `system` is the phone-language option.
    var preferenceKey: String
    /// `.lproj` folder used for interface strings.
    var bundleCode: String
    var script: InterslavicScript?

    /// Foundation / SwiftUI locale. Always the `.lproj` code (e.g. `isv`), never
    /// `isv-Glag` / `isv-Cyrl` — those folders do not exist, and using them made
    /// the system skip Interslavic strings so the UI stayed in Latinica.
    var localeIdentifier: String { bundleCode }

    /// View-identity token that changes when the alphabet changes.
    var presentationIdentity: String {
        "\(bundleCode)|\(script?.rawValue ?? "-")|\(preferenceKey)"
    }

    var followsDevice: Bool { preferenceKey == LanguageCatalog.systemKey }
}

enum LanguageCatalog {
    static let systemKey = "system"
    static let preferenceDefaultsKey = "AppLanguagePreference"
    /// Last Interslavic script choice. Kept even while another UI language is active.
    static let interslavicScriptDefaultsKey = "AppInterslavicScriptPreference"
    static let featured = ["pl", "en", "es", "eo"]

    static func resolve(
        preferenceKey: String?,
        deviceLanguages: [String],
        available: Set<String>
    ) -> ResolvedLanguage {
        let available = available.isEmpty ? ["en"] : available
        let stored = preferenceKey?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if stored.isEmpty || stored == systemKey {
            let code = deviceBundleCode(deviceLanguages: deviceLanguages, available: available)
            return ResolvedLanguage(preferenceKey: systemKey, bundleCode: code, script: nil)
        }
        if let script = InterslavicScript.from(storageKey: stored) {
            let code = available.contains("isv") ? "isv" : "en"
            return ResolvedLanguage(
                preferenceKey: stored,
                bundleCode: code,
                script: code == "isv" ? script : nil
            )
        }
        if available.contains(stored) {
            return ResolvedLanguage(preferenceKey: stored, bundleCode: stored, script: nil)
        }
        return ResolvedLanguage(preferenceKey: stored, bundleCode: "en", script: nil)
    }

    static func deviceBundleCode(deviceLanguages: [String], available: Set<String>) -> String {
        let choices = Array(available)
        let matched = Bundle.preferredLocalizations(from: choices, forPreferences: deviceLanguages)
        if let code = matched.first, available.contains(code) {
            return code
        }
        return available.contains("en") ? "en" : (choices.sorted().first ?? "en")
    }

    static func loadTable(_ code: String, bundle: Bundle = .main) -> [String: String] {
        loadStringsTable(named: "Localizable", locale: code, bundle: bundle)
    }

    /// Loads a compiled `.strings` table for one localization (e.g. `Localizable`, `TimePerspective`).
    /// Xcode compiles `.xcstrings` catalogs into per-locale `.strings` files at build time.
    static func loadStringsTable(
        named name: String,
        locale: String,
        bundle: Bundle = .main
    ) -> [String: String] {
        guard let path = bundle.path(
            forResource: name,
            ofType: "strings",
            inDirectory: nil,
            forLocalization: locale
        ), let dictionary = NSDictionary(contentsOfFile: path) as? [String: String] else {
            return [:]
        }
        return dictionary
    }

    /// Loads one locale column from a String Catalog (`.xcstrings`) on disk.
    /// Used by unit tests that read the source catalog; the app bundle uses compiled `.strings`.
    static func loadXCStringsTable(
        named name: String,
        locale: String,
        from url: URL
    ) -> [String: String] {
        guard let data = try? Data(contentsOf: url),
              let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let strings = root["strings"] as? [String: Any] else {
            return [:]
        }
        let candidates = localeColumnCandidates(locale)
        var result: [String: String] = [:]
        for (key, raw) in strings {
            guard let entry = raw as? [String: Any],
                  let localizations = entry["localizations"] as? [String: Any] else { continue }
            for candidate in candidates {
                guard let loc = localizations[candidate] as? [String: Any],
                      let unit = loc["stringUnit"] as? [String: Any],
                      let value = unit["value"] as? String,
                      !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                    continue
                }
                result[key] = value
                break
            }
        }
        return result
    }

    private static func localeColumnCandidates(_ locale: String) -> [String] {
        var list = [locale]
        if let dash = locale.firstIndex(of: "-") {
            let base = String(locale[..<dash])
            if !list.contains(base) { list.append(base) }
        }
        return list
    }

    /// Looks up one interface string. A missing translation uses English.
    /// English stand-ins are not run through the Interslavic letter map.
    static func lookup(
        key: String,
        bundleCode: String,
        script: InterslavicScript?,
        tables: [String: [String: String]]
    ) -> String {
        if let value = nonEmpty(tables[bundleCode]?[key]) {
            return apply(script, to: value, sourceIsInterslavic: bundleCode == "isv")
        }
        if bundleCode != "en", let english = nonEmpty(tables["en"]?[key]) {
            return english
        }
        return key
    }

    private static func nonEmpty(_ value: String?) -> String? {
        guard let value, !value.isEmpty else { return nil }
        return value
    }

    private static func apply(_ script: InterslavicScript?, to text: String, sourceIsInterslavic: Bool) -> String {
        guard sourceIsInterslavic, let script, script != .latin else { return text }
        if InterslavicTransliterator.appearsConverted(to: script, text: text) {
            return text
        }
        switch script {
        case .latin: return text
        case .cyrillic: return InterslavicTransliterator.latinToCyrillic(text)
        case .glagolitic: return InterslavicTransliterator.latinToGlagolitic(text)
        }
    }
}

enum InterslavicTransliterator {
    /// Printf / String Catalog placeholders that must survive script conversion.
    private static let formatToken = try! NSRegularExpression(
        pattern: #"%(?:\d+\$)?[@dDuUxXoOfeEgGcCsSpaAF%]"#
    )

    static func latinToCyrillic(_ text: String) -> String {
        convert(text, multi: cyrillicDigraphs, single: cyrillicLetters)
    }

    static func latinToGlagolitic(_ text: String) -> String {
        convert(text, multi: glagoliticDigraphs, single: glagoliticLetters)
    }

    /// Applies the active Interslavic script map (no-op for Latinica).
    static func convert(_ text: String, to script: InterslavicScript) -> String {
        switch script {
        case .latin: return text
        case .cyrillic: return latinToCyrillic(text)
        case .glagolitic: return latinToGlagolitic(text)
        }
    }

    /// True when the string already looks converted — avoids a second pass.
    static func appearsConverted(to script: InterslavicScript, text: String) -> Bool {
        switch script {
        case .latin:
            return false
        case .cyrillic:
            return text.unicodeScalars.contains { (0x0400...0x04FF).contains($0.value) }
        case .glagolitic:
            return text.unicodeScalars.contains { (0x2C00...0x2C5F).contains($0.value) }
        }
    }

    private static func convert(
        _ text: String,
        multi: [(String, String)],
        single: [Character: String]
    ) -> String {
        guard !text.isEmpty else { return text }
        let (masked, tokens) = maskFormats(text)
        var converted = masked
        for pair in multi {
            converted = converted.replacingOccurrences(of: pair.0, with: pair.1)
        }
        var output = ""
        output.reserveCapacity(converted.count)
        for character in converted {
            output.append(single[character] ?? String(character))
        }
        return unmask(output, tokens: tokens)
    }

    private static func maskFormats(_ text: String) -> (String, [String]) {
        let ns = text as NSString
        let matches = formatToken.matches(in: text, range: NSRange(location: 0, length: ns.length))
        guard !matches.isEmpty else { return (text, []) }
        var tokens: [String] = []
        var masked = ""
        var cursor = text.startIndex
        for match in matches {
            guard let range = Range(match.range, in: text) else { continue }
            masked.append(contentsOf: text[cursor..<range.lowerBound])
            masked.append("\u{E000}\(tokens.count)\u{E001}")
            tokens.append(String(text[range]))
            cursor = range.upperBound
        }
        masked.append(contentsOf: text[cursor...])
        return (masked, tokens)
    }

    private static func unmask(_ text: String, tokens: [String]) -> String {
        var result = text
        for (index, token) in tokens.enumerated() {
            result = result.replacingOccurrences(of: "\u{E000}\(index)\u{E001}", with: token)
        }
        return result
    }

    // Digraphs first. Orthography follows Medžuslovjansky Latinica from the corpus
    // and the Interslavic scientific Latin alphabet.
    private static let cyrillicDigraphs: [(String, String)] = [
        ("DŽ", "Џ"), ("Dž", "Џ"), ("dž", "џ"),
        ("NJ", "Њ"), ("Nj", "Њ"), ("nj", "њ"),
        ("LJ", "Љ"), ("Lj", "Љ"), ("lj", "љ"),
        // j + nasal e collapses to я (avoids the awkward "јя" sequence)
        ("JĘ", "Я"), ("Ję", "Я"), ("ję", "я"),
        // Foreign Latin leftovers that otherwise survive as Latin glyphs
        ("X", "КС"), ("x", "кс")
    ]

    private static let cyrillicLetters: [Character: String] = [
        "A": "А", "B": "Б", "C": "Ц", "Č": "Ч", "Ć": "Ћ", "D": "Д", "Đ": "Ђ",
        "E": "Е", "Ě": "Є", "Ę": "Я",
        "F": "Ф", "G": "Г", "H": "Х", "I": "И", "J": "Ј", "K": "К", "L": "Л",
        "M": "М", "N": "Н", "O": "О", "P": "П", "R": "Р", "S": "С", "Š": "Ш",
        "T": "Т", "U": "У", "V": "В", "W": "В", "Y": "Ы", "Z": "З", "Ž": "Ж",
        "Q": "К",
        "a": "а", "b": "б", "c": "ц", "č": "ч", "ć": "ћ", "d": "д", "đ": "ђ",
        "e": "е", "ě": "є", "ę": "я",
        "f": "ф", "g": "г", "h": "х", "i": "и", "j": "ј", "k": "к", "l": "л",
        "m": "м", "n": "н", "o": "о", "p": "п", "r": "р", "s": "с", "š": "ш",
        "t": "т", "u": "у", "v": "в", "w": "в", "y": "ы", "z": "з", "ž": "ж",
        "q": "к",
        // Latin diacritics that appear in names / non-ISV orthography
        "Á": "А", "À": "А", "Ä": "А", "Â": "А", "Ã": "А",
        "á": "а", "à": "а", "ä": "а", "â": "а", "ã": "а",
        "É": "Е", "È": "Е", "Ë": "Е", "Ê": "Е",
        "é": "е", "è": "е", "ë": "е", "ê": "е",
        "Í": "И", "Ì": "И", "Ï": "И", "Î": "И",
        "í": "и", "ì": "и", "ï": "и", "î": "и",
        "Ó": "О", "Ò": "О", "Ö": "О", "Ô": "О", "Õ": "О",
        "ó": "о", "ò": "о", "ö": "о", "ô": "о", "õ": "о",
        "Ú": "У", "Ù": "У", "Ü": "У", "Û": "У",
        "ú": "у", "ù": "у", "ü": "у", "û": "у",
        "Ý": "Ы", "ý": "ы", "Ñ": "Н", "ñ": "н",
        "Ā": "А", "ā": "а", "Ē": "Е", "ē": "е", "Ī": "И", "ī": "и",
        "Ō": "О", "ō": "о", "Ū": "У", "ū": "у"
    ]

    private static let glagoliticDigraphs: [(String, String)] = [
        ("DŽ", "Ⱛ"), ("Dž", "Ⱛ"), ("dž", "ⱛ"),
        ("NJ", "Ⱘ"), ("Nj", "Ⱘ"), ("nj", "ⱘ"),
        ("LJ", "Ⱙ"), ("Lj", "Ⱙ"), ("lj", "ⱙ"),
        ("JĘ", "Ⱔ"), ("Ję", "Ⱔ"), ("ję", "ⱔ"),
        ("X", "ⰊⰑ"), ("x", "ⰺⱁ")
    ]

    /// Glagolitic map for Noto Sans Glagolitic (Unicode Glagolitic block).
    /// ě/y share yat; ę uses ens; ć follows č; đ follows dž.
    private static let glagoliticLetters: [Character: String] = [
        "A": "Ⰰ", "B": "Ⰱ", "V": "Ⰲ", "G": "Ⰳ", "D": "Ⰴ", "E": "Ⰵ", "Ž": "Ⰶ",
        "Z": "Ⰷ", "I": "Ⰸ", "J": "Ⰹ", "K": "Ⰺ", "L": "Ⰻ", "M": "Ⰼ", "N": "Ⰽ",
        "O": "Ⰾ", "P": "Ⰿ", "R": "Ⱀ", "S": "Ⱁ", "T": "Ⱂ", "U": "Ⱃ", "F": "Ⱄ",
        "H": "Ⱅ", "C": "Ⱆ", "Č": "Ⱇ", "Ć": "Ⱇ", "Š": "Ⱈ", "Ě": "Ⱑ", "Ę": "Ⱔ",
        "Y": "Ⱑ", "Đ": "Ⱛ", "W": "Ⰲ", "Q": "Ⰺ",
        "a": "ⰰ", "b": "ⰱ", "v": "ⰲ", "g": "ⰳ", "d": "ⰴ", "e": "ⰵ", "ž": "ⰶ",
        "z": "ⰷ", "i": "ⰸ", "j": "ⰹ", "k": "ⰺ", "l": "ⰻ", "m": "ⰼ", "n": "ⰽ",
        "o": "ⰾ", "p": "ⰿ", "r": "ⱀ", "s": "ⱁ", "t": "ⱂ", "u": "ⱃ", "f": "ⱄ",
        "h": "ⱅ", "c": "ⱆ", "č": "ⱇ", "ć": "ⱇ", "š": "ⱈ", "y": "ⱑ", "ě": "ⱑ",
        "ę": "ⱔ", "đ": "ⱛ", "w": "ⰲ", "q": "ⰺ",
        "Á": "Ⰰ", "á": "ⰰ", "Ö": "Ⰾ", "ö": "ⰾ", "Ó": "Ⰾ", "ó": "ⰾ"
    ]

}

/// Thread-safe copy used by `Bundle` while SwiftUI observes `AppLanguage`.
final class LanguageState: @unchecked Sendable {
    static let shared = LanguageState()
    private let lock = NSLock()
    private var resolved = ResolvedLanguage(preferenceKey: LanguageCatalog.systemKey, bundleCode: "en", script: nil)
    /// `[tableName: [localeCode: [key: value]]]`
    private var tables: [String: [String: [String: String]]] = [:]
    /// Presentation cache: `"table|key|bundle|script" → displayed string`.
    private var presentationCache: [String: String] = [:]

    func replace(_ resolved: ResolvedLanguage) {
        lock.lock()
        let scriptChanged = self.resolved.script != resolved.script
            || self.resolved.bundleCode != resolved.bundleCode
        self.resolved = resolved
        if scriptChanged {
            presentationCache.removeAll(keepingCapacity: true)
        }
        lock.unlock()
    }

    func bundleCode() -> String {
        lock.lock()
        defer { lock.unlock() }
        return resolved.bundleCode
    }

    func script() -> InterslavicScript? {
        lock.lock()
        defer { lock.unlock() }
        return resolved.script
    }

    func string(_ key: String, table: String = "Localizable") -> String {
        lock.lock()
        let resolved = self.resolved
        let cacheKey = "\(table)|\(key)|\(resolved.bundleCode)|\(resolved.script?.rawValue ?? "-")"
        if let cached = presentationCache[cacheKey] {
            lock.unlock()
            return cached
        }
        lock.unlock()

        let tables = tables(named: table, bundleCode: resolved.bundleCode)
        let value = LanguageCatalog.lookup(
            key: key,
            bundleCode: resolved.bundleCode,
            script: resolved.script,
            tables: tables
        )

        lock.lock()
        presentationCache[cacheKey] = value
        lock.unlock()
        return value
    }

    private func tables(named table: String, bundleCode: String) -> [String: [String: String]] {
        lock.lock()
        defer { lock.unlock() }
        var byLocale = tables[table] ?? [:]
        for code in [bundleCode, "en"] where byLocale[code] == nil {
            if table == "Localizable" || table == "TimePerspective" {
                byLocale[code] = LanguageCatalog.loadStringsTable(named: table, locale: code)
            } else {
                byLocale[code] = [:]
            }
        }
        tables[table] = byLocale
        return byLocale
    }
}

@MainActor
final class AppLanguage: ObservableObject {
    static let shared = AppLanguage()

    @Published private(set) var resolved: ResolvedLanguage
    /// Last Interslavic script, independent of the active UI language.
    @Published private(set) var savedInterslavicScript: InterslavicScript
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard, deviceLanguages: [String]? = nil) {
        self.defaults = defaults
        let available = Self.bundledCodes()
        let devices = deviceLanguages ?? Locale.preferredLanguages
        let stored = defaults.string(forKey: LanguageCatalog.preferenceDefaultsKey)
        let scriptKey = defaults.string(forKey: LanguageCatalog.interslavicScriptDefaultsKey)
        let savedScript = InterslavicScript.from(storageKey: scriptKey ?? "") ?? .latin
        self.savedInterslavicScript = savedScript
        let resolved = LanguageCatalog.resolve(
            preferenceKey: stored,
            deviceLanguages: devices,
            available: available
        )
        self.resolved = resolved
        LanguageState.shared.replace(resolved)
    }

    func select(_ preferenceKey: String) {
        if let script = InterslavicScript.from(storageKey: preferenceKey) {
            defaults.set(script.storageKey, forKey: LanguageCatalog.interslavicScriptDefaultsKey)
            savedInterslavicScript = script
        }
        defaults.set(preferenceKey, forKey: LanguageCatalog.preferenceDefaultsKey)
        let resolved = LanguageCatalog.resolve(
            preferenceKey: preferenceKey,
            deviceLanguages: Locale.preferredLanguages,
            available: Self.bundledCodes()
        )
        self.resolved = resolved
        LanguageState.shared.replace(resolved)
    }

    /// Activates Interslavic using the last saved script (Latin by default).
    func selectInterslavicRestoringScript() {
        select(savedInterslavicScript.storageKey)
    }

    /// Re-reads the device language when the preference is still “device language”.
    func refreshIfFollowingDevice() {
        guard resolved.followsDevice else { return }
        select(LanguageCatalog.systemKey)
    }

    static func bundledCodes() -> Set<String> {
        var codes = Set(Bundle.main.localizations.map { $0 == "Base" ? "en" : $0 })
        if let resource = Bundle.main.resourceURL,
           let folders = try? FileManager.default.contentsOfDirectory(
            at: resource,
            includingPropertiesForKeys: nil
           ) {
            for url in folders where url.pathExtension == "lproj" {
                codes.insert(url.deletingPathExtension().lastPathComponent)
            }
        }
        codes.insert("en")
        return codes
    }

}

enum AppFontRegistry {
    static let glagoliticFamily = "NotoSansGlagolitic-Regular"
    private static var didRegister = false

    static func registerIfNeeded() {
        guard !didRegister else { return }
        didRegister = true
        guard let url = Bundle.main.url(
            forResource: "NotoSansGlagolitic-Regular",
            withExtension: "ttf",
            subdirectory: "Fonts"
        ) ?? Bundle.main.url(forResource: "NotoSansGlagolitic-Regular", withExtension: "ttf") else {
            return
        }
        CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
    }

    static func uiFont(for script: InterslavicScript?, textStyle: Font.TextStyle = .body) -> Font? {
        guard script == .glagolitic else { return nil }
        return Font.custom(glagoliticFamily, size: 17, relativeTo: textStyle)
    }
}

/// Routes interface strings through the selected language without a second catalog.
private final class LanguageBundle: Bundle, @unchecked Sendable {
    override func localizedString(forKey key: String, value: String?, table tableName: String?) -> String {
        let table = tableName ?? "Localizable"
        if table == "Localizable" || table == "TimePerspective" {
            return LanguageState.shared.string(key, table: table)
        }
        return super.localizedString(forKey: key, value: value, table: tableName)
    }
}

enum LanguageBundleInstall {
    private static var didInstall = false

    static func installIfNeeded() {
        guard !didInstall else { return }
        didInstall = true
        object_setClass(Bundle.main, LanguageBundle.self)
    }
}
