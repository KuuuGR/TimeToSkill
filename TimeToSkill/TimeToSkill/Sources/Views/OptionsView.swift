import SwiftUI
import SwiftData
import PDFKit
import UIKit

struct OptionsView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Skill.name, animation: .default) private var skills: [Skill]
    @State private var showingShareSheet = false
    @State private var pdfData: Data?
    
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
            }
            .navigationTitle(LocalizedStringKey("options_title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(LocalizedStringKey("button_done")) {
                        dismiss()
                    }
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
            
            for skill in skills {  // Using skills directly since they're already sorted
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