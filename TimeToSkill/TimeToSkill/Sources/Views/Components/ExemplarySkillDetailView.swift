//
//  ExemplarySkillDetailView.swift
//  TimeToSkill
//
//  Created by admin on 10/04/2025.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct ExemplarySkillDetailView: View {
    let skill: ExemplarySkill
    let onEvaluate: (Int, String) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var selectedRating: Int = 1
    @State private var verificationCode: String = ""
    @State private var showingVerification = false
    @State private var verificationError = false
    @State private var generatedVerificationCode: String = ""
    @State private var currentVerificationCode: String = ""
    @State private var showUpdateSection: Bool = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                skillDetailContent
            }
            .navigationTitle(LocalizedStringKey("skill_details_title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(LocalizedStringKey("close")) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    // Small gear button on the right to reveal Update & Verify
                    if skill.isObtained {
                        Button(action: { withAnimation { showUpdateSection.toggle() } }) {
                            Image(systemName: "gearshape")
                                .imageScale(.medium)
                        }
                        .accessibilityLabel(LocalizedStringKey("change_rating_accessibility"))
                    }
                }
            }
            .sheet(isPresented: $showingVerification) {
                VerificationView(
                    verificationCode: $verificationCode,
                    generatedCode: $currentVerificationCode,
                    onVerify: {
                        verifyAndEvaluate()
                    },
                    onCancel: {
                        showingVerification = false
                    }
                )
                .onAppear {
                    print("Sheet appeared with generated code: '\(currentVerificationCode)'")
                    if currentVerificationCode.isEmpty {
                        print("WARNING: currentVerificationCode is empty!")
                    }
                }
            }
            .onAppear {
                // Initialize picker with current rating for re-evaluation
                selectedRating = max(0, min(3, skill.userRating ?? 0))
            }
        }
    }
    
    private var skillDetailContent: some View {
        VStack(spacing: 24) {
                    // Header with image and title
                    VStack(spacing: 16) {
                        if UIImage(named: skill.imageName) != nil {
                            Image(skill.imageName)
                                .resizable()
                                .scaledToFit()
                                .saturation((skill.userRating ?? 0) == 0 ? 0 : 1)
                                .opacity((skill.userRating ?? 0) == 0 ? 0.6 : 1)
                                .frame(width: 120, height: 120)
                                .background(
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill((skill.userRating ?? 0) == 0 ? Color.gray.opacity(0.1) : Color.blue.opacity(0.1))
                                )
                        } else {
                            Image(systemName: skill.imageName)
                                .font(.system(size: 80))
                                .foregroundColor((skill.userRating ?? 0) == 0 ? .gray : .blue)
                                .frame(width: 120, height: 120)
                                .background(
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill((skill.userRating ?? 0) == 0 ? Color.gray.opacity(0.1) : Color.blue.opacity(0.1))
                                )
                        }
                        
                        VStack(spacing: 8) {
                            Text(skill.title)
                                .font(.title2)
                                .fontWeight(.bold)
                                .multilineTextAlignment(.center)
                            
                            Text(skill.category)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 4)
                                .background(Color.secondary.opacity(0.2))
                                .cornerRadius(8)
                        }
                    }
                    
                    // Description
                    VStack(alignment: .leading, spacing: 12) {
                        Text(LocalizedStringKey("description"))
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text(skill.skillDescription)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Current status
                    if skill.isObtained {
                        VStack(spacing: 12) {
                            Text(LocalizedStringKey("achievement_status"))
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            HStack {
                                Text(LocalizedStringKey("obtained_label"))
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                Text(skill.obtainedAt?.formatted(date: .abbreviated, time: .omitted) ?? NSLocalizedString("unknown", comment: ""))
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                            
                            HStack {
                                Text(LocalizedStringKey("your_rating_label"))
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                StarRating(rating: skill.userRating ?? 0, interactive: false)
                            }
                            
                            if let code = skill.verificationCode {
                                HStack {
                                    Text(LocalizedStringKey("verification_code_label"))
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    
                                    Spacer()
                                    
                                    Text(code)
                                        .font(.system(.caption, design: .monospaced))
                                        .foregroundColor(Color.blue)
                                }
                            }
                            
                            // Achievement History
                            if !skill.achievementHistory.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(LocalizedStringKey("achievement_history"))
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.primary)
                                    
                                    ForEach(skill.achievementHistory.indices, id: \.self) { index in
                                        let record = skill.achievementHistory[index]
                                        HStack {
                                            StarRating(rating: record.stars, interactive: false)
                                            
                                            Spacer()
                                            
                                            Text(record.achievedAt, style: .date)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
                            }
                        }
                        .padding()
                        .background(Color.blue.opacity(0.05))
                        .cornerRadius(12)
                        
                        // Re-evaluation section (revealed via top-right button)
                        if showUpdateSection {
                            VStack(spacing: 20) {
                                Text(LocalizedStringKey("update_your_rating"))
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                
                                VStack(spacing: 16) {
                                    StarRating(rating: selectedRating, interactive: true) { rating in
                                        selectedRating = rating
                                    }
                                    
                                    Text(selectedRating == 0 ? NSLocalizedString("no_stars", comment: "") : String(format: "%d %@", selectedRating, selectedRating > 1 ? "Stars" : "Star"))
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(.blue)
                                }
                                
                                Button(LocalizedStringKey("update_and_verify")) {
                                    currentVerificationCode = ""
                                    generatedVerificationCode = ""
                                    verificationCode = ""
                                    showingVerification = true
                                }
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(12)
                            }
                            .padding()
                            .background(Color.gray.opacity(0.05))
                            .cornerRadius(12)
                        }
                    } else {
                        // Evaluation section
                        VStack(spacing: 20) {
                            Text(LocalizedStringKey("self_evaluation"))
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            VStack(spacing: 16) {
                                Text(LocalizedStringKey("how_many_stars_question"))
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                
                                StarRating(rating: selectedRating, interactive: true) { rating in
                                    selectedRating = rating
                                }
                                
                                Text(selectedRating == 0 ? NSLocalizedString("no_stars", comment: "") : String(format: "%d %@", selectedRating, selectedRating > 1 ? "Stars" : "Star"))
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.blue)
                            }
                            
                            Button(LocalizedStringKey("evaluate_my_skill")) {
                                currentVerificationCode = ""
                                generatedVerificationCode = ""
                                print("Button clicked - preparing verification")
                                verificationCode = "" // Clear previous input
                                showingVerification = true
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(12)
                        }
                        .padding()
                        .background(Color.gray.opacity(0.05))
                        .cornerRadius(12)
                    }
                    
            Spacer(minLength: 50)
        }
        .padding()
    }
    
    private func verifyAndEvaluate() {
        print("Verification attempt:")
        print("  User input: '\(verificationCode)'")
        print("  Expected: '\(currentVerificationCode)'")
        print("  Length check: \(verificationCode.count) >= \(ExemplarySkillConstants.verificationCodeLength)")
        
        guard verificationCode.count >= ExemplarySkillConstants.verificationCodeLength else {
            print("  FAILED: Length too short")
            verificationError = true
            return
        }
        
        // Use the stored generated code
        if verificationCode == currentVerificationCode {
            print("  SUCCESS: Codes match!")
            onEvaluate(selectedRating, currentVerificationCode)
            dismiss()
        } else {
            print("  FAILED: Codes don't match")
            verificationError = true
        }
    }
    
    private func generateVerificationCode() -> String {
        let characters = Array(ExemplarySkillConstants.allowedCharacters)
        let code = String((0..<ExemplarySkillConstants.verificationCodeLength).map { _ in
            characters.randomElement()!
        })
        print("Generated verification code: \(code)")
        return code
    }
}

