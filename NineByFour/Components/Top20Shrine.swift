import SwiftUI

/// Tier and tenure for one artist in a user's list.
///
/// From `/communities/user/:id/stan-card`, which is public and returns rows
/// WITHOUT a position — ordered by score, not by the user's own ordering. So
/// this is joined onto the profile list by `artist_id` rather than used as the
/// list itself; taking its order would silently reorder someone's Top 20
/// behind their back.
struct StanRank: Codable, Identifiable, Sendable {
    let artistId: Int
    let tier: String?
    let daysAsMember: Int?

    var id: Int { artistId }

    enum CodingKeys: String, CodingKey {
        case artistId = "artist_id"
        case tier
        case daysAsMember = "days_as_member"
    }
}

/// One row of the shrine: the artist, their position, and how long they've
/// been there.
struct ShrineEntry: Identifiable {
    let artist: Artist
    let position: Int
    let tier: String?
    let daysAsMember: Int?

    var id: Int { artist.artistId }
}

/// The Top 20 as an identity artifact rather than a browse list.
///
/// Ported from the web shrine (9by4app #152). The #1 slot gets real estate
/// instead of just a colour, and tier and tenure are first-class rather than
/// living in a separate card — which is why the web retired StanCard rather
/// than sitting it alongside.
///
/// Slots 1-5 are marked: only the first five count toward community
/// membership, so the boundary is load-bearing and worth showing.
struct Top20Shrine: View {
    let entries: [ShrineEntry]
    var onRemove: ((Int) -> Void)?

    /// Only the first five count toward community membership.
    private static let communitySlots = 5

    private static let tierLabels: [String: String] = [
        "casual": "Casual",
        "fan": "Fan",
        "stan": "Stan",
        "day-one": "Day One",
    ]

    /// "3 yrs" / "7 mo" / "12 days" — tenure has to read at a glance.
    static func tenureLabel(_ days: Int?) -> String? {
        guard let days else { return nil }
        if days >= 365 {
            let y = days / 365
            return "\(y) yr\(y > 1 ? "s" : "")"
        }
        if days >= 30 { return "\(days / 30) mo" }
        return "\(days) day\(days == 1 ? "" : "s")"
    }

    private var hero: ShrineEntry? { entries.first }
    private var rest: [ShrineEntry] { Array(entries.dropFirst()) }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let hero {
                heroCard(hero)
            }
            ForEach(rest) { entry in
                row(entry)
            }
        }
    }

    // MARK: - #1

    private func heroCard(_ entry: ShrineEntry) -> some View {
        HStack(spacing: 14) {
            art(entry.artist, size: 76)

            VStack(alignment: .leading, spacing: 4) {
                // Chartreuse for rank #1, per the brand rule.
                Text("#1")
                    .font(.caption.bold())
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(Color.Theme.contrast)
                    .foregroundStyle(Color.Theme.bgBase)
                    .clipShape(Capsule())

                Text(entry.artist.artistName)
                    .font(.title3.bold())
                    .foregroundStyle(Color.Theme.textPrimary)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    if let tier = entry.tier, let label = Self.tierLabels[tier] {
                        Text(label)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(Color.Theme.accent)
                    }
                    if let tenure = Self.tenureLabel(entry.daysAsMember) {
                        Text("\(tenure) in your top 20")
                            .font(.caption2)
                            .foregroundStyle(Color.Theme.textSecondary)
                    }
                }
            }
            Spacer()
        }
        .padding(12)
        .background(Color.Theme.bgCardElevated)
        .cornerRadius(12)
    }

    // MARK: - 2…20

    private func row(_ entry: ShrineEntry) -> some View {
        HStack(spacing: 12) {
            Text("\(entry.position)")
                .font(.caption.weight(.bold))
                .foregroundStyle(Color.Theme.textSecondary)
                .frame(width: 22, alignment: .trailing)

            art(entry.artist, size: 40)

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.artist.artistName)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.Theme.textPrimary)
                    .lineLimit(1)
                HStack(spacing: 6) {
                    if let tier = entry.tier, let label = Self.tierLabels[tier] {
                        Text(label)
                            .font(.caption2)
                            .foregroundStyle(Color.Theme.accent)
                    }
                    if let tenure = Self.tenureLabel(entry.daysAsMember) {
                        Text(tenure)
                            .font(.caption2)
                            .foregroundStyle(Color.Theme.textSecondary)
                    }
                }
            }

            Spacer()

            if let onRemove {
                Button {
                    onRemove(entry.artist.artistId)
                } label: {
                    Image(systemName: "minus.circle")
                        .font(.footnote)
                        .foregroundStyle(Color.Theme.textSecondary)
                }
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background(
            // The first five count toward community membership. Marking the
            // boundary makes a rule that already exists visible, rather than
            // something a user only discovers from its effects.
            entry.position <= Self.communitySlots
                ? Color.Theme.bgCard
                : Color.clear
        )
        .cornerRadius(8)
    }

    @ViewBuilder
    private func art(_ artist: Artist, size: CGFloat) -> some View {
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
        .cornerRadius(size > 50 ? 10 : 6)
    }
}
