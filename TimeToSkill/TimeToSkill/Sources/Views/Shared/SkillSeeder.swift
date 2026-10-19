import Foundation
import SwiftData

struct SeedSkill: Decodable {
    let id: String
    let title: String
    let description: String
    let imageName: String
    let category: String
    let difficulty: Int
}

struct SkillCatalog: Decodable {
    let catalogVersion: Int
    let items: [SeedSkill]
}

enum CatalogDefaults {
    static let lastSeededVersionKey = "ExemplarySkills_LastSeededVersion"
}

enum SkillSeeder {
    /// Attempts to load a localized skills catalog first (e.g., `ExemplarySkills_pl.json` for Polish),
    /// then falls back to the base `ExemplarySkills.json`.
    static func seedIfNeeded(context: ModelContext) {
        let preferredLang = Locale.preferredLanguages.first ?? "en"
        let langPrefix = String(preferredLang.prefix(2)).lowercased()
        let localizedName = "ExemplarySkills_\(langPrefix)"

        let bundle = Bundle.main
        let url = bundle.url(forResource: localizedName, withExtension: "json")
            ?? bundle.url(forResource: "ExemplarySkills", withExtension: "json")
        guard let url else {
            print("[Seeder] ExemplarySkills(.json) not found in bundle")
            return
        }
        guard let data = try? Data(contentsOf: url) else {
            print("[Seeder] Failed to read ExemplarySkills.json")
            return
        }
        guard let catalog = try? JSONDecoder().decode(SkillCatalog.self, from: data) else {
            print("[Seeder] Failed to decode ExemplarySkills.json")
            return
        }
        
        reconcile(catalog.items, in: context)
        let stored = UserDefaults.standard.integer(forKey: CatalogDefaults.lastSeededVersionKey)
        if catalog.catalogVersion > stored {
            UserDefaults.standard.set(catalog.catalogVersion, forKey: CatalogDefaults.lastSeededVersionKey)
        }
        print("[Seeder] Reconciled catalog version \(catalog.catalogVersion) with \(catalog.items.count) items")
    }

    /// Inserts catalog rows that are missing and refreshes catalog text.
    /// Obtained state, ratings, favorites, dates, and user-created skills stay as they are.
    static func reconcile(_ items: [SeedSkill], in context: ModelContext) {
        var updated = 0
        var inserted = 0
        for item in items {
            if let existing = fetchByCatalogID(item.id, in: context) {
                updateCatalogFields(existing, with: item)
                updated += 1
                continue
            }
            if let legacy = fetchByExactTitle(item.title, in: context), !legacy.isUserCreated {
                legacy.catalogID = item.id
                updateCatalogFields(legacy, with: item)
                updated += 1
                continue
            }
            let new = ExemplarySkill(
                catalogID: item.id,
                title: item.title,
                skillDescription: item.description,
                imageName: item.imageName,
                category: item.category,
                difficultyLevel: item.difficulty
            )
            context.insert(new)
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
    }
    
    private static func fetchByCatalogID(_ id: String, in context: ModelContext) -> ExemplarySkill? {
        let d = FetchDescriptor<ExemplarySkill>(predicate: #Predicate { $0.catalogID == id })
        return try? context.fetch(d).first
    }
    
    private static func fetchByExactTitle(_ title: String, in context: ModelContext) -> ExemplarySkill? {
        let d = FetchDescriptor<ExemplarySkill>(predicate: #Predicate { $0.catalogID == nil && $0.title == title })
        return try? context.fetch(d).first
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
