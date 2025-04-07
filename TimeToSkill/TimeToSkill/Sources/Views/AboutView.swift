//
//  AboutView.swift
//  TimeToSkill
//
//  Created by Grzegorz Kulesza on 06/04/2025.
//

import SwiftUI

struct AboutView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("TimeToSkill")
                    .font(.largeTitle.bold())
                    .foregroundColor(AppColors.primary)
                    .padding(.top)

                AboutSection(title: "ab_section_about_app", items: [
                    "ab_app_name", "ab_version", "ab_developer"
                ])

                AboutSection(title: "ab_section_purpose", items: [
                    "ab_purpose_major_system",
                    "ab_purpose_large_numbers",
                    "ab_purpose_dates",
                    "ab_purpose_words"
                ])

                AboutSection(title: "ab_section_support", items: []) {
                    NavigationLink(destination: SupportDeveloperView()) {
                        Label(
                            NSLocalizedString("ab_support_developer", comment: ""),
                            systemImage: "heart.fill"
                        )
                        .foregroundColor(AppColors.onPrimary)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(AppColors.primary)
                        .cornerRadius(12)
                    }
                }

                Spacer()
            }
            .padding()
        }
        .navigationTitle(LocalizedStringKey("ab_navigation_title"))
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
                Text(LocalizedStringKey(key))
                    .font(.body)
                    .foregroundColor(AppColors.onSurface)
            }

            customContent()
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }
}
