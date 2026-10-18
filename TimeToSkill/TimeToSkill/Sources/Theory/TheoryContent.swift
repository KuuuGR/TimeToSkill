//
//  TheoryContent.swift
//  TimeToSkill
//
//  Bundled editorial topics for the theory screen (T4S-002).
//  Stable identifiers. No SwiftData model and no runtime download.
//  User-facing sentences live in Localizable.strings.

import Foundation

enum TheorySourceKind: String, Identifiable, Hashable {
    case framework
    case article
    case metaAnalysis

    var id: String { rawValue }

    var labelKey: String {
        switch self {
        case .framework: return "theory_type_framework"
        case .article: return "theory_type_article"
        case .metaAnalysis: return "theory_type_meta"
        }
    }
}

struct TheoryLink: Identifiable, Hashable {
    let id: String
    let labelKey: String
    let url: URL
}

struct TheoryFinding: Identifiable, Hashable {
    let id: String
    let labelKey: String
    let valueKey: String
}

struct TheoryTopic: Identifiable, Hashable {
    let id: String
    let titleKey: String
    let summaryKey: String
    let takeawayKey: String
    let sourceKind: TheorySourceKind
    let citationKey: String
    let contextKey: String
    let limitationKey: String
    let findingsIntroKey: String?
    let findings: [TheoryFinding]
    let links: [TheoryLink]
}

struct TheoryMilestone: Identifiable, Hashable {
    let id: String
    let titleKey: String
}

