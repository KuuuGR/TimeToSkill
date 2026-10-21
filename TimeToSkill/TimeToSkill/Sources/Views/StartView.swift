import SwiftUI
import SwiftData

/// Displays the list of skills with progress tracking functionality.
struct StartView: View {
    @Environment(\.modelContext) private var context
    @Query private var skills: [Skill]  // Auto-fetched from SwiftData

    @State private var selectedSkillForOptions: Skill?
    @State private var selectedSkillForChart: Skill?
    @State private var showingAddSkill = false

    // Using AppStorage for automatic UserDefaults persistence
    @AppStorage("selectedSortOption") private var selectedSortRawValue: String = SkillSortOption.nameAsc.rawValue
    @AppStorage(TrackerToolKind.storageKey) private var trackerToolRaw: String = TrackerToolKind.default.rawValue

    private var trackerTool: TrackerToolKind {
        TrackerToolKind.resolve(trackerToolRaw)
    }

    enum SkillSortOption: String, CaseIterable, Identifiable {
        case nameAsc = "sort_name_asc"
        case nameDesc = "sort_name_desc"
        case hoursAsc = "sort_time_asc"
        case hoursDesc = "sort_time_desc"

        var id: String { self.rawValue }
    }

    var body: some View {
        // A single, always-present TimelineView keeps the view identity stable.
        // Previously the content switched between `TimelineView { ... }` and a
        // plain view depending on whether a timer was running; that identity
        // change tore down and recreated the ScrollView, so tapping Start/Stop
        // scrolled the skills list back to the top. Keeping one TimelineView at
        // a fixed position means the ScrollView is preserved across toggles.
        TimelineView(.periodic(from: .now, by: 1)) { context in
            mainContent(now: context.date)
        }
        .navigationTitle(Text(verbatim: L10n.string("tracking_nav_title")))
        // Only on Progress. Time Balance has its own "new balance" toolbar item;
        // showing both plus actions at once is confusing.
        .toolbar {
            #if os(macOS)
            if trackerTool.showsNewSkillAction {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddSkill = true
                    } label: {
                        Label {
                            Text(verbatim: L10n.string("fab_add_skill"))
                        } icon: {
                            Image(systemName: "plus")
                        }
                    }
                    .help(L10n.string("fab_add_skill"))
                    .keyboardShortcut("n", modifiers: .command)
                }
            }
            #endif
        }
        .sheet(isPresented: $showingAddSkill) {
            AddSkillView()
        }
        .sheet(item: $selectedSkillForOptions) { skill in
            SkillOptionsSheet(skill: skill) {
                let skillId = skill.id
                do {
                    _ = try SkillIntervalCleanup.deleteEntries(for: skillId, in: context)
                    context.delete(skill)
                    try context.save()
                } catch {
                    // Keep the sheet usable; SwiftData will surface a later save failure.
                    context.delete(skill)
                }
            }
        }
        .sheet(item: $selectedSkillForChart) { skill in
            NavigationStack {
                TimeDistributionView(skill: skill, showsDoneButton: true)
            }
        }
        .onAppear {
            PreviewProgressSeeder.apply(context: context)
        }
    }

    @ViewBuilder
    private func mainContent(now: Date) -> some View {
        VStack {
            // Title
            LText(key: "tracking_title")
                .font(.headline)
                .accessibilityIdentifier("StartViewTitle")

            // Picker for sorting
            Picker(selection: $selectedSortRawValue) {
                ForEach(SkillSortOption.allCases) { option in
                    Text(verbatim: L10n.string(option.rawValue))
                        .tag(option.rawValue)
                }
            } label: {
                Text(verbatim: L10n.string("sort_by_label"))
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.bottom, 8)

            Picker(selection: $trackerToolRaw) {
                Text(verbatim: L10n.string("tracker_tool_progress")).tag(TrackerToolKind.progress.rawValue)
                Text(verbatim: L10n.string("tracker_tool_balance")).tag(TrackerToolKind.balance.rawValue)
            } label: {
                Text(verbatim: L10n.string("tracker_tool_label"))
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .accessibilityIdentifier("TrackerToolPicker")

            if trackerTool == .balance {
                TimeBalanceView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
            // Content with skills and FAB
            ZStack {
                let sorted = sortedSkills(at: now)
                if sorted.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "lightbulb")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 64, height: 64)
                            .foregroundColor(.yellow.opacity(0.8))

                        LText(key: "empty_message_title")
                            .font(.title3)
                            .fontWeight(.semibold)

                        LText(key: "empty_message_description")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            ForEach(sorted) { skill in
                                SkillProgressView(
                                    skill: skill,
                                    now: now,
                                    isActive: skill.activeStart != nil,
                                    onToggleTimer: {
                                        toggleTimer(for: skill)
                                    },
                                    onShowOptions: {
                                        selectedSkillForOptions = skill
                                    },
                                    onShowChart: {
                                        selectedSkillForChart = skill
                                    }
                                )
                            }
                        }
                        .padding()
                        .padding(.bottom, 100)
                        .macOSContentWidth(760)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }

                #if !os(macOS)
                // Floating action button (iOS pattern; on macOS the same action
                // lives in the window toolbar as ⌘N).
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        FABButton(
                            icon: "plus",
                            action: { showingAddSkill = true },
                            accessibilityLabelKey: "fab_add_skill"
                        )
                        .padding(20)
                    }
                }
                #endif
            }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// Toggles the timer state for a given skill.
    private func toggleTimer(for skill: Skill) {
        if let start = skill.activeStart {
            let elapsed = Date().timeIntervalSince(start)
            let hoursToAdd = elapsed / 3600

            // Guard against NaN and infinite values
            guard hoursToAdd.isFinite && !hoursToAdd.isNaN && hoursToAdd >= 0 else {
                skill.activeStart = nil
                skill.touchLastUpdated()
                return
            }

            skill.hours += hoursToAdd
            // Persist interval entry (minutes)
            let minutes = hoursToAdd * 60.0
            let entry = TimeIntervalEntry(skillId: skill.id, durationMinutes: minutes, source: .timer)
            context.insert(entry)

            skill.activeStart = nil
            skill.touchLastUpdated()
        } else {
            skill.activeStart = Date()
            skill.touchLastUpdated()
        }
    }

    private func sortedSkills(at now: Date) -> [Skill] {
        let currentSort = SkillSortOption(rawValue: selectedSortRawValue) ?? .nameAsc
        switch currentSort {
        case .nameAsc:
            return skills.sorted { $0.name.lowercased() < $1.name.lowercased() }
        case .nameDesc:
            return skills.sorted { $0.name.lowercased() > $1.name.lowercased() }
        case .hoursAsc:
            return skills.sorted {
                $0.effectiveHours(at: now) < $1.effectiveHours(at: now)
            }
        case .hoursDesc:
            return skills.sorted {
                $0.effectiveHours(at: now) > $1.effectiveHours(at: now)
            }
        }
    }
}
