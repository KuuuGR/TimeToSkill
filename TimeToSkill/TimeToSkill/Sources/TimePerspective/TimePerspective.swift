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
        String(
            localized: String.LocalizationValue("perspective.\(id).title"),
            table: "TimePerspective"
        )
    }

    var description: String {
        String(
            localized: String.LocalizationValue("perspective.\(id).description"),
            table: "TimePerspective"
        )
    }
}
