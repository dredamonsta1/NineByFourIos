import SwiftUI

// Fan's owned albums (Pillar B). Purchases hydrate onto AuthManager
// after login and after every completed Stripe Checkout. This tab
// just renders them grouped by artist — playback + download-for-
// offline are Phase 6 concerns.
struct LibraryTab: View {
    @Environment(AuthManager.self) private var authManager
    @State private var isRefreshing = false

    private var grouped: [ArtistGroup] {
        let byArtist = Dictionary(grouping: authManager.purchases, by: \.artistId)
        return byArtist.compactMap { (artistId, purchases) -> ArtistGroup? in
            guard let first = purchases.first else { return nil }
            let sorted = purchases.sorted { lhs, rhs in
                (lhs.createdAt ?? "") > (rhs.createdAt ?? "")
            }
            return ArtistGroup(
                artistId: artistId,
                artistName: first.artistName ?? "Unknown",
                artistImageUrl: first.artistImageUrl,
                purchases: sorted
            )
        }
        .sorted { $0.artistName.localizedCaseInsensitiveCompare($1.artistName) == .orderedAscending }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.Theme.bgBase.ignoresSafeArea()

                if authManager.purchases.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 20, pinnedViews: [.sectionHeaders]) {
                            ForEach(grouped) { group in
                                Section {
                                    ForEach(group.purchases) { purchase in
                                        LibraryAlbumRow(purchase: purchase)
                                            .padding(.horizontal, 16)
                                    }
                                } header: {
                                    LibraryArtistHeader(group: group)
                                }
                            }
                        }
                        .padding(.vertical, 16)
                    }
                    .refreshable {
                        await authManager.loadPurchases()
                    }
                }
            }
            .navigationTitle("Library")
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "square.stack.fill")
                .font(.system(size: 48))
                .foregroundStyle(Color.Theme.textSecondary)
            Text("Your library is empty")
                .font(.headline)
                .foregroundStyle(Color.Theme.textPrimary)
            Text("Albums you buy on stanbox will show up here.")
                .font(.subheadline)
                .foregroundStyle(Color.Theme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
    }
}

// MARK: - Grouped model

private struct ArtistGroup: Identifiable {
    let artistId: Int
    let artistName: String
    let artistImageUrl: String?
    let purchases: [Purchase]

    var id: Int { artistId }
}

// MARK: - Artist section header

private struct LibraryArtistHeader: View {
    let group: ArtistGroup

    var body: some View {
        HStack(spacing: 12) {
            CachedAsyncImage(url: group.artistImageUrl?.fullImageURL, cornerRadius: 20)
                .frame(width: 40, height: 40)

            VStack(alignment: .leading, spacing: 2) {
                Text(group.artistName)
                    .font(.headline)
                    .foregroundStyle(Color.Theme.textBright)
                Text("^[\(group.purchases.count) album](inflect: true)")
                    .font(.caption)
                    .foregroundStyle(Color.Theme.textSecondary)
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.Theme.bgBase.opacity(0.95))
    }
}

// MARK: - Album row

private struct LibraryAlbumRow: View {
    let purchase: Purchase

    private var purchasedAt: String? {
        guard let raw = purchase.createdAt,
              let date = ISO8601DateFormatter().date(from: raw) ?? isoWithFraction(raw) else {
            return nil
        }
        let df = DateFormatter()
        df.dateStyle = .medium
        return "Purchased \(df.string(from: date))"
    }

    var body: some View {
        HStack(spacing: 12) {
            CachedAsyncImage(url: purchase.albumImageUrl?.fullImageURL, cornerRadius: 6)
                .frame(width: 60, height: 60)

            VStack(alignment: .leading, spacing: 3) {
                Text(purchase.albumName ?? "Untitled album")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.Theme.textPrimary)
                    .lineLimit(2)

                if let year = purchase.year, !year.isEmpty {
                    Text(year)
                        .font(.caption)
                        .foregroundStyle(Color.Theme.textSecondary)
                }

                if let purchasedAt {
                    Text(purchasedAt)
                        .font(.caption2)
                        .foregroundStyle(Color.Theme.textSecondary)
                }
            }

            Spacer()

            // Downloads + in-app playback land in Phase 6. For now the row
            // just shows the purchase — tapping the album cover on the
            // artist page still routes to the sheet where you can play
            // preview tracks.
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(Color.Theme.textSecondary)
        }
        .padding(10)
        .background(Color.Theme.bgCard)
        .cornerRadius(8)
    }

    // Postgres often returns timestamps as "2026-07-08T12:34:56.789Z" —
    // ISO8601DateFormatter without fractional-second option rejects the
    // .789 fractional part. Retry with fractional seconds enabled.
    private func isoWithFraction(_ raw: String) -> Date? {
        let df = ISO8601DateFormatter()
        df.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return df.date(from: raw)
    }
}
