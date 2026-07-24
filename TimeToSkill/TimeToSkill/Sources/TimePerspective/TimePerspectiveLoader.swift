import Foundation

/// Errors thrown while loading the bundled Time Perspective library.
enum TimePerspectiveLoaderError: Error, LocalizedError {
    case assetNotFound(resourceName: String)
    case dataReadFailed(underlying: Error)
    case decodingFailed(underlying: Error)

    var errorDescription: String? {
        switch self {
        case .assetNotFound(let resourceName):
            return "Time Perspective asset \"\(resourceName).json\" was not found in the app bundle."
        case .dataReadFailed(let underlying):
            return "Failed to read perspectives.json: \(underlying.localizedDescription)"
        case .decodingFailed(let underlying):
            return "Failed to decode perspectives.json: \(underlying.localizedDescription)"
        }
    }
}

/// Loads and decodes `perspectives.json` from the application bundle.
enum TimePerspectiveLoader {
    private static let resourceName = "perspectives"

    /// Decodes the bundled library into `[TimePerspective]`.
    /// - Parameter bundle: Bundle containing the JSON asset (defaults to `.main`).
    /// - Throws: `TimePerspectiveLoaderError` when the asset is missing or invalid.
    static func loadLibrary(from bundle: Bundle = .main) throws -> [TimePerspective] {
        guard let url = bundle.url(forResource: resourceName, withExtension: "json") else {
            throw TimePerspectiveLoaderError.assetNotFound(resourceName: resourceName)
        }

        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            throw TimePerspectiveLoaderError.dataReadFailed(underlying: error)
        }

        do {
            return try JSONDecoder().decode([TimePerspective].self, from: data)
        } catch {
            throw TimePerspectiveLoaderError.decodingFailed(underlying: error)
        }
    }
}
