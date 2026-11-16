import SwiftUI
import Kingfisher

/// A person's round photo. While it loads, or if they have none or it fails,
/// it shows their initial in brand blue (CachedAsyncImage's placeholder is a
/// microphone, which reads as an artist, not a fan).
struct UserAvatar: View {
    var imagePath: String?
    var name: String?
    var size: CGFloat = 32

    private var initial: String { Self.initial(for: name) }

    /// First letter of the name, uppercased; "?" when there's no name.
    static func initial(for name: String?) -> String {
        let letter = (name ?? "").trimmingCharacters(in: .whitespaces).first
        return letter.map { String($0).uppercased() } ?? "?"
    }

    private var initialView: some View {
        ZStack {
            Color.Theme.accent
            Text(initial)
                .font(.system(size: size * 0.42, weight: .bold))
                .foregroundStyle(Color.Theme.textBright)
        }
    }

    var body: some View {
        Group {
            if let url = imagePath.flatMap({ $0.isEmpty ? nil : $0.fullImageURL }) {
                KFImage(url)
                    .placeholder { initialView }
                    .fade(duration: 0.2)
                    .resizable()
                    .scaledToFill()
            } else {
                initialView
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .accessibilityHidden(true)
    }
}
