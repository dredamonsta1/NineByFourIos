import SwiftUI

/// Music Personality — the payoff for building a Top 20.
///
/// Shipped on web 2026-08 and absent from iOS entirely until now. `/users/me`
/// has returned `music_personality_title` / `_desc` / `_public` the whole
/// time; the iOS `User` model just never decoded them, so the data arrived and
/// was discarded.
///
/// Three artists is the threshold, matching the web and the server, which
/// rejects fewer with a 400. Below it this is a prompt rather than a locked
/// door: it says how many more are needed, because "come back later" with no
/// number is the kind of empty state people bounce off.
struct MusicPersonalityCard: View {
    let artists: [Artist]
    /// Nil while the user has never generated one.
    let title: String?
    let description: String?
    let isPublic: Bool

    var onGenerated: ((String, String) -> Void)?
    var onVisibilityChanged: ((Bool) -> Void)?

    @State private var isGenerating = false
    @State private var errorMessage: String?
    @State private var justRevealed = false

    private let threshold = 3

    private var canGenerate: Bool { artists.count >= threshold }
    private var remaining: Int { max(0, threshold - artists.count) }
    private var hasPersonality: Bool { !(title ?? "").isEmpty }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header

            if hasPersonality {
                revealed
            } else if canGenerate {
                prompt
            } else {
                locked
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(Color.Theme.error)
            }
        }
        .padding(16)
        .background(Color.Theme.bgCard)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.Theme.borderDefault, lineWidth: 1)
        )
    }

    private var header: some View {
        HStack {
            Text("Your Music Personality")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.Theme.textPrimary)
            Spacer()
            if hasPersonality {
                // Public/private is the user's call. Defaults to private on the
                // server, so this never exposes anything without a deliberate tap.
                Button {
                    onVisibilityChanged?(!isPublic)
                } label: {
                    Label(
                        isPublic ? "Public" : "Private",
                        systemImage: isPublic ? "eye" : "eye.slash"
                    )
                    .font(.caption2)
                    .foregroundStyle(Color.Theme.textSecondary)
                }
            }
        }
    }

    private var revealed: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title ?? "")
                .font(.title3.bold())
                .foregroundStyle(Color.Theme.accent)
                .scaleEffect(justRevealed ? 1.0 : 0.96)
                .opacity(justRevealed ? 1 : 0.9)
                .animation(.spring(response: 0.45, dampingFraction: 0.7), value: justRevealed)

            if let description, !description.isEmpty {
                Text(description)
                    .font(.footnote)
                    .foregroundStyle(Color.Theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Button {
                Task { await generate() }
            } label: {
                Text(isGenerating ? "Rethinking…" : "Regenerate")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.Theme.textSecondary)
            }
            .disabled(isGenerating)
            .padding(.top, 2)
        }
    }

    private var prompt: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("You've got \(artists.count) artists. Let's see what that says about you.")
                .font(.footnote)
                .foregroundStyle(Color.Theme.textSecondary)

            Button {
                Task { await generate() }
            } label: {
                HStack(spacing: 6) {
                    if isGenerating { ProgressView().tint(Color.Theme.bgBase).scaleEffect(0.8) }
                    Text(isGenerating ? "Reading your taste…" : "Reveal my personality")
                        .font(.subheadline.weight(.bold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.Theme.accent)
                .foregroundStyle(Color.Theme.bgBase)
                .cornerRadius(8)
            }
            .disabled(isGenerating)
        }
    }

    private var locked: some View {
        // Says the number. An empty state that does not tell you how far away
        // you are is one people leave.
        VStack(alignment: .leading, spacing: 6) {
            Text("Add \(remaining) more artist\(remaining == 1 ? "" : "s") to unlock")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Color.Theme.textPrimary)
            Text("We read your top artists and tell you what kind of listener you are.")
                .font(.caption)
                .foregroundStyle(Color.Theme.textSecondary)
            ProgressView(value: Double(artists.count), total: Double(threshold))
                .tint(Color.Theme.accent)
                .padding(.top, 2)
        }
    }

    private func generate() async {
        guard canGenerate, !isGenerating else { return }
        isGenerating = true
        errorMessage = nil
        do {
            let body = PersonalityRequest(
                artists: artists.map {
                    PersonalityRequest.ArtistRef(artist_name: $0.artistName, genre: $0.genre)
                }
            )
            let result: PersonalityResponse = try await APIClient.shared.request(
                endpoint: .musicPersonality,
                body: body
            )
            onGenerated?(result.title, result.description)
            justRevealed = true
        } catch {
            errorMessage = "Couldn't read your taste right now. Try again."
        }
        isGenerating = false
    }
}

struct PersonalityRequest: Encodable {
    struct ArtistRef: Encodable {
        let artist_name: String
        let genre: String?
    }
    let artists: [ArtistRef]
}

struct PersonalityResponse: Decodable {
    let title: String
    let description: String
}
