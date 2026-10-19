//
//  ProgressBarCompact.swift
//  TimeToSkill
//
//  Created by Grzegorz Kulesza on 10/04/2025.
//

/// Compact progress bar used in Top Skills
///
import SwiftUI

struct ProgressBarCompact: View {
    let hours: Double

    var progressColor: Color {
        SkillProgressView.progressColor(for: hours)
    }

    var progress: Double {
        ProgressFill.fraction(value: hours)
    }

    var body: some View {
        CrystalProgressBar(progress: progress, hours: hours, height: 10, animated: true)
    }
}
