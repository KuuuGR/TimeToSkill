import SwiftUI
import SwiftData

/// Displays the list of skills with progress tracking functionality.
struct StartView: View {
    @Environment(\.modelContext) private var context
    @Query private var skills: [Skill]  // Auto-fetched from SwiftData

    @State private var activeTimer: Skill?
    @State private var startTime: Date?

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
                            SkillProgressView(skill: skill,
                                              isActive: activeTimer == skill) {
                                toggleTimer(for: skill)
                            }
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
            AddSkillView { name in
                let newSkill = Skill(name: name)
                context.insert(newSkill)
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
        if activeTimer == skill {
            // Timer is stopping
            skill.hours += Date().timeIntervalSince(startTime ?? Date()) / 3600
            activeTimer = nil
        } else {
            // Timer is starting
            activeTimer = skill
            startTime = Date()
        }
    }
}
