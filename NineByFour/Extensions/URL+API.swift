import Foundation

extension String {
    var fullImageURL: URL? {
        if self.hasPrefix("http://") || self.hasPrefix("https://") {
            return URL(string: self)
        }
        // Relative path from backend (e.g., /uploads/image.jpg)
        return URL(string: "https://ninebyfourapi.herokuapp.com\(self)")
    }
}
