import Foundation

nonisolated struct MultipartFormData: Sendable {
    private let boundary: String
    private var body = Data()

    var contentType: String {
        "multipart/form-data; boundary=\(boundary)"
    }

    init(boundary: String = UUID().uuidString) {
        self.boundary = boundary
    }

    mutating func addField(named name: String, value: String) {
        body.append("--\(boundary)\r\n")
        body.append("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n")
        body.append("\(value)\r\n")
    }

    mutating func addFile(named name: String, fileName: String, mimeType: String, data: Data) {
        body.append("--\(boundary)\r\n")
        body.append("Content-Disposition: form-data; name=\"\(name)\"; filename=\"\(fileName)\"\r\n")
        body.append("Content-Type: \(mimeType)\r\n\r\n")
        body.append(data)
        body.append("\r\n")
    }

    mutating func finalize() -> Data {
        body.append("--\(boundary)--\r\n")
        return body
    }
}

nonisolated private extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}
