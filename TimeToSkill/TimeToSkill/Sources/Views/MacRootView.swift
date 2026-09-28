//
//  MacRootView.swift
//  TimeToSkill
//
//  macOS root: native sidebar navigation built with `NavigationSplitView`.
//  Every sidebar row maps to a view that already existed for iOS, so the detail
//  column simply hosts it - no feature, model or persistence code changes.
//

#if os(macOS)

import SwiftUI
import SwiftData

/// Sections reachable from the macOS sidebar. Mirrors what the iOS home links
/// to, with Settings and About kept at the bottom, as requested.
enum MacSidebarSection: String, CaseIterable, Identifiable, Hashable {
    case overview, trackers, counters, statistics, theory, skills, settings, about

    var id: String { rawValue }

    static let primary: [MacSidebarSection] = [.overview, .trackers, .counters, .statistics, .theory, .skills]
    static let secondary: [MacSidebarSection] = [.settings, .about]

    var titleKey: LocalizedStringKey {
        switch self {
        case .overview: return "sidebar_overview"
        case .trackers: return "main_manage_trackers"
        case .counters: return "main_manage_counters"
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
        case .statistics: return "chart.bar.fill"
        case .theory: return "book"
        case .skills: return "star.fill"
        case .settings: return "gearshape"
        case .about: return "info.circle"
        }
    }
}

struct MacRootView: View {
    @Environment(\.modelContext) private var modelContext

    @State private var selection: MacSidebarSection? = .overview
    @State private var showingAddSkill = false
    @State private var showingCustomSkillSheet = false

    var body: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            detail
        }
        .sheet(isPresented: $showingAddSkill) {
            AddSkillView()
        }
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
        List(selection: $selection) {
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
            BrandMark(size: 26, wordmarkFont: .headline)
                .padding(.leading, 14)
                .padding(.vertical, 10)

            Divider()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.bar)
    }

    private func sidebarRow(_ section: MacSidebarSection) -> some View {
        Label(section.titleKey, systemImage: section.systemImage)
            .tag(section)
    }

    // MARK: - Detail column

    @ViewBuilder
    private var detail: some View {
        switch selection ?? .overview {
        case .overview:
            NavigationStack {
                MacOverviewView(selection: $selection, onAddSkill: { showingAddSkill = true })
            }
        case .trackers:
            NavigationStack { StartView() }
        case .counters:
            ManageCountersView()
        case .statistics:
            StatsView(showsDoneButton: false)
        case .theory:
            NavigationStack { TheoryView() }
        case .skills:
            ExemplarySkillsView()
                .macOSToolbarAction(
                    title: "fab_add_custom_skill",
                    systemImage: "plus.square.on.square",
                    shortcut: KeyboardShortcut("n", modifiers: [.command, .shift])
                ) {
                    showingCustomSkillSheet = true
                }
        case .settings:
            OptionsView(showsDoneButton: false)
        case .about:
            NavigationStack { AboutView() }
        }
    }
}

#endif
