import SwiftUI
import SwiftData
import PDFKit
import Combine
#if canImport(UIKit)
import UIKit
#endif

struct OptionsView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Skill.name, animation: .default) private var skills: [Skill]
    @Query(sort: \Counter.title, animation: .default) private var counters: [Counter]
    @Environment(\.modelContext) private var modelContext
    @State private var showingShareSheet = false
    @State private var pdfData: Data?
    @AppStorage(TimeBalanceSound.defaultsKey) private var balanceZeroSoundEnabled = true

    /// iOS presents this view as a sheet (with a Done button); macOS hosts it as
    /// the "Settings" sidebar section, where "Done" makes no sense.
    var showsDoneButton: Bool = true

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

                Section {
                    Toggle(isOn: $balanceZeroSoundEnabled) {
                        Text(LocalizedStringKey("time_balance_zero_sound"))
                    }
                    .accessibilityIdentifier("TimeBalanceZeroSoundToggle")
                } header: {
                    Text(LocalizedStringKey("time_balance_sound_section"))
                }
            }
            .navigationTitle(LocalizedStringKey("options_title"))
            .inlineNavigationBarTitle()
            .toolbar {
                if showsDoneButton {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(LocalizedStringKey("button_done")) {
                            dismiss()
                        }
                    }
                }
            }
            // Shared with Overview: same corner, same AppLanguage.shared state.
            .languageSelectorCorner()
        }
        .macOSSheetMinSize(width: 620, height: 660)
        .sheet(isPresented: $showingShareSheet) {
            if let data = pdfData {
                ShareSheet(items: [data])
            }
        }
        .onChange(of: pdfData) { _, newValue in
            if newValue != nil {
                showingShareSheet = true
            }
        }
    }

#if canImport(UIKit)
    private func generatePDF() {
        // Create PDF document
        let pdfMetaData = [
            kCGPDFContextCreator: "Time4Skill",
            kCGPDFContextAuthor: "Time4Skill User"
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
            let dateString = String(
                format: NSLocalizedString("export_pdf_generated_on_format", comment: ""),
                Date().formatted(date: .long, time: .shortened)
            )
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

            // New page for Counters section if needed
            if yPosition > pageRect.height - 200 {
                context.beginPage()
                yPosition = 50
            }

            // Counters Section Title
            let countersTitleAttributes = [
                NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 18)
            ]
            let countersTitle = NSLocalizedString("manage_counters_title", comment: "")
            countersTitle.draw(at: CGPoint(x: 50, y: yPosition), withAttributes: countersTitleAttributes)
            yPosition += 28

            // Counters list
            let counterAttributes = [
                NSAttributedString.Key.font: UIFont.systemFont(ofSize: 13)
            ]
            for counter in counters {
                let thresholdsText: String
                let limits = counter.thresholds
                if limits.isEmpty {
                    thresholdsText = NSLocalizedString("counter_no_thresholds", comment: "")
                } else {
                    thresholdsText = limits.map { String($0) }.joined(separator: ", ")
                }
                let line = "\(counter.title): \(counter.value)  [\(thresholdsText)]"
                line.draw(at: CGPoint(x: 50, y: yPosition), withAttributes: counterAttributes)
                yPosition += 22

                if yPosition > pageRect.height - 80 {
                    context.beginPage()
                    yPosition = 50
                }
            }

            // Add Global Time Distribution Histogram (bars)
            do {
                let descriptor = FetchDescriptor<TimeIntervalEntry>()
                let entries = (try? modelContext.fetch(descriptor)) ?? []
                let minutes = entries.map { max(0, $0.durationMinutes) }
                let bins: [(String, Int)] = makeBinsForPDF(values: minutes)

                if !bins.isEmpty {
                    if yPosition > pageRect.height - 200 {
                        context.beginPage()
                        yPosition = 50
                    }

                    let sectionTitleAttributes = [
                        NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 18)
                    ]
                    let sectionTitle = NSLocalizedString("global_time_distribution_title", comment: "")
                    sectionTitle.draw(at: CGPoint(x: 50, y: yPosition), withAttributes: sectionTitleAttributes)
                    yPosition += 26

                    drawHistogramBars(bins: bins, pageRect: pageRect, yPosition: &yPosition, color: UIColor.systemBlue, rendererContext: context)
                }
            }

            // Per-skill distributions
            for skill in skills {
                let targetId = skill.id
                let descriptor = FetchDescriptor<TimeIntervalEntry>(predicate: #Predicate { entry in entry.skillId == targetId })
                let entries = (try? modelContext.fetch(descriptor)) ?? []
                let minutes = entries.map { max(0, $0.durationMinutes) }
                let bins = makeBinsForPDF(values: minutes)
                if bins.isEmpty { continue }

                if yPosition > pageRect.height - 200 {
                    context.beginPage()
                    yPosition = 50
                }

                let sectionTitleAttributes = [
                    NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 18)
                ]
                let skillSectionTitle = String(format: NSLocalizedString("time_distribution_skill_format", comment: ""), skill.name)
                (skillSectionTitle as NSString).draw(at: CGPoint(x: 50, y: yPosition), withAttributes: sectionTitleAttributes)
                yPosition += 24

                drawHistogramBars(bins: bins, pageRect: pageRect, yPosition: &yPosition, color: UIColor.systemPurple, rendererContext: context)
            }
        }
    }
