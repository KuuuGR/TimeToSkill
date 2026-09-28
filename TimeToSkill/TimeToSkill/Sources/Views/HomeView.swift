//
//  HomeView.swift
//  TimeToSkill
//
//  iPhone / iPad home surface. Navigation stays exactly as before (a
//  `NavigationStack` plus the existing sheets); only the presentation is
//  adjusted: a branded hero with one primary action, and the remaining
//  sections as compact cards. The macOS counterpart is `MacRootView`.
//

#if !os(macOS)

import SwiftUI
import SwiftData

/// Sections offered as shortcut cards on the home screen. Each one maps to a
/// view that already existed in the app - nothing new is introduced.
enum HomeSection: String, CaseIterable, Identifiable {
    case counters, theory, skills, about

    var id: String { rawValue }

    var titleKey: LocalizedStringKey {
        switch self {
        case .counters: return "main_manage_counters"
        case .theory: return "main_learning_theory"
        case .skills: return "main_exemplary_skills"
        case .about: return "main_about_app"
        }
    }

    var systemImage: String {
        switch self {
        case .counters: return "number"
        case .theory: return "book"
        case .skills: return "star.fill"
        case .about: return "info.circle"
        }
    }

    @ViewBuilder var destination: some View {
        switch self {
        case .counters: ManageCountersView()
        case .theory: TheoryView()
        case .skills: ExemplarySkillsView()
        case .about: AboutView()
        }
    }
}

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Query private var skills: [Skill]

    @State private var selectedQuote: Quote? = nil
    @State private var showingOptions = false
    @State private var showingStats = false
    @State private var showingCustomSkillSheet: Bool = false
    @AppStorage("hasSeenFABAnimation") private var hasSeenFABAnimation = false
    @State private var animateFAB = false

    private let backgroundAnimation: BackgroundAnimationType = .staticCircle

    /// iPad gets a two-column card grid and a wider measure instead of a
    /// stretched iPhone column.
    private var isWideLayout: Bool { horizontalSizeClass == .regular }

    private var cardColumns: [GridItem] {
        isWideLayout
            ? [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
            : [GridItem(.flexible())]
    }

    private var contentMaxWidth: CGFloat { isWideLayout ? 720 : 520 }

    private var totalTrackedHours: Double {
        skills.reduce(0) { $0 + $1.effectiveHours(at: Date()) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground(animationType: backgroundAnimation)

                ScrollView {
                    VStack(spacing: 20) {
                        hero
                        quoteCard
                        sectionCards
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                    .padding(.bottom, 130)
                    .frame(maxWidth: contentMaxWidth)
                    .frame(maxWidth: .infinity)
                }

                floatingActions
            }
            .hiddenNavigationBar()
            .navigationTitle(LocalizedStringKey("ab_app_name"))
        }
        .onAppear(perform: prepareHome)
        .sheet(isPresented: $showingStats) {
            StatsView()
        }
        .sheet(isPresented: $showingOptions) {
            OptionsView()
        }
        .sheet(isPresented: $showingCustomSkillSheet) {
            CustomExemplarySkillSheet { title, description, category, difficulty, one, two, three, imagePath in
                let model = ExemplarySkill(
                    isUserCreated: true,
                    title: title,
                    skillDescription: description,
                    imageName: imagePath ?? "star.fill",
                    category: category.isEmpty ? "Custom" : category,
                    difficultyLevel: difficulty,
                    oneStarDescription: one,
                    twoStarDescription: two,
                    threeStarDescription: three
                )
                modelContext.insert(model)
                try? modelContext.save()
            }
        }
    }
    // MARK: - Hero

    /// Headline, one-line introduction and a single primary action / progress
    /// point. The brand mark lives on the splash screen only, so the title sits
    /// as high as possible on small iPhones.
    private var hero: some View {
        VStack(spacing: 14) {
            Text("ab_app_name")
                .font(AppTypography.display)
                .foregroundColor(AppColors.onSurface)
                .multilineTextAlignment(.center)

            Text(LocalizedStringKey("home_hero_intro"))
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 8)

            Text(String(
                format: NSLocalizedString("time_total_hours_format", comment: "Total tracked time"),
                formatHours(totalTrackedHours)
            ))
            .font(.title3.weight(.semibold))
            .monospacedDigit()
            .foregroundColor(AppColors.onSurface)
            .accessibilityIdentifier("HomeTotalTrackedLabel")

            NavigationLink(destination: StartView()) {
                Label(LocalizedStringKey("main_manage_trackers"), systemImage: "bolt.fill")
                    .font(AppTypography.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(AppColors.accent)
            .padding(.top, 4)
        }
        .padding(.vertical, 24)
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(AppColors.surface.opacity(0.55))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(AppColors.hairline, lineWidth: 1)
        )
    }

    // MARK: - Quote (existing content, quieter presentation)

    @ViewBuilder
    private var quoteCard: some View {
        if let quote = selectedQuote {
            VStack(alignment: .center, spacing: 6) {
                Text("“\(quote.quote)”")
                    .font(.footnote)
                    .italic()
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .minimumScaleFactor(0.8)

                Text("- \(quote.author)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity)
            .transition(.opacity)
        }
    }

    // MARK: - Section shortcuts

    private var sectionCards: some View {
        LazyVGrid(columns: cardColumns, spacing: 12) {
            ForEach(HomeSection.allCases) { section in
                NavigationLink(destination: section.destination) {
                    HomeSectionCard(section: section)
                }
                .buttonStyle(.plain)
            }
        }
    }
    // MARK: - Floating actions (unchanged iOS pattern)

    private var floatingActions: some View {
        VStack {
            Spacer()
            HStack {
                // Options FAB (left side)
                FABButton(
                    icon: "ellipsis",
                    action: { showingOptions = true },
                    accessibilityLabelKey: "fab_options"
                )
                .padding(20)

                Spacer()

                // Center FAB (create custom skill)
                FABButton(
                    icon: "star",
                    action: { showingCustomSkillSheet = true },
                    backgroundColor: .purple,
                    size: 60,
                    animatePulse: false,
                    accessibilityLabelKey: "fab_add_custom_skill"
                )
                .padding(.vertical, 20)

                Spacer()

                // Stats FAB (right side)
                FABButton(
                    icon: "chart.bar.fill",
                    action: {
                        showingStats = true
                        hasSeenFABAnimation = true
                    },
                    backgroundColor: .warningDark,
                    size: 64,
                    animatePulse: !hasSeenFABAnimation,
                    accessibilityLabelKey: "fab_view_stats"
                )
                .padding(20)
            }
            .frame(maxWidth: contentMaxWidth)
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Helpers

    private func prepareHome() {
        let quotes = QuoteLoader.loadLocalizedQuotes()
        if let random = quotes.randomElement() {
            selectedQuote = random
        }

        // Trigger subtle animation if needed
        if !hasSeenFABAnimation {
            withAnimation(Animation.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                animateFAB = true
            }
        }
    }

    private func formatHours(_ hours: Double) -> String {
        let safeHours = hours.isFinite && !hours.isNaN ? hours : 0
        return String(format: "%.1f", safeHours)
    }
}

/// Compact shortcut card used by the home screen.
private struct HomeSectionCard: View {
    let section: HomeSection

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: section.systemImage)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(AppColors.accent)
                .frame(width: 34, height: 34)
                .background(
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .fill(AppColors.accent.opacity(0.14))
                )
                .accessibilityHidden(true)

            Text(section.titleKey)
                .font(AppTypography.headline)
                .foregroundColor(AppColors.onSurface)
                .multilineTextAlignment(.leading)

            Spacer(minLength: 8)

            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundColor(Color.secondary.opacity(0.6))
                .accessibilityHidden(true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(AppColors.surface.opacity(0.55))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(AppColors.hairline, lineWidth: 1)
        )
    }
}

#endif
