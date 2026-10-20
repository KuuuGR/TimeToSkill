//
//  .
//  TimeToSkill
//
//  Created by Grzegorz Kulesza on 10/04/2025.
//

import SwiftUI
import SwiftData

/// Displays full statistics summary of user's tracked skills
struct StatsView: View {
    @Environment(\.dismiss) private var dismiss
    @Query private var skills: [Skill]

    /// iOS presents this view as a sheet (with a Done button); macOS hosts it as
    /// a sidebar section in the detail column, where "Done" makes no sense.
    var showsDoneButton: Bool = true

    @State private var tab: StatsTab = .overview

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 0) {
                statsTabs
                    .padding(.horizontal)
                    .padding(.top, 8)
                ScrollView {
                    VStack(alignment: .leading, spacing: 28) {
                        tabContent
                    }
                    .padding()
                    .padding(.bottom, 24)
                    .macOSContentWidth(820)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle(Text(verbatim: L10n.string("stats_nav_title")))

            .inlineNavigationBarTitle()
            .toolbar {
                if showsDoneButton {
                    ToolbarItem(placement: .cancellationAction) {
                        Button {
                            dismiss()
                        } label: {
                            Text(verbatim: L10n.string("button_done"))
                        }
                    }
                }
            }
            .macOSSheetMinSize(width: 640, height: 660)
        }
    }

    private var statsTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .bottom, spacing: 6) {
                ForEach(StatsTab.allCases) { item in
                    let selected = item == tab
                    Button {
                        tab = item
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: item.systemImage)
                                .font(.body)
                            Text(verbatim: L10n.string(item.titleKey))
                                .font(.caption.weight(selected ? .semibold : .regular))
                                .lineLimit(1)
                        }
                        .frame(minWidth: 88)
                        .padding(.horizontal, 12)
                        .padding(.top, 10)
                        .padding(.bottom, selected ? 12 : 8)
                        .background(
                            UnevenRoundedRectangle(topLeadingRadius: 12, bottomLeadingRadius: 0, bottomTrailingRadius: 0, topTrailingRadius: 12)
                                .fill(selected ? Color.primary.opacity(0.08) : Color.primary.opacity(0.03))
                        )
                        .overlay(alignment: .top) {
                            UnevenRoundedRectangle(topLeadingRadius: 12, bottomLeadingRadius: 0, bottomTrailingRadius: 0, topTrailingRadius: 12)
                                .stroke(selected ? Color.brandAccent.opacity(0.8) : Color.primary.opacity(0.12), lineWidth: selected ? 1.4 : 0.6)
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("StatsTab_\(item.rawValue)")
                    .accessibilityAddTraits(selected ? .isSelected : [])
                }
            }
        }
        .accessibilityIdentifier("StatsTabs")
    }

    @ViewBuilder
    private var tabContent: some View {
        switch tab {
        case .overview:
            StatsSummaryView(skills: skills)
            StatsCollectionCounts()
        case .time:
            TrackedTimeView(skills: skills)
            TopSkillsView(skills: skills)
            GlobalTimeDistributionView()
        case .skills:
            StatsSkillGroups()
        case .thresholds:
            StatsThresholds(skills: skills)
        case .activity:
            YearActivityCalendarView()
            ActivityLogView(skills: skills)
        }
    }
}

enum StatsTab: String, CaseIterable, Identifiable {
    case overview, time, skills, thresholds, activity

    var id: String { rawValue }

    var titleKey: String {
        switch self {
        case .overview: return "stats_tab_overview"
        case .time: return "stats_tab_time"
        case .skills: return "stats_tab_skills"
        case .thresholds: return "stats_tab_thresholds"
        case .activity: return "stats_tab_activity"
        }
    }

    var systemImage: String {
        switch self {
        case .overview: return "square.grid.2x2"
        case .time: return "clock"
        case .skills: return "star"
        case .thresholds: return "flag"
        case .activity: return "calendar"
        }
    }
}

/// Catalog completion and tracked-skill time are separate counts.
struct StatsCollectionCounts: View {
    @Query private var catalog: [ExemplarySkill]

    var body: some View {
        let visible = catalog.filter { !$0.isHidden }
        let obtained = visible.filter(\.isObtained).count
        VStack(alignment: .leading, spacing: 8) {
            LText(key: "stats_collection_heading")
                .font(.title3.weight(.semibold))
            Text(String(format: L10n.string("stats_catalog_obtained_format"), obtained, visible.count))
                .font(.body)
            Text(String(format: L10n.string("stats_catalog_not_obtained_format"), visible.count - obtained))
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

struct StatsSkillGroups: View {
    @Query private var tracked: [Skill]
    @Query private var catalog: [ExemplarySkill]

    var body: some View {
        let visible = catalog.filter { !$0.isHidden }
        let obtained = visible.filter(\.isObtained)
        let withTime = tracked.filter { $0.hours > 0 }
        VStack(alignment: .leading, spacing: 18) {
            group(
                title: "stats_collection_heading",
                lines: [
                    String(format: L10n.string("stats_catalog_obtained_format"), obtained.count, visible.count),
                    String(format: L10n.string("stats_catalog_not_obtained_format"), visible.count - obtained.count)
                ],
                names: obtained.prefix(5).map(\.title)
            )
            group(
                title: "stats_tracked_heading",
                lines: [
                    String(format: L10n.string("stats_tracked_with_time_format"), withTime.count),
                    String(format: L10n.string("stats_tracked_without_time_format"), tracked.count - withTime.count)
                ],
                names: withTime.sorted { $0.hours > $1.hours }.prefix(5).map(\.name)
            )
        }
    }

    private func group(title: String, lines: [String], names: [String]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(verbatim: L10n.string(title))
                .font(.title3.weight(.semibold))
            ForEach(lines, id: \.self) { line in
                Text(line)
            }
            if names.isEmpty {
                LText(key: "stats_group_empty")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(names, id: \.self) { name in
                    Text(name)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

struct StatsThresholds: View {
    let skills: [Skill]

    private let marks = [21, 100, 1000, 10000]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            LText(key: "stats_thresholds_note")
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            if skills.isEmpty {
                LText(key: "stats_thresholds_empty")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(marks, id: \.self) { mark in
                    let reached = skills.filter { $0.hours >= Double(mark) }.count
                    let palette = CrystalPalette.forHours(Double(mark))
                    HStack(spacing: 12) {
                        Circle()
                            .fill(palette?.gradient ?? CrystalPalette.emerald.gradient)
                            .frame(width: 16, height: 16)
                        Text(mark, format: .number.grouping(.automatic))
                            .font(.headline.monospacedDigit())
                        LText(key: "theory_hour_unit")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(String(format: L10n.string("stats_threshold_count_format"), reached))
                            .font(.title3.weight(.semibold).monospacedDigit())
                    }
                    .padding(12)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }
}
