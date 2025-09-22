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
                .stroke(Color.gray.opacity(0.2), lineWidth: 8)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(AngularGradient(gradient: Gradient(colors: [.green, .yellow, .orange, .red]), center: .center), style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text("\(Int(progress * 100))%")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}
