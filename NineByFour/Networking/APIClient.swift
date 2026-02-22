import Foundation

actor APIClient {
    static let shared = APIClient()

    private let baseURL: String
    private let decoder: JSONDecoder
    private let session: URLSession

    private init() {
        self.baseURL = AppConstants.apiBaseURL
        self.decoder = JSONDecoder()
        self.session = URLSession.shared
    }

    // MARK: - JSON Request

    func request<T: Decodable>(
        endpoint: APIEndpoint,
        body: Encodable? = nil,
        queryItems: [URLQueryItem]? = nil
    ) async throws -> T {
        let request = try buildRequest(endpoint: endpoint, body: body, queryItems: queryItems)
        let (data, response) = try await performRequest(request)
        try validateResponse(response, data: data)
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decodingError
        }
    }

    // MARK: - Void Request (no response body)

    func requestVoid(
        endpoint: APIEndpoint,
        body: Encodable? = nil
    ) async throws {
        let request = try buildRequest(endpoint: endpoint, body: body)
        let (data, response) = try await performRequest(request)
        try validateResponse(response, data: data)
    }

    // MARK: - Multipart Upload

    func upload<T: Decodable>(
        endpoint: APIEndpoint,
        formData: MultipartFormData
    ) async throws -> T {
        var formData = formData
        let finalData = formData.finalize()

        var request = try buildBaseRequest(endpoint: endpoint)
        request.httpMethod = endpoint.method.rawValue
        request.setValue(formData.contentType, forHTTPHeaderField: "Content-Type")
        request.httpBody = finalData

        if endpoint.requiresAuth {
            try injectAuth(&request)
        }

        let (data, response) = try await performRequest(request)
        try validateResponse(response, data: data)
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decodingError
        }
    }

    // MARK: - Private Helpers

    private func buildRequest(
        endpoint: APIEndpoint,
        body: Encodable? = nil,
        queryItems: [URLQueryItem]? = nil
    ) throws -> URLRequest {
        var request = try buildBaseRequest(endpoint: endpoint, queryItems: queryItems)
        request.httpMethod = endpoint.method.rawValue

        if let body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONEncoder().encode(body)
        }

        if endpoint.requiresAuth {
            try injectAuth(&request)
        }

        return request
    }

    private func buildBaseRequest(
        endpoint: APIEndpoint,
        queryItems: [URLQueryItem]? = nil
    ) throws -> URLRequest {
        guard var components = URLComponents(string: baseURL + endpoint.path) else {
            throw APIError.invalidResponse
        }
        if let queryItems, !queryItems.isEmpty {
            components.queryItems = queryItems
        }
        guard let url = components.url else {
            throw APIError.invalidResponse
        }
        return URLRequest(url: url)
    }

    private func injectAuth(_ request: inout URLRequest) throws {
        guard let token = KeychainHelper.shared.getToken() else {
            throw APIError.unauthorized
        }
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    }

    private func performRequest(_ request: URLRequest) async throws -> (Data, URLResponse) {
        do {
            return try await session.data(for: request)
        } catch {
            throw APIError.networkError
        }
    }

    private func validateResponse(_ response: URLResponse, data: Data) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        switch httpResponse.statusCode {
        case 200...299:
            return
        case 401:
            throw APIError.unauthorized
        case 403:
            throw APIError.forbidden
        default:
            let message = extractErrorMessage(from: data) ?? "Unknown error"
            throw APIError.httpError(statusCode: httpResponse.statusCode, message: message)
        }
    }

    private func extractErrorMessage(from data: Data) -> String? {
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            return json["message"] as? String ?? json["error"] as? String
        }
        return String(data: data, encoding: .utf8)
    }
}
