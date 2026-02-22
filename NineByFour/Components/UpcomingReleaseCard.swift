import SwiftUI

struct UpcomingReleaseCard: View {
    let release: UpcomingRelease

    var body: some View {
        HStack(spacing: 12) {
            CachedAsyncImage(url: release.imageUrl?.fullImageURL, cornerRadius: 8)
                .frame(width: 70, height: 70)

            VStack(alignment: .leading, spacing: 4) {
                Text(release.title)
                    .font(.subheadline.bold())
                    .foregroundStyle(Color.Theme.textPrimary)
                    .lineLimit(1)

                if let artist = release.artist, !artist.isEmpty {
                    Text(artist)
                        .font(.caption)
                        .foregroundStyle(Color.Theme.accent)
                }

                if let date = release.date, !date.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.caption2)
                        Text(date)
                            .font(.caption)
                    }
                    .foregroundStyle(Color.Theme.textSecondary)
                }
            }

            Spacer()
        }
        .padding(12)
        .background(Color.Theme.bgCard)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.Theme.borderDefault, lineWidth: 1)
        )
    }
}
