import SwiftUI

struct ArtistCard: View {
    var artist: Artist
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                CachedAsyncImage(url: artist.imageUrl?.fullImageURL, cornerRadius: 12)
                    .frame(height: 160)
                    .frame(maxWidth: .infinity)
                    .clipped()

                VStack(alignment: .leading, spacing: 4) {
                    Text(artist.artistName)
                        .font(.subheadline.bold())
                        .foregroundStyle(Color.Theme.textPrimary)
                        .lineLimit(1)

                    if let genre = artist.genre, !genre.isEmpty {
                        Text(genre)
                            .font(.caption)
                            .foregroundStyle(Color.Theme.accent)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.Theme.accent.opacity(0.15))
                            .cornerRadius(4)
                    }

                    HStack(spacing: 12) {
                        if let state = artist.state, !state.isEmpty {
                            Label(state, systemImage: "mappin")
                                .font(.caption2)
                                .foregroundStyle(Color.Theme.textSecondary)
                        }

                        if let count = artist.count, count > 0 {
                            Label("\(count)", systemImage: "flame.fill")
                                .font(.caption2)
                                .foregroundStyle(Color.Theme.hot)
                        }
                    }
                }
                .padding(.horizontal, 8)
                .padding(.bottom, 8)
            }
            .background(Color.Theme.bgCard)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.Theme.borderDefault, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
