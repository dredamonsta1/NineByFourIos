import Foundation
import Testing
@testable import NineByFour

// Through 1.2 the app shipped without background audio: the project set it
// with INFOPLIST_KEY_UIBackgroundModes, which Xcode silently drops, so iOS
// suspended StanBox on lock and every sample, stream and post went quiet.
// These read the Info.plist of the app the tests run inside, so a setting
// that doesn't make it into the build fails here instead of on a phone.
struct InfoPlistTests {
    private let info = Bundle.main.infoDictionary ?? [:]

    @Test func keepsPlayingAudioWhenThePhoneLocks() {
        let modes = info["UIBackgroundModes"] as? [String] ?? []
        #expect(modes.contains("audio"))
    }

    @Test func usesTheNavyLaunchBackgroundInsteadOfAWhiteFlash() {
        let launch = info["UILaunchScreen"] as? [String: Any] ?? [:]
        #expect(launch["UIColorName"] as? String == "LaunchBackground")
    }

    @Test func stillHasTheGeneratedKeys() {
        #expect(info["CFBundleDisplayName"] as? String == "StanBox")
        #expect(info["NSMicrophoneUsageDescription"] != nil)
        #expect(info["NSCameraUsageDescription"] != nil)
        #expect(info["ITSAppUsesNonExemptEncryption"] as? Bool == false)
    }
}
