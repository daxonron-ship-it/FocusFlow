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

    /// Check and perform scheduled disable if time has passed
    /// Call this on app launch and periodically to ensure disable happens
    func checkAndPerformScheduledDisable() {
        if strictModeDisablePending,
           let disableTime = strictModeDisableTime,
           Date() >= disableTime {
            // Time has passed - actually disable strict mode
            strictModeEnabled = false
            strictModeDisablePending = false
            strictModeDisableTime = nil
            strictModeEnabledAt = nil
        }
    }

    /// Enable strict mode with buyer's remorse window
    func enableStrictMode() {
        strictModeEnabled = true
        strictModeEnabledAt = Date()
        strictModeDisablePending = false
        strictModeDisableTime = nil
    }

    /// Disable strict mode - either instantly (if in buyer's remorse) or schedule for 24h
    /// - Returns: true if disabled instantly, false if scheduled
    @discardableResult
    func disableStrictMode() -> Bool {
        if isInBuyersRemorseWindow {
            // Instant disable during buyer's remorse window
            strictModeEnabled = false
            strictModeEnabledAt = nil
            strictModeDisablePending = false
            strictModeDisableTime = nil
            return true
        } else {
            // Schedule 24-hour delayed disable
            strictModeDisablePending = true
            strictModeDisableTime = Date().addingTimeInterval(24 * 60 * 60)
            return false
        }
    }

    /// Cancel a pending disable
    func cancelPendingDisable() {
        strictModeDisablePending = false
        strictModeDisableTime = nil
    }
}
