import SwiftUI

struct CounterRing: View {
    let value: Int
    let stageMax: Int?
    
    var progress: Double {
        guard let maxVal = stageMax, maxVal > 0 else { return 0 }
        return min(1.0, max(0.0, Double(value) / Double(maxVal)))
    }
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.black.opacity(0.28), lineWidth: 8)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    AngularGradient(
                        colors: [
                            Color(hex: "#A5E5FF"),
                            Color(hex: "#1677CB"),
                            Color(hex: "#10406F")
                        ],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
            Text("\(Int(progress * 100))%")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}
