import SwiftUI

enum CatalogArtwork {
    /// Emoji stored as `imageName` are drawn as text. SF Symbols stay symbols.
    static func isEmoji(_ name: String) -> Bool {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        return trimmed.unicodeScalars.contains { scalar in
            scalar.properties.isEmojiPresentation || (scalar.properties.isEmoji && scalar.value > 255)
        }
    }
}

struct CatalogArtworkIcon: View {
    let name: String
    var side: CGFloat
    var dimmed: Bool

    var body: some View {
        ZStack {
            if let image = PlatformImageLoader.image(namedOrPath: name) {
                Image(platformImage: image)
                    .resizable()
                    .scaledToFit()
                    .saturation(dimmed ? 0 : 1)
                    .opacity(dimmed ? 0.6 : 1)
            } else if CatalogArtwork.isEmoji(name) {
                Text(name)
                    .font(.system(size: side * 0.42))
                    .opacity(dimmed ? 0.6 : 1)
            } else {
                Image(systemName: PlatformImageLoader.systemSymbolExists(name) ? name : "star.fill")
                    .font(.system(size: side * 0.42))
                    .foregroundColor(dimmed ? .gray : .primary)
            }
        }
        .frame(width: side, height: side)
        .background(
            RoundedRectangle(cornerRadius: side * 0.16)
                .fill(dimmed ? Color.gray.opacity(0.1) : Color.blue.opacity(0.1))
        )
    }
}
