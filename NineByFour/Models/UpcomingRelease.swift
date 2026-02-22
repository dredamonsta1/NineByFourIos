import Foundation

struct UpcomingRelease: Codable, Identifiable, Sendable {
    let id: String
    let title: String
    var artist: String?
    var date: String?
    var imageUrl: String?
    var source: String?
}
