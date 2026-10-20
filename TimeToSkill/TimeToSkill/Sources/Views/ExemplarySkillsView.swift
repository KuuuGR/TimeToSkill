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
    
    @AppStorage("ExemplarySkillsSortOption") private var sortOptionRaw: String = CatalogSort.name.rawValue
    @AppStorage("ExemplarySkillsCompletionFilter") private var completionRaw: String = CompletionFilter.all.rawValue
    @AppStorage("ExemplarySkillsFavoriteFilter") private var favoriteRaw: String = FavoriteFilter.all.rawValue
    @AppStorage("ExemplarySkillsOwnershipFilter") private var ownershipRaw: String = OwnershipFilter.all.rawValue
    @State private var searchText: String = ""

    private var catalogQuery: CatalogQuery {
        CatalogQuery(
            text: searchText,
            completion: CompletionFilter(rawValue: completionRaw) ?? .all,
            favorites: FavoriteFilter(rawValue: favoriteRaw) ?? .all,
            ownership: OwnershipFilter(rawValue: ownershipRaw) ?? .all,
            sort: CatalogSort(rawValue: sortOptionRaw) ?? .name
        )
    }

    private var displayedSkills: [ExemplarySkill] {
        let entries = exemplarySkills.map(catalogEntry)
        let orderedIDs = catalogQuery.apply(entries).map(\.id)
        let byID = Dictionary(uniqueKeysWithValues: exemplarySkills.map { ($0.id.uuidString, $0) })
        return orderedIDs.compactMap { byID[$0] }
    }

    private func catalogEntry(_ skill: ExemplarySkill) -> CatalogEntry {
        CatalogEntry(
            id: skill.id.uuidString,
            title: skill.title,
            description: skill.skillDescription,
            category: skill.category,
            levelTexts: [skill.oneStarDescription, skill.twoStarDescription, skill.threeStarDescription],
            isObtained: skill.isObtained,
            obtainedAt: skill.obtainedAt,
            isFavorite: skill.isFavorite,
            rating: skill.userRating ?? 0,
            difficulty: skill.difficultyLevel,
            isUserCreated: skill.isUserCreated
        )
    }

    private var visibleSkills: [ExemplarySkill] { displayedSkills.filter { !$0.isHidden } }
    private var archivedSkills: [ExemplarySkill] { displayedSkills.filter { $0.isHidden } }

    private func resetCatalogQuery() {
        searchText = ""
        completionRaw = CompletionFilter.all.rawValue
        favoriteRaw = FavoriteFilter.all.rawValue
        ownershipRaw = OwnershipFilter.all.rawValue
        sortOptionRaw = CatalogSort.name.rawValue
    }

    /// macOS lets the window be any width, so the number of grid columns follows
    /// the available space instead of always forcing a phone-style three-across.
    private var gridColumns: [GridItem] {
        #if os(macOS)
        [GridItem(.adaptive(minimum: 140, maximum: 190), spacing: 8)]
        #else
        Array(repeating: GridItem(.flexible(), spacing: 3), count: 3)
        #endif
    }
    
    var body: some View {
        VStack(spacing: 0) {
            catalogControls
                .padding(.horizontal)
                .padding(.top, 8)

            LText(key: "catalog_exemplary_note")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                .padding(.top, 8)
                .accessibilityIdentifier("CatalogExemplaryNote")

            // Only the grid scrolls. The header stays put, and the scroll
            // view takes the height the window actually offered instead of
            // growing to the full catalog.
            ScrollView {
                    if visibleSkills.isEmpty {
                        Text(verbatim: L10n.string(catalogQuery.emptyStateKey))
                            .font(.callout)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                            .padding(.top, 12)
                            .accessibilityIdentifier("CatalogNoResults")
                    }
                    LazyVGrid(columns: gridColumns, spacing: 3) {
                        ForEach(visibleSkills) { skill in
                            ZStack(alignment: .topTrailing) {
                                ExemplarySkillCard(skill: skill) {
                                    selectedSkill = skill
                                }
                                if skill.isUserCreated {
                                    Menu {
                                        Button(L10n.string("hide")) { skill.isHidden = true; try? context.save() }
                                        Button(L10n.string("delete_skill"), role: .destructive) {
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
                                        Button(L10n.string("hide")) { skill.isHidden = true; try? context.save() }
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
                            .overlay(alignment: .topLeading) {
                                favoriteButton(skill)
                            }
                        }
                    }
                    .padding(.horizontal, 3)
                    .padding(.vertical, 3)
                    .macOSContentWidth(760)
                    if !archivedSkills.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            LText(key: "archived_section").font(.headline).padding(.horizontal)
                            LazyVGrid(columns: gridColumns, spacing: 3) {
                                ForEach(archivedSkills) { skill in
                                    ZStack(alignment: .topTrailing) {
                                        ExemplarySkillCard(skill: skill) { selectedSkill = skill }
                                        Button(L10n.string("unhide")) { skill.isHidden = false; try? context.save() }
                                            .buttonStyle(.bordered)
                                            .tint(.gray)
                                            .padding(6)
                                    }
                                    .overlay(alignment: .topLeading) {
                                        favoriteButton(skill)
                                    }
                                }
                            }
                            .padding(.horizontal, 3)
                        }
                        .macOSContentWidth(760)
                    }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .accessibilityIdentifier("CatalogSkillList")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle(Text(verbatim: L10n.string("exemplary_skills_title")))

        .onAppear {
            loadDailyEvaluationsCount()
            SkillSeeder.seedIfNeeded(context: context)
            PreviewProgressSeeder.apply(context: context)
        }
        .modifier(CatalogSkillPresentation(selectedSkill: $selectedSkill, evaluate: evaluateSkill))
        .alert(L10n.string("daily_limit_reached_title"), isPresented: $showingDailyLimitAlert) {
                Button(L10n.string("ok")) { }
            } message: {
                Text(String(format: L10n.string("daily_limit_reached_message_format"), ExemplarySkillConstants.dailyEvaluationLimit))
            }
            .background(deleteConfirmDialog)
    }

    @State private var showingDeleteConfirm: Bool = false
    @State private var pendingDelete: ExemplarySkill?
    private func deleteSkill(_ skill: ExemplarySkill) {
        context.delete(skill)
        try? context.save()
    }
}
extension ExemplarySkillsView {
    private var catalogControls: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("", text: $searchText, prompt: Text(verbatim: L10n.string("catalog_search_prompt")))
                    .textFieldStyle(.plain)
                    .accessibilityIdentifier("CatalogSearchField")
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Text(verbatim: L10n.string("catalog_filter_reset")))
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))

            // A nested horizontal scroller here swallows the mouse wheel on
            // macOS even when the chips already fit. Prefer a plain row.
            ViewThatFits(in: .horizontal) {
                chipRow
                ScrollView(.horizontal, showsIndicators: false) {
                    chipRow
                }
            }

            HStack(spacing: 12) {
                Menu {
                    ForEach(CatalogSort.allCases, id: \.self) { option in
                        Button {
                            sortOptionRaw = option.rawValue
                        } label: {
                            Text(verbatim: option.localizedTitle)
                        }
                    }
                } label: {
                    Label { Text(verbatim: L10n.string("sort_menu_label")) } icon: { Image(systemName: "arrow.up.arrow.down") }
                        .font(.caption)
                }
                .accessibilityIdentifier("CatalogSortMenu")
                if !catalogQuery.isDefault {
                    Button(action: resetCatalogQuery) {
                        Text(verbatim: L10n.string("catalog_filter_reset"))
                    }
                        .font(.caption)
                        .accessibilityIdentifier("CatalogResetFilters")
                }
            }

            HStack {
                Text(String(format: L10n.string("daily_evaluations_format"), dailyEvaluationsCount, ExemplarySkillConstants.dailyEvaluationLimit))
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Button { resetDailyLimit() } label: {
                    Text(verbatim: L10n.string("reset_daily_limit"))
                }
                    .font(.caption)
                    .foregroundColor(.blue)
                    .macOSLinkButtonStyle()
            }
        }
    }

    private var chipRow: some View {
        HStack(spacing: 8) {
            catalogChip(L10n.string("catalog_filter_all"), selected: completionRaw == CompletionFilter.all.rawValue) {
                completionRaw = CompletionFilter.all.rawValue
            }
            catalogChip(L10n.string("catalog_filter_done"), selected: completionRaw == CompletionFilter.done.rawValue) {
                completionRaw = CompletionFilter.done.rawValue
            }
            catalogChip(L10n.string("catalog_filter_not_done"), selected: completionRaw == CompletionFilter.notDone.rawValue) {
                completionRaw = CompletionFilter.notDone.rawValue
            }
            catalogChip(L10n.string("catalog_favorites_only"), selected: favoriteRaw == FavoriteFilter.favorites.rawValue) {
                favoriteRaw = favoriteRaw == FavoriteFilter.favorites.rawValue
                    ? FavoriteFilter.all.rawValue
                    : FavoriteFilter.favorites.rawValue
            }
            catalogChip(L10n.string("catalog_filter_custom"), selected: ownershipRaw == OwnershipFilter.custom.rawValue) {
                ownershipRaw = ownershipRaw == OwnershipFilter.custom.rawValue
                    ? OwnershipFilter.all.rawValue
                    : OwnershipFilter.custom.rawValue
            }
        }
    }

    private func catalogChip(_ title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(verbatim: title)
                .font(.caption)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(selected ? Color.brandAccent.opacity(0.22) : Color.primary.opacity(0.06), in: Capsule())
                .overlay(Capsule().stroke(selected ? Color.brandAccent.opacity(0.7) : Color.primary.opacity(0.12), lineWidth: 0.7))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private func favoriteButton(_ skill: ExemplarySkill) -> some View {
        Button {
            skill.isFavorite.toggle()
            try? context.save()
        } label: {
            Image(systemName: skill.isFavorite ? "heart.fill" : "heart")
                .font(.caption)
                .foregroundColor(skill.isFavorite ? Color.brandAccent : .secondary)
                .padding(6)
                .background(.ultraThinMaterial, in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(verbatim: L10n.string(skill.isFavorite ? "catalog_favorite_remove" : "catalog_favorite_add")))
        .accessibilityIdentifier("CatalogFavoriteButton_\(skill.id.uuidString)")
    }

    @ViewBuilder
    private var deleteConfirmDialog: some View {
        EmptyView()
            .confirmationDialog(
                Text(verbatim: L10n.string("delete_confirm_title")),
                isPresented: $showingDeleteConfirm,
                titleVisibility: .visible
            ) {
                Button(role: .destructive) {
                    if let skill = pendingDelete { deleteSkill(skill) }
                    pendingDelete = nil
                } label: {
                    Text(verbatim: L10n.string("delete_confirm_action"))
                }
                Button(role: .cancel) {
                    pendingDelete = nil
                } label: {
                    Text(verbatim: L10n.string("cancel"))
                }
            } message: {
                LText(key: "delete_confirm_message")
            }
    }
}

/// macOS keeps the skill inside the sidebar's detail column, so the section
/// stays selected and the system back button returns to the catalog.
/// iPhone and iPad keep the existing sheet.
private struct CatalogSkillPresentation: ViewModifier {
    @Binding var selectedSkill: ExemplarySkill?
    let evaluate: (ExemplarySkill, Int, String) -> Void

    func body(content: Content) -> some View {
        #if os(macOS)
        content.navigationDestination(item: $selectedSkill) { skill in
            detail(for: skill)
        }
        #else
        content.sheet(item: $selectedSkill) { skill in
            NavigationStack {
                detail(for: skill)
            }
        }
        #endif
    }

    private func detail(for skill: ExemplarySkill) -> some View {
        ExemplarySkillDetailView(skill: skill) { rating, verificationCode in
            evaluate(skill, rating, verificationCode)
        }
    }
}

extension ExemplarySkillsView {
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
