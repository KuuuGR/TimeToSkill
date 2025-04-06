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
                Text("Teorie czasu nauki")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top)

                TheoryCard(
                    icon: "🔥",
                    title: "Zasada 10 000 godzin",
                    author: "Malcolm Gladwell (na podstawie Andersa Ericssona)",
                    description: """
Twierdzi, że aby osiągnąć mistrzostwo, potrzeba ok. 10 000 godzin celowego treningu. Dotyczy elity (muzycy, sportowcy, szachiści), nie tylko ilości, ale i jakości nauki. Krytykowana za uproszczenia.
""",
                    worksFor: "✔️ Precyzyjne dziedziny, profesjonalna kariera\n✖️ Nieprzydatna dla szybkiego startu"
                )

                TheoryCard(
                    icon: "⚡",
                    title: "Zasada 20/21 godzin",
                    author: "Josh Kaufman",
                    description: """
Wystarczy 20 godzin świadomej nauki, by zacząć cieszyć się nową umiejętnością. Idealna do hobby lub podstaw (np. ukulele, język A1).
""",
                    worksFor: "✔️ Szybki start, hobby\n✖️ Nie prowadzi do mistrzostwa"
                )

                TheoryCard(
                    icon: "🧠",
                    title: "Zasada 100 godzin",
                    author: "Nieformalna koncepcja edukacyjna",
                    description: """
Około 100 godzin pozwala osiągnąć solidną biegłość – idealna do zdobycia nowych zawodowych kompetencji, np. framework czy nowy język programowania.
""",
                    worksFor: "✔️ Praktyczne kompetencje, przekwalifikowanie\n✖️ Nie wystarczy do eksperckiego poziomu"
                )

                TheoryCard(
                    icon: "🌀",
                    title: "Zasada 1000 godzin",
                    author: "Popularna wśród mentorów IT, języków, freelancingu",
                    description: """
1000 godzin intensywnego treningu wystarczy, by być zawodowym ekspertem. Świetna do osiągnięcia zawodowej niezależności w IT, tłumaczenia, sztuce cyfrowej.
""",
                    worksFor: "✔️ Ekspert zawodowy, własne projekty\n✖️ Nie elita światowa"
                )

                VStack(alignment: .leading, spacing: 12) {
                    Text("📈 Porównanie")
                        .font(.title3)
                        .fontWeight(.semibold)

                    Text("""
• 20 godzin → Dobry start (Amator)
• 100 godzin → Solidna biegłość (Zaaw. pocz.)
• 1000 godzin → Mistrz praktyki (Zawodowiec)
• 10 000 godzin → Mistrzostwo (Elita)
""")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.bottom, 40)
            }
            .padding(.horizontal)
        }
        .navigationTitle("Teoria nauki")
    }
}

struct TheoryCard: View {
    let icon: String
    let title: String
    let author: String
    let description: String
    let worksFor: String

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
                .foregroundColor(.green)
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .shadow(radius: 4, y: 2)
    }
}
