import SwiftUI

struct MainTabView: View {
    @State private var messagesViewModel = MessagesViewModel()

    var body: some View {
        TabView {
            HomeTab()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }

            FeedTab()
                .tabItem {
                    Label("Feed", systemImage: "text.bubble.fill")
                }

            DiscoverTab()
                .tabItem {
                    Label("Discover", systemImage: "magnifyingglass")
                }

            MessagesTab(viewModel: messagesViewModel)
                .tabItem {
                    Label("Messages", systemImage: "envelope.fill")
                }
                .badge(messagesViewModel.unreadCount)

            ProfileTab()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
        }
        .tint(Color.Theme.accent)
    }
}
