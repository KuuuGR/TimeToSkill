import SwiftUI
import SwiftData

struct ManageCountersView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Counter.title) private var counters: [Counter]
    @State private var showingNew = false
    
    private func haptic(_ style: HapticStyle = .medium) {
        triggerHaptic(style)
    }
    
    private func adjust(_ counter: Counter, by delta: Int) {
        counter.value += delta
        counter.updatedAt = Date()
        try? context.save()
    }

    /// macOS windows can be much wider than a phone, so the grid adapts its
    /// column count to the available width.
    private var gridColumns: [GridItem] {
        #if os(macOS)
        [GridItem(.adaptive(minimum: 120, maximum: 160), spacing: 8)]
        #else
        Array(repeating: GridItem(.flexible(), spacing: 3), count: 3)
        #endif
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    if counters.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "number")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 64, height: 64)
                                .foregroundColor(.secondary)
                            Text(LocalizedStringKey("counters_empty_title"))
                                .font(.title3)
                                .fontWeight(.semibold)
                            Text(LocalizedStringKey("counters_empty_description"))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 24)
                            Button(LocalizedStringKey("create")) { showingNew = true }
                                .buttonStyle(.borderedProminent)
                        }
                        .padding(20)
                    } else {
                        LazyVGrid(columns: gridColumns, spacing: 3) {
                            ForEach(counters) { counter in
                            ZStack(alignment: .topTrailing) {
                                VStack(spacing: 8) {
                                    if !counter.symbol.isEmpty {
                                        Text(counter.symbol)
                                            .font(.title3)
                                            .accessibilityHidden(true)
                                    }
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
                                        .macOSHoverFeedback(scale: 1.04)
                                    Text(counter.title)
                                        .font(.caption)
                                        .multilineTextAlignment(.center)
                                        .lineLimit(2)
                                    Text("\(counter.value)")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                    CrystalProgressBar(
                                        progress: counter.barFraction,
                                        hours: 0,
                                        paletteOverride: counter.barPalette,
                                        height: 8,
                                        animated: false
                                    )
                                    if counter.kind == .elapsedDays {
                                        Button(LocalizedStringKey("counter_refresh")) {
                                            if counter.refreshFromAnchor() {
                                                try? context.save()
                                            }
                                        }
                                        .font(.caption2)
                                        .buttonStyle(.bordered)
                                        .accessibilityIdentifier("CounterRefresh_\(counter.id.uuidString)")
                                    }
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
                        .macOSContentWidth(760)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle(LocalizedStringKey("manage_counters_title"))
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showingNew = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingNew) {
                NewCounterSheet { title, symbol, step, thresholds, kind, anchor in
                    let model = Counter(title: title, symbol: symbol, step: step, thresholds: thresholds)
                    model.kind = kind
                    model.anchorDay = kind == .elapsedDays ? anchor : nil
                    if kind == .elapsedDays {
                        model.refreshFromAnchor()
                    }
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
    @State private var symbol: String = ""
    @State private var step: Int = 1
    @State private var thresholdsText: String = "100,200,500,10000,30000,3000000"
    @State private var kind: CounterKind = .manual
    @State private var anchor: Date = .now
    let onCreate: (String, String, Int, [Int], CounterKind, Date?) -> Void
    
    var body: some View {
        NavigationStack {
            Form {
                Section(LocalizedStringKey("counter_details_section")) {
                    SkillEmojiPickerButton(selection: $symbol)
                    TextField(LocalizedStringKey("counter_title_placeholder"), text: $title)
                    Picker(LocalizedStringKey("counter_kind_label"), selection: $kind) {
                        Text(LocalizedStringKey("counter_kind_manual")).tag(CounterKind.manual)
                        Text(LocalizedStringKey("counter_kind_elapsed")).tag(CounterKind.elapsedDays)
                    }
                    if kind == .elapsedDays {
                        DatePicker(LocalizedStringKey("counter_anchor_label"), selection: $anchor, displayedComponents: .date)
                    }
                    Stepper(value: $step, in: 1...1000) {
                        Text(String(format: NSLocalizedString("counter_step_label%d", comment: ""), step))
                    }
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
                        onCreate(title, symbol, step, limits, kind, kind == .elapsedDays ? anchor : nil)
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}

struct CounterDetailView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Bindable var counter: Counter
    @State private var valueText: String = ""
    @State private var showDeleteConfirmation = false
    
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
                CrystalProgressBar(
                    progress: counter.barFraction,
                    hours: 0,
                    paletteOverride: counter.barPalette,
                    height: 12,
                    animated: false
                )
                if counter.kind == .elapsedDays {
                    Button(LocalizedStringKey("counter_refresh")) {
                        if counter.refreshFromAnchor() {
                            try? context.save()
                        }
                    }
                    .accessibilityIdentifier("CounterRefresh_\(counter.id.uuidString)")
                    if counter.anchorDay == nil {
                        Text(LocalizedStringKey("counter_refresh_unavailable"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Button(LocalizedStringKey("counter_reset_to_zero"), role: .destructive) { counter.value = 0; counter.updatedAt = Date() }
            }
            Section(LocalizedStringKey("counter_configuration_section")) {
                SkillEmojiPickerButton(selection: $counter.symbol)
                TextField(LocalizedStringKey("counter_title_placeholder"), text: $counter.title)
                Stepper(value: $counter.step, in: -1000...1000) {
                    Text(String(format: NSLocalizedString("counter_step_label%d", comment: ""), counter.step))
                }
                NavigationLink(LocalizedStringKey("counter_edit_thresholds")) { ThresholdEditor(thresholds: $counter.thresholds) }
            }
            // The allowed range lives in the section title, not in the field's
            // placeholder, so the input row stays a plain field + Apply button.
            Section(LocalizedStringKey("counter_set_value_section")) {
                HStack {
                    TextField(LocalizedStringKey("counter_value_label"), text: $valueText)
                        .numbersAndPunctuationKeyboard()
                    Button(LocalizedStringKey("apply")) {
                        if let v = Int(valueText) { counter.value = v; counter.updatedAt = Date() }
                        valueText = ""
                    }
                    .disabled(Int(valueText) == nil)
                }
            }
            Section {
                Button(role: .destructive) {
                    showDeleteConfirmation = true
                } label: {
                    Label(LocalizedStringKey("counter_delete"), systemImage: "trash")
                }
                .confirmationDialog(LocalizedStringKey("delete_confirm_title"), isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
                    Button(LocalizedStringKey("delete_confirm_action"), role: .destructive) {
                        context.delete(counter)
                        try? context.save()
                        dismiss()
                    }
                    Button(LocalizedStringKey("cancel"), role: .cancel) { }
                } message: {
                    Text(LocalizedStringKey("delete_confirm_message"))
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
                        .numberPadKeyboard()
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
