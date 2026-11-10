import SwiftUI

/// Legal links and the music-data credit, shown at the foot of your Profile.
///
/// The credit is required: MusicBrainz genre tags are licensed CC BY-NC-SA,
/// which requires attribution, and MetaBrainz asks to be credited for
/// ListenBrainz data. The web app carries the same line in its footer
/// (9by4app #202). Terms and Privacy open the web pages, which are the
/// source of truth; Apple also expects the privacy policy to be reachable
/// from inside an app with accounts.
enum AboutURL {
    static let terms = URL(string: "https://onstanbox.com/terms")!
    static let privacy = URL(string: "https://onstanbox.com/privacy")!
    static let support = URL(string: "https://onstanbox.com/support")!
    static let musicBrainz = URL(string: "https://musicbrainz.org")!
    static let listenBrainz = URL(string: "https://listenbrainz.org")!
    static let metaBrainz = URL(string: "https://metabrainz.org")!
}

struct AboutLinks: View {
    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 14) {
                Link("Terms of Use", destination: AboutURL.terms)
                Link("Privacy Policy", destination: AboutURL.privacy)
                Link("Support", destination: AboutURL.support)
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(Color.Theme.textSecondary)

            Text(Self.credit)
                .font(.caption2)
                .foregroundStyle(Color.Theme.textSecondary)
                .tint(Color.Theme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 16)
    }

    /// Built as an AttributedString so each name is a real link.
    static var credit: AttributedString {
        var text = AttributedString("Music data from ")
        text += linked("MusicBrainz", AboutURL.musicBrainz)
        text += AttributedString(" and ")
        text += linked("ListenBrainz", AboutURL.listenBrainz)
        text += AttributedString(", projects of the ")
        text += linked("MetaBrainz Foundation", AboutURL.metaBrainz)
        text += AttributedString(".")
        return text
    }

    private static func linked(_ label: String, _ url: URL) -> AttributedString {
        var part = AttributedString(label)
        part.link = url
        part.underlineStyle = .single
        return part
    }
}
