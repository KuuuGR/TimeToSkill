import SwiftUI

/// Curated emoji catalog for Skill icon picking.
enum SkillEmojiCatalog {
    struct Section: Identifiable {
        let id: String
        let symbol: String
        let titleKey: LocalizedStringKey
        let emojis: [String]
    }

    static let sections: [Section] = [
        Section(
            id: "faces",
            symbol: "😀",
            titleKey: "skill_emoji_section_faces",
            emojis: [
                "😀", "😃", "😄", "😁", "😆", "😅", "😂", "🙂", "😉", "😊",
                "😇", "🥰", "😍", "🤩", "😎", "🤓", "🧐", "😏", "😌", "😴",
                "🤔", "🫡", "🤗", "😮", "😲", "🥺", "😤", "🤯", "😈", "👻",
                "🤢", "😵", "🧟‍♀️"
            ]
        ),
        Section(
            id: "work",
            symbol: "💼",
            titleKey: "skill_emoji_section_work",
            emojis: [
                "💼", "💻", "🖥️", "⌨️", "🖱️", "📱", "📞", "📧", "📅", "📁",
                "📂", "📊", "📈", "📉", "🧾", "✏️", "🖊️", "📝", "🗂️", "🏢",
                "📨", "📰", "🔎", "📒", "⚖️"
            ]
        ),
        Section(
            id: "creativity",
            symbol: "🎨",
            titleKey: "skill_emoji_section_creativity",
            emojis: [
                "🎨", "🖌️", "🖍️", "🧵", "🧶", "✂️", "🎭", "🖼️", "📸", "📷",
                "🎬", "🎥", "🪧", "🪄", "✨", "🌟", "💡", "🧩", "🪩", "🖋️",
                "✿", "✎", "🪶", "📽"
            ]
        ),
        Section(
            id: "fitness",
            symbol: "💪",
            titleKey: "skill_emoji_section_fitness",
            emojis: [
                "💪", "🏋️", "🤸", "🧘", "🏃", "🚴", "🏊", "⚽", "🏀", "🎾",
                "🏐", "🥊", "🥋", "⛷️", "🏂", "🧗", "⛳", "🏆", "🥇", "🎯",
                "🩰", "🩸", "☯️"
            ]
        ),
        Section(
            id: "learning",
            symbol: "📚",
            titleKey: "skill_emoji_section_learning",
            emojis: [
                "📚", "📖", "📕", "📗", "📘", "📙", "📓", "📔", "✏️", "📌",
                "📎", "🔬", "🔭", "🧪", "🧬", "🧮", "🧠", "🎓", "🏫", "🗣️",
                "🔖", "🦠", "⚗️", "⚕️", "🎒"
            ]
        ),
        Section(
            id: "gaming",
            symbol: "🎮",
            titleKey: "skill_emoji_section_gaming",
            emojis: [
                "🎮", "🕹️", "🎲", "♟️", "🃏", "🎰", "👾", "🤖", "🐉", "⚔️",
                "🛡️", "🗺️", "🏹", "🪄", "💣", "🚀", "♛", "💀", "☠️", "🗿",
                "🔫", "🏴‍☠️"
            ]
        ),
        Section(
            id: "music",
            symbol: "🎵",
            titleKey: "skill_emoji_section_music",
            emojis: [
                "🎵", "🎶", "🎼", "🎤", "🎧", "🎸", "🎹", "🥁", "🎺", "🎷",
                "🎻", "🪕", "🪘", "📻", "🔊", "♫", "𝄞", "🎙"
            ]
        ),
        Section(
            id: "food",
            symbol: "🍳",
            titleKey: "skill_emoji_section_food",
            emojis: [
                "🍳", "🥘", "🍲", "🥗", "🍕", "🍔", "🌮", "🍣", "🍜", "🍝",
                "🥐", "🍞", "🧀", "🍎", "🍇", "☕", "🍵", "🧃", "🧁", "🍰",
                "🍥", "🍓", "🎂"
            ]
        ),
        Section(
            id: "nature",
            symbol: "🌱",
            titleKey: "skill_emoji_section_nature",
            emojis: [
                "🌱", "🌿", "🍀", "🌳", "🌲", "🌴", "🌵", "🌸", "🌺", "🌻",
                "🌞", "🌙", "⭐", "🌈", "🌊", "🔥", "❄️", "⛰️", "🏞️", "🌍",
                "🍂", "🌑", "🌕", "🦋", "🐾", "🦅", "🐠", "🪸", "🪼", "🦀",
                "🦢", "🌀", "🍄", "🌹", "🌷", "💐", "🥀", "🕊", "☀️", "🏕",
                "♻️", "☄️"
            ]
        ),
        Section(
            id: "technology",
            symbol: "🚀",
            titleKey: "skill_emoji_section_technology",
            emojis: [
                "🚀", "🛰️", "📡", "💾", "🔌", "🔋", "⚙️", "🛠️", "🧰", "🧲",
                "🖨️", "🧭", "⌚", "🤖", "🛸", "🌐", "☢️", "☣️"
            ]
        ),
        Section(
            id: "achievement",
            symbol: "🏆",
            titleKey: "skill_emoji_section_achievement",
            emojis: [
                "🏆", "🥇", "🥈", "🥉", "🎖️", "🏅", "👑", "💎", "🔑", "🔓",
                "✅", "✔️", "📌", "🚩", "🎯", "🚀", "✩", "✮", "⚜️", "💫",
                "🔰"
            ]
        ),
        Section(
            id: "lifestyle",
            symbol: "❤️",
            titleKey: "skill_emoji_section_lifestyle",
            emojis: [
                "❤️", "🧡", "💛", "💚", "💙", "💜", "🖤", "🤍", "💯", "🎉",
                "🎊", "🏠", "🛏️", "🧼", "🧺", "🛒", "🎁", "🕯️", "⏳", "🕰️",
                "💔", "❣️", "💌", "💋", "🫀", "🪞", "🛍", "🎀", "🎫", "💭",
                "💍", "⛱️", "☂️", "✈️", "💰", "🩹", "🔮", "⛩️", "🏙", "🧸"
            ]
        )
    ]
}

