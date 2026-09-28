import SwiftUI

/// Genre and region pills above the rankings.
///
/// These are not a convenience — they are the reason the rankings lead the
/// screen. The web's landing rework identified the *feedback loop* as the
/// point: tap "Hip Hop", watch the list change. Without it a ranking is a
/// static list you scroll once; with it, it is something you play with.
///
/// Same vocabulary as the web's FiltersBar so the two platforms filter
/// identically. StanBox is genre agnostic, so the genre spread is broad
/// rather than a house style.
struct FilterPills: View {
    @Binding var selection: ArtistFilter
    let onSelect: (ArtistFilter) -> Void

    private static let genres = [
        "Hip Hop", "R&B", "Pop", "Rock", "Country",
        "Latin", "Drill", "Trap", "Reggae", "Dancehall",
    ]

    /// Every one of these was counted against production on 2026-09-28 and
    /// returns results. The API matches `region OR state`, exactly, with no
    /// wildcards — which is why the vocabulary matters more than it looks.
    ///
    /// The web's pill list is NOT reused here because four of its nine are
    /// dead: "Chicago", "Houston" and "Detroit" are cities and the catalogue
    /// has no city column, and "East" does not match the stored value "East
    /// Coast". Tapping any of them returns an empty list. See backlog.
    ///
    /// Counts at time of writing: East Coast 1783, South 553, West Coast 543,
    /// Midwest 459, NY 1231, Georgia 115, UK 77.
    private static let regions = [
        "East Coast", "West Coast", "South", "Midwest", "NY", "Georgia", "UK",
    ]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                pill("All", filter: .all)

                divider

                ForEach(Self.genres, id: \.self) { g in
                    pill(g, filter: .genre(g))
                }

                divider

                ForEach(Self.regions, id: \.self) { r in
                    pill(r, filter: .region(r))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 2)
        }
    }

    private var divider: some View {
        Rectangle()
            .fill(Color.Theme.borderDefault)
            .frame(width: 1, height: 18)
    }

    private func pill(_ label: String, filter: ArtistFilter) -> some View {
        let active = selection == filter
        return Button {
            onSelect(filter)
        } label: {
            Text(label)
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                // Cyan for the selected state, not chartreuse. The contrast
                // colour means "act"; a selected filter means "you are here",
                // and letting it take chartreuse would put navigation in
                // competition with the things worth pressing.
                .background(active ? Color.Theme.accent : Color.Theme.bgCard)
                .foregroundStyle(active ? Color.white : Color.Theme.textSecondary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}