#else
    // macOS implementation built on Core Graphics + Core Text.
    private func generatePDF() {
        let pageRect = CGRect(x: 0, y: 0, width: 595.2, height: 841.8) // A4 size
        let builder = PDFReportBuilder(pageSize: pageRect.size)
        builder.begin()
        builder.newPage()

        let titleFont = "Helvetica-Bold"
        let bodyFont = "Helvetica"

        let titleString = NSLocalizedString("skills_report_title", comment: "")
        builder.drawText(titleString, topLeft: CGPoint(x: 50, y: 50), fontName: titleFont, fontSize: 24, color: .black)

        let dateString = String(
            format: NSLocalizedString("export_pdf_generated_on_format", comment: ""),
            Date().formatted(date: .long, time: .shortened)
        )
        builder.drawText(dateString, topLeft: CGPoint(x: 50, y: 80), fontName: bodyFont, fontSize: 12, color: .black)

        var yPosition: CGFloat = 120

        for skill in skills {
            let hours = Int(skill.hours)
            let minutes = Int((skill.hours - Double(hours)) * 60)
            let skillString = "\(skill.name): \(hours)h \(minutes)m"
            builder.drawText(skillString, topLeft: CGPoint(x: 50, y: yPosition), fontName: bodyFont, fontSize: 14, color: .black)
            yPosition += 30
            if yPosition > pageRect.height - 100 {
                builder.newPage()
                yPosition = 50
            }
        }

        if yPosition > pageRect.height - 200 {
            builder.newPage()
            yPosition = 50
        }

        let countersTitle = NSLocalizedString("manage_counters_title", comment: "")
        builder.drawText(countersTitle, topLeft: CGPoint(x: 50, y: yPosition), fontName: titleFont, fontSize: 18, color: .black)
        yPosition += 28

        for counter in counters {
            let thresholdsText: String
            let limits = counter.thresholds
            if limits.isEmpty {
                thresholdsText = NSLocalizedString("counter_no_thresholds", comment: "")
            } else {
                thresholdsText = limits.map { String($0) }.joined(separator: ", ")
            }
            let line = "\(counter.title): \(counter.value)  [\(thresholdsText)]"
            builder.drawText(line, topLeft: CGPoint(x: 50, y: yPosition), fontName: bodyFont, fontSize: 13, color: .black)
            yPosition += 22
            if yPosition > pageRect.height - 80 {
                builder.newPage()
                yPosition = 50
            }
        }

        do {
            let descriptor = FetchDescriptor<TimeIntervalEntry>()
            let entries = (try? modelContext.fetch(descriptor)) ?? []
            let minutes = entries.map { max(0, $0.durationMinutes) }
            let bins = makeBinsForPDF(values: minutes)
            if !bins.isEmpty {
                if yPosition > pageRect.height - 200 {
                    builder.newPage()
                    yPosition = 50
                }
                let sectionTitle = NSLocalizedString("global_time_distribution_title", comment: "")
                builder.drawText(sectionTitle, topLeft: CGPoint(x: 50, y: yPosition), fontName: titleFont, fontSize: 18, color: .black)
                yPosition += 26
                drawHistogramBars(bins: bins, pageRect: pageRect, yPosition: &yPosition, color: .systemBlue, builder: builder)
            }
        }

        for skill in skills {
            let targetId = skill.id
            let descriptor = FetchDescriptor<TimeIntervalEntry>(predicate: #Predicate { entry in entry.skillId == targetId })
            let entries = (try? modelContext.fetch(descriptor)) ?? []
            let minutes = entries.map { max(0, $0.durationMinutes) }
            let bins = makeBinsForPDF(values: minutes)
            if bins.isEmpty { continue }
            if yPosition > pageRect.height - 200 {
                builder.newPage()
                yPosition = 50
            }
            let skillSectionTitle = String(format: NSLocalizedString("time_distribution_skill_format", comment: ""), skill.name)
            builder.drawText(skillSectionTitle, topLeft: CGPoint(x: 50, y: yPosition), fontName: titleFont, fontSize: 18, color: .black)
            yPosition += 24
            drawHistogramBars(bins: bins, pageRect: pageRect, yPosition: &yPosition, color: .systemPurple, builder: builder)
        }

        pdfData = builder.finish()
    }
#endif

    // Helper to build bins for PDF rendering
    private func makeBinsForPDF(values: [Double]) -> [(String, Int)] {
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

#if canImport(UIKit)
    private func drawHistogramBars(bins: [(String, Int)], pageRect: CGRect, yPosition: inout CGFloat, color: UIColor, rendererContext: UIGraphicsPDFRendererContext) {
        let leftX: CGFloat = 50
        let rightX: CGFloat = pageRect.width - 50
        let barAreaWidth: CGFloat = rightX - leftX - 120
        let maxCount = max(1, bins.map { $0.1 }.max() ?? 1)
        let barHeight: CGFloat = 10
        let barSpacing: CGFloat = 16

        let labelAttributes: [NSAttributedString.Key: Any] = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 10)]
        let countAttributes: [NSAttributedString.Key: Any] = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 10), NSAttributedString.Key.foregroundColor: UIColor.secondaryLabel]

        for (label, count) in bins {
            (label as NSString).draw(at: CGPoint(x: leftX, y: yPosition - 2), withAttributes: labelAttributes)
            let ratio = CGFloat(count) / CGFloat(maxCount)
            let safeRatio = ratio.isNaN || !ratio.isFinite ? 0 : max(0, min(1, ratio))
            let width = safeRatio * barAreaWidth
            let barX = leftX + 90
            let barRect = CGRect(x: barX, y: yPosition, width: width, height: barHeight)
            color.setFill()
            UIBezierPath(roundedRect: barRect, cornerRadius: 4).fill()
            ("\(count)" as NSString).draw(at: CGPoint(x: barX + barAreaWidth + 8, y: yPosition - 2), withAttributes: countAttributes)

            yPosition += barHeight + barSpacing
            if yPosition > pageRect.height - 60 {
                rendererContext.beginPage()
                yPosition = 50
            }
        }
    }
