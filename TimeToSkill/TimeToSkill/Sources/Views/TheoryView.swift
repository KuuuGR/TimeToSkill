//
//  TheoryView.swift
//  TimeToSkill
//
//  Ideas about learning. Summaries stay on this page. Research records open
//  in a sheet. Progress-hour marks are labeled as milestones, not as proof
//  of mastery. The 21-hour progress band is unchanged.

import SwiftUI

struct TheoryView: View {
    @State private var selectedTopic: TheoryTopic?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(LocalizedStringKey("theory_title"))
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top)

                Text(LocalizedStringKey("theory_intro"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                ForEach(TheoryCatalog.topics) { topic in
                    TheoryCard(topic: topic) {
                        selectedTopic = topic
                    }
                }

                milestones
            }
            .padding(.horizontal)
            .padding(.bottom, 40)
            .macOSContentWidth(700)
        }
        .navigationTitle(LocalizedStringKey("theory_nav_title"))
        .sheet(item: $selectedTopic) { topic in
            NavigationStack {
                TheoryDetailView(topic: topic)
            }
        }
    }

    private var milestones: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(LocalizedStringKey("theory_milestones_title"))
                .font(.title3)
                .fontWeight(.semibold)

            Text(LocalizedStringKey("theory_milestones_note"))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            ForEach(TheoryCatalog.milestones) { milestone in
                VStack(alignment: .leading, spacing: 2) {
                    Text(LocalizedStringKey(milestone.titleKey))
                        .font(.headline)
                    Text(LocalizedStringKey("theory_milestone_note"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.vertical, 4)
                .accessibilityElement(children: .combine)
            }
        }
        .padding(.top, 8)
    }
}
