import Foundation

/// Reads secret values injected at build time from `Secrets.xcconfig` (which is
/// git-ignored). The key flows: Secrets.xcconfig → Info.plist → here. If it's
/// missing or wasn't substituted, `tmdbAPIKey` is empty and the app falls back
/// to placeholder gradients instead of crashing.
enum Secrets {
    static var tmdbAPIKey: String {
        value(forKey: "TMDBApiKey")
    }

    static var anthropicAPIKey: String {
        value(forKey: "ClaudeApiKey")
    }

    private static func value(forKey key: String) -> String {
        let raw = (Bundle.main.object(forInfoDictionaryKey: key) as? String) ?? ""
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        // If build-setting substitution didn't run, the value is still the
        // literal "$(...)" — treat that as no key.
        return trimmed.contains("$(") ? "" : trimmed
    }
}
