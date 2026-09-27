import SwiftUI

/// A shareable bundle of artists. Shipped on web 2026-09-12 and never ported.
struct Crate: Codable, Identifiable, Sendable {
    let crateId: Int
    let slug: String
    let name: String
    let artistCount: Int
    let adoptions: Int
    let createdAt: String?

    var id: Int { crateId }

    /// Crates exist to travel, so the share URL is the point of the feature.
    /// Points at the web app, not the API host — `/crate/:slug` is a public
    /// page that renders for logged-out visitors by design.
    var shareURL: URL? {
        URL(string: "https://onstanbox.com/crate/\(slug)")
    }

    enum CodingKeys: String, CodingKey {
        case crateId = "crate_id"
        case slug
        case name
        case artistCount = "artist_count"
        case adoptions
        case createdAt = "created_at"
    }
}

struct CratesResponse: Codable, Sendable {
    let crates: [Crate]
}

/// The user's crates, on their profile.
///
/// Read and share only. Creating one means picking artists and naming the
/// bundle, which is a flow rather than a card, and porting the viewing half
/// first is what closes the "iOS is a generation behind" gap — a crate made
/// on web was previously invisible on the phone that shares it.
struct CratesSection: View {
    let crates: [Crate]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Your crates")
                    .font(.headline)
                    .foregroundStyle(Color.Theme.textPrimary)
                Spacer()
                if !crates.isEmpty {
                    Text("\(crates.count)")
                        .font(.caption)
                        .foregroundStyle(Color.Theme.textSecondary)
                }
            }

            if crates.isEmpty {
                Text("Bundle artists into a crate on the web and it'll show up here to share.")
                    .font(.footnote)
                    .foregroundStyle(Color.Theme.textSecondary)
            } else {
                ForEach(crates) { crate in
                    row(crate)
                }
            }
        }
    }

    private func row(_ crate: Crate) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "shippingbox.fill")
                .foregroundStyle(Color.Theme.accent)

            VStack(alignment: .leading, spacing: 2) {
                Text(crate.name)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.Theme.textPrimary)
                    .lineLimit(1)
                HStack(spacing: 6) {
                    Text("\(crate.artistCount) artist\(crate.artistCount == 1 ? "" : "s")")
                    // Adoption is how a crate is judged, so it is worth
                    // showing even at zero — a crate nobody took is
                    // information, not an empty state.
                    Text("· \(crate.adoptions) adopted")
                }
                .font(.caption2)
                .foregroundStyle(Color.Theme.textSecondary)
            }

            Spacer()

            if let url = crate.shareURL {
                ShareLink(item: url) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.footnote)
                        .foregroundStyle(Color.Theme.accent)
                }
            }
        }
        .padding(10)
        .background(Color.Theme.bgCard)
        .cornerRadius(8)
    }
}
