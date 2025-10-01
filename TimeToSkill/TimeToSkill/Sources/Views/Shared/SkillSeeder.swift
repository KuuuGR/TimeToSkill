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
        
        let lastVersion = UserDefaults.standard.integer(forKey: CatalogDefaults.lastSeededVersionKey)
        guard catalog.catalogVersion > lastVersion else {
            print("[Seeder] Catalog already seeded (version \(lastVersion))")
            return
        }
        
        upsert(catalog.items, in: context)
        UserDefaults.standard.set(catalog.catalogVersion, forKey: CatalogDefaults.lastSeededVersionKey)
        print("[Seeder] Seeded catalog version \(catalog.catalogVersion) with \(catalog.items.count) items")
    }
    
    private static func upsert(_ items: [SeedSkill], in context: ModelContext) {
        var updated = 0
        var inserted = 0
        for item in items {
            if let existing = fetchByCatalogID(item.id, in: context) {
                updateCatalogFields(existing, with: item)
                updated += 1
                continue
            }
            if let legacy = fetchByExactTitle(item.title, in: context) {
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
