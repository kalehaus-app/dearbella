import Foundation

/// Reads secret values that are injected at build time from `Secrets.xcconfig`
/// (which is git-ignored). The key flows: Secrets.xcconfig → Info.plist →
/// here. If it's missing, `tmdbAPIKey` is just empty and the app falls back to
/// placeholder gradients instead of crashing.
enum Secrets {
    static var tmdbAPIKey: String {
        (Bundle.main.object(forInfoDictionaryKey: "TMDBApiKey") as? String) ?? ""
    }
}
