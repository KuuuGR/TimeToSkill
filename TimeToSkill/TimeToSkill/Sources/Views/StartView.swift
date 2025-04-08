import SwiftUI
import SwiftData

/// Displays the list of skills with progress tracking functionality.
struct StartView: View {
    @Environment(\.modelContext) private var context
    @Query private var skills: [Skill]  // Auto-fetched from SwiftData

    @State private var selectedSkillForOptions: Skill?

    @State private var showingAddSkill = false

    var body: some View {
        VStack {
            // Title for UI testing
            Text(NSLocalizedString("tracking_title", comment: "Tracking screen title"))
                .font(.headline)
                .accessibilityIdentifier("StartViewTitle")

            ZStack {
                ScrollView {
                    VStack(spacing: 20) {
                        ForEach(skills) { skill in
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
                    .padding(.bottom, 100) // Add space so FAB doesn't overlap the last skill
                }

                // Floating Action Button (FAB)
                VStack {
                    Spacer()
                    HStack {
                        Spacer()

                        // Add Skill FAB
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
}
