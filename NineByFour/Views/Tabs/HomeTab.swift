import SwiftUI

struct HomeTab: View {
    @State private var viewModel = ArtistListViewModel()
    @State private var selectedArtistId: Int?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.Theme.bgBase.ignoresSafeArea()

                if viewModel.isLoading && viewModel.artists.isEmpty {
                    LoadingStateView()
                } else if let error = viewModel.errorMessage, viewModel.artists.isEmpty {
                    ErrorStateView(message: error) {
                        Task { await viewModel.loadArtists() }
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 2) {
                            SearchBar(text: $viewModel.searchText)
                                .padding(.horizontal, 16)
                                .onChange(of: viewModel.searchText) {
                                    Task { await viewModel.search() }
                                }

                            // The feedback loop, not a convenience. Tap a
                            // genre, watch the ranking change.
                            FilterPills(selection: $viewModel.filter) { filter in
                                Task { await viewModel.apply(filter: filter) }
                            }
                            .padding(.bottom, 6)

                            if viewModel.artists.isEmpty && !viewModel.isLoading {
                                Text("Nothing here yet. Try another filter.")
                                    .font(.footnote)
                                    .foregroundStyle(Color.Theme.textSecondary)
                                    .padding(.top, 40)
                            }

                            // Rank is positional within the current result
                            // set, which is what a filtered ranking means:
                            // "#1 in Drill", not "#1 overall, filtered".
                            ForEach(Array(viewModel.artists.enumerated()), id: \.element.id) { index, artist in
                                RankedArtistRow(rank: index + 1, artist: artist) {
                                    selectedArtistId = artist.artistId
                                }
                                .padding(.horizontal, 4)
                                .onAppear {
                                    if artist.id == viewModel.artists.last?.id {
                                        Task { await viewModel.loadMore() }
                                    }
                                }
                            }
                        }
                        .padding(.bottom, 16)
                    }
                    .refreshable {
                        await viewModel.loadArtists()
                    }
                }
            }
            .navigationTitle("Rankings")
            .brandedNavBar()
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheet(item: Binding(
                get: { selectedArtistId.map { SheetItem(id: $0) } },
                set: { selectedArtistId = $0?.id }
            )) { item in
                ArtistDetailSheet(artistId: item.id)
            }
        }
        .task {
            if viewModel.artists.isEmpty {
                await viewModel.loadArtists()
            }
        }
    }
}

private struct SheetItem: Identifiable {
    let id: Int
}
