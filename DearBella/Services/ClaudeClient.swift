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

/// Minimal client for Anthropic's Messages API.
///
/// There's no official Swift SDK, so we call the REST endpoint directly with
/// `URLSession` (the documented path for unsupported languages). We force a
/// single tool call so Claude's reply is always clean structured JSON that we
/// decode into `Output`.
///
/// PRODUCTION: the API key currently ships inside the app. Before a public App
/// Store release, move these calls behind a small backend proxy that holds the
/// key, and set a spend limit in the Anthropic Console in the meantime.
struct ClaudeClient {
    static let shared = ClaudeClient()

    /// Sonnet 4.6 — fast and cost-efficient, ideal for a recommendation chat.
    let model = "claude-sonnet-4-6"

    private let session = URLSession.shared
    private let endpoint = URL(string: "https://api.anthropic.com/v1/messages")!

    var hasAPIKey: Bool { !Secrets.anthropicAPIKey.isEmpty }

    /// Sends one request that forces `tool`, then decodes the tool input as `Output`.
    func generate<Output: Decodable>(
        system: String,
        userPrompt: String,
        tool: ClaudeTool,
        as outputType: Output.Type
    ) async throws -> Output {
        guard hasAPIKey else { throw ClaudeError.missingKey }

        let body: [String: Any] = [
            "model": model,
            "max_tokens": 1024,
            "system": system,
            // Thinking off + low effort keeps replies fast and cheap.
            "thinking": ["type": "disabled"],
            "output_config": ["effort": "low"],
            "tools": [tool.asDictionary],
            "tool_choice": ["type": "tool", "name": tool.name],
            "messages": [["role": "user", "content": userPrompt]],
        ]

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(Secrets.anthropicAPIKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
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
