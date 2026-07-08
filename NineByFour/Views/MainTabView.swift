import SwiftUI

struct MainTabView: View {
    @State private var messagesViewModel = MessagesViewModel()
    @Environment(AudioPlayer.self) private var audioPlayer
    @Environment(Router.self) private var router

    var body: some View {
        @Bindable var router = router

        TabView(selection: $router.selectedTab) {
            HomeTab()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(Router.Tab.home)

            FeedTab()
                .tabItem {
                    Label("Feed", systemImage: "text.bubble.fill")
                }
                .tag(Router.Tab.feed)

            DiscoverTab()
                .tabItem {
                    Label("Discover", systemImage: "magnifyingglass")
                }
                .tag(Router.Tab.discover)

            MessagesTab(viewModel: messagesViewModel)
                .tabItem {
                    Label("Messages", systemImage: "envelope.fill")
                }
                .badge(messagesViewModel.unreadCount)
                .tag(Router.Tab.messages)

            LibraryTab()
                .tabItem {
                    Label("Library", systemImage: "square.stack.fill")
                }
                .tag(Router.Tab.library)

            ProfileTab()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
                .tag(Router.Tab.profile)
        }
        .tint(Color.Theme.accent)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if audioPlayer.currentPost != nil {
                PlayerBar()
            }
        }
    }
}
