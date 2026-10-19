//
//  CatalogQuery.swift
//  TimeToSkill
//
//  Local filtering and search for the exemplary-skill catalog.
//  Dates here are the user's completion dates, not catalog creation dates.
//

import Foundation

struct CatalogEntry: Equatable, Identifiable {
    var id: String
    var title: String
    var description: String
    var category: String
    var levelTexts: [String]
    var isObtained: Bool
    var obtainedAt: Date?
    var isFavorite: Bool
    var rating: Int
    var difficulty: Int
}

enum CompletionFilter: String, CaseIterable {
    case all
    case done
    case notDone
}

enum FavoriteFilter: String, CaseIterable {
    case all
    case favorites
}

enum CatalogSort: String, CaseIterable {
    case name = "sort_name"
    case category = "sort_category"
    case starsAsc = "sort_stars_asc"
    case starsDesc = "sort_stars_desc"
    case difficultyAsc = "sort_difficulty_asc"
    case difficultyDesc = "sort_difficulty_desc"
    case obtainedOldest = "sort_completed_asc"
    case obtainedNewest = "sort_completed_desc"

    var localizedTitle: String {
        NSLocalizedString(rawValue, comment: "")
    }
}

struct CatalogQuery: Equatable {
    var text: String = ""
    var completion: CompletionFilter = .all
    var favorites: FavoriteFilter = .all
    var sort: CatalogSort = .name

    var isDefault: Bool {
        text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && completion == .all
            && favorites == .all
            && sort == .name
    }

    func apply(_ entries: [CatalogEntry], locale: Locale = .current) -> [CatalogEntry] {
        let matched = entries.filter { matches($0) }
        return matched.sorted { ordered($0, before: $1, locale: locale) }
    }

    func matches(_ entry: CatalogEntry) -> Bool {
        switch completion {
        case .all:
            break
        case .done:
            if !entry.isObtained { return false }
        case .notDone:
            if entry.isObtained { return false }
        }
        if favorites == .favorites && !entry.isFavorite {
            return false
        }
        let needle = Self.searchKey(text.trimmingCharacters(in: .whitespacesAndNewlines))
        if needle.isEmpty { return true }
        let haystack = ([entry.title, entry.description, entry.category] + entry.levelTexts)
            .map(Self.searchKey)
            .joined(separator: "\n")
        return haystack.contains(needle)
    }

    /// Case- and diacritic-insensitive key. `ł` is folded to `l` because
    /// Foundation does not treat it as a combining mark.
    static func searchKey(_ value: String) -> String {
        let folded = value.folding(
            options: [.caseInsensitive, .diacriticInsensitive],
            locale: Locale(identifier: "pl")
        )
        return folded
            .replacingOccurrences(of: "ł", with: "l")
            .replacingOccurrences(of: "Ł", with: "L")
    }

    private func ordered(_ lhs: CatalogEntry, before rhs: CatalogEntry, locale: Locale) -> Bool {
        switch sort {
        case .name:
            return Self.nameAscending(lhs, rhs, locale: locale)
        case .category:
            let category = lhs.category.compare(rhs.category, options: [.caseInsensitive], locale: locale)
            if category == .orderedSame { return Self.nameAscending(lhs, rhs, locale: locale) }
            return category == .orderedAscending
        case .starsAsc:
            if lhs.rating == rhs.rating { return Self.nameAscending(lhs, rhs, locale: locale) }
            return lhs.rating < rhs.rating
        case .starsDesc:
            if lhs.rating == rhs.rating { return Self.nameAscending(lhs, rhs, locale: locale) }
            return lhs.rating > rhs.rating
        case .difficultyAsc:
            if lhs.difficulty == rhs.difficulty { return Self.nameAscending(lhs, rhs, locale: locale) }
            return lhs.difficulty < rhs.difficulty
        case .difficultyDesc:
            if lhs.difficulty == rhs.difficulty { return Self.nameAscending(lhs, rhs, locale: locale) }
            return lhs.difficulty > rhs.difficulty
        case .obtainedOldest:
            return Self.dateOrder(lhs, rhs, newestFirst: false, locale: locale)
        case .obtainedNewest:
            return Self.dateOrder(lhs, rhs, newestFirst: true, locale: locale)
        }
    }

    private static func nameAscending(_ lhs: CatalogEntry, _ rhs: CatalogEntry, locale: Locale) -> Bool {
        lhs.title.compare(rhs.title, options: [.caseInsensitive], locale: locale) == .orderedAscending
    }

    /// Records with no completion date stay at the end in both directions.
    private static func dateOrder(_ lhs: CatalogEntry, _ rhs: CatalogEntry, newestFirst: Bool, locale: Locale) -> Bool {
        switch (lhs.obtainedAt, rhs.obtainedAt) {
        case (nil, nil):
            return nameAscending(lhs, rhs, locale: locale)
        case (nil, _?):
            return false
        case (_?, nil):
            return true
        case let (left?, right?):
            if left == right { return nameAscending(lhs, rhs, locale: locale) }
            return newestFirst ? left > right : left < right
        }
    }
}
