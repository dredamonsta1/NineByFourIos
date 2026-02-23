import SwiftUI

struct ArtistSearchRow: View {
    let artist: Artist
    let isAdded: Bool
    let isListFull: Bool
    var onAdd: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            CachedAsyncImage(url: artist.imageUrl?.fullImageURL, cornerRadius: 6)
                .frame(width: 40, height: 40)

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

            if isAdded {
                Label("Added", systemImage: "checkmark")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Color.Theme.accent)
            } else if isListFull {
                Text("Full")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Color.Theme.textSecondary)
            } else {
                Button {
                    onAdd()
                } label: {
                    Text("Add")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.Theme.accent)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.Theme.accent, lineWidth: 1)
                        )
                }
            }
        }
        .padding(10)
        .background(Color.Theme.bgCard)
        .cornerRadius(8)
    }
}
