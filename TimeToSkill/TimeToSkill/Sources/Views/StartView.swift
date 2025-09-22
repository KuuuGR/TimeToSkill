import SwiftUI
import SwiftData

/// Displays the list of skills with progress tracking functionality.
struct StartView: View {
    @Environment(\.modelContext) private var context
    @Query private var skills: [Skill]  // Auto-fetched from SwiftData

    @State private var selectedSkillForOptions: Skill?
    @State private var showingAddSkill = false

    // Using AppStorage for automatic UserDefaults persistence
    @AppStorage("selectedSortOption") private var selectedSortRawValue: String = SkillSortOption.nameAsc.rawValue

    enum SkillSortOption: String, CaseIterable, Identifiable {
        case nameAsc = "sort_name_asc"
        case nameDesc = "sort_name_desc"
        case hoursAsc = "sort_time_asc"
        case hoursDesc = "sort_time_desc"

        var id: String { self.rawValue }
    }

    var body: some View {
        VStack {
            // Title
            Text(LocalizedStringKey("tracking_title"))
                .font(.headline)
                .accessibilityIdentifier("StartViewTitle")

            // Picker for sorting
            Picker(LocalizedStringKey("sort_by_label"), selection: $selectedSortRawValue) {
                ForEach(SkillSortOption.allCases) { option in
                    Text(LocalizedStringKey(option.rawValue))
                        .tag(option.rawValue)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.bottom, 8)

            // Content with skills and FAB
            ZStack {
                if sortedSkills.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "lightbulb")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 64, height: 64)
                            .foregroundColor(.yellow.opacity(0.8))

                        Text(LocalizedStringKey("empty_message_title"))
                            .font(.title3)
                            .fontWeight(.semibold)

                        Text(LocalizedStringKey("empty_message_description"))
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
                            ForEach(sortedSkills) { skill in
                                SkillProgressView(
                                    skill: skill,
                                    isActive: skill.activeStart != nil,
                                    onToggleTimer: {
                                        toggleTimer(for: skill)
                                    },
                                    onShowOptions: {
                                        selectedSkillForOptions = skill
                                    }
                                )
                            }
                        }
                        .padding()
                        .padding(.bottom, 100)
                    }
                }

                // Floating action button
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
            }
        }
        .navigationTitle(LocalizedStringKey("tracking_nav_title"))
        .sheet(isPresented: $showingAddSkill) {
            AddSkillView()
        }
        .sheet(item: $selectedSkillForOptions) { skill in
            SkillOptionsSheet(skill: skill) {
                context.delete(skill)
            }
        }
    }

    /// Toggles the timer state for a given skill.
    private func toggleTimer(for skill: Skill) {
        if let start = skill.activeStart {
            let elapsed = Date().timeIntervalSince(start)
            let hoursToAdd = elapsed / 3600
            
            // Guard against NaN and infinite values
            guard hoursToAdd.isFinite && !hoursToAdd.isNaN && hoursToAdd >= 0 else {
                skill.activeStart = nil
                return
            }
            
            skill.hours += hoursToAdd
            // Persist interval entry (minutes)
            let minutes = hoursToAdd * 60.0
            let entry = TimeIntervalEntry(skillId: skill.id, durationMinutes: minutes, source: .timer)
            context.insert(entry)
            
            skill.activeStart = nil
        } else {
            skill.activeStart = Date()
        }
    }

    var sortedSkills: [Skill] {
        let currentSort = SkillSortOption(rawValue: selectedSortRawValue) ?? .nameAsc
        switch currentSort {
        case .nameAsc:
            return skills.sorted { $0.name.lowercased() < $1.name.lowercased() }
        case .nameDesc:
            return skills.sorted { $0.name.lowercased() > $1.name.lowercased() }
        case .hoursAsc:
            return skills.sorted { $0.hours < $1.hours }
        case .hoursDesc:
            return skills.sorted { $0.hours > $1.hours }
        }
    }
}
