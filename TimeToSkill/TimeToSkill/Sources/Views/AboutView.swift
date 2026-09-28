//
//  AboutView.swift
//  TimeToSkill
//
//  Created by Grzegorz Kulesza on 06/04/2025.
//

import SwiftUI

struct AboutView: View {
    private static let wikiURL = "https://github.com/GKulesza/Time4Skill/wiki"
    private static let privacyPolicyURL = URL(string: "\(wikiURL)#privacy")!
    private static let termsOfUseURL = URL(string: "\(wikiURL)#welcome-to-time4skill")!
    private static let supportURL = URL(string: "\(wikiURL)/Support")!

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                BrandMark(size: 84, wordmarkFont: .largeTitle.bold(), showsBorder: false)
                    .padding(.top)

                AboutSection(title: "ab_section_about_app", items: [
                    "ab_app_name",
                    String(format: NSLocalizedString("ab_version", comment: "Version format string"), appVersion),
                    "ab_developer"
                ])

                AboutSection(title: "ab_section_purpose", items: [
                    "ab_purpose_major_system",
                    "ab_purpose_large_numbers",
                    "ab_purpose_dates",
                    "ab_purpose_words"
                ])

                AboutSection(title: "ab_section_support", items: []) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "envelope.fill")
                                .foregroundColor(AppColors.primary)
                            Text("etaosin@gmail.com")
                                .foregroundColor(AppColors.onSurface)
                                .font(.body)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        // Three wiki links do not fit on one row in every locale
                        // (German, Slovak, ...), so stack them when needed.
                        ViewThatFits(in: .horizontal) {
                            HStack(spacing: 16) { supportLinks }
                            VStack(alignment: .leading, spacing: 8) { supportLinks }
                        }
                        .font(.footnote)
                        .foregroundColor(.secondary)
                    }
                }

                Spacer(minLength: 32)
            }
            .padding()
            .macOSContentWidth(700)
        }
        .navigationTitle(LocalizedStringKey("ab_navigation_title"))
    }

    /// The three public wiki links, rendered either in a row or stacked
    /// depending on the width available (see `ViewThatFits` above).
    @ViewBuilder
    private var supportLinks: some View {
        Link(LocalizedStringKey("privacy_policy_link"), destination: Self.privacyPolicyURL)
        Link(LocalizedStringKey("terms_of_use_link"), destination: Self.termsOfUseURL)
        Link(LocalizedStringKey("support_link"), destination: Self.supportURL)
    }
}

struct AboutSection<Content: View>: View {
    let title: String
    let items: [String]
    let customContent: () -> Content

    init(title: String, items: [String], @ViewBuilder customContent: @escaping () -> Content = { EmptyView() }) {
        self.title = title
        self.items = items
        self.customContent = customContent
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(LocalizedStringKey(title))
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(AppColors.primary)

            ForEach(items, id: \.self) { key in
                if key.hasPrefix("ab_") {
                    Text(LocalizedStringKey(key))
                        .font(.body)
                        .foregroundColor(AppColors.onSurface)
                } else {
                    Text(key)
                        .font(.body)
                        .foregroundColor(AppColors.onSurface)
                }
            }

            customContent()
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 6, y: 2)
    }
}
