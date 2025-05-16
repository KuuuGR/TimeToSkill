import SwiftUI
import SwiftData
import PDFKit
import UIKit
import Combine

struct OptionsView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Skill.name, animation: .default) private var skills: [Skill]
    @State private var showingShareSheet = false
    @State private var pdfData: Data?

    // MARK: - Time Converter State Variables
    @State private var hoursInput: String = ""
    @State private var days8hOutput: String = ""
    @State private var days12hOutput: String = ""
    @State private var days24hOutput: String = ""
    @State private var yearsOutput: String = ""
    
    // Character limits for each field
    private let hoursMaxChars = 9
    private let days8hMaxChars = 8
    private let days12hMaxChars = 7
    private let days24hMaxChars = 7
    private let yearsMaxChars = 5
    
    // Focus management
    enum Field: Hashable {
        case hours, days8, days12, days24, years, none
    }
    @FocusState private var focusedField: Field?
    
    // Stores the input field that should be the source of calculations
    @State private var activeSource: Field = .none
    @State private var calculationInProgress: Bool = false
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button(action: {
                        generatePDF()
                    }) {
                        Label(
                            LocalizedStringKey("export_pdf_button"),
                            systemImage: "square.and.arrow.up"
                        )
                    }
                } header: {
                    Text(LocalizedStringKey("options_export_section"))
                }

                // MARK: - Time Converter Section
                Section {
                    // Hours field (full width)
                    VStack(alignment: .leading, spacing: 8) {
                        Text(LocalizedStringKey("Time_Converter_Hours_Label"))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        TextField(LocalizedStringKey("Time_Converter_Hours_Placeholder"), text: $hoursInput)
                            .keyboardType(.numberPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .focused($focusedField, equals: .hours)
                            .onChange(of: hoursInput) { _, newValue in
                                // Limit to specified characters and validate for numbers only
                                let filtered = String(newValue.filter({ $0.isNumber }).prefix(hoursMaxChars))
                                if filtered != newValue {
                                    hoursInput = filtered
                                }
                            }
                    }
                    .padding(.vertical, 4)
                    
                    // Two columns layout for the remaining fields
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        // Days 8h
                        VStack(alignment: .leading) {
                            Text(LocalizedStringKey("Time_Converter_Days8h_Label"))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            TextField(LocalizedStringKey("Time_Converter_Days_Placeholder"), text: $days8hOutput)
                                .keyboardType(.numberPad)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .focused($focusedField, equals: .days8)
                                .onChange(of: days8hOutput) { _, newValue in
                                    let filtered = String(newValue.filter({ $0.isNumber }).prefix(days8hMaxChars))
                                    if filtered != newValue {
                                        days8hOutput = filtered
                                    }
                                }
                        }
                        
                        // Days 12h
                        VStack(alignment: .leading) {
                            Text(LocalizedStringKey("Time_Converter_Days12h_Label"))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            TextField(LocalizedStringKey("Time_Converter_Days_Placeholder"), text: $days12hOutput)
                                .keyboardType(.numberPad)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .focused($focusedField, equals: .days12)
                                .onChange(of: days12hOutput) { _, newValue in
                                    let filtered = String(newValue.filter({ $0.isNumber }).prefix(days12hMaxChars))
                                    if filtered != newValue {
                                        days12hOutput = filtered
                                    }
                                }
                        }
                        
                        // Days 24h
                        VStack(alignment: .leading) {
                            Text(LocalizedStringKey("Time_Converter_Days24h_Label"))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            TextField(LocalizedStringKey("Time_Converter_Days_Placeholder"), text: $days24hOutput)
                                .keyboardType(.numberPad)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .focused($focusedField, equals: .days24)
                                .onChange(of: days24hOutput) { _, newValue in
                                    let filtered = String(newValue.filter({ $0.isNumber }).prefix(days24hMaxChars))
                                    if filtered != newValue {
                                        days24hOutput = filtered
                                    }
                                }
                        }
                        
                        // Years
                        VStack(alignment: .leading) {
                            Text(LocalizedStringKey("Time_Converter_Years_Label"))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            TextField(LocalizedStringKey("Time_Converter_Days_Placeholder"), text: $yearsOutput)
                                .keyboardType(.numberPad)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .focused($focusedField, equals: .years)
                                .onChange(of: yearsOutput) { _, newValue in
                                    let filtered = String(newValue.filter({ $0.isNumber }).prefix(yearsMaxChars))
                                    if filtered != newValue {
                                        yearsOutput = filtered
                                    }
                                }
                        }
                    }
                    .padding(.vertical, 8)
                    
                    Button(LocalizedStringKey("Time_Converter_Calculate_Button")) {
                        // If a field is currently focused, use that as the active source
                        if let focused = focusedField {
                            activeSource = focused
                        }
                        focusedField = .none
                        updateConversions()
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.top, 8)
                    
                } header: {
                    Text(LocalizedStringKey("Time_Converter_Section_Header"))
                }
            }
            .navigationTitle(LocalizedStringKey("options_title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(LocalizedStringKey("button_done")) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .keyboard) {
                    Button(LocalizedStringKey("Time_Converter_Calculate_Button")) {
                        // If a field is currently focused, use that as the active source
                        if let focused = focusedField {
                            activeSource = focused
                        }
                        focusedField = .none
                        updateConversions()
                    }
                }
            }
            // Apply calculations when a field loses focus
            .onChange(of: focusedField) { oldValue, newValue in
                if oldValue != nil && newValue != nil && oldValue != newValue {
                    // Field changed - use the old field as source for calculations
                    activeSource = oldValue!
                    updateConversions()
                }
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            if let data = pdfData {
                ShareSheet(items: [data])
            }
        }
        .onChange(of: pdfData) { newValue in
            if newValue != nil {
                showingShareSheet = true
            }
        }
    }

    // MARK: - Time Converter Logic
    private func updateConversions() {
        guard activeSource != .none, !calculationInProgress else {
            return
        }

        calculationInProgress = true

        // Parse input values, defaulting to 0 if invalid
        var currentHours = 0
        if let hours = Int(hoursInput) {
            currentHours = hours // Accept 0 as a valid input
        }
        
        var currentDays8 = 0
        if let days = Int(days8hOutput) {
            currentDays8 = days // Accept 0 as a valid input
        }
        
        var currentDays12 = 0
        if let days = Int(days12hOutput) {
            currentDays12 = days // Accept 0 as a valid input
        }
        
        var currentDays24 = 0
        if let days = Int(days24hOutput) {
            currentDays24 = days // Accept 0 as a valid input
        }
        
        var currentYears = 0
        if let years = Int(yearsOutput) {
            currentYears = years // Accept 0 as a valid input
        }

        var totalHoursValue: Int = 0

        switch activeSource {
        case .hours:
            totalHoursValue = currentHours
        case .days8:
            totalHoursValue = currentDays8 * 8
        case .days12:
            totalHoursValue = currentDays12 * 12
        case .days24:
            totalHoursValue = currentDays24 * 24
        case .years:
            totalHoursValue = currentYears * 365 * 24 // Approximate hours in a year
        case .none:
            break
        }

        // Only update fields that are not the source of the calculation
        if activeSource != .hours {
            hoursInput = "\(totalHoursValue)"
        }
        
        if activeSource != .days8 {
            let days8 = totalHoursValue / 8
            days8hOutput = "\(days8)"
        }
        
        if activeSource != .days12 {
            let days12 = totalHoursValue / 12
            days12hOutput = "\(days12)"
        }
        
        if activeSource != .days24 {
            let days24 = totalHoursValue / 24
            days24hOutput = "\(days24)"
        }
        
        if activeSource != .years {
            let years = totalHoursValue / (365 * 24)
            yearsOutput = "\(years)"
        }
        
        calculationInProgress = false
    }
    
    private func generatePDF() {
        // Create PDF document
        let pdfMetaData = [
            kCGPDFContextCreator: "TimeToSkill",
            kCGPDFContextAuthor: "TimeToSkill User"
        ]
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        let pageRect = CGRect(x: 0, y: 0, width: 595.2, height: 841.8) // A4 size
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        pdfData = renderer.pdfData { context in
            context.beginPage()
            
            // Title
            let titleAttributes = [
                NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 24)
            ]
            let titleString = NSLocalizedString("skills_report_title", comment: "")
            titleString.draw(at: CGPoint(x: 50, y: 50), withAttributes: titleAttributes)
            
            // Date
            let dateAttributes = [
                NSAttributedString.Key.font: UIFont.systemFont(ofSize: 12)
            ]
            let dateString = "Generated on: \(Date().formatted(date: .long, time: .shortened))"
            dateString.draw(at: CGPoint(x: 50, y: 80), withAttributes: dateAttributes)
            
            // Skills list
            let skillAttributes = [
                NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14)
            ]
            var yPosition: CGFloat = 120
            
            for skill in skills {
                let hours = Int(skill.hours)
                let minutes = Int((skill.hours - Double(hours)) * 60)
                let skillString = "\(skill.name): \(hours)h \(minutes)m"
                skillString.draw(at: CGPoint(x: 50, y: yPosition), withAttributes: skillAttributes)
                yPosition += 30
                
                // Start new page if needed
                if yPosition > pageRect.height - 100 {
                    context.beginPage()
                    yPosition = 50
                }
            }
        }
    }
}