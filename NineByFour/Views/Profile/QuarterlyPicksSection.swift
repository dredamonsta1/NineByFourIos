import SwiftUI

/// One of five ranked releases for a calendar quarter.
struct QuarterlyPick: Codable, Identifiable, Sendable {
    let albumId: Int
    let albumName: String
    let albumImageUrl: String?
    let artistId: Int
    let artistName: String
    let position: Int
    let releaseType: String?

    var id: Int { albumId }

    enum CodingKeys: String, CodingKey {
        case albumId = "album_id"
        case albumName = "album_name"
        case albumImageUrl = "album_image_url"
        case artistId = "artist_id"
        case artistName = "artist_name"
        case position
        case releaseType = "release_type"
    }
}

struct QuarterlyPicksResponse: Codable, Sendable {
    let year: Int
    let quarter: Int
    /// Ballots seal 14 days after the quarter ends; after that a chart is a
    /// historical record and editing it would rewrite a published result.
    let locked: Bool
    let picks: [QuarterlyPick]
}

/// The user's five picks for the current quarter.
///
/// Shipped on web 2026-08-25 and never ported. Read-only here: picking is a
/// selection flow, and a quarter the user cannot even SEE on their phone is
/// the more pressing half of the gap.
struct QuarterlyPicksSection: View {
    let response: QuarterlyPicksResponse?

    private static let tierLabel = ["1st", "2nd", "3rd", "4th", "5th"]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Text("Quarterly picks")
                    .font(.headline)
                    .foregroundStyle(Color.Theme.textPrimary)
                if let response {
                    Text("Q\(response.quarter) \(String(response.year))")
                        .font(.caption)
                        .foregroundStyle(Color.Theme.textSecondary)
                    if response.locked {
                        // Locked is a fact about the chart, not an error.
                        Label("Sealed", systemImage: "lock.fill")
                            .font(.caption2)
                            .foregroundStyle(Color.Theme.textSecondary)
                    }
                }
                Spacer()
            }

            if let response, !response.picks.isEmpty {
                ForEach(response.picks.sorted { $0.position < $1.position }) { pick in
                    row(pick)
                }
            } else {
                Text("Pick five releases on the web and they'll appear here.")
                    .font(.footnote)
                    .foregroundStyle(Color.Theme.textSecondary)
            }
        }
    }

    private func row(_ pick: QuarterlyPick) -> some View {
        HStack(spacing: 12) {
            Text(Self.tierLabel.indices.contains(pick.position - 1)
                 ? Self.tierLabel[pick.position - 1]
                 : "\(pick.position)")
                .font(.caption.weight(.bold))
                // #1 in chartreuse, matching the rank rule used on the shrine.
                .foregroundStyle(pick.position == 1 ? Color.Theme.contrast : Color.Theme.textSecondary)
                .frame(width: 26, alignment: .leading)

            if let url = pick.albumImageUrl, let parsed = URL(string: url) {
                AsyncImage(url: parsed) { image in
                    image.resizable().aspectRatio(contentMode: .fill)
                } placeholder: {
                    Color.Theme.bgCard
                }
                .frame(width: 40, height: 40)
                .clipped()
                .cornerRadius(4)
            } else {
                Color.Theme.bgCard
                    .frame(width: 40, height: 40)
                    .cornerRadius(4)
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 5) {
                    Text(pick.albumName)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color.Theme.textPrimary)
                        .lineLimit(1)
                    // The release_type work landed in the API but has no
                    // fan-facing surface yet (backlog Story 17). Album is the
                    // overwhelming default, so badging it would be noise.
                    if let type = pick.releaseType, type != "album" {
                        Text(type.uppercased())
                            .font(.system(size: 9, weight: .bold))
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Color.Theme.bgCardElevated)
                            .foregroundStyle(Color.Theme.textSecondary)
                            .cornerRadius(3)
                    }
                }
                Text(pick.artistName)
                    .font(.caption2)
                    .foregroundStyle(Color.Theme.textSecondary)
                    .lineLimit(1)
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }
}
