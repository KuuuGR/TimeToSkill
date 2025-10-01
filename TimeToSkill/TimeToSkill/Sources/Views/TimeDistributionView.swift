import SwiftUI
import SwiftData

struct TimeDistributionView: View {
    let skill: Skill
    @Environment(\.modelContext) private var context
    @State private var bins: [(range: String, count: Int)] = []
    @State private var totalMinutes: Double = 0
    @State private var meanMinutes: Double = 0
    @State private var stdMinutes: Double = 0
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(LocalizedStringKey("time_distribution_title"))
                    .font(.title2)
                    .bold()
                Text(String(format: NSLocalizedString("time_distribution_skill_format", comment: ""), skill.name))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                // Stats
                VStack(alignment: .leading, spacing: 6) {
                    Text(String(format: NSLocalizedString("time_total_hours_format", comment: ""), formatHours(totalMinutes / 60)))
                    Text(String(format: NSLocalizedString("time_mean_minutes_format", comment: ""), formatMinutes(meanMinutes)))
                    Text(String(format: NSLocalizedString("time_std_minutes_format", comment: ""), formatMinutes(stdMinutes)))
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.gray.opacity(0.08)))
                
                // Histogram bars
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(bins.indices, id: \.self) { i in
                        let bin = bins[i]
                        HStack {
                            Text(bin.range)
                                .font(.caption)
                                .frame(width: 90, alignment: .leading)
                            GeometryReader { geo in
                                let maxCount = max(1, bins.map { $0.1 }.max() ?? 1)
                                let width = CGFloat(max(1, bin.count)) / CGFloat(maxCount) * geo.size.width
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing))
                                    .frame(width: width, height: 12)
                            }
                            .frame(height: 12)
                            Text("\(bin.count)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .frame(width: 36, alignment: .trailing)
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle(LocalizedStringKey("distribution_nav_title"))
        .onAppear { load() }
    }
    
    private func load() {
        let targetId = skill.id
        let descriptor = FetchDescriptor<TimeIntervalEntry>(predicate: #Predicate { entry in entry.skillId == targetId })
        let entries = (try? context.fetch(descriptor)) ?? []
        let minutes = entries.map { max(0, $0.durationMinutes) }
        totalMinutes = minutes.reduce(0, +)
        meanMinutes = minutes.isEmpty ? 0 : minutes.reduce(0, +) / Double(minutes.count)
        let variance = minutes.isEmpty ? 0 : minutes.reduce(0) { $0 + pow($1 - meanMinutes, 2) } / Double(minutes.count)
        stdMinutes = sqrt(variance)
        bins = makeBins(values: minutes)
    }
    
    private func makeBins(values: [Double]) -> [(String, Int)] {
        guard !values.isEmpty else { return [] }
        let maxVal = values.max() ?? 0
        let edges: [Double] = [0,5,10,15,30,60,120,240,480,960, maxVal + 1]
        var result: [(String, Int)] = []
        for i in 0..<(edges.count - 1) {
            let a = edges[i]
            let b = edges[i+1]
            let count = values.filter { $0 >= a && $0 < b }.count
            let label = b >= 960 ? "≥ \(Int(a))m" : "\(Int(a))–\(Int(b))m"
            result.append((label, count))
        }
        return result.filter { $0.1 > 0 }
    }
    
    private func formatMinutes(_ m: Double) -> String {
        String(format: "%.1f", m)
    }
    private func formatHours(_ h: Double) -> String {
        String(format: "%.2f", h)
    }
}
