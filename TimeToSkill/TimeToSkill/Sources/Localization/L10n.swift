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
