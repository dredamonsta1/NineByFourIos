import Testing
@testable import NineByFour

// The fallback a fan sees when they have no photo, or it's still loading.
struct UserAvatarTests {
    @Test func usesTheFirstLetterUppercased() {
        #expect(UserAvatar.initial(for: "andrew3") == "A")
        #expect(UserAvatar.initial(for: "  paperhand") == "P")
    }

    @Test func keepsNonLatinAndStylisedFirstLetters() {
        #expect(UserAvatar.initial(for: "éclair") == "É")
        #expect(UserAvatar.initial(for: "9by4") == "9")
    }

    @Test func fallsBackToAQuestionMarkWithNoName() {
        #expect(UserAvatar.initial(for: nil) == "?")
        #expect(UserAvatar.initial(for: "   ") == "?")
    }
}
