import SwiftUI
import SwiftData

/// Displays the list of skills with progress tracking functionality.
struct StartView: View {
    @Environment(\.modelContext) private var context
    @Query private var skills: [Skill]  // Auto-fetched from SwiftData

    @State private var selectedSkillForOptions: Skill?

    @State private var showingAddSkill = false
    
    enum SkillSortOption: String, CaseIterable, Identifiable {
        case nameAsc = "Name ↑"
        case nameDesc = "Name ↓"
        case hoursAsc = "Time ↑"
        case hoursDesc = "Time ↓"

        var id: String { self.rawValue }
    }

    @State private var selectedSort: SkillSortOption = .nameAsc

    var body: some View {
        VStack {
            // Title
            Text(NSLocalizedString("tracking_title", comment: "Tracking screen title"))
                .font(.headline)
                .accessibilityIdentifier("StartViewTitle")

            // Picker for sorting
            Picker("Sort By", selection: $selectedSort) {
                ForEach(SkillSortOption.allCases) { option in
                    Text(option.rawValue).tag(option)
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
                            .font(.system(size: 60))
                            .foregroundColor(.yellow.opacity(0.8))

                        Text("No skills yet")
                            .font(.title3)
                            .fontWeight(.semibold)

                        Text("Tap + to begin your learning journey.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .multilineTextAlignment(.center)
                    .transition(.opacity)
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

                // FAB
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        FABButton(icon: "plus") {
                            showingAddSkill = true
                        }
                        .padding(20)
                    }
                }
            }

        }
        .navigationTitle(NSLocalizedString("tracking_nav_title", comment: "Navigation title for tracking view"))
        .sheet(isPresented: $showingAddSkill) {
            AddSkillView()
        }

        .sheet(item: $selectedSkillForOptions) { skill in
            SkillOptionsSheet(skill: skill) {
                context.delete(skill)
            }
        }
        .onAppear {
            if skills.isEmpty {
                context.insert(Skill(name: NSLocalizedString("default_guitar", comment: "")))
                context.insert(Skill(name: NSLocalizedString("default_spanish", comment: "")))
            }
        }
    }

    /// Toggles the timer state for a given skill.
    private func toggleTimer(for skill: Skill) {
        if let start = skill.activeStart {
            let elapsed = Date().timeIntervalSince(start)
            skill.hours += elapsed / 3600
            skill.activeStart = nil
        } else {
            skill.activeStart = Date()
        }
    }
    
    var sortedSkills: [Skill] {
        switch selectedSort {
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
