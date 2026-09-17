import SwiftUI

/// Self-service account deletion.
///
/// App Store review requires this for any app that creates accounts, and an
/// endpoint with no control does not satisfy it — the reviewer looks for the
/// button. It is the customer's right regardless of the rule.
///
/// Deliberately not one tap. The requirement is that deletion be *available*,
/// not frictionless, and it cannot be undone. Typing the username is the same
/// standard the web uses.
///
/// The copy names what survives. Posts are parked, crates stay live and
/// purchases are kept, so "this deletes everything" would be a lie the user
/// only discovers afterwards.
struct DeleteAccountView: View {
    let username: String

    @Environment(AuthManager.self) private var authManager
    @Environment(\.dismiss) private var dismiss

    @State private var confirmation = ""
    @State private var isDeleting = false
    @State private var errorMessage: String?

    private var matches: Bool {
        !username.isEmpty && confirmation.trimmingCharacters(in: .whitespaces) == username
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("Delete your account")
                    .font(.title2.bold())
                    .foregroundStyle(Color.Theme.error)

                section(
                    "This removes, permanently:",
                    [
                        "Your email, username and profile picture",
                        "Your Top 20 and your music personality",
                    ]
                )

                section(
                    "This stays on stanbox:",
                    [
                        "Posts and messages you wrote, shown as a deleted account — so replies and conversations stay readable for everyone else",
                        "Crates you shared, so links other people hold keep working",
                        "Quarterly picks and purchase records, which we keep for sealed charts and for refunds",
                    ]
                )

                VStack(alignment: .leading, spacing: 8) {
                    Text("This cannot be undone. Type \(username) to confirm.")
                        .font(.subheadline)
                        .foregroundStyle(Color.Theme.hot)

                    TextField(username, text: $confirmation)
                        .textFieldStyle(.plain)
                        .padding(12)
                        .background(Color.Theme.bgInput)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.Theme.borderDefault, lineWidth: 1)
                        )
                        .foregroundStyle(Color.Theme.textPrimary)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .disabled(isDeleting)
                }

                if let errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(Color.Theme.error)
                }

                Button {
                    Task { await deleteAccount() }
                } label: {
                    HStack {
                        if isDeleting { ProgressView().tint(.white) }
                        Text(isDeleting ? "Deleting…" : "Delete my account")
                            .fontWeight(.bold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(14)
                    .background(matches ? Color.Theme.error : Color.Theme.error.opacity(0.3))
                    .foregroundStyle(.white)
                    .cornerRadius(8)
                }
                .disabled(!matches || isDeleting)

                Button("Cancel") { dismiss() }
                    .font(.subheadline)
                    .foregroundStyle(Color.Theme.textSecondary)
                    .frame(maxWidth: .infinity)
                    .disabled(isDeleting)
            }
            .padding(20)
        }
        .background(Color.Theme.bgBase.ignoresSafeArea())
    }

    @ViewBuilder
    private func section(_ heading: String, _ items: [String]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(heading)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.Theme.textPrimary)
            ForEach(items, id: \.self) { item in
                HStack(alignment: .top, spacing: 6) {
                    Text("•").foregroundStyle(Color.Theme.textSecondary)
                    Text(item)
                        .font(.footnote)
                        .foregroundStyle(Color.Theme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private func deleteAccount() async {
        guard matches, !isDeleting else { return }
        isDeleting = true
        errorMessage = nil
        do {
            try await APIClient.shared.requestVoid(endpoint: .deleteAccount)
            // Clears the keychain token and returns to the signed-out root.
            // Holding a token for an account that no longer resolves leaves
            // every request failing with no explanation.
            authManager.logout()
        } catch {
            errorMessage = "Couldn't delete your account. Try again."
            isDeleting = false
        }
    }
}
