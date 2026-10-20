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
                            Text(verbatim: L10n.string("counters_empty_title"))
                                .font(.title3)
                                .fontWeight(.semibold)
                            Text(verbatim: L10n.string("counters_empty_description"))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 24)
                            Button {
                                showingNew = true
                            } label: {
                                Text(verbatim: L10n.string("create"))
                            }
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
                                        Button {
                                            if counter.refreshFromAnchor() {
                                                try? context.save()
                                            }
                                        } label: {
                                            Text(verbatim: L10n.string("counter_refresh"))
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
            .navigationTitle(Text(verbatim: L10n.string("manage_counters_title")))

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
                Section {
                    SkillEmojiPickerButton(selection: $symbol)
                    TextField("", text: $title, prompt: Text(verbatim: L10n.string("counter_title_placeholder")))
                    Picker(selection: $kind) {
                        Text(verbatim: L10n.string("counter_kind_manual")).tag(CounterKind.manual)
                        Text(verbatim: L10n.string("counter_kind_elapsed")).tag(CounterKind.elapsedDays)
                    } label: {
                        Text(verbatim: L10n.string("counter_kind_label"))
                    }
                    if kind == .elapsedDays {
                        DatePicker(selection: $anchor, displayedComponents: .date) {
                            Text(verbatim: L10n.string("counter_anchor_label"))
                        }
                    }
                    Stepper(value: $step, in: 1...1000) {
                        Text(verbatim: String(format: L10n.string("counter_step_label%d"), step))
                    }
                } header: {
                    Text(verbatim: L10n.string("counter_details_section"))
                }
                Section {
                    TextField("", text: $thresholdsText, prompt: Text(verbatim: L10n.string("counter_thresholds_placeholder")))
                } header: {
                    Text(verbatim: L10n.string("counter_thresholds_section"))
                }
            }
            .navigationTitle(Text(verbatim: L10n.string("counter_new_title")))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: { Text(verbatim: L10n.string("cancel")) }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        let limits = thresholdsText.split(separator: ",").compactMap { Int($0.trimmingCharacters(in: .whitespaces)) }.sorted()
                        onCreate(title, symbol, step, limits, kind, kind == .elapsedDays ? anchor : nil)
                        dismiss()
                    } label: {
                        Text(verbatim: L10n.string("create"))
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
            Section {
                HStack {
                    Spacer()
                    CounterRing(value: counter.value, stageMax: counter.currentStageMax)
                        .frame(width: 140, height: 140)
                    Spacer()
                }
                Text(verbatim: "\(L10n.string("counter_value_label")): \(counter.value)")
                if let maxStage = counter.currentStageMax {
                    Text(verbatim: "\(L10n.string("counter_stage_max_label")): \(maxStage)")
                } else {
                    Text(verbatim: L10n.string("counter_no_thresholds"))
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
                    Button {
                        if counter.refreshFromAnchor() {
                            try? context.save()
                        }
                    } label: {
                        Text(verbatim: L10n.string("counter_refresh"))
                    }
                    .accessibilityIdentifier("CounterRefresh_\(counter.id.uuidString)")
                    if counter.anchorDay == nil {
                        Text(verbatim: L10n.string("counter_refresh_unavailable"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Button(role: .destructive) {
                    counter.value = 0
                    counter.updatedAt = Date()
                } label: {
                    Text(verbatim: L10n.string("counter_reset_to_zero"))
                }
            } header: {
                Text(verbatim: L10n.string("counter_progress_section"))
            }
            Section {
                SkillEmojiPickerButton(selection: $counter.symbol)
                TextField("", text: $counter.title, prompt: Text(verbatim: L10n.string("counter_title_placeholder")))
                Stepper(value: $counter.step, in: -1000...1000) {
                    Text(verbatim: String(format: L10n.string("counter_step_label%d"), counter.step))
                }
                NavigationLink {
                    ThresholdEditor(thresholds: $counter.thresholds)
                } label: {
                    Text(verbatim: L10n.string("counter_edit_thresholds"))
                }
            } header: {
                Text(verbatim: L10n.string("counter_configuration_section"))
            }
            // The allowed range lives in the section title, not in the field's
            // placeholder, so the input row stays a plain field + Apply button.
            Section {
                HStack {
                    TextField("", text: $valueText, prompt: Text(verbatim: L10n.string("counter_value_label")))
                        .numbersAndPunctuationKeyboard()
                    Button {
                        if let v = Int(valueText) { counter.value = v; counter.updatedAt = Date() }
                        valueText = ""
                    } label: {
                        Text(verbatim: L10n.string("apply"))
                    }
                    .disabled(Int(valueText) == nil)
                }
            } header: {
                Text(verbatim: L10n.string("counter_set_value_section"))
            }
            Section {
                Button(role: .destructive) {
                    showDeleteConfirmation = true
                } label: {
                    Label {
                        Text(verbatim: L10n.string("counter_delete"))
                    } icon: {
                        Image(systemName: "trash")
                    }
                }
                .confirmationDialog(
                    Text(verbatim: L10n.string("delete_confirm_title")),
                    isPresented: $showDeleteConfirmation,
                    titleVisibility: .visible
                ) {
                    Button(role: .destructive) {
                        context.delete(counter)
                        try? context.save()
                        dismiss()
                    } label: {
                        Text(verbatim: L10n.string("delete_confirm_action"))
                    }
                    Button(role: .cancel) {} label: {
                        Text(verbatim: L10n.string("cancel"))
                    }
                } message: {
                    Text(verbatim: L10n.string("delete_confirm_message"))
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
            Section {
                if thresholds.isEmpty {
                    Text(verbatim: L10n.string("counter_no_thresholds"))
                        .foregroundColor(.secondary)
                } else {
                    ForEach(thresholds, id: \.self) { t in Text("\(t)") }
                        .onDelete { indexSet in thresholds.remove(atOffsets: indexSet) }
                }
            } header: {
                Text(verbatim: L10n.string("counter_current_thresholds"))
            }
            Section {
                HStack {
                    TextField("", text: $newValue, prompt: Text(verbatim: L10n.string("value")))
                        .numberPadKeyboard()
                    Button {
                        if let v = Int(newValue) { thresholds.append(v); thresholds.sort(); newValue = "" }
                    } label: {
                        Text(verbatim: L10n.string("add"))
                    }
                    .disabled(Int(newValue) == nil)
                }
            } header: {
                Text(verbatim: L10n.string("counter_add_threshold"))
            }
        }
        .navigationTitle(Text(verbatim: L10n.string("counter_thresholds_title")))
    }
}