#else
    private func drawHistogramBars(bins: [(String, Int)], pageRect: CGRect, yPosition: inout CGFloat, color: PlatformColor, builder: PDFReportBuilder) {
        let leftX: CGFloat = 50
        let rightX: CGFloat = pageRect.width - 50
        let barAreaWidth: CGFloat = rightX - leftX - 120
        let maxCount = max(1, bins.map { $0.1 }.max() ?? 1)
        let barHeight: CGFloat = 10
        let barSpacing: CGFloat = 16

        for (label, count) in bins {
            builder.drawText(label, topLeft: CGPoint(x: leftX, y: yPosition - 2), fontName: "Helvetica", fontSize: 10, color: .black)
            let ratio = CGFloat(count) / CGFloat(maxCount)
            let safeRatio = ratio.isNaN || !ratio.isFinite ? 0 : max(0, min(1, ratio))
            let width = safeRatio * barAreaWidth
            let barX = leftX + 90
            let barRect = CGRect(x: barX, y: yPosition, width: width, height: barHeight)
            builder.drawBar(rect: barRect, cornerRadius: 4, color: color)
            builder.drawText("\(count)", topLeft: CGPoint(x: barX + barAreaWidth + 8, y: yPosition - 2), fontName: "Helvetica", fontSize: 10, color: .secondaryLabelColor)

            yPosition += barHeight + barSpacing
            if yPosition > pageRect.height - 60 {
                builder.newPage()
                yPosition = 50
            }
        }
    }
#endif
}