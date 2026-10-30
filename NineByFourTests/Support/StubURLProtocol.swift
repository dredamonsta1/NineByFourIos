import Foundation

/// Stands in for the server in tests.
///
/// APIClient sends everything through URLSession.shared, so registering this
/// protocol intercepts every request without changing app code. Any request
/// without a stub fails instead of reaching the real API: tests must never
/// talk to production.
final class StubURLProtocol: URLProtocol, @unchecked Sendable {
    struct Stub {
        let status: Int
        let body: String
    }

    nonisolated(unsafe) private static var stubs: [String: Stub] = [:]
    nonisolated(unsafe) private(set) static var requests: [URLRequest] = []
    private static let lock = NSLock()

    /// Key is "METHOD /path", e.g. "POST /profile/list/85".
    static func stub(_ method: String, _ path: String, status: Int = 200, body: String = "{}") {
        lock.withLock { stubs["\(method) /api\(path)"] = Stub(status: status, body: body) }
    }

    static func reset() {
        lock.withLock {
            stubs = [:]
            requests = []
        }
    }

    /// "METHOD /path" for every request made, in order, without the /api prefix.
    static var calls: [String] {
        lock.withLock {
            requests.map { "\($0.httpMethod ?? "GET") \($0.url?.path.replacingOccurrences(of: "/api", with: "", options: .anchored) ?? "")" }
        }
    }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        let key = "\(request.httpMethod ?? "GET") \(request.url?.path ?? "")"
        let stub = Self.lock.withLock { () -> Stub? in
            Self.requests.append(request)
            return Self.stubs[key]
        }
        guard let stub, let url = request.url,
              let response = HTTPURLResponse(url: url, statusCode: stub.status, httpVersion: nil, headerFields: ["Content-Type": "application/json"])
        else {
            client?.urlProtocol(self, didFailWithError: URLError(.cannotConnectToHost))
            return
        }
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Data(stub.body.utf8))
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}
