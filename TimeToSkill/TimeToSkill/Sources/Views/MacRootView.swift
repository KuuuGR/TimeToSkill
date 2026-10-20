//
//  MacRootView.swift
//  TimeToSkill
//
//  macOS root: native sidebar navigation built with `NavigationSplitView`.
//  Every sidebar row maps to a view that already existed for iOS, so the detail
//  column simply hosts it - no feature, model or persistence code changes.
//

import SwiftUI

/// Sections reachable from the macOS sidebar. Mirrors what the iOS home links
/// to, with Settings and About kept at the bottom, as requested.
enum MacSidebarSection: String, CaseIterable, Identifiable, Hashable {
    case overview, trackers, counters, timeConverter, statistics, theory, skills, settings, about

    var id: String { rawValue }

    static let primary: [MacSidebarSection] = [
        .overview, .trackers, .counters, .timeConverter, .statistics, .theory, .skills
    ]
    static let secondary: [MacSidebarSection] = [.settings, .about]

    /// Persists the open sidebar section across language-driven view refreshes.
    static let selectionDefaultsKey = "MacSidebarSelection"

    /// Localizable key — resolved via `L10n` / LanguageBundle so Glagolica applies.
    var localizationKey: String {
        switch self {
        case .overview: return "sidebar_overview"
        case .trackers: return "main_manage_trackers"
        case .counters: return "main_manage_counters"
        case .timeConverter: return "time_converter_nav_title"
        case .statistics: return "stats_nav_title"
        case .theory: return "theory_nav_title"
        case .skills: return "exemplary_skills_title"
        case .settings: return "options_title"
        case .about: return "ab_navigation_title"
        }
    }

    var systemImage: String {
        switch self {
        case .overview: return "hourglass"
        case .trackers: return "bolt.fill"
        case .counters: return "number"
        case .timeConverter: return "arrow.left.arrow.right"
        case .statistics: return "chart.bar.fill"
        case .theory: return "book"
        case .skills: return "star.fill"
        case .settings: return "gearshape"
        case .about: return "info.circle"
        }
    }
}

#if os(macOS)

import SwiftData

struct MacRootView: View {
    @Environment(\.modelContext) private var modelContext
    /// Observed so sidebar / detail strings refresh when the script changes
    /// (Latinica → Cyrilica / Glagolica) without restarting the app.
    @ObservedObject private var language = AppLanguage.shared

    @AppStorage(MacSidebarSection.selectionDefaultsKey)
    private var selectionRaw: String = MacSidebarSection.overview.rawValue
    @State private var showingCustomSkillSheet = false

    private var selection: Binding<MacSidebarSection?> {
        Binding(
            get: { MacSidebarSection(rawValue: selectionRaw) ?? .overview },
            set: { selectionRaw = ($0 ?? .overview).rawValue }
        )
    }

    var body: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            // The split column proposes a real height. Pinning the detail to
            // that height stops a tall screen (the skill catalog) from sizing
            // itself to its content, sticking to the top of the window and
            // leaving the bottom unreachable.
            GeometryReader { proxy in
                detail
                    .frame(width: proxy.size.width, height: proxy.size.height, alignment: .top)
            }
            .frame(minWidth: 520, minHeight: 420)
        }
        .navigationSplitViewStyle(.balanced)
        // Script-aware identity forces Label/LocalizedStringKey rows to
        // re-resolve through LanguageBundle after Latinica → Glagolica, etc.
        .id(language.resolved.presentationIdentity)
        .sheet(isPresented: $showingCustomSkillSheet) {
            CustomExemplarySkillSheet { title, description, category, difficulty, one, two, three, imagePath in
                let model = ExemplarySkill(
                    isUserCreated: true,
                    title: title,
                    skillDescription: description,
                    imageName: imagePath ?? "star.fill",
                    category: category.isEmpty ? "Custom" : category,
                    difficultyLevel: difficulty,
                    oneStarDescription: one,
                    twoStarDescription: two,
                    threeStarDescription: three
                )
                modelContext.insert(model)
                try? modelContext.save()
            }
        }
    }

    // MARK: - Sidebar

    private var sidebar: some View {
        List(selection: selection) {
            Section {
                ForEach(MacSidebarSection.primary) { section in
                    sidebarRow(section)
                }
            }
            Section {
                ForEach(MacSidebarSection.secondary) { section in
                    sidebarRow(section)
                }
            }
        }
        .listStyle(.sidebar)
        .navigationSplitViewColumnWidth(min: 190, ideal: 208, max: 280)
        .safeAreaInset(edge: .top, spacing: 0) { sidebarHeader }
    }

    private var sidebarHeader: some View {
        VStack(alignment: .leading, spacing: 0) {
            BrandMark(size: 26, wordmarkFont: .headline, symbol: .glyph(BrandMark.sidebarGlyph))
                .padding(.leading, 14)
                .padding(.vertical, 10)

            Divider()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.bar)
    }

    private func sidebarRow(_ section: MacSidebarSection) -> some View {
        Label {
            LText(key: section.localizationKey)
        } icon: {
            Image(systemName: section.systemImage)
        }
        .tag(section)
        .accessibilityIdentifier("Sidebar_\(section.rawValue)")
    }

    // MARK: - Detail column

    @ViewBuilder
    private var detail: some View {
        switch selection.wrappedValue ?? .overview {
        case .overview:
            NavigationStack {
                MacOverviewView(selection: selection)
            }
        case .trackers:
            NavigationStack { StartView() }
        case .counters:
            ManageCountersView()
        case .timeConverter:
            NavigationStack { TimeConverterView() }
        case .statistics:
            StatsView(showsDoneButton: false)
        case .theory:
            NavigationStack { TheoryView() }
        case .skills:
            // One navigation stack for this column. The catalog used to bring
            // its own stack, and a pushed skill then replaced the split view,
            // so the sidebar rows disappeared with no way back.
            NavigationStack {
                ExemplarySkillsView()
                    .macOSToolbarAction(
                        title: "fab_add_custom_skill",
                        systemImage: "plus.square.on.square",
                        shortcut: KeyboardShortcut("n", modifiers: [.command, .shift])
                    ) {
                        showingCustomSkillSheet = true
                    }
            }
        case .settings:
            OptionsView(showsDoneButton: false)
        case .about:
            NavigationStack { AboutView() }
        }
    }
}

#endif
