import SwiftUI

/// One row of the rankings.
///
/// Replaces the two-column card grid on Home. A grid can show artists but it
/// cannot show a *ranking* — the eye does not follow 1, 2, 3 across two
/// columns, so rank badges on cards read as decoration. The whole argument of
/// the web's landing rework was that the platform IS the leaderboard, and a
/// numbered list is what says that.
struct RankedArtistRow: View {
    let rank: Int
    let artist: Artist
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // #1 in chartreuse, matching the shrine and quarterly picks.
                // Reserved for the top slot only — spending it on every rank
                // would make it decoration rather than a signal.
                Text("\(rank)")
                    .font(.system(size: rank == 1 ? 17 : 15, weight: .heavy))
                    .foregroundStyle(rank == 1 ? Color.Theme.contrast : Color.Theme.textSecondary)
                    .frame(width: 28, alignment: .trailing)
                    .monospacedDigit()

                art

                VStack(alignment: .leading, spacing: 2) {
                    Text(artist.artistName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.Theme.textPrimary)
                        .lineLimit(1)

                    HStack(spacing: 5) {
                        if let genre = artist.genre, !genre.isEmpty {
                            Text(genre)
                                .lineLimit(1)
                        }
                        if let region = artist.region, !region.isEmpty {
                            Text("· \(region)")
                                .lineLimit(1)
                        }
                    }
                    .font(.caption2)
                    .foregroundStyle(Color.Theme.textSecondary)
                }

                Spacer(minLength: 6)

                // Clout is the ranking's unit, so it earns a place on the row.
                // Zero is shown as a dash rather than "0" — only ~57 of 112k
                // artists have any, so a column of zeroes would read as the
                // ranking being broken rather than the catalogue being deep.
                if let count = artist.count, count > 0 {
                    Label("\(count)", systemImage: "flame.fill")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(Color.Theme.accent)
                        .labelStyle(.titleAndIcon)
                } else {
                    Text("—")
                        .font(.caption2)
                        .foregroundStyle(Color.Theme.textSecondary.opacity(0.5))
                }
            }
            .padding(.vertical, 7)
            .padding(.horizontal, 12)
            .background(rank == 1 ? Color.Theme.bgCard : Color.clear)
            .cornerRadius(8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var art: some View {
        let size: CGFloat = rank == 1 ? 48 : 40
        Group {
            if let url = artist.imageUrl, let parsed = URL(string: url) {
                AsyncImage(url: parsed) { image in
                    image.resizable().aspectRatio(contentMode: .fill)
                } placeholder: {
                    Color.Theme.bgCard
                }
            } else {
                Color.Theme.bgCard.overlay(
                    Text(String(artist.artistName.prefix(1)))
                        .font(.headline)
                        .foregroundStyle(Color.Theme.textSecondary)
                )
            }
        }
        .frame(width: size, height: size)
        .clipped()
        .cornerRadius(6)
    }
}
