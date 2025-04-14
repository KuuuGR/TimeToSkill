import Foundation

class QuoteLoader {
    
    static func loadLocalizedQuotes() -> [Quote] {
        let preferredLang = Locale.preferredLanguages.first ?? "en"
        let langPrefix = String(preferredLang.prefix(2)).lowercased()
        
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
