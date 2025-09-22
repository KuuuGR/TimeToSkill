//
//  ExemplarySkillDetailView.swift
//  TimeToSkill
//
//  Created by admin on 10/04/2025.
//

import SwiftUI

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
    
    var body: some View {
        NavigationStack {
            ScrollView {
                skillDetailContent
            }
            .navigationTitle("Skill Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
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
        }
    }
    
    private var skillDetailContent: some View {
        VStack(spacing: 24) {
                    // Header with image and title
                    VStack(spacing: 16) {
                        Image(systemName: skill.imageName)
                            .font(.system(size: 80))
                            .foregroundColor(skill.isObtained ? .blue : .gray)
                            .frame(width: 120, height: 120)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(skill.isObtained ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
                            )
                        
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
                        Text("Description")
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
                            Text("Achievement Status")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            HStack {
                                Text("Obtained:")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                Text(skill.obtainedAt?.formatted(date: .abbreviated, time: .omitted) ?? "Unknown")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                            
                            HStack {
                                Text("Your Rating:")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                StarRating(rating: skill.userRating ?? 0, interactive: false)
                            }
                            
                            if let code = skill.verificationCode {
                                HStack {
                                    Text("Verification Code:")
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
                                    Text("Achievement History")
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
                    } else {
                        // Evaluation section
                        VStack(spacing: 20) {
                            Text("Self-Evaluation")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            VStack(spacing: 16) {
                                Text("How many stars do you deserve for this skill?")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                
                                StarRating(rating: selectedRating, interactive: true) { rating in
                                    selectedRating = rating
                                }
                                
                                Text(selectedRating == 0 ? "No Stars" : "\(selectedRating) Star\(selectedRating > 1 ? "s" : "")")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.blue)
                            }
                            
                            Button("Evaluate My Skill") {
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
                    Text("Verification Required")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Please enter the verification code below to confirm your self-evaluation:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                VStack(spacing: 12) {
                    Text("Verification Code:")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text(generatedCode.isEmpty ? "NO CODE RECEIVED" : generatedCode)
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
                    Text("Enter the code above:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    TextField("Verification Code", text: $verificationCode)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .font(.system(.title3, design: .monospaced))
                        .multilineTextAlignment(.center)
                }
                
                Spacer()
                
                VStack(spacing: 12) {
                    Button("Verify & Evaluate") {
                        onVerify()
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
                    
                    Button("Cancel") {
                        onCancel()
                    }
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                }
            }
            .padding()
            .navigationTitle("Verification")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                if generatedCode.isEmpty {
                    generatedCode = generateVerificationCode()
                    print("VerificationView generated code: \(generatedCode)")
                }
                print("VerificationView received code: '\(generatedCode)'")
            }
            .alert("Invalid Code", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text("Please enter the correct verification code.")
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
