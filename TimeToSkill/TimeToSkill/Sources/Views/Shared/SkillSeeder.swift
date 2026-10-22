import Foundation
import SwiftData

struct SeedSkill: Decodable, Equatable {
    let id: String
    let title: String
    let description: String
    let imageName: String
    let category: String
    let difficulty: Int
    let oneStarDescription: String
    let twoStarDescription: String
    let threeStarDescription: String

    init(
        id: String,
        title: String,
        description: String,
        imageName: String,
        category: String,
        difficulty: Int,
        oneStarDescription: String = "",
        twoStarDescription: String = "",
        threeStarDescription: String = ""
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.imageName = imageName
        self.category = category
        self.difficulty = difficulty
        self.oneStarDescription = oneStarDescription
        self.twoStarDescription = twoStarDescription
        self.threeStarDescription = threeStarDescription
    }

    private enum CodingKeys: String, CodingKey {
        case id, title, description, imageName, category, difficulty
        case oneStarDescription, twoStarDescription, threeStarDescription
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            id: try container.decode(String.self, forKey: .id),
            title: try container.decode(String.self, forKey: .title),
            description: try container.decode(String.self, forKey: .description),
            imageName: try container.decode(String.self, forKey: .imageName),
            category: try container.decode(String.self, forKey: .category),
            difficulty: try container.decode(Int.self, forKey: .difficulty),
            oneStarDescription: try container.decodeIfPresent(String.self, forKey: .oneStarDescription) ?? "",
            twoStarDescription: try container.decodeIfPresent(String.self, forKey: .twoStarDescription) ?? "",
            threeStarDescription: try container.decodeIfPresent(String.self, forKey: .threeStarDescription) ?? ""
        )
    }
}

struct SkillCatalog: Decodable {
    let catalogVersion: Int
    let items: [SeedSkill]
}

enum CatalogDefaults {
    static let lastSeededVersionKey = "ExemplarySkills_LastSeededVersion"
}

enum SkillSeeder {
    /// Shipped `ExemplarySkills_<code>.json` suffixes (non-English). Keep in sync with Resources.
    static let shippedOverlayCodes: Set<String> = [
        "ar", "ca", "cs", "da", "de", "el", "eo", "es", "es-419", "fi", "fr", "fr-CA",
        "he", "hi", "hr", "hu", "id", "isv", "it", "ja", "ko", "ms", "nb", "nl", "pl",
        "pt-BR", "pt-PT", "ro", "ru", "sk", "sv", "th", "tr", "uk", "vi", "zh-Hans", "zh-Hant"
    ]

    /// Catalog overlays follow the device language preference list, not the
    /// in-app UI language. Changing Options → language must not rewrite skill
    /// titles or descriptions.
    ///
    /// Resolution order: exact regional/script form → language head → family default.
    /// English (`en` / `en-*`) always uses the base catalog (returns nil).
    static func catalogOverlayCode(for deviceLanguageCode: String) -> String? {
        let trimmed = deviceLanguageCode.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmed.isEmpty else { return nil }
        let head = trimmed.split(separator: "-", maxSplits: 1, omittingEmptySubsequences: true)
            .first
            .map(String.init) ?? trimmed
        if head == "en" { return nil }

        var candidates: [String] = []
        if trimmed.hasPrefix("zh-hans") || trimmed == "zh-cn" {
            candidates.append("zh-Hans")
        } else if trimmed.hasPrefix("zh-hant") || trimmed == "zh-tw" || trimmed == "zh-hk" {
            candidates.append("zh-Hant")
        } else if trimmed == "pt-br" || trimmed.hasPrefix("pt-br") {
            candidates.append("pt-BR")
        } else if trimmed == "pt-pt" || trimmed.hasPrefix("pt-pt") {
            candidates.append("pt-PT")
        } else if trimmed == "es-419" || trimmed.hasPrefix("es-419") {
            candidates.append("es-419")
        } else if trimmed == "fr-ca" || trimmed.hasPrefix("fr-ca") {
            candidates.append("fr-CA")
        } else if head == "isv" {
            candidates.append("isv")
        } else if shippedOverlayCodes.contains(trimmed) {
            candidates.append(trimmed)
        }

        candidates.append(head)
        // Bare language tags that only exist as regional overlays.
        if head == "pt" {
            candidates.append(contentsOf: ["pt-BR", "pt-PT"])
        } else if head == "zh" {
            candidates.append(contentsOf: ["zh-Hans", "zh-Hant"])
        }

        var seen = Set<String>()
        for code in candidates where seen.insert(code).inserted {
            if shippedOverlayCodes.contains(code) { return code }
        }
        return nil
    }

    /// Loads the full base catalog, then overlays a localized file by id.
    /// A translation file does not replace the catalog, so untranslated rows stay.
    static func seedIfNeeded(context: ModelContext) {
        guard let base = loadCatalog(named: "ExemplarySkills") else {
            print("[Seeder] ExemplarySkills.json not found or unreadable")
            return
        }
        let device = Locale.preferredLanguages.first ?? "en"
        let langPrefix = catalogOverlayCode(for: device)
        let localized = langPrefix.flatMap { loadCatalog(named: "ExemplarySkills_\($0)") }
        let items = mergedItems(base: base.items, localized: localized?.items)
        reconcile(items, in: context)
        let stored = UserDefaults.standard.integer(forKey: CatalogDefaults.lastSeededVersionKey)
        if base.catalogVersion > stored {
            UserDefaults.standard.set(base.catalogVersion, forKey: CatalogDefaults.lastSeededVersionKey)
        }
        print("[Seeder] Reconciled catalog version \(base.catalogVersion) with \(items.count) items (device=\(device), overlay=\(langPrefix ?? "en-base"))")
    }

