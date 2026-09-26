import SwiftUI

struct AuthGateView: View {
    @Environment(AuthManager.self) private var authManager

    /// Nil until we have asked the server how many artists this user has.
    /// Deciding before that would flash the welcome screen at people who
    /// already have a list, which is worse than a brief spinner.
    @State private var needsOnboarding: Bool?

    var body: some View {
        Group {
            if authManager.isLoading {
                LoadingStateView()
            } else if authManager.isAuthenticated {
                if needsOnboarding == nil {
                    LoadingStateView()
                        .task { await decide() }
                } else if needsOnboarding == true {
                    WelcomeView { needsOnboarding = false }
                } else {
                    MainTabView()
                }
            } else {
                NavigationStack {
                    LoginView()
                }
            }
        }
        .onChange(of: authManager.isAuthenticated) { _, isAuthed in
            // Re-decide per session. Without this a sign-out followed by a
            // different account signing in on the same device would reuse the
            // previous verdict.
            if isAuthed {
                needsOnboarding = nil
            } else {
                OnboardingState.reset()
                needsOnboarding = nil
            }
        }
    }

    /// Shows the first run only to someone who would actually land in an
    /// empty app: fewer than three artists AND has not already said "later".
    ///
    /// Checked against the server rather than a local flag, so a user who
    /// built a list on the web is not asked to do it again on their phone.
    /// On failure it proceeds into the app — a network blip should not put
    /// someone through onboarding they may not need.
    private func decide() async {
        if OnboardingState.hasSeen {
            needsOnboarding = false
            return
        }
        // Goes through ProfileViewModel rather than decoding here. The
        // response is a wrapper, not a bare array, and getting that wrong
        // fails INTO the catch — which looks identical to an existing user
        // and would silently skip onboarding for everyone.
        let probe = ProfileViewModel()
        await probe.loadProfileList()
        if probe.errorMessage != nil {
            needsOnboarding = false
            return
        }
        needsOnboarding = probe.profileList.count < 3
    }
}
