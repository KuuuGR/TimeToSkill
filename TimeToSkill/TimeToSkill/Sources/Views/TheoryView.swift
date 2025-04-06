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
            VStack(alignment: .leading, spacing: 20) {
                Text("21 Hour Rule")
                    .font(.title)
                Text("It takes 21 hours of focused practice to go from knowing nothing to being reasonably good.")
                
                Text("10,000 Hour Rule")
                    .font(.title)
                    .padding(.top)
                Text("The concept from Malcolm Gladwell's book suggesting it takes 10,000 hours to achieve mastery.")
            }
            .padding()
        }
        .navigationTitle("Theory")
    }
}
