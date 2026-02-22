import SwiftUI

struct FavoriteArtistRow: View {
    let artist: Artist
    var onRemove: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            CachedAsyncImage(url: artist.imageUrl?.fullImageURL, cornerRadius: 6)
                .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 2) {
                Text(artist.artistName)
                    .font(.subheadline)
                    .foregroundStyle(Color.Theme.textPrimary)
                    .lineLimit(1)

                if let genre = artist.genre, !genre.isEmpty {
                    Text(genre)
                        .font(.caption)
                        .foregroundStyle(Color.Theme.textSecondary)
                }
            }

            Spacer()

            Button {
                onRemove()
            } label: {
                Image(systemName: "xmark.circle")
                    .foregroundStyle(Color.Theme.textSecondary)
            }
        }
        .padding(10)
        .background(Color.Theme.bgCard)
        .cornerRadius(8)
    }
}
