import SwiftUI

/// Reporting and blocking.
///
/// App Store Guideline 1.2 requires an app carrying user-generated content to
/// offer all four of: filtering of objectionable material, a way to report
/// content, a way to block abusive users, and published contact details. The
/// platform had automated moderation and none of the rest, which is one of the
/// most common rejections for a social app — and a reviewer checks it by
/// looking for these controls, not by reading the backend.
///
/// The reasons deliberately mirror the server's allow-list. A mismatch here
/// produces a 400 the user reads as "reporting is broken".
enum ReportReason: String, CaseIterable, Identifiable {
    case harassment
    case hateSpeech = "hate_speech"
    case violence
    case sexualContent = "sexual_content"
    case selfHarm = "self_harm"
    case spam
    case impersonation
    case misinformation
    case copyright
    case other

    var id: String { rawValue }

    var label: String {
        switch self {
        case .harassment:     return "Harassment or bullying"
        case .hateSpeech:     return "Hate speech"
        case .violence:       return "Violence or threats"
        case .sexualContent:  return "Sexual content"
        case .selfHarm:       return "Self-harm or suicide"
        case .spam:           return "Spam"
        case .impersonation:  return "Impersonation"
        case .misinformation: return "False information"
        case .copyright:      return "Copyright infringement"
        case .other:          return "Something else"
        }
    }
}

struct ReportRequestBody: Encodable {
    let target_type: String
    let target_id: Int
    let reason: String
    let detail: String?
    let reported_user_id: Int?
}

struct ReportSheet: View {
    let targetType: String
    let targetId: Int
    let reportedUserId: Int?
    /// Shown so the user can see what they are reporting rather than trusting
    /// that they tapped the right row.
    let preview: String?

    @Environment(\.dismiss) private var dismiss

    @State private var reason: ReportReason?
    @State private var detail = ""
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    @State private var didSubmit = false

    var body: some View {
        NavigationStack {
            Group {
                if didSubmit {
                    submitted
                } else {
                    form
                }
            }
            .background(Color.Theme.bgBase.ignoresSafeArea())
            .navigationTitle(didSubmit ? "Reported" : "Report")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(didSubmit ? "Done" : "Cancel") { dismiss() }
                        .foregroundStyle(Color.Theme.textSecondary)
                }
                if !didSubmit {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Submit") { Task { await submit() } }
                            .disabled(reason == nil || isSubmitting)
                            .foregroundStyle(reason == nil ? Color.Theme.textSecondary : Color.Theme.accent)
                    }
                }
            }
        }
    }

    private var form: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                if let preview, !preview.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("You're reporting")
                            .font(.caption)
                            .foregroundStyle(Color.Theme.textSecondary)
                        Text(preview)
                            .font(.footnote)
                            .foregroundStyle(Color.Theme.textPrimary)
                            .lineLimit(3)
                            .padding(10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.Theme.bgInput)
                            .cornerRadius(8)
                    }
                }

                Text("Why are you reporting this?")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.Theme.textPrimary)

                VStack(spacing: 0) {
                    ForEach(ReportReason.allCases) { option in
                        Button {
                            reason = option
                        } label: {
                            HStack {
                                Text(option.label)
                                    .font(.subheadline)
                                    .foregroundStyle(Color.Theme.textPrimary)
                                Spacer()
                                if reason == option {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(Color.Theme.accent)
                                }
                            }
                            .padding(.vertical, 12)
                            .contentShape(Rectangle())
                        }
                        Divider().overlay(Color.Theme.borderDefault)
                    }
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Anything else? (optional)")
                        .font(.caption)
                        .foregroundStyle(Color.Theme.textSecondary)
                    TextEditor(text: $detail)
                        .frame(height: 90)
                        .scrollContentBackground(.hidden)
                        .background(Color.Theme.bgInput)
                        .cornerRadius(8)
                        .foregroundStyle(Color.Theme.textPrimary)
                }

                if let errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(Color.Theme.error)
                }

                Text("Reports go to the stanbox team for review. We don't tell the other person who reported them.")
                    .font(.caption2)
                    .foregroundStyle(Color.Theme.textSecondary)
            }
            .padding(20)
        }
    }

    private var submitted: some View {
        VStack(spacing: 14) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 44))
                .foregroundStyle(Color.Theme.accent)
            Text("Thanks — we'll take a look")
                .font(.headline)
                .foregroundStyle(Color.Theme.textPrimary)
            Text("If you'd rather not see this person at all, you can block them from the same menu.")
                .font(.footnote)
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.Theme.textSecondary)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func submit() async {
        guard let reason, !isSubmitting else { return }
        isSubmitting = true
        errorMessage = nil
        let trimmed = detail.trimmingCharacters(in: .whitespacesAndNewlines)
        do {
            try await APIClient.shared.requestVoid(
                endpoint: .reportContent,
                body: ReportRequestBody(
                    target_type: targetType,
                    target_id: targetId,
                    reason: reason.rawValue,
                    detail: trimmed.isEmpty ? nil : trimmed,
                    reported_user_id: reportedUserId
                )
            )
            didSubmit = true
        } catch {
            errorMessage = "Couldn't send that report. Try again."
        }
        isSubmitting = false
    }
}
