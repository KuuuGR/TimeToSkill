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
    @Query(sort: \ExemplarySkill.title) private var exemplarySkills: [ExemplarySkill]
    
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
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 3), count: 3), spacing: 3) {
                        ForEach(exemplarySkills) { skill in
                            ExemplarySkillCard(skill: skill) {
                                selectedSkill = skill
                            }
                        }
                    }
                    .padding(.horizontal, 3)
                    .padding(.vertical, 3)
                }
            }
            .navigationTitle("Exemplary Skills")
            .onAppear {
                loadDailyEvaluationsCount()
                SkillSeeder.seedIfNeeded(context: context)
            }
            .sheet(item: $selectedSkill) { skill in
                ExemplarySkillDetailView(
                    skill: skill,
                    onEvaluate: { rating, verificationCode in
                        evaluateSkill(skill, rating: rating, verificationCode: verificationCode)
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
    
    private func evaluateSkill(_ skill: ExemplarySkill, rating: Int, verificationCode: String) {
        // Allow re-evaluation of already obtained skills without daily limit
        let isReEvaluation = skill.isObtained
        
        if !isReEvaluation {
            // Only check daily limit for new evaluations
            guard dailyEvaluationsCount < ExemplarySkillConstants.dailyEvaluationLimit else {
                showingDailyLimitAlert = true
                return
            }
        }
        
        // Update skill
        skill.userRating = rating
        skill.obtainedAt = Date()
        skill.verificationCode = verificationCode
        skill.isObtained = rating > 0
        
        // Append achievement history record
        skill.achievementHistory.append(AchievementRecord(stars: rating, verificationCode: verificationCode))
        
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
}

#Preview {
    ExemplarySkillsView()
        .modelContainer(for: ExemplarySkill.self)
}
