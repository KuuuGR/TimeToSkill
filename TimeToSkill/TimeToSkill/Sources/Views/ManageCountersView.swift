import SwiftUI
import SwiftData

struct ManageCountersView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Counter.title) private var counters: [Counter]
    @State private var showingNew = false
    
    private func haptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        #if canImport(UIKit)
        UIImpactFeedbackGenerator(style: style).impactOccurred()
        #endif
    }
    
    private func adjust(_ counter: Counter, by delta: Int) {
        counter.value += delta
        counter.updatedAt = Date()
        try? context.save()
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 3), count: 3), spacing: 3) {
                        ForEach(counters) { counter in
                            ZStack(alignment: .topTrailing) {
                                VStack(spacing: 8) {
                                    CounterRing(value: counter.value, stageMax: counter.currentStageMax)
                                        .frame(width: 72, height: 72)
                                        .contentShape(Circle())
                                        .onTapGesture {
                                            adjust(counter, by: counter.step)
                                            haptic(.light)
                                        }
                                        .onLongPressGesture(minimumDuration: 0.35) {
                                            adjust(counter, by: -counter.step)
                                            haptic(.rigid)
                                        }
                                    Text(counter.title)
                                        .font(.caption)
                                        .multilineTextAlignment(.center)
                                        .lineLimit(2)
                                    Text("\(counter.value)")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                .padding(8)
                                .background(RoundedRectangle(cornerRadius: 12).fill(Color.gray.opacity(0.06)))
                                
                                NavigationLink(destination: CounterDetailView(counter: counter)) {
                                    Image(systemName: "gearshape")
                                        .imageScale(.small)
                                        .padding(6)
                                        .background(.ultraThinMaterial, in: Circle())
                                }
                                .buttonStyle(PlainButtonStyle())
                                .padding(6)
                            }
                        }
                    }
                    .padding(3)
                }
            }
            .navigationTitle(LocalizedStringKey("manage_counters_title"))
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showingNew = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingNew) {
                NewCounterSheet { title, step, thresholds in
                    let model = Counter(title: title, step: step, thresholds: thresholds)
                    context.insert(model)
                    try? context.save()
                }
            }
        }
    }
}

struct NewCounterSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var title: String = ""
    @State private var step: Int = 1
    @State private var thresholdsText: String = "100,200,500,10000,30000,3000000"
    let onCreate: (String, Int, [Int]) -> Void
    
    var body: some View {
        NavigationStack {
            Form {
                Section(LocalizedStringKey("counter_details_section")) {
                    TextField(LocalizedStringKey("counter_title_placeholder"), text: $title)
                    Stepper(LocalizedStringKey("counter_step_label\(step)"), value: $step, in: 1...1000)
                }
                Section(LocalizedStringKey("counter_thresholds_section")) {
                    TextField(LocalizedStringKey("counter_thresholds_placeholder"), text: $thresholdsText)
                }
            }
            .navigationTitle(LocalizedStringKey("counter_new_title"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button(LocalizedStringKey("cancel")) { dismiss() } }
                ToolbarItem(placement: .primaryAction) {
                    Button(LocalizedStringKey("create")) {
                        let limits = thresholdsText.split(separator: ",").compactMap { Int($0.trimmingCharacters(in: .whitespaces)) }.sorted()
                        onCreate(title, step, limits)
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}

struct CounterDetailView: View {
    @Bindable var counter: Counter
    @State private var valueText: String = ""
    
    var body: some View {
        Form {
            Section(LocalizedStringKey("counter_progress_section")) {
                HStack {
                    Spacer()
                    CounterRing(value: counter.value, stageMax: counter.currentStageMax)
                        .frame(width: 140, height: 140)
                    Spacer()
                }
                Text(LocalizedStringKey("counter_value_label")) + Text(": \(counter.value)")
                if let maxStage = counter.currentStageMax {
                    Text(LocalizedStringKey("counter_stage_max_label")) + Text(": \(maxStage)")
                } else {
                    Text(LocalizedStringKey("counter_no_thresholds"))
                        .foregroundColor(.secondary)
                }
                Button(LocalizedStringKey("counter_reset_to_zero"), role: .destructive) { counter.value = 0; counter.updatedAt = Date() }
            }
            Section(LocalizedStringKey("counter_configuration_section")) {
                TextField(LocalizedStringKey("counter_title_placeholder"), text: $counter.title)
                Stepper(LocalizedStringKey("counter_step_label\(counter.step)"), value: $counter.step, in: -1000...1000)
                NavigationLink(LocalizedStringKey("counter_edit_thresholds")) { ThresholdEditor(thresholds: $counter.thresholds) }
            }
            Section(LocalizedStringKey("counter_set_value_section")) {
                HStack {
                    TextField(LocalizedStringKey("counter_set_value_placeholder"), text: $valueText)
                        .keyboardType(.numbersAndPunctuation)
                    Button(LocalizedStringKey("apply")) {
                        if let v = Int(valueText) { counter.value = v; counter.updatedAt = Date() }
                        valueText = ""
                    }
                    .disabled(Int(valueText) == nil)
                }
            }
        }
        .navigationTitle(counter.title)
        .onAppear { valueText = "\(counter.value)" }
    }
}

struct ThresholdEditor: View {
    @Binding var thresholds: [Int]
    @State private var newValue: String = ""
    
    var body: some View {
        Form {
            Section(LocalizedStringKey("counter_current_thresholds")) {
                if thresholds.isEmpty {
                    Text(LocalizedStringKey("counter_no_thresholds"))
                        .foregroundColor(.secondary)
                } else {
                    ForEach(thresholds, id: \.self) { t in Text("\(t)") }
                        .onDelete { indexSet in thresholds.remove(atOffsets: indexSet) }
                }
            }
            Section(LocalizedStringKey("counter_add_threshold")) {
                HStack {
                    TextField(LocalizedStringKey("value"), text: $newValue)
                        .keyboardType(.numberPad)
                    Button(LocalizedStringKey("add")) {
                        if let v = Int(newValue) { thresholds.append(v); thresholds.sort(); newValue = "" }
                    }
                    .disabled(Int(newValue) == nil)
                }
            }
        }
        .navigationTitle(LocalizedStringKey("counter_thresholds_title"))
    }
}
