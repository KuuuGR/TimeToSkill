import Foundation

class QuoteLoader {
    
    static func loadLocalizedQuotes() -> [Quote] {
        let preferredLang = LanguageState.shared.bundleCode()
        let langPrefix: String
        if let hyphen = preferredLang.firstIndex(of: "-") {
            langPrefix = String(preferredLang[..<hyphen]).lowercased()
        } else {
            langPrefix = preferredLang.lowercased()
        }
        
        let preferredFile = "\(langPrefix)_quotes"
        let fallbackFile = "en_quotes"

        let quotes: [Quote]
        if let loaded = loadQuotes(from: preferredFile) {
            quotes = loaded
        } else if let fallback = loadQuotes(from: fallbackFile) {
            quotes = fallback
        } else {
            print("❌ No quotes file found for locale prefix \(langPrefix)")
            return []
        }

        // Interslavic Latinica source → Cyrilica / Glagolica at presentation time.
        guard preferredLang == "isv",
              let script = LanguageState.shared.script(),
              script != .latin else {
            return quotes
        }
        return quotes.map { quote in
            Quote(
                quote: InterslavicTransliterator.convert(quote.quote, to: script),
                author: InterslavicTransliterator.convert(quote.author, to: script)
            )
        }
    }

    private static func loadQuotes(from fileName: String) -> [Quote]? {
        guard let url = Bundle.main.url(forResource: fileName, withExtension: "json") else {
            print("⚠️ Could not find \(fileName).json in bundle")
            return nil
        }

        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode([Quote].self, from: data)
        } catch {
            print("❌ Failed to decode \(fileName).json:", error)
            return nil
        }
    }
}
