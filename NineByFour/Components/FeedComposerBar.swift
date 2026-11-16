import SwiftUI

/// The top of the feed for the signed-in fan: their own photo beside a
/// "What's on your mind?" prompt, so the feed reads as theirs. Tapping it
/// opens the same composer as the + button. Matches the web feed's
/// FeedComposerBar.
struct FeedComposerBar: View {
    let user: User?
    let onCompose: () -> Void

    var body: some View {
        Button(action: onCompose) {
            HStack(spacing: 10) {
                UserAvatar(imagePath: user?.profileImage, name: user?.username, size: 36)

                Text("What's on your mind?")
                    .font(.subheadline)
                    .foregroundStyle(Color.Theme.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color.Theme.bgInput)
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(Color.Theme.borderDefault, lineWidth: 1))
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("What's on your mind? Create a post")
    }
}