enum TheoryCatalog {
    static let topics: [TheoryTopic] = [
        TheoryTopic(
            id: "theory.kaufman.first20",
            titleKey: "theory_topic_first20_title",
            summaryKey: "theory_topic_first20_summary",
            takeawayKey: "theory_topic_first20_takeaway",
            sourceKind: .framework,
            citationKey: "theory_topic_first20_citation",
            contextKey: "theory_topic_first20_context",
            limitationKey: "theory_topic_first20_limitation",
            findingsIntroKey: nil,
            findings: [],
            links: [
                TheoryLink(id: "theory.kaufman.site", labelKey: "theory_link_author_site", url: url("https://joshkaufman.net/books/")),
                TheoryLink(id: "theory.kaufman.publisher", labelKey: "theory_link_publisher", url: url("https://www.penguinrandomhouse.com/books/312040/the-first-20-hours-by-josh-kaufman/"))
            ]
        ),
        TheoryTopic(
            id: "theory.ericsson.deliberate",
            titleKey: "theory_topic_deliberate_title",
            summaryKey: "theory_topic_deliberate_summary",
            takeawayKey: "theory_topic_deliberate_takeaway",
            sourceKind: .article,
            citationKey: "theory_topic_deliberate_citation",
            contextKey: "theory_topic_deliberate_context",
            limitationKey: "theory_topic_deliberate_limitation",
            findingsIntroKey: nil,
            findings: [],
            links: [
                TheoryLink(id: "theory.ericsson.1993", labelKey: "theory_link_ericsson_1993", url: url("https://doi.org/10.1037/0033-295X.100.3.363"))
            ]
        ),
        TheoryTopic(
            id: "theory.tenthousand.popular",
            titleKey: "theory_topic_10k_title",
            summaryKey: "theory_topic_10k_summary",
            takeawayKey: "theory_topic_10k_takeaway",
            sourceKind: .article,
            citationKey: "theory_topic_10k_citation",
            contextKey: "theory_topic_10k_context",
            limitationKey: "theory_topic_10k_limitation",
            findingsIntroKey: nil,
            findings: [],
            links: [
                TheoryLink(id: "theory.ericsson.1993.via10k", labelKey: "theory_link_ericsson_1993", url: url("https://doi.org/10.1037/0033-295X.100.3.363")),
                TheoryLink(id: "theory.macnamara.2019", labelKey: "theory_link_macnamara_2019", url: url("https://pmc.ncbi.nlm.nih.gov/articles/PMC6731745/"))
            ]
        ),
        TheoryTopic(
            id: "theory.macnamara.variance",
            titleKey: "theory_topic_variance_title",
            summaryKey: "theory_topic_variance_summary",
            takeawayKey: "theory_topic_variance_takeaway",
            sourceKind: .metaAnalysis,
            citationKey: "theory_topic_variance_citation",
            contextKey: "theory_topic_variance_context",
            limitationKey: "theory_topic_variance_limitation",
            findingsIntroKey: "theory_topic_variance_findings_intro",
            findings: [
                TheoryFinding(id: "theory.finding.games", labelKey: "theory_finding_games", valueKey: "theory_finding_games_value"),
                TheoryFinding(id: "theory.finding.music", labelKey: "theory_finding_music", valueKey: "theory_finding_music_value"),
                TheoryFinding(id: "theory.finding.sports", labelKey: "theory_finding_sports", valueKey: "theory_finding_sports_value"),
                TheoryFinding(id: "theory.finding.education", labelKey: "theory_finding_education", valueKey: "theory_finding_education_value"),
                TheoryFinding(id: "theory.finding.professions", labelKey: "theory_finding_professions", valueKey: "theory_finding_professions_value")
            ],
            links: [
                TheoryLink(id: "theory.macnamara.2014.doi", labelKey: "theory_link_macnamara_2014", url: url("https://doi.org/10.1177/0956797614535810")),
                TheoryLink(id: "theory.macnamara.2014.pubmed", labelKey: "theory_link_pubmed", url: url("https://pubmed.ncbi.nlm.nih.gov/24986855/"))
            ]
        ),
        TheoryTopic(
            id: "theory.cepeda.distributed",
            titleKey: "theory_topic_spacing_title",
            summaryKey: "theory_topic_spacing_summary",
            takeawayKey: "theory_topic_spacing_takeaway",
            sourceKind: .metaAnalysis,
            citationKey: "theory_topic_spacing_citation",
            contextKey: "theory_topic_spacing_context",
            limitationKey: "theory_topic_spacing_limitation",
            findingsIntroKey: nil,
            findings: [],
            links: [
                TheoryLink(id: "theory.cepeda.2006.doi", labelKey: "theory_link_cepeda_2006", url: url("https://doi.org/10.1037/0033-2909.132.3.354")),
                TheoryLink(id: "theory.cepeda.2006.pubmed", labelKey: "theory_link_pubmed", url: url("https://pubmed.ncbi.nlm.nih.gov/16719566/"))
            ]
        ),
        TheoryTopic(
            id: "theory.lally.habit",
            titleKey: "theory_topic_habit_title",
            summaryKey: "theory_topic_habit_summary",
            takeawayKey: "theory_topic_habit_takeaway",
            sourceKind: .article,
            citationKey: "theory_topic_habit_citation",
            contextKey: "theory_topic_habit_context",
            limitationKey: "theory_topic_habit_limitation",
            findingsIntroKey: nil,
            findings: [],
            links: [
                TheoryLink(id: "theory.lally.2010", labelKey: "theory_link_lally_2010", url: url("https://doi.org/10.1002/ejsp.674"))
            ]
        )
    ]

    /// Hour marks already used by the app. They are labels for time spent,
    /// not a change to the 21-hour progress band.
    static let milestones: [TheoryMilestone] = [
        TheoryMilestone(id: "milestone.100", titleKey: "theory_milestone_100_title"),
        TheoryMilestone(id: "milestone.1000", titleKey: "theory_milestone_1000_title"),
        TheoryMilestone(id: "milestone.10000", titleKey: "theory_milestone_10000_title")
    ]

    static func topic(id: String) -> TheoryTopic? {
        topics.first { $0.id == id }
    }

    private static func url(_ string: String) -> URL {
        guard let url = URL(string: string) else {
            preconditionFailure("Invalid bundled theory URL: \(string)")
        }
        return url
    }
}
