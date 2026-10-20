//
//  TimeConverterView.swift
//  TimeToSkill
//
//  Standalone time-unit converter with Time Perspective curiosities.
//  Formerly embedded in Options; now a top-level destination.
//

import SwiftUI

struct TimeConverterView: View {
    @ObservedObject private var language = AppLanguage.shared

    @State private var hoursInput: String = ""
    @State private var days8hOutput: String = ""
    @State private var days12hOutput: String = ""
    @State private var days24hOutput: String = ""
    @State private var yearsOutput: String = ""

    private let hoursMaxChars = 9
    private let days8hMaxChars = 8
    private let days12hMaxChars = 7
    private let days24hMaxChars = 7
    private let yearsMaxChars = 5

    enum Field: Hashable {
        case hours, days8, days12, days24, years, none
    }

    @FocusState private var focusedField: Field?
    @State private var activeSource: Field = .none
    @State private var calculationInProgress = false
    @State private var perspectiveLibrary: [TimePerspective] = []
    @State private var matchedPerspective: TimePerspective?

    var body: some View {
        let _ = language.resolved.presentationIdentity
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    LText(key: "Time_Converter_Hours_Label")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    TextField(
                        "",
                        text: $hoursInput,
                        prompt: Text(verbatim: L10n.string("Time_Converter_Hours_Placeholder"))
                    )
                        .numberPadKeyboard()
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .focused($focusedField, equals: .hours)
                        .onChange(of: hoursInput) { _, newValue in
                            let filtered = String(newValue.filter(\.isNumber).prefix(hoursMaxChars))
                            if filtered != newValue { hoursInput = filtered }
                        }
                }
                .padding(.vertical, 4)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    converterField(
                        labelKey: "Time_Converter_Days8h_Label",
                        text: $days8hOutput,
                        field: .days8,
                        maxChars: days8hMaxChars
                    )
                    converterField(
                        labelKey: "Time_Converter_Days12h_Label",
                        text: $days12hOutput,
                        field: .days12,
                        maxChars: days12hMaxChars
                    )
                    converterField(
                        labelKey: "Time_Converter_Days24h_Label",
                        text: $days24hOutput,
                        field: .days24,
                        maxChars: days24hMaxChars
                    )
                    converterField(
                        labelKey: "Time_Converter_Years_Label",
                        text: $yearsOutput,
                        field: .years,
                        maxChars: yearsMaxChars
                    )
                }
                .padding(.vertical, 8)

                Button {
                    if let focused = focusedField {
                        activeSource = focused
                    }
                    focusedField = nil
                    updateConversions()
                } label: {
                    LText(key: "Time_Converter_Calculate_Button")
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.top, 8)

                TimePerspectiveCard(perspective: matchedPerspective)
                    .padding(.top, 4)
            } header: {
                LText(key: "Time_Converter_Section_Header")
            }
        }
        .navigationTitle(Text(verbatim: L10n.string("time_converter_nav_title")))
        .inlineNavigationBarTitle()
        .onAppear {
            if perspectiveLibrary.isEmpty {
                perspectiveLibrary = (try? TimePerspectiveLoader.loadLibrary())?
                    .sorted { $0.thresholdMinutes < $1.thresholdMinutes }
                    ?? []
            }
        }
        .onChange(of: focusedField) { oldValue, newValue in
            if oldValue != nil && newValue != nil && oldValue != newValue {
                activeSource = oldValue!
                updateConversions()
            }
        }
        #if canImport(UIKit)
        .toolbar {
            ToolbarItem(placement: .keyboard) {
                Button {
                    if let focused = focusedField {
                        activeSource = focused
                    }
                    focusedField = nil
                    updateConversions()
                } label: {
                    LText(key: "Time_Converter_Calculate_Button")
                }
            }
        }
        #endif
    }

    private func converterField(
        labelKey: String,
        text: Binding<String>,
        field: Field,
        maxChars: Int
    ) -> some View {
        VStack(alignment: .leading) {
            LText(key: labelKey)
                .font(.subheadline)
                .foregroundColor(.secondary)
            TextField(
                "",
                text: text,
                prompt: Text(verbatim: L10n.string("Time_Converter_Days_Placeholder"))
            )
                .numberPadKeyboard()
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .focused($focusedField, equals: field)
                .onChange(of: text.wrappedValue) { _, newValue in
                    let filtered = String(newValue.filter(\.isNumber).prefix(maxChars))
                    if filtered != newValue { text.wrappedValue = filtered }
                }
        }
    }

    private func updateConversions() {
        guard activeSource != .none, !calculationInProgress else { return }
        calculationInProgress = true

        let currentHours = Int(hoursInput) ?? 0
        let currentDays8 = Int(days8hOutput) ?? 0
        let currentDays12 = Int(days12hOutput) ?? 0
        let currentDays24 = Int(days24hOutput) ?? 0
        let currentYears = Int(yearsOutput) ?? 0

        let totalHoursValue: Int
        switch activeSource {
        case .hours: totalHoursValue = currentHours
        case .days8: totalHoursValue = currentDays8 * 8
        case .days12: totalHoursValue = currentDays12 * 12
        case .days24: totalHoursValue = currentDays24 * 24
        case .years: totalHoursValue = currentYears * 365 * 24
        case .none: totalHoursValue = 0
        }

        if activeSource != .hours { hoursInput = "\(totalHoursValue)" }
        if activeSource != .days8 { days8hOutput = "\(totalHoursValue / 8)" }
        if activeSource != .days12 { days12hOutput = "\(totalHoursValue / 12)" }
        if activeSource != .days24 { days24hOutput = "\(totalHoursValue / 24)" }
        if activeSource != .years { yearsOutput = "\(totalHoursValue / (365 * 24))" }

        let match = TimePerspectiveMatcher.findBestPerspective(
            for: totalHoursValue * 60,
            in: perspectiveLibrary
        )
        withAnimation(.easeInOut(duration: 0.28)) {
            matchedPerspective = match
        }
        calculationInProgress = false
    }
}
