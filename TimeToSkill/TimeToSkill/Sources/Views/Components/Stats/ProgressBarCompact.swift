//
//  ProgressBarCompact.swift
//  TimeToSkill
//
//  Created by admin on 10/04/2025.
//

/// Compact progress bar used in Top Skills
///
import SwiftUI

struct ProgressBarCompact: View {
    let hours: Double

    var progressColor: Color {
        switch hours {
        case ..<0: return .trueGray
        case 0..<21: return .success
        case 21..<100: return .infoDark
        case 100..<1000: return .warningDark
        case 1000..<10000: return .danger
        case 10000..<100000: return .purple
        default: return .black
        }
    }

    var progress: Double {
        switch hours {
        case ..<0: return 0
        case 0..<21: return hours / 21
        case 21..<100: return hours / 100
        case 100..<1000: return hours / 1000
        case 1000..<10000: return hours / 10000
        case 10000..<100000: return hours / 100000
        default: return 1
        }
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .frame(height: 10)
                    .foregroundColor(.gray.opacity(0.15))

                Capsule()
                    .frame(
                        width: geo.size.width * CGFloat(min(progress, 1)),
                        height: 10
                    )
                    .foregroundColor(progressColor)
                    .animation(.easeInOut(duration: 0.5), value: hours)
            }
        }
        .frame(height: 10)
    }
}