import Foundation
import SwiftData

@Model
final class FocusSession {
    @Attribute(.unique) var id: UUID
    var startTime: Date
    var plannedDuration: TimeInterval
    var actualDuration: TimeInterval?
    var sessionType: SessionType
    var completionStatus: CompletionStatus
    var strictModeEnabled: Bool
    var quitTimestamp: Date?
    var challengePhraseUsed: String?

    init(
        id: UUID = UUID(),
        startTime: Date = Date(),
        plannedDuration: TimeInterval,
        sessionType: SessionType = .work,
        completionStatus: CompletionStatus = .inProgress,
        strictModeEnabled: Bool = false,
        quitTimestamp: Date? = nil,
        challengePhraseUsed: String? = nil
    ) {
        self.id = id
        self.startTime = startTime
        self.plannedDuration = plannedDuration
        self.actualDuration = nil
        self.sessionType = sessionType
        self.completionStatus = completionStatus
        self.strictModeEnabled = strictModeEnabled
        self.quitTimestamp = quitTimestamp
        self.challengePhraseUsed = challengePhraseUsed
    }

    var endTime: Date {
        startTime.addingTimeInterval(plannedDuration)
    }

    var remainingTime: TimeInterval {
        max(0, endTime.timeIntervalSince(Date()))
    }

    var elapsedTime: TimeInterval {
        Date().timeIntervalSince(startTime)
    }

    var progress: Double {
        guard plannedDuration > 0 else { return 0 }
        return min(1.0, elapsedTime / plannedDuration)
    }

    var isExpired: Bool {
        Date() >= endTime
    }
}
