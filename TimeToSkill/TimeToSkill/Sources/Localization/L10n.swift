//
//  L10n.swift
//  TimeToSkill
//
//  Single presentation entry for UI strings. Always goes through
//  LanguageState (Interslavic Latinica → Cyrilica / Glagolica) so views that
//  cannot rely on LocalizedStringKey alone still match the active alphabet.
//

import Foundation
import SwiftUI

enum L10n {
    static func string(_ key: String, table: String = "Localizable") -> String {
        LanguageState.shared.string(key, table: table)
    }

    static func format(_ key: String, table: String = "Localizable", _ arguments: CVarArg...) -> String {
        let template = string(key, table: table)
        return String(format: template, locale: Locale(identifier: LanguageState.shared.bundleCode()), arguments: arguments)
    }

    /// Locale for dates / numbers — always the `.lproj` code (`isv`), never `isv-Cyrl`.
    static var locale: Locale {
        Locale(identifier: LanguageState.shared.bundleCode())
    }

    static func text(_ key: String, table: String = "Localizable") -> Text {
        Text(verbatim: string(key, table: table))
    }

    /// Applies the active Interslavic script to free-form text (dates, etc.).
    static func present(_ text: String) -> String {
        guard LanguageState.shared.bundleCode() == "isv",
              let script = LanguageState.shared.script(),
              script != .latin
        else { return text }
        if InterslavicTransliterator.appearsConverted(to: script, text: text) {
            return text
        }
        return InterslavicTransliterator.convert(text, to: script)
    }

    /// Month + year for calendars. Interslavic has no CLDR data, so month
    /// names come from Localizable keys (then script conversion).
    static func monthYear(_ date: Date, calendar: Calendar = .current) -> String {
        if LanguageState.shared.bundleCode() == "isv" {
            let month = calendar.component(.month, from: date)
            let year = calendar.component(.year, from: date)
            return "\(string("calendar_month_\(month)")) \(year)"
        }
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.setLocalizedDateFormatFromTemplate("MMMM yyyy")
        return formatter.string(from: date)
    }

    static func monthAbbreviation(_ date: Date, calendar: Calendar = .current) -> String {
        if LanguageState.shared.bundleCode() == "isv" {
            let month = calendar.component(.month, from: date)
            return string("calendar_month_short_\(month)")
        }
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.setLocalizedDateFormatFromTemplate("MMM")
        return formatter.string(from: date)
    }

    static func mediumDate(_ date: Date) -> String {
        if LanguageState.shared.bundleCode() == "isv" {
            let calendar = Calendar.current
            let day = calendar.component(.day, from: date)
            let month = calendar.component(.month, from: date)
            let year = calendar.component(.year, from: date)
            return "\(day) \(string("calendar_month_short_\(month)")) \(year)"
        }
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    /// Very short weekday symbols, Monday-first order matching `firstWeekday`.
    static func veryShortWeekdays(calendar: Calendar = .current) -> [String] {
        if LanguageState.shared.bundleCode() == "isv" {
            // Keys are Sunday=1 … Saturday=7 (Calendar weekday numbering).
            let symbols = (1...7).map { string("calendar_weekday_short_\($0)") }
            var cal = calendar
            cal.locale = locale
            return (0..<7).map { symbols[($0 + cal.firstWeekday - 1) % 7] }
        }
        var cal = calendar
        cal.locale = locale
        let symbols = cal.veryShortWeekdaySymbols
        return (0..<7).map { symbols[($0 + cal.firstWeekday - 1) % 7] }
    }
}

/// Observes `AppLanguage` and renders a Localizable key as verbatim text after
/// script conversion — avoids a second Bundle lookup that could skip Glagolica.
struct LText: View {
    let key: String
    var table: String = "Localizable"

    @ObservedObject private var language = AppLanguage.shared

    var body: some View {
        let _ = language.resolved.presentationIdentity
        Text(verbatim: L10n.string(key, table: table))
    }
}

/// Re-evaluates LocalizedStringKey / Bundle-swizzled lookups when the
/// Interslavic alphabet changes without destroying navigation selection.
struct InterslavicPresentationRefresh: ViewModifier {
    @ObservedObject private var language = AppLanguage.shared

    func body(content: Content) -> some View {
        content
            // Touching presentationIdentity invalidates this modifier's body so
            // child Text(LocalizedStringKey) rows resolve again through LanguageBundle.
            .environment(\.locale, Locale(identifier: language.resolved.localeIdentifier))
            .id(language.resolved.presentationIdentity)
    }
}

extension View {
    /// Forces UI strings to refresh after Latinica ↔ Cyrilica ↔ Glagolica.
    func interslavicPresentationRefresh() -> some View {
        modifier(InterslavicPresentationRefresh())
    }
}
