import Foundation

/// A single real-world duration comparison from the Time Perspective library.
///
/// Localized `title` and `description` are resolved at read time from the String Catalog
/// using keys `perspective.{id}.title` and `perspective.{id}.description`.
struct TimePerspective: Identifiable, Codable {
    let id: String
    let thresholdMinutes: Int
    let icon: String
    let category: PerspectiveCategory

    var title: String {
        localizedString(key: "perspective.\(id).title")
    }

    var description: String {
        localizedString(key: "perspective.\(id).description")
    }

    /// Looks up a fully formed catalog key in the `TimePerspective` strings table.
    ///
    /// Dynamic keys must use `Bundle.localizedString(forKey:value:table:)`.
    /// `String.LocalizationValue("…\(id)…")` interpolates to format key
    /// `perspective.%@.title` and returns the raw key when lookup fails.
    private func localizedString(key: String) -> String {
        Bundle.main.localizedString(
            forKey: key,
            value: nil,
            table: "TimePerspective"
        )
    }
}
