import Foundation
import SwiftData

@Model
final class AppSettings {
    var strictModeEnabled: Bool
    var strictModeTone: StrictModeTone
    var customChallengePhrase: String?
    var challengeType: ChallengeType
    var strictModeEnabledAt: Date?
    var strictModeDisablePending: Bool
    var strictModeDisableTime: Date?

    init(
        strictModeEnabled: Bool = false,
        strictModeTone: StrictModeTone = .neutral,
        customChallengePhrase: String? = nil,
        challengeType: ChallengeType = .phrase,
        strictModeEnabledAt: Date? = nil,
        strictModeDisablePending: Bool = false,
        strictModeDisableTime: Date? = nil
    ) {
        self.strictModeEnabled = strictModeEnabled
        self.strictModeTone = strictModeTone
        self.customChallengePhrase = customChallengePhrase
        self.challengeType = challengeType
        self.strictModeEnabledAt = strictModeEnabledAt
        self.strictModeDisablePending = strictModeDisablePending
        self.strictModeDisableTime = strictModeDisableTime
    }

    /// Check if within 15-minute buyer's remorse window
    var isInBuyersRemorseWindow: Bool {
        guard let enabledAt = strictModeEnabledAt else { return false }
        return Date().timeIntervalSince(enabledAt) < 15 * 60
    }

    /// Check if strict mode is actually active (accounting for pending disable)
    var isStrictModeActive: Bool {
        if strictModeDisablePending,
           let disableTime = strictModeDisableTime,
           Date() >= disableTime {
            return false
        }
        return strictModeEnabled
    }
}
