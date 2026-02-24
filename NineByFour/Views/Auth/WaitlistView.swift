import SwiftUI

struct WaitlistView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var fullName = ""
    @State private var email = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var isSuccess = false
    @State private var submittedEmail = ""

    var body: some View {
        ZStack {
            Color.Theme.bgBase.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    Spacer().frame(height: 40)

                    // Logo
                    VStack(spacing: 8) {
                        Text("9by4")
                            .font(.system(size: 48, weight: .bold))
                            .foregroundStyle(Color.Theme.accent)
                        Text("Join the Waitlist")
                            .font(.title3)
                            .foregroundStyle(Color.Theme.textPrimary)
                    }

                    if isSuccess {
                        successView
                    } else {
                        formView
                    }
                }
                .padding(.horizontal, 24)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .foregroundStyle(Color.Theme.textPrimary)
                }
            }
        }
    }

    private var formView: some View {
        VStack(spacing: 16) {
            Text("NineByFour is currently invite-only to ensure a high-quality community.")
                .font(.subheadline)
                .foregroundStyle(Color.Theme.textSecondary)
                .multilineTextAlignment(.center)

            TextField("Full Name", text: $fullName)
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

            TextField("Email Address", text: $email)
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
                .keyboardType(.emailAddress)

            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(Color.Theme.error)
            }

            Button {
                Task { await joinWaitlist() }
            } label: {
                HStack {
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                    }
                    Text(isLoading ? "Requesting..." : "Request Invite Code")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(14)
                .background(Color.Theme.accent)
                .foregroundStyle(.white)
                .cornerRadius(8)
            }
            .disabled(isLoading)

            Button {
                dismiss()
            } label: {
                Text("Already a member? ")
                    .foregroundStyle(Color.Theme.textSecondary)
                + Text("Sign In")
                    .foregroundStyle(Color.Theme.accent)
            }
            .font(.subheadline)
        }
    }

    private var successView: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(Color.Theme.success)

            Text("You're on the list!")
                .font(.headline)
                .foregroundStyle(Color.Theme.textPrimary)

            Text("We'll email your invite code soon. Keep an eye on **\(submittedEmail)** for your access link.")
                .font(.subheadline)
                .foregroundStyle(Color.Theme.textSecondary)
                .multilineTextAlignment(.center)

            Button {
                dismiss()
            } label: {
                Text("Back to Login")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(14)
                    .background(Color.Theme.accent)
                    .foregroundStyle(.white)
                    .cornerRadius(8)
            }
        }
    }

    private func joinWaitlist() async {
        let trimmedName = fullName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        guard !trimmedName.isEmpty, !trimmedEmail.isEmpty else {
            errorMessage = "Please fill in all fields."
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            let body = WaitlistJoinBody(email: trimmedEmail, fullName: trimmedName)
            let _: WaitlistJoinResponse = try await APIClient.shared.request(
                endpoint: .waitlistJoin,
                body: body
            )
            submittedEmail = trimmedEmail
            isSuccess = true
        } catch let error as APIError {
            switch error {
            case .httpError(let statusCode, let message):
                if statusCode == 409 {
                    errorMessage = "This email is already on the waitlist."
                } else {
                    errorMessage = message
                }
            default:
                errorMessage = error.errorDescription
            }
        } catch {
            errorMessage = "Something went wrong. Please try again."
        }

        isLoading = false
    }
}

private struct WaitlistJoinBody: Encodable {
    let email: String
    let fullName: String

    enum CodingKeys: String, CodingKey {
        case email
        case fullName = "full_name"
    }
}

private struct WaitlistJoinResponse: Codable {
    let message: String
    let email: String
}
