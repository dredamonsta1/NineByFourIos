import SwiftUI

/// "New to StanBox?" on the login screen. Signup is invite-only and the order
/// matters: join the waitlist, get approved (the invite code arrives by
/// email), then create the account with that same email and code. The two
/// bare links this replaced didn't say any of that, so beta testers went
/// straight to Create account and hit a rejection at the last step.
struct NewHereGuide: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("New to StanBox?")
                .font(.headline)
                .foregroundStyle(Color.Theme.textPrimary)

            step(1, title: "Join the waitlist", detail: "Takes a few seconds.") {
                NavigationLink {
                    WaitlistView()
                } label: {
                    linkLabel("Join the waitlist")
                }
            }

            step(2, title: "Watch your email", detail: "When you're approved, we email you an invite code.")

            step(3, title: "Create your account", detail: "Use the same email and your invite code.") {
                NavigationLink {
                    RegisterView()
                } label: {
                    linkLabel("I have an invite code")
                }
            }

            Text("After that, sign in above with just your email.")
                .font(.footnote)
                .foregroundStyle(Color.Theme.textSecondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.Theme.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.Theme.borderDefault, lineWidth: 1)
        )
    }

    private func step<Action: View>(
        _ number: Int,
        title: String,
        detail: String,
        @ViewBuilder action: () -> Action = { EmptyView() }
    ) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(.subheadline.bold())
                .foregroundStyle(Color.Theme.bgBase)
                .frame(width: 26, height: 26)
                .background(Color.Theme.contrast)
                .clipShape(Circle())
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundStyle(Color.Theme.textPrimary)
                Text(detail)
                    .font(.footnote)
                    .foregroundStyle(Color.Theme.textSecondary)
                action()
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Step \(number): \(title). \(detail)")
    }

    private func linkLabel(_ text: String) -> some View {
        Text("\(text) →")
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(Color.Theme.accentLight)
            .padding(.top, 2)
    }
}
