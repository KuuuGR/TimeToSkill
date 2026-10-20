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
        
        //print("📘 Detected language prefix:", langPrefix)
        
        let preferredFile = "\(langPrefix)_quotes"
        let fallbackFile = "en_quotes"

        if let quotes = loadQuotes(from: preferredFile) {
            return quotes
        } else if let fallback = loadQuotes(from: fallbackFile) {
            return fallback
        }

        print("❌ No quotes file found for locale prefix \(langPrefix)")
        return []
    }

    private static func loadQuotes(from fileName: String) -> [Quote]? {
        guard let url = Bundle.main.url(forResource: fileName, withExtension: "json") else {
            print("⚠️ Could not find \(fileName).json in bundle")
            return nil
        }

        do {
            let data = try Data(contentsOf: url)
            let quotes = try JSONDecoder().decode([Quote].self, from: data)
            return quotes
        } catch {
            print("❌ Failed to decode \(fileName).json:", error)
            return nil
        }
    }
}
