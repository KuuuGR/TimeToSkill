import SwiftUI
import PhotosUI

struct CustomExemplarySkillSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var title: String = ""
    @State private var description: String = ""
    @State private var category: String = ""
    @State private var selectedPresetCategory: String = "cat_custom"
    @State private var difficulty: Int = 1
    @State private var oneStarDesc: String = ""
    @State private var twoStarDesc: String = ""
    @State private var threeStarDesc: String = ""
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var imageData: Data? = nil
    @State private var builtinSelection: String? = nil
    let onCreate: (String, String, String, Int, String, String, String, String?) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text(LocalizedStringKey("skill_details_title"))) {
                    TextField(LocalizedStringKey("enter_skill_name"), text: $title)
                    TextField(LocalizedStringKey("description"), text: $description, axis: .vertical)
                        .lineLimit(3...6)
                    Picker(LocalizedStringKey("category_label"), selection: $selectedPresetCategory) {
                        ForEach(presetCategories, id: \.self) { key in
                            Text(LocalizedStringKey(key)).tag(key)
                        }
                    }
                    if selectedPresetCategory == "cat_custom" || selectedPresetCategory == "Custom" {
                        TextField(LocalizedStringKey("category_custom_placeholder"), text: $category)
                    }
                    Stepper(value: $difficulty, in: 1...10) {
                        Text(LocalizedStringKey("difficulty_label")) + Text(": \(difficulty)")
                    }
                }
                Section(header: Text(LocalizedStringKey("image_label"))) {
                    HStack {
                        if let data = imageData, let ui = UIImage(data: data) {
                            Image(uiImage: ui)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 80)
                                .cornerRadius(8)
                        } else {
                            Image(systemName: "photo")
                                .font(.title)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        PhotosPicker(selection: $selectedItem, matching: .images) {
                            Text(LocalizedStringKey("choose_image"))
                        }
                        .onChange(of: selectedItem) { newItem in
                            guard let item = newItem else { return }
                            Task {
                                if let raw = try? await item.loadTransferable(type: Data.self), let ui = UIImage(data: raw) {
                                    let resized = resizeImage(ui, to: CGSize(width: 300, height: 300))
                                    imageData = resized.pngData()
                                } else {
                                    imageData = try? await item.loadTransferable(type: Data.self)
                                }
                            }
                        }
                    }
                    // Built-in icons gallery
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(bundledIcons, id: \.self) { icon in
                                Button {
                                    imageData = nil // prioritize built-in icon name
                                    selectedItem = nil
                                    builtinSelection = icon
                                } label: {
                                    Image(systemName: icon)
                                        .frame(width: 44, height: 44)
                                        .background(RoundedRectangle(cornerRadius: 8).fill((builtinSelection == icon) ? Color.blue.opacity(0.2) : Color.gray.opacity(0.1)))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                Section(header: Text(LocalizedStringKey("star_descriptions_title"))) {
                    TextField(LocalizedStringKey("one_star_description"), text: $oneStarDesc, axis: .vertical)
                        .lineLimit(2...4)
                    TextField(LocalizedStringKey("two_star_description"), text: $twoStarDesc, axis: .vertical)
                        .lineLimit(2...4)
                    TextField(LocalizedStringKey("three_star_description"), text: $threeStarDesc, axis: .vertical)
                        .lineLimit(2...4)
                }
            }
            .navigationTitle(LocalizedStringKey("add_skill"))
            .onAppear {
                if !presetCategories.contains(selectedPresetCategory) {
                    selectedPresetCategory = "cat_custom"
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button(LocalizedStringKey("cancel")) { dismiss() } }
                ToolbarItem(placement: .primaryAction) {
                    Button(LocalizedStringKey("create")) {
                        var savedPath: String? = nil
                        var imageName: String? = nil
                        if let data = imageData { savedPath = saveImageData(data) }
                        if let icon = builtinSelection { imageName = icon }
                        let finalCategoryKey = (selectedPresetCategory == "cat_custom" || selectedPresetCategory == "Custom") ? nil : selectedPresetCategory
                        let finalCategory = finalCategoryKey != nil ? NSLocalizedString(finalCategoryKey!, comment: "") : category.trimmingCharacters(in: .whitespaces)
                        onCreate(
                            title.trimmingCharacters(in: .whitespaces),
                            description.trimmingCharacters(in: .whitespacesAndNewlines),
                            finalCategory.isEmpty ? "Custom" : finalCategory,
                            difficulty,
                            oneStarDesc.trimmingCharacters(in: .whitespacesAndNewlines),
                            twoStarDesc.trimmingCharacters(in: .whitespacesAndNewlines),
                            threeStarDesc.trimmingCharacters(in: .whitespacesAndNewlines),
                            savedPath ?? imageName
                        )
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}

private func saveImageData(_ data: Data) -> String? {
    let fm = FileManager.default
    guard let dir = fm.urls(for: .documentDirectory, in: .userDomainMask).first else { return nil }
    let filename = "skill_\(UUID().uuidString).png"
    let url = dir.appendingPathComponent(filename)
    if let ui = UIImage(data: data), let png = ui.pngData() {
        try? png.write(to: url)
    } else {
        try? data.write(to: url)
    }
    return url.path
}

private func resizeImage(_ image: UIImage, to targetSize: CGSize) -> UIImage {
    let renderer = UIGraphicsImageRenderer(size: targetSize)
    return renderer.image { _ in
        image.draw(in: CGRect(origin: .zero, size: targetSize))
    }
}

private let bundledIcons: [String] = [
    "star.fill", "guitars.fill", "globe", "book.fill", "pencil", "paintbrush.fill",
    "camera.fill", "hammer.fill", "gamecontroller.fill", "music.note", "figure.run",
    "laptopcomputer", "brain.head.profile", "mic.fill", "airplane", "bicycle",
    "lightbulb.fill", "wrench.fill", "leaf.fill", "flame.fill", "timer",
    "doc.text.fill", "graduationcap.fill", "chart.bar.fill", "plus.slash.minus",
    "bag.fill", "cart.fill", "banknote", "dollarsign.circle.fill", "bitcoinsign.circle",
    "shield.checkerboard", "lock.fill", "bolt.fill", "sparkles", "paperplane.fill",
    "mappin.and.ellipse", "house.fill", "building.2.fill", "tortoise.fill", "hare.fill",
    "scissors", "paintpalette.fill", "fork.knife", "cup.and.saucer.fill"
]

private let presetCategories: [String] = [
    "cat_custom",
    "cat_music",
    "cat_language",
    "cat_art",
    "cat_coding",
    "cat_fitness",
    "cat_cooking",
    "cat_photography",
    "cat_writing",
    "cat_public_speaking",
    "cat_science",
    "cat_math",
    "cat_engineering",
    "cat_design",
    "cat_business",
    "cat_marketing",
    "cat_finance",
    "cat_investing",
    "cat_entrepreneurship",
    "cat_psychology",
    "cat_education",
    "cat_history",
    "cat_geography",
    "cat_health",
    "cat_meditation",
    "cat_yoga",
    "cat_sports",
    "cat_dance",
    "cat_theatre",
    "cat_film",
    "cat_editing",
    "cat_3d",
    "cat_ai",
    "cat_data",
    "cat_cybersecurity",
    "cat_gardening",
    "cat_diy",
    "cat_travel",
    "cat_cars",
    "cat_parenting",
    "cat_animals"
]


