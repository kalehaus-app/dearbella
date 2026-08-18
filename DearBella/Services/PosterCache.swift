import UIKit

/// A shared, decoded-image cache for TMDB poster art.
///
/// This replaces the caching that `AsyncImage` *doesn't* do. Three properties
/// matter, and each fixes a real symptom:
///
/// 1. **Decoded images are held in memory.** `AsyncImage` only gets the tiny
///    default `URLCache` on `URLSession.shared` (~512 KB), so posters evict
///    almost immediately and every re-render re-downloads.
/// 2. **Downloads survive view teardown.** The work runs in an unstructured
///    `Task` kept in `inFlight`, so a caller going away (a row re-rendering
///    when a film is saved, a card scrolling off) cancels only the *waiting*,
///    never the download. The image still lands in the cache, so the next
///    appearance is instant.
/// 3. **Failures are retried and never cached.** `AsyncImage` treats `.failure`
///    as terminal and shows the placeholder forever; here a transient error
///    gets three attempts, and nothing negative is remembered.
actor PosterCache {
    static let shared = PosterCache()

    /// Thread-safe decoded-image store. `NSCache` evicts under memory pressure
    /// on its own, so this needs no manual trimming. Kept `nonisolated` so a
    /// view can peek synchronously and render a cached poster on the very
    /// first frame, with no placeholder flash.
    private nonisolated let store = MemoryStore()

    /// One shared download per URL, so a poster that appears in several rows
    /// at once is fetched a single time.
    private var inFlight: [URL: Task<UIImage?, Never>] = [:]

    private nonisolated let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.urlCache = URLCache(
            memoryCapacity: 32 * 1024 * 1024,
            diskCapacity: 256 * 1024 * 1024,
            directory: URL.cachesDirectory.appending(path: "dearbella-posters")
        )
        config.requestCachePolicy = .returnCacheDataElseLoad
        // Posters are immutable per URL, so a long timeout beats a fast failure.
        config.timeoutIntervalForRequest = 30
        return URLSession(configuration: config)
    }()

    /// Synchronous peek at the in-memory cache. Safe from any thread.
    nonisolated func cachedImage(for url: URL) -> UIImage? {
        store.image(for: url)
    }

    /// Returns the poster, downloading it if needed. Cancelling the *caller*
    /// does not cancel the download — see the note above.
    func image(for url: URL) async -> UIImage? {
        if let cached = store.image(for: url) { return cached }

        if let existing = inFlight[url] {
            return await existing.value
        }

        let task = Task { [session] in
            await PosterCache.download(url, session: session)
        }
        inFlight[url] = task

        let image = await task.value
        inFlight[url] = nil

        if let image { store.insert(image, for: url) }
        return image
    }

    /// Fetches and decodes one poster, retrying transient failures.
    ///
    /// A 4xx means there is genuinely no art at that path, so it returns
    /// immediately rather than burning retries on a guaranteed miss.
    private static func download(_ url: URL, session: URLSession) async -> UIImage? {
        for attempt in 0..<3 {
            if attempt > 0 {
                try? await Task.sleep(nanoseconds: UInt64(attempt) * 400_000_000)
            }

            do {
                let (data, response) = try await session.data(from: url)
                guard let http = response as? HTTPURLResponse else { continue }

                if (400..<500).contains(http.statusCode) { return nil }
                guard http.statusCode == 200 else { continue }

                // `preparingForDisplay` decodes off the main thread, so
                // scrolling doesn't stutter on first display of each poster.
                return UIImage(data: data)?.preparingForDisplay() ?? UIImage(data: data)
            } catch {
                continue
            }
        }
        return nil
    }
}

/// A thin `NSCache` wrapper. `NSCache` is already thread-safe, which is what
/// makes the synchronous `cachedImage(for:)` peek above sound.
private final class MemoryStore: @unchecked Sendable {
    private let cache: NSCache<NSURL, UIImage> = {
        let cache = NSCache<NSURL, UIImage>()
        cache.countLimit = 400
        cache.totalCostLimit = 96 * 1024 * 1024
        return cache
    }()

    func image(for url: URL) -> UIImage? {
        cache.object(forKey: url as NSURL)
    }

    func insert(_ image: UIImage, for url: URL) {
        let scale = image.scale
        let cost = Int(image.size.width * scale * image.size.height * scale * 4)
        cache.setObject(image, forKey: url as NSURL, cost: cost)
    }
}
