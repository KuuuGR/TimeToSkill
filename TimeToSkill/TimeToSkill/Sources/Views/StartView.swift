import SwiftUI
import SwiftData

/// Shows skill vials with progress tracking
struct StartView: View {
    @Environment(\.modelContext) private var context
    @Query private var skills: [Skill]  // Auto-fetched from SwiftData

    @State private var activeTimer: Skill?
    @State private var startTime: Date?

    @State private var showingAddSkill = false

    var body: some View {
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
                .padding(.bottom, 100) // So FAB doesn't overlap last item
            }

            // Floating Action Button
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

    private func toggleTimer(for skill: Skill) {
        if activeTimer == skill {
            skill.hours += Date().timeIntervalSince(startTime ?? Date()) / 3600
            activeTimer = nil
        } else {
            activeTimer = skill
            startTime = Date()
        }
    }
}