struct StarRating: View {
    let rating: Int
    let interactive: Bool
    let onRatingChanged: ((Int) -> Void)?
    
    init(rating: Int, interactive: Bool = false, onRatingChanged: ((Int) -> Void)? = nil) {
        self.rating = rating
        self.interactive = interactive
        self.onRatingChanged = onRatingChanged
    }
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(1...3, id: \.self) { star in
                Button(action: {
                    if interactive {
                        // Allow clicking on filled star to set to 0, or set to star number
                        if star == rating {
                            onRatingChanged?(0) // Clicking filled star sets to 0
                        } else {
                            onRatingChanged?(star)
                        }
                    }
                }) {
                    Image(systemName: star <= rating ? "star.fill" : "star")
                        .font(.title2)
                        .foregroundColor(star <= rating ? .orange : .gray)
                }
                .disabled(!interactive)
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    
    private func generateVerificationCode() -> String {
        let characters = Array(ExemplarySkillConstants.allowedCharacters)
        let code = String((0..<ExemplarySkillConstants.verificationCodeLength).map { _ in
            characters.randomElement()!
        })
        print("Generated verification code: \(code)")
        return code
    }
}

struct VerificationView: View {
    @Binding var verificationCode: String
    @Binding var generatedCode: String
    let onVerify: () -> Void
    let onCancel: () -> Void
    @State private var showingError = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                VStack(spacing: 16) {
                    Text(LocalizedStringKey("verification_required_title"))
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(LocalizedStringKey("verification_required_message"))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                VStack(spacing: 12) {
                    Text(LocalizedStringKey("verification_code_title"))
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text(generatedCode.isEmpty ? NSLocalizedString("no_code_received", comment: "") : generatedCode)
                        .font(.system(.title, design: .monospaced))
                        .foregroundColor(Color.blue)
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                        .onAppear {
                            print("VerificationView displaying code: '\(generatedCode)'")
                        }
                }
                
                VStack(spacing: 12) {
                    Text(LocalizedStringKey("enter_the_code"))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    TextField(LocalizedStringKey("verification_code_title"), text: $verificationCode)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .font(.system(.title3, design: .monospaced))
                        .multilineTextAlignment(.center)
                }
                
                Spacer()
                
                VStack(spacing: 12) {
                    Button(LocalizedStringKey("verify_and_evaluate")) {
                        onVerify()
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
                    
                    Button(LocalizedStringKey("cancel")) {
                        onCancel()
                    }
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                }
            }
            .padding()
            .navigationTitle(LocalizedStringKey("verification_nav_title"))
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                if generatedCode.isEmpty {
                    generatedCode = generateVerificationCode()
                    print("VerificationView generated code: \(generatedCode)")
                }
                print("VerificationView received code: '\(generatedCode)'")
            }
            .alert(LocalizedStringKey("invalid_code_title"), isPresented: $showingError) {
                Button(LocalizedStringKey("ok")) { }
            } message: {
                Text(LocalizedStringKey("invalid_code_message"))
            }
        }
    }
    
    private func generateVerificationCode() -> String {
        let characters = Array(ExemplarySkillConstants.allowedCharacters)
        let code = String((0..<ExemplarySkillConstants.verificationCodeLength).map { _ in
            characters.randomElement()!
        })
        print("Generated verification code: \(code)")
        return code
    }
}

#Preview {
    ExemplarySkillDetailView(
        skill: ExemplarySkill(
            title: "Guitar Master",
            skillDescription: "Mastered guitar playing with over 1000 hours of practice. Can play complex pieces and improvise.",
            imageName: "guitars.fill",
            category: "Music",
            difficultyLevel: 3
        ),
        onEvaluate: { _, _ in }
    )
}
