//
//  ExemplarySkillsView.swift
//  TimeToSkill
//
//  Created by admin on 10/04/2025.
//

import SwiftUI
import SwiftData

struct ExemplarySkillsView: View {
    @Environment(\.modelContext) private var context
    @State private var exemplarySkills: [ExemplarySkill] = []
    
    @State private var selectedSkill: ExemplarySkill?
    @State private var showingEvaluationSheet = false
    @State private var showingDailyLimitAlert = false
    @State private var dailyEvaluationsCount = 0
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header with daily limit info
                HStack {
                    Text("Daily Evaluations: \(dailyEvaluationsCount)/\(ExemplarySkillConstants.dailyEvaluationLimit)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Button("Reset Daily Limit") {
                        resetDailyLimit()
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
                .padding(.horizontal)
                .padding(.top, 8)
                
                // Skills grid
                ScrollView {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 16) {
                        ForEach(exemplarySkills) { skill in
                            ExemplarySkillCard(skill: skill) {
                                selectedSkill = skill
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Exemplary Skills")
            .onAppear {
                loadDailyEvaluationsCount()
                loadExemplarySkills()
                if exemplarySkills.isEmpty {
                    createSampleSkills()
                }
            }
            .sheet(item: $selectedSkill) { skill in
                ExemplarySkillDetailView(
                    skill: skill,
                    onEvaluate: { rating in
                        evaluateSkill(skill, rating: rating)
                    }
                )
            }
            .alert("Daily Limit Reached", isPresented: $showingDailyLimitAlert) {
                Button("OK") { }
            } message: {
                Text("You've reached your daily limit of \(ExemplarySkillConstants.dailyEvaluationLimit) skill evaluations. Try again tomorrow!")
            }
        }
    }
    
    private func evaluateSkill(_ skill: ExemplarySkill, rating: Int) {
        // Allow re-evaluation of already obtained skills without daily limit
        let isReEvaluation = skill.isObtained
        
        if !isReEvaluation {
            // Only check daily limit for new evaluations
            guard dailyEvaluationsCount < ExemplarySkillConstants.dailyEvaluationLimit else {
                showingDailyLimitAlert = true
                return
            }
        }
        
        // Generate verification code
        let verificationCode = generateVerificationCode()
        
        // Update skill
        skill.userRating = rating
        skill.obtainedAt = Date()
        skill.verificationCode = verificationCode
        skill.isObtained = true
        
        // Only update daily count for new evaluations
        if !isReEvaluation {
            dailyEvaluationsCount += 1
            UserDefaults.standard.set(dailyEvaluationsCount, forKey: "dailyEvaluationsCount")
            UserDefaults.standard.set(Date(), forKey: "lastEvaluationDate")
        }
        
        try? context.save()
    }
    
    private func generateVerificationCode() -> String {
        let characters = Array(ExemplarySkillConstants.allowedCharacters)
        return String((0..<ExemplarySkillConstants.verificationCodeLength).map { _ in
            characters.randomElement()!
        })
    }
    
    private func loadDailyEvaluationsCount() {
        let lastDate = UserDefaults.standard.object(forKey: "lastEvaluationDate") as? Date ?? Date.distantPast
        let today = Calendar.current.startOfDay(for: Date())
        let lastEvaluationDay = Calendar.current.startOfDay(for: lastDate)
        
        if today > lastEvaluationDay {
            // New day, reset count
            dailyEvaluationsCount = 0
            UserDefaults.standard.set(0, forKey: "dailyEvaluationsCount")
        } else {
            // Same day, load existing count
            dailyEvaluationsCount = UserDefaults.standard.integer(forKey: "dailyEvaluationsCount")
        }
    }
    
    private func resetDailyLimit() {
        dailyEvaluationsCount = 0
        UserDefaults.standard.set(0, forKey: "dailyEvaluationsCount")
        UserDefaults.standard.set(Date(), forKey: "lastEvaluationDate")
    }
    
    private func loadExemplarySkills() {
        do {
            let descriptor = FetchDescriptor<ExemplarySkill>()
            exemplarySkills = try context.fetch(descriptor)
            print("Loaded \(exemplarySkills.count) exemplary skills")
            for skill in exemplarySkills {
                print("  - \(skill.title) (obtained: \(skill.isObtained), rating: \(skill.userRating ?? 0))")
            }
        } catch {
            print("Error loading exemplary skills: \(error)")
            exemplarySkills = []
        }
    }
    
    private func createSampleSkills() {
        let sampleSkills = [
            ExemplarySkill(
                title: "Guitar Master",
                skillDescription: "Mastered guitar playing with over 1000 hours of practice. Can play complex pieces and improvise.",
                imageName: "guitars.fill",
                category: "Music",
                difficultyLevel: 3
            ),
            ExemplarySkill(
                title: "Language Learner",
                skillDescription: "Achieved fluency in Spanish through dedicated study and practice.",
                imageName: "globe",
                category: "Language",
                difficultyLevel: 2
            ),
            ExemplarySkill(
                title: "Code Warrior",
                skillDescription: "Became proficient in Swift programming with extensive project experience.",
                imageName: "laptopcomputer",
                category: "Programming",
                difficultyLevel: 3
            ),
            ExemplarySkill(
                title: "Chef Extraordinaire",
                skillDescription: "Developed advanced cooking skills and can prepare gourmet meals.",
                imageName: "fork.knife",
                category: "Cooking",
                difficultyLevel: 2
            ),
            ExemplarySkill(
                title: "Fitness Enthusiast",
                skillDescription: "Maintained consistent fitness routine and achieved personal health goals.",
                imageName: "figure.run",
                category: "Fitness",
                difficultyLevel: 1
            ),
            ExemplarySkill(
                title: "Art Creator",
                skillDescription: "Developed artistic skills in painting and digital art creation.",
                imageName: "paintbrush.fill",
                category: "Art",
                difficultyLevel: 2
            )
        ]
        
        for skill in sampleSkills {
            context.insert(skill)
        }
        
        try? context.save()
    }
}

#Preview {
    ExemplarySkillsView()
        .modelContainer(for: ExemplarySkill.self)
}
