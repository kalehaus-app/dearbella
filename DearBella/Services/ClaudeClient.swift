import Foundation

/// A tool we expose to Claude so it returns structured data instead of prose.
/// `inputSchema` is a raw JSON-schema dictionary.
struct ClaudeTool {
    let name: String
    let description: String
    let inputSchema: [String: Any]

    var asDictionary: [String: Any] {
        ["name": name, "description": description, "input_schema": inputSchema]
    }
}

enum ClaudeError: Error {
    case missingKey
    case http(Int)
    case badResponse
    case noToolUse
}

/// Parses a JSON-schema string into a dictionary. Writing schemas as JSON text
/// (rather than nested Swift literals) keeps the compiler happy and the schema
/// readable.
func claudeJSONSchema(_ string: String) -> [String: Any] {
    guard let object = try? JSONSerialization.jsonObject(with: Data(string.utf8)),
          let dictionary = object as? [String: Any] else {
        return [:]
    }
    return dictionary
}

/// Client for our Claude calls. Routes through a Vercel proxy that holds the
/// Anthropic API key and rebuilds the full Messages API body (model, max_tokens,
/// thinking, output_config) server-side. We send `system`, `userPrompt`, and the
/// forced `tool`; the proxy returns the standard Anthropic response (a content
/// array with a tool_use block), which we decode into `Output`.
struct ClaudeClient {
    static let shared = ClaudeClient()

    /// Sonnet 4.6 — the model the proxy uses (kept here for reference).
    let model = "claude-sonnet-4-6"

    private let session = URLSession.shared
    private let endpoint = URL(string: "https://dearbella-proxy.vercel.app/api/claude")!

    /// The proxy holds the key, so Claude is always reachable from the app's side.
    var hasAPIKey: Bool { true }

    /// Sends one request that forces `tool`, then decodes the tool input as `Output`.
    func generate<Output: Decodable>(
        system: String,
        userPrompt: String,
        tool: ClaudeTool,
        as outputType: Output.Type
    ) async throws -> Output {
        // The proxy rebuilds the full Anthropic body server-side.
        let body: [String: Any] = [
            "system": system,
            "userPrompt": userPrompt,
            "tool": tool.asDictionary,
        ]

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw ClaudeError.badResponse }
        guard http.statusCode == 200 else { throw ClaudeError.http(http.statusCode) }

        // Pull the forced tool_use block's `input` object out of the response
        // and decode it as our expected shape.
        guard
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
            let content = json["content"] as? [[String: Any]],
            let toolBlock = content.first(where: { ($0["type"] as? String) == "tool_use" }),
            let input = toolBlock["input"] as? [String: Any]
        else {
            throw ClaudeError.noToolUse
        }

        let inputData = try JSONSerialization.data(withJSONObject: input)
        return try JSONDecoder().decode(Output.self, from: inputData)
    }
}
