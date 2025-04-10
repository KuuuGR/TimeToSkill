//
//  TheoryCard.swift
//  TimeToSkill
//
//  Created by admin on 10/04/2025.
//

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
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(borderColor, lineWidth: 2)
        )
        .shadow(radius: 4, y: 2)
    }
}