    static func loadCatalog(named name: String, bundle: Bundle = .main) -> SkillCatalog? {
        guard let url = bundle.url(forResource: name, withExtension: "json"),
              let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(SkillCatalog.self, from: data)
    }

    /// Localized rows replace the visible text of matching ids, including a
    /// non-empty level criterion. An empty translation keeps the base text.
    /// Rows that exist only in the translation file are appended.
    static func mergedItems(base: [SeedSkill], localized: [SeedSkill]?) -> [SeedSkill] {
        guard let localized, !localized.isEmpty else { return base }
        let translations = Dictionary(localized.map { ($0.id, $0) }, uniquingKeysWith: { current, _ in current })
        let baseIDs = Set(base.map(\.id))
        let overlaid = base.map { item -> SeedSkill in
            guard let translation = translations[item.id] else { return item }
            return SeedSkill(
                id: item.id,
                title: translation.title,
                description: translation.description,
                imageName: item.imageName,
                category: translation.category,
                difficulty: item.difficulty,
                oneStarDescription: translation.oneStarDescription.isEmpty ? item.oneStarDescription : translation.oneStarDescription,
                twoStarDescription: translation.twoStarDescription.isEmpty ? item.twoStarDescription : translation.twoStarDescription,
                threeStarDescription: translation.threeStarDescription.isEmpty ? item.threeStarDescription : translation.threeStarDescription
            )
        }
        return overlaid + localized.filter { !baseIDs.contains($0.id) }
    }

    /// Inserts catalog rows that are missing and refreshes catalog text.
    /// Obtained state, ratings, favorites, dates, hours, and user-created skills stay as they are.
    /// Rows the file no longer contains are left in place.
    static func reconcile(_ items: [SeedSkill], in context: ModelContext) {
        let existing = (try? context.fetch(FetchDescriptor<ExemplarySkill>())) ?? []
        var byID: [String: ExemplarySkill] = [:]
        var legacyByTitle: [String: ExemplarySkill] = [:]
        for skill in existing {
            if let catalogID = skill.catalogID {
                byID[catalogID] = skill
            } else if !skill.isUserCreated {
                legacyByTitle[skill.title] = skill
            }
        }

        var updated = 0
        var inserted = 0
        for item in items {
            if let match = byID[item.id] {
                if match.isUserCreated { continue }
                updateCatalogFields(match, with: item)
                updated += 1
                continue
            }
            if let legacy = legacyByTitle[item.title] {
                legacy.catalogID = item.id
                updateCatalogFields(legacy, with: item)
                byID[item.id] = legacy
                legacyByTitle[item.title] = nil
                updated += 1
                continue
            }
            let new = ExemplarySkill(
                catalogID: item.id,
                title: item.title,
                skillDescription: item.description,
                imageName: item.imageName,
                category: item.category,
                difficultyLevel: item.difficulty,
                oneStarDescription: item.oneStarDescription,
                twoStarDescription: item.twoStarDescription,
                threeStarDescription: item.threeStarDescription
            )
            context.insert(new)
            byID[item.id] = new
            inserted += 1
        }
        try? context.save()
        print("[Seeder] Upsert complete. Inserted: \(inserted), Updated: \(updated)")
    }

    private static func updateCatalogFields(_ skill: ExemplarySkill, with item: SeedSkill) {
        skill.title = item.title
        skill.skillDescription = item.description
        skill.imageName = item.imageName
        skill.category = item.category
        skill.difficultyLevel = item.difficulty
        if !item.oneStarDescription.isEmpty { skill.oneStarDescription = item.oneStarDescription }
        if !item.twoStarDescription.isEmpty { skill.twoStarDescription = item.twoStarDescription }
        if !item.threeStarDescription.isEmpty { skill.threeStarDescription = item.threeStarDescription }
    }
}

/// Debug-only sample data for a visual check of the glass bar and the crystal.
/// Runs only when the process was launched with `-T4SPreviewProgress`.
enum PreviewProgressSeeder {
    static func apply(context: ModelContext) {
        #if DEBUG
        guard ProcessInfo.processInfo.arguments.contains("-T4SPreviewProgress") else { return }
        let tracked: [(String, Double)] = [
            ("Szklany pasek szmaragdowy", 12.5),
            ("Szklany pasek szafirowy", 50)
        ]
        let existing = (try? context.fetch(FetchDescriptor<Skill>())) ?? []
        for (name, hours) in tracked {
            if let found = existing.first(where: { $0.name == name }) {
                if found.hours < hours {
                    found.hours = hours
                }
            } else {
                context.insert(Skill(name: name, hours: hours))
            }
        }
        let catalog = (try? context.fetch(FetchDescriptor<ExemplarySkill>())) ?? []
        let sample = catalog.first { $0.title == "Brzuszki – kamień milowy" } ?? catalog.first
        if let sample, !sample.isObtained {
            sample.isObtained = true
            sample.userRating = 2
            sample.obtainedAt = Date(timeIntervalSince1970: 1_700_000_000)
            sample.isFavorite = true
        }
        try? context.save()
        #endif
    }
}
