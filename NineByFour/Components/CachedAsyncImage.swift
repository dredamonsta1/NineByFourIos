import SwiftUI
import Kingfisher

struct CachedAsyncImage: View {
    var url: URL?
    var cornerRadius: CGFloat = 8

    var body: some View {
        KFImage(url)
            .placeholder {
                ZStack {
                    Color.Theme.bgCardElevated
                    Image(systemName: "music.mic")
                        .font(.title2)
                        .foregroundStyle(Color.Theme.textSecondary)
                }
            }
            .fade(duration: 0.25)
            .resizable()
            .scaledToFill()
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
}
