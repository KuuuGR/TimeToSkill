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
    
    private enum SortOption: String, CaseIterable {
        case name = "sort_name"
        case category = "sort_category"
        case starsAsc = "sort_stars_asc"
        case starsDesc = "sort_stars_desc"
        case difficultyAsc = "sort_difficulty_asc"
        case difficultyDesc = "sort_difficulty_desc"
        case completedAsc = "sort_completed_asc"
        case completedDesc = "sort_completed_desc"
        
        var localizedTitle: String {
            switch self {
            case .name: return NSLocalizedString("sort_name", comment: "")
            case .category: return NSLocalizedString("sort_category", comment: "")
            case .starsAsc: return NSLocalizedString("sort_stars_asc", comment: "")
            case .starsDesc: return NSLocalizedString("sort_stars_desc", comment: "")
            case .difficultyAsc: return NSLocalizedString("sort_difficulty_asc", comment: "")
            case .difficultyDesc: return NSLocalizedString("sort_difficulty_desc", comment: "")
            case .completedAsc: return NSLocalizedString("sort_completed_asc", comment: "")
            case .completedDesc: return NSLocalizedString("sort_completed_desc", comment: "")
            }
        }
    }
    
    @AppStorage("ExemplarySkillsSortOption") private var sortOptionRaw: String = SortOption.name.rawValue
    private var sortOption: SortOption {
        get { SortOption(rawValue: sortOptionRaw) ?? .name }
        set { sortOptionRaw = newValue.rawValue }
    }
    
    private var displayedSkills: [ExemplarySkill] {
        switch sortOption {
        case .name:
            return exemplarySkills.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        case .category:
            return exemplarySkills.sorted {
                if $0.category.caseInsensitiveCompare($1.category) == .orderedSame {
                    return $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending
                }
                return $0.category.localizedCaseInsensitiveCompare($1.category) == .orderedAscending
            }
        case .starsAsc:
            return exemplarySkills.sorted {
                let a = $0.userRating ?? 0
                let b = $1.userRating ?? 0
                if a == b { return $0.title < $1.title }
                return a < b
            }
        case .starsDesc:
            return exemplarySkills.sorted {
                let a = $0.userRating ?? 0
                let b = $1.userRating ?? 0
                if a == b { return $0.title < $1.title }
                return a > b
            }
        case .difficultyAsc:
            return exemplarySkills.sorted {
                if $0.difficultyLevel == $1.difficultyLevel { return $0.title < $1.title }
                return $0.difficultyLevel < $1.difficultyLevel
            }
        case .difficultyDesc:
            return exemplarySkills.sorted {
                if $0.difficultyLevel == $1.difficultyLevel { return $0.title < $1.title }
                return $0.difficultyLevel > $1.difficultyLevel
            }
        case .completedAsc:
            return exemplarySkills.sorted { a, b in
                switch (a.obtainedAt, b.obtainedAt) {
                case (nil, nil):
                    return a.title < b.title
                case (nil, _?):
                    return false // nil last
                case (_?, nil):
                    return true  // non-nil first
                case let (da?, db?):
                    if da == db { return a.title < b.title }
                    return da < db
                }
            }
        case .completedDesc:
            return exemplarySkills.sorted { a, b in
                switch (a.obtainedAt, b.obtainedAt) {
                case (nil, nil):
                    return a.title < b.title
                case (nil, _?):
                    return false // nil last
                case (_?, nil):
                    return true  // non-nil first
                case let (da?, db?):
                    if da == db { return a.title < b.title }
                    return da > db
                }
            }
        }
    }
    private var visibleSkills: [ExemplarySkill] { displayedSkills.filter { !$0.isHidden } }
    private var archivedSkills: [ExemplarySkill] { displayedSkills.filter { $0.isHidden } }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header with daily limit info and sorting
                HStack {
                    Text(String(format: NSLocalizedString("daily_evaluations_format", comment: ""), dailyEvaluationsCount, ExemplarySkillConstants.dailyEvaluationLimit))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Menu {
                        ForEach(SortOption.allCases, id: \.self) { option in
                            Button(option.localizedTitle) { sortOptionRaw = option.rawValue }
                        }
                    } label: {
                        Label(LocalizedStringKey("sort_menu_label"), systemImage: "arrow.up.arrow.down")
                            .font(.caption)
                    }
                    
                    Button(LocalizedStringKey("reset_daily_limit")) {
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
                        ForEach(visibleSkills) { skill in
                            ZStack(alignment: .topTrailing) {
                                ExemplarySkillCard(skill: skill) {
                                    selectedSkill = skill
                                }
                                if skill.isUserCreated {
                                    Menu {
                                        Button(LocalizedStringKey("hide")) { skill.isHidden = true; try? context.save() }
                                        Button(LocalizedStringKey("delete_skill"), role: .destructive) {
                                            pendingDelete = skill
                                            showingDeleteConfirm = true
                                        }
                                    } label: {
                                        Image(systemName: "ellipsis.circle")
                                            .foregroundColor(.gray)
                                            .padding(6)
                                            .background(.ultraThinMaterial, in: Circle())
                                    }
                                    .buttonStyle(.plain)
                                    .padding(6)
                                } else {
                                    Menu {
                                        Button(LocalizedStringKey("hide")) { skill.isHidden = true; try? context.save() }
                                    } label: {
                                        Image(systemName: "ellipsis.circle")
                                            .foregroundColor(.gray)
                                            .padding(6)
                                            .background(.ultraThinMaterial, in: Circle())
                                    }
                                    .buttonStyle(.plain)
                                    .padding(6)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 3)
                    .padding(.vertical, 3)
                    if !archivedSkills.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(LocalizedStringKey("archived_section")).font(.headline).padding(.horizontal)
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 3), count: 3), spacing: 3) {
                                ForEach(archivedSkills) { skill in
                                    ZStack(alignment: .topTrailing) {
                                        ExemplarySkillCard(skill: skill) { selectedSkill = skill }
                                        Button(LocalizedStringKey("unhide")) { skill.isHidden = false; try? context.save() }
                                            .buttonStyle(.bordered)
                                            .tint(.gray)
                                            .padding(6)
                                    }
                                }
                            }
                            .padding(.horizontal, 3)
                        }
                    }
                }
            }
            .navigationTitle(LocalizedStringKey("exemplary_skills_title"))
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
            .alert(LocalizedStringKey("daily_limit_reached_title"), isPresented: $showingDailyLimitAlert) {
                Button(LocalizedStringKey("ok")) { }
            } message: {
                Text(String(format: NSLocalizedString("daily_limit_reached_message_format", comment: ""), ExemplarySkillConstants.dailyEvaluationLimit))
            }
            .background(deleteConfirmDialog)
        }
    }

    @State private var showingDeleteConfirm: Bool = false
    @State private var pendingDelete: ExemplarySkill?
    private func deleteSkill(_ skill: ExemplarySkill) {
        context.delete(skill)
        try? context.save()
    }
}
extension ExemplarySkillsView {
    @ViewBuilder
    private var deleteConfirmDialog: some View {
        EmptyView()
            .confirmationDialog(
                LocalizedStringKey("delete_confirm_title"),
                isPresented: $showingDeleteConfirm,
                titleVisibility: .visible
            ) {
                Button(LocalizedStringKey("delete_confirm_action"), role: .destructive) {
                    if let skill = pendingDelete { deleteSkill(skill) }
                    pendingDelete = nil
                }
                Button(LocalizedStringKey("cancel"), role: .cancel) {
                    pendingDelete = nil
                }
            } message: {
                Text(LocalizedStringKey("delete_confirm_message"))
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
