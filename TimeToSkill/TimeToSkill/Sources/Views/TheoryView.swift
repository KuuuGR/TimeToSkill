//
//  TheoryView.swift
//  TimeToSkill
//
//  Created by Grzegorz Kulesza on 06/04/2025.
//

import SwiftUI

struct TheoryView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text(LocalizedStringKey("theory_title"))
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top)

                // 0–21 hours
                TheoryCard(
                    icon: "⚡",
                    title: NSLocalizedString("theory_20_title", comment: ""),
                    author: NSLocalizedString("theory_20_author", comment: ""),
                    description: NSLocalizedString("theory_20_description", comment: ""),
                    worksFor: NSLocalizedString("theory_20_works", comment: ""),
                    borderColor: AppColors.tertiary
                )

                // 21–100 hours
                TheoryCard(
                    icon: "🧠",
                    title: NSLocalizedString("theory_100_title", comment: ""),
                    author: NSLocalizedString("theory_100_author", comment: ""),
                    description: NSLocalizedString("theory_100_description", comment: ""),
                    worksFor: NSLocalizedString("theory_100_works", comment: ""),
                    borderColor: AppColors.secondary
                )

                // 100–1000 hours
                TheoryCard(
                    icon: "🌀",
                    title: NSLocalizedString("theory_1000_title", comment: ""),
                    author: NSLocalizedString("theory_1000_author", comment: ""),
                    description: NSLocalizedString("theory_1000_description", comment: ""),
                    worksFor: NSLocalizedString("theory_1000_works", comment: ""),
                    borderColor: AppColors.primary
                )

                // 1000–10000 hours
                TheoryCard(
                    icon: "🔥",
                    title: NSLocalizedString("theory_10k_title", comment: ""),
                    author: NSLocalizedString("theory_10k_author", comment: ""),
                    description: NSLocalizedString("theory_10k_description", comment: ""),
                    worksFor: NSLocalizedString("theory_10k_works", comment: ""),
                    borderColor: AppColors.error
                )

                VStack(alignment: .leading, spacing: 12) {
                    Text(LocalizedStringKey("theory_comparison_title"))
                        .font(.title3)
                        .fontWeight(.semibold)

                    Text(LocalizedStringKey("theory_comparison_text"))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.bottom, 40)
            }
            .padding(.horizontal)
        }
        .navigationTitle(LocalizedStringKey("theory_nav_title"))
    }
}

import SwiftUI

struct TheoryCard: View {
    let icon: String
    let title: String
    let author: String
    let description: String
    let worksFor: String
    let borderColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Text(icon)
                    .font(.largeTitle)
                VStack(alignment: .leading) {
                    Text(title)
                        .font(.title3)
                        .fontWeight(.semibold)
                    Text(author)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Text(description)
                .font(.body)

            Text(worksFor)
                .font(.footnote)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(borderColor, lineWidth: 2)
        )
        .shadow(radius: 4, y: 2)
    }
}