/// Button that opens a curated emoji picker sheet/popover for Skill icons.
struct SkillEmojiPickerButton: View {
    @Binding var selection: String
    @State private var isPresented = false
    #if canImport(UIKit)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    #endif

    /// Present as a popover on regular-width iOS layouts; use a sheet elsewhere.
    private var usePopover: Bool {
        #if canImport(UIKit)
        return horizontalSizeClass == .regular
        #else
        return false
        #endif
    }

    var body: some View {
        Button {
            isPresented = true
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.secondary.opacity(0.3))
                if selection.isEmpty {
                    Image(systemName: "face.smiling")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                } else {
                    Text(selection)
                        .font(.title2)
                }
            }
            .frame(width: 56, height: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(LocalizedStringKey("skill_icon_label"))
        .accessibilityValue(selection.isEmpty
            ? String(localized: "skill_emoji_picker_none")
            : selection)
        .modifier(EmojiPickerPresentation(
            isPresented: $isPresented,
            usePopover: usePopover,
            selection: $selection
        ))
    }
}

private struct EmojiPickerPresentation: ViewModifier {
    @Binding var isPresented: Bool
    let usePopover: Bool
    @Binding var selection: String

    func body(content: Content) -> some View {
        if usePopover {
            content.popover(isPresented: $isPresented) {
                SkillEmojiPickerView(selection: $selection, isPresented: $isPresented)
                    .frame(minWidth: 320, minHeight: 420)
            }
        } else {
            content.sheet(isPresented: $isPresented) {
                NavigationStack {
                    SkillEmojiPickerView(selection: $selection, isPresented: $isPresented)
                        .navigationTitle(LocalizedStringKey("skill_emoji_picker_title"))
                        .inlineNavigationBarTitle()
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button(LocalizedStringKey("cancel")) {
                                    isPresented = false
                                }
                            }
                        }
                }
                .mediumLargePresentationDetents()
            }
        }
    }
}

struct SkillEmojiPickerView: View {
    @Binding var selection: String
    @Binding var isPresented: Bool

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 6)

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 20) {
                ForEach(SkillEmojiCatalog.sections) { section in
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 8) {
                            Text(section.symbol)
                            Text(section.titleKey)
                                .font(.headline)
                        }

                        LazyVGrid(columns: columns, spacing: 8) {
                            ForEach(section.emojis, id: \.self) { emoji in
                                Button {
                                    selection = emoji
                                    isPresented = false
                                } label: {
                                    Text(emoji)
                                        .font(.title2)
                                        .frame(maxWidth: .infinity, minHeight: 40)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(selection == emoji
                                                      ? Color.accentColor.opacity(0.18)
                                                      : Color.secondary.opacity(0.08))
                                        )
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel(emoji)
                            }
                        }
                    }
                }
            }
            .padding()
        }
    }
}
