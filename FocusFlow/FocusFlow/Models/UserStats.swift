import Foundation
import SwiftData

@Model
final class UserStats {
    var currentStreak: Int
    var longestStreak: Int
    var totalSessionsCompleted: Int
    var totalSessionsQuit: Int
    var lastCompletionDate: Date?

    init(
        currentStreak: Int = 0,
        longestStreak: Int = 0,
        totalSessionsCompleted: Int = 0,
        totalSessionsQuit: Int = 0,
        lastCompletionDate: Date? = nil
    ) {
        self.currentStreak = currentStreak
        self.longestStreak = longestStreak
        self.totalSessionsCompleted = totalSessionsCompleted
        self.totalSessionsQuit = totalSessionsQuit
        self.lastCompletionDate = lastCompletionDate
    }

    var quitRate: Double {
        let total = totalSessionsCompleted + totalSessionsQuit
        guard total > 0 else { return 0 }
        return Double(totalSessionsQuit) / Double(total) * 100
    }

    func recordCompletion() {
        totalSessionsCompleted += 1

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        if let lastDate = lastCompletionDate {
            let lastDay = calendar.startOfDay(for: lastDate)
            let daysDifference = calendar.dateComponents([.day], from: lastDay, to: today).day ?? 0

            if daysDifference == 1 {
                // Consecutive day - increment streak
                currentStreak += 1
            } else if daysDifference > 1 {
                // Missed days - reset streak
                currentStreak = 1
            }
            // Same day - don't change streak
        } else {
            // First completion ever
            currentStreak = 1
        }

        longestStreak = max(longestStreak, currentStreak)
        lastCompletionDate = Date()
    }

    func recordQuit() {
        totalSessionsQuit += 1
        currentStreak = 0
    }
}
