//
//  MainView.swift
//  TimeToSkill
//

//
//  MainView.swift
//  TimeToSkill
//

import SwiftUI

struct MainView: View {
    @State private var selectedQuote: Quote? = nil
    @State private var showStats = false
    @AppStorage("hasSeenFABAnimation") private var hasSeenFABAnimation = false
    @State private var animateFAB = false
    @State private var showingOptions = false
    @State private var showingStats = false
    @AppStorage("customSkillUnlocked") private var customSkillUnlocked: Bool = false
    @State private var showingPaywall: Bool = false
    @State private var showingCustomSkillSheet: Bool = false
    @Environment(\.modelContext) private var modelContext

    private let backgroundAnimation: BackgroundAnimationType = .staticCircle

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground(animationType: backgroundAnimation)

                ScrollView {
                    VStack(spacing: 24) {
                        Text("TimeToSkill")
                            .font(AppTypography.display)
                            .foregroundColor(AppColors.onSurface)
                            .padding(.top, 40)

                        if let quote = selectedQuote {
                            VStack(alignment: .center, spacing: 6) {
                                Text("“\(quote.quote)”")
                                    .font(.body)
                                    .italic()
                                    .multilineTextAlignment(.center)
                                    .foregroundColor(AppColors.onSurface)
                                    .padding(.horizontal, 24)
                                    .minimumScaleFactor(0.8)

                                Text("- \(quote.author)")
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.top, 8)
                            .transition(.opacity)
                            .frame(maxWidth: .infinity)
                        }

                        VStack(spacing: 16) {
                            NavigationLink(destination: StartView()) {
                                Label {
                                    Text(LocalizedStringKey("main_manage_trackers"))
                                        .font(AppTypography.headline)
                                } icon: {
                                    Image(systemName: "bolt.fill")
                                        .font(.headline)
                                }
                            }
                            .buttonStyle(
                                FancyButtonStyle(
                                    background: .gold,
                                    gradientEnd: .darkGold,
                                    cornerRadius: 18,
                                    shadow: .black.opacity(0.25),
                                    shadowRadius: 10
                                )
                            )

                            NavigationLink(destination: ManageCountersView()) {
                                Label {
                                    Text(LocalizedStringKey("main_manage_counters"))
                                        .font(AppTypography.headline)
                                } icon: {
                                    Image(systemName: "number")
                                        .font(.headline)
                                }
                            }
                            .buttonStyle(FancyButtonStyle(background: .info, gradientEnd: .infoDark))

                            Spacer().frame(height: 12)

                            NavigationLink(destination: TheoryView()) {
                                Text(LocalizedStringKey("main_learning_theory"))
                            }
                            .buttonStyle(FancyButtonStyle(background: .mdbBlue, gradientEnd: .info))

                            NavigationLink(destination: ExemplarySkillsView()) {
                                Label {
                                    Text(LocalizedStringKey("main_exemplary_skills"))
                                        .font(AppTypography.headline)
                                } icon: {
                                    Image(systemName: "star.fill")
                                        .font(.headline)
                                }
                            }
                            .buttonStyle(FancyButtonStyle(background: .purple, gradientEnd: .purple.opacity(0.7)))

                            NavigationLink(destination: AboutView()) {
                                Text(LocalizedStringKey("main_about_app"))
                            }
                            .buttonStyle(FancyButtonStyle(background: .mdbBlue, gradientEnd: .infoDark))
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(AppColors.surface.opacity(0.7))
                                .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
                        )
                        .padding(.horizontal, 20)
                        .padding(.top, 40)

                        Spacer()
                    }
                }

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
                        
                        // Center FAB (paywalled custom skill)
                        FABButton(
                            icon: customSkillUnlocked ? "star" : "lock",
                            action: {
                                if customSkillUnlocked { showingCustomSkillSheet = true } else { showingPaywall = true }
                            },
                            backgroundColor: customSkillUnlocked ? .purple : .gray,
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
                }
            }
            .navigationBarHidden(true)
        }
        .onAppear {
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
        .sheet(isPresented: $showingStats) {
            StatsView()
        }
        .sheet(isPresented: $showingOptions) {
            OptionsView()
        }
        .sheet(isPresented: $showingPaywall) {
            DevPaywallView(onUnlock: { customSkillUnlocked = true })
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
}
