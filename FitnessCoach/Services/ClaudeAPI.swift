import Foundation

/// Talks to the Claude API over HTTPS. (Swift has no official Anthropic SDK, so requests are built by hand.)
struct ClaudeAPI {
    static let model = "claude-opus-5-5"
    /// The API version sent in the `anthropic-version` header.
    static let apiVersion = "2026-10-21"
    static let baseURL = URL(string: "https://api.anthropic.com")!

    let apiKey: String
    var session: URLSession = .shared

    /// Uses the key saved in the Keychain, or returns nil if there isn't one.
    static func fromKeychain() -> ClaudeAPI? {
        guard let key = KeychainStore.read(.anthropicAPIKey), !key.isEmpty else { return nil }
        return ClaudeAPI(apiKey: key)
    }

    /// Checks that the key works and the app's model is available. Uses no tokens, so it's free.
    /// Returns the model's display name, e.g. "Claude Opus 5.5".
    func checkConnection() async throws -> String {
        let data = try await send(makeRequest(path: "/v1/models/\(Self.model)"))
        struct ModelInfo: Decodable {
            let id: String
            let display_name: String?
        }
        let info = try JSONDecoder().decode(ModelInfo.self, from: data)
        return info.display_name ?? info.id
    }

    // MARK: - Requests

    func makeRequest(path: String, method: String = "GET", body: Data? = nil) -> URLRequest {
        var request = URLRequest(url: Self.baseURL.appending(path: path))
        request.httpMethod = method
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue(Self.apiVersion, forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.httpBody = body
        return request
    }

    /// Sends a request and returns the body, or throws a `ClaudeAPIError` with a readable message.
    func send(_ request: URLRequest) async throws -> Data {
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch let error as URLError {
            throw ClaudeAPIError.network(error)
        }
        guard let http = response as? HTTPURLResponse else { throw ClaudeAPIError.invalidResponse }
        guard (200..<300).contains(http.statusCode) else {
            throw ClaudeAPIError(status: http.statusCode, body: data)
        }
        return data
    }
}

enum ClaudeAPIError: LocalizedError {
    case network(URLError)
    case invalidResponse
    case http(status: Int, type: String?, message: String?)

    /// Builds an error from an API error response such as
    /// `{"type":"error","error":{"type":"authentication_error","message":"invalid x-api-key"}}`.
    init(status: Int, body: Data) {
        struct Envelope: Decodable {
            struct Detail: Decodable {
                let type: String?
                let message: String?
            }
            let error: Detail?
        }
        let detail = (try? JSONDecoder().decode(Envelope.self, from: body))?.error
        self = .http(status: status, type: detail?.type, message: detail?.message)
    }

    var errorDescription: String? {
        switch self {
        case .network(let error):
            switch error.code {
            case .notConnectedToInternet, .networkConnectionLost, .dataNotAllowed:
                return "No internet connection."
            case .timedOut:
                return "The request timed out. Check your connection and try again."
            default:
                return "Couldn't reach Claude: \(error.localizedDescription)"
            }
        case .invalidResponse:
            return "Claude sent an unexpected response."
        case .http(let status, _, let message):
            switch status {
            case 401:
                return "This API key isn't valid. Check that it was copied completely, or create a new one."
            case 402:
                return "Your Anthropic account needs a payment method or more credit (Billing in the console)."
            case 403:
                return "This API key doesn't have permission for that. \(message ?? "")"
            case 404:
                return "Claude couldn't find what the app asked for. \(message ?? "")"
            case 429:
                return "Too many requests, or your spending limit was reached. Wait a moment and try again."
            case 500..<600:
                return "Claude's servers had a problem (\(status)). Try again shortly."
            default:
                return message.map { "Error \(status): \($0)" } ?? "Error \(status)."
            }
        }
    }
}
