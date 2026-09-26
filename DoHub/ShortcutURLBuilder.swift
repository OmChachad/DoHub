import Foundation

/// Builds `shortcuts://x-callback-url/run-shortcut` URLs and recognizes DoHub's callback URLs.
nonisolated enum ShortcutURLBuilder {
    /// The input sent to a shortcut. The URL scheme supports a single input per run.
    enum Input: Equatable, Sendable {
        case none
        case clipboard
        case text(String)
    }

    /// The x-callback parameters Shortcuts calls back with when a run ends.
    enum Callback: String, CaseIterable, Sendable {
        case success
        case cancel
        case error

        var parameterName: String { "x-\(rawValue)" }

        var outcome: RunOutcome {
            switch self {
            case .success: .succeeded
            case .cancel: .cancelled
            case .error: .failed
            }
        }
    }

    static let callbackScheme = "dohub"
    private static let callbackHost = "x-callback"

    /// Characters left unescaped in query values. Everything else, including `&`, `=`, and `+`,
    /// is percent-encoded so nested callback URLs and JSON input survive intact.
    private static let unreservedCharacters = CharacterSet(
        charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~"
    )

    /// The URL that runs `shortcutName`. `context` is echoed back in every callback URL.
    static func runURL(shortcutName: String, input: Input, context: [String: String]) -> URL? {
        var items = [("name", shortcutName)]
        switch input {
        case .none:
            break
        case .clipboard:
            items.append(("input", "clipboard"))
        case .text(let text):
            items.append(("input", "text"))
            items.append(("text", text))
        }
        for callback in Callback.allCases {
            guard let url = callbackURL(callback, context: context) else { return nil }
            items.append((callback.parameterName, url.absoluteString))
        }

        var components = URLComponents()
        components.scheme = "shortcuts"
        components.host = "x-callback-url"
        components.path = "/run-shortcut"
        components.percentEncodedQuery = encodedQuery(items)
        return components.url
    }

    static func callbackURL(_ callback: Callback, context: [String: String]) -> URL? {
        var components = URLComponents()
        components.scheme = callbackScheme
        components.host = callbackHost
        components.path = "/\(callback.rawValue)"
        let items = context.sorted { $0.key < $1.key }.map { ($0.key, $0.value) }
        components.percentEncodedQuery = encodedQuery(items)
        return components.url
    }

    /// The callback a URL represents, or `nil` if it isn't a DoHub callback.
    static func callback(from url: URL) -> Callback? {
        guard url.scheme == callbackScheme, url.host() == callbackHost else { return nil }
        return Callback(rawValue: url.lastPathComponent)
    }

    /// Encodes parameters as a JSON dictionary, skipping rows without a key.
    static func parametersJSON(_ parameters: [ShortcutParameter]) -> String {
        var dictionary: [String: String] = [:]
        for parameter in parameters {
            let key = parameter.key.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !key.isEmpty else { continue }
            dictionary[key] = parameter.value
        }
        guard let data = try? JSONSerialization.data(withJSONObject: dictionary, options: [.sortedKeys]) else {
            return "{}"
        }
        return String(decoding: data, as: UTF8.self)
    }

    private static func encodedQuery(_ items: [(String, String)]) -> String {
        items.map { "\(encode($0.0))=\(encode($0.1))" }.joined(separator: "&")
    }

    private static func encode(_ string: String) -> String {
        string.addingPercentEncoding(withAllowedCharacters: unreservedCharacters) ?? string
    }
}
