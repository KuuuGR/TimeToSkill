//
//  MacOverviewView.swift
//  TimeToSkill
//
//  Calm, native landing surface for macOS: brand, one primary action and two
//  secondary shortcuts. Deliberately avoids the mobile "full-width gradient
//  button" pattern so the wide window reads as a desktop app.
//

#if os(macOS)

import SwiftUI
import SwiftData

struct MacOverviewView: View {
    @Binding var selection: MacSidebarSection?
    let onAddSkill: () -> Void

    @Query private var skills: [Skill]

    private var totalTrackedHours: Double {
        skills.reduce(0) { $0 + $1.effectiveHours(at: Date()) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                // Hero: small brand mark, app name and a one-line introduction.
                VStack(alignment: .leading, spacing: 12) {
                    BrandMark(size: 44, showsWordmark: false)

                    Text("ab_app_name")
                        .font(.system(.largeTitle, weight: .bold))
                        .foregroundColor(AppColors.onSurface)

                    Text(LocalizedStringKey("home_hero_intro"))
                        .font(.body)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                // Single progress point plus the primary action.
                GroupBox {
                    HStack(alignment: .firstTextBaseline, spacing: 16) {
                        Text(String(
                            format: NSLocalizedString("time_total_hours_format", comment: "Total tracked time"),
                            formatHours(totalTrackedHours)
                        ))
                        .font(.title2.weight(.semibold))
                        .monospacedDigit()
                        .foregroundColor(AppColors.onSurface)
                        .accessibilityIdentifier("MacTotalTrackedLabel")

                        Spacer(minLength: 12)

                        Button(LocalizedStringKey("main_manage_trackers")) {
                            selection = .trackers
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(AppColors.accent)
                    }
                    .padding(.top, 2)
                } label: {
                    Label(LocalizedStringKey("stats_total_hours"), systemImage: "hourglass")
                }

                // Secondary shortcuts into sections that already exist
                // (the sidebar lists every section as well).
                HStack(spacing: 10) {
                    Button(LocalizedStringKey("fab_add_skill")) { onAddSkill() }
                        .buttonStyle(.bordered)

                    Button(LocalizedStringKey("exemplary_skills_title")) { selection = .skills }
                        .buttonStyle(.bordered)

                    Button(LocalizedStringKey("stats_nav_title")) { selection = .statistics }
                        .buttonStyle(.bordered)
                }

                Spacer(minLength: 8)
            }
            .padding(28)
            .frame(maxWidth: 660, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .navigationTitle(LocalizedStringKey("ab_app_name"))
        .macOSToolbarAction(
            title: "fab_add_skill",
            systemImage: "plus",
            shortcut: KeyboardShortcut("n", modifiers: .command)
        ) {
            onAddSkill()
        }
    }

    private func formatHours(_ hours: Double) -> String {
        let safeHours = hours.isFinite && !hours.isNaN ? hours : 0
        return String(format: "%.1f", safeHours)
    }
}

#endif
