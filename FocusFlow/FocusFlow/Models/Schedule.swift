import Foundation
import SwiftData

@Model
final class Schedule {
    @Attribute(.unique) var id: UUID
    var name: String
    var activeDays: [Int]  // Weekday raw values stored as array
    var startHour: Int
    var startMinute: Int
    var duration: TimeInterval
    var strictModeEnabled: Bool
    var isActive: Bool
    var blockedAppsData: Data?  // Encoded FamilyActivitySelection

    init(
        id: UUID = UUID(),
        name: String = "",
        activeDays: [Int] = [],
        startHour: Int = 9,
        startMinute: Int = 0,
        duration: TimeInterval = 60 * 60,  // 1 hour default
        strictModeEnabled: Bool = false,
        isActive: Bool = true,
        blockedAppsData: Data? = nil
    ) {
        self.id = id
        self.name = name
        self.activeDays = activeDays
        self.startHour = startHour
        self.startMinute = startMinute
        self.duration = duration
        self.strictModeEnabled = strictModeEnabled
        self.isActive = isActive
        self.blockedAppsData = blockedAppsData
    }

    // MARK: - Computed Properties

    /// Get active days as Weekday set
    var activeDaysSet: Set<Weekday> {
        get {
            Set(activeDays.compactMap { Weekday(rawValue: $0) })
        }
        set {
            activeDays = newValue.map { $0.rawValue }.sorted()
        }
    }

    /// Get start time as DateComponents
    var startTimeComponents: DateComponents {
        var components = DateComponents()
        components.hour = startHour
        components.minute = startMinute
        return components
    }

    /// Formatted start time string
    var formattedStartTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"

        var components = DateComponents()
        components.hour = startHour
        components.minute = startMinute

        if let date = Calendar.current.date(from: components) {
            return formatter.string(from: date)
        }
        return "\(startHour):\(String(format: "%02d", startMinute))"
    }

    /// Formatted duration string
    var formattedDuration: String {
        duration.formattedTimeVerbose
    }

    /// Short description of active days
    var daysDescription: String {
        let daysSet = activeDaysSet

        if daysSet.count == 7 {
            return "Daily"
        } else if daysSet == Set([Weekday.monday, .tuesday, .wednesday, .thursday, .friday]) {
            return "Weekdays"
        } else if daysSet == Set([Weekday.saturday, .sunday]) {
            return "Weekends"
        } else {
            return daysSet.sorted().map { $0.shortName }.joined(separator: " ")
        }
    }

    // MARK: - Schedule Checking

    /// Check if the schedule is active on a given date
    func isActiveOn(date: Date) -> Bool {
        guard isActive else { return false }

        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date)

        guard let day = Weekday(rawValue: weekday) else { return false }
        return activeDaysSet.contains(day)
    }

    /// Check if the given date/time is within this schedule's window
    func isWithinWindow(at date: Date) -> Bool {
        guard isActiveOn(date: date) else { return false }

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)

        guard let scheduleStart = calendar.date(
            bySettingHour: startHour,
            minute: startMinute,
            second: 0,
            of: startOfDay
        ) else { return false }

        let scheduleEnd = scheduleStart.addingTimeInterval(duration)

        return date >= scheduleStart && date < scheduleEnd
    }

    /// Get the next scheduled start time from the given date
    func nextScheduledTime(from date: Date) -> Date? {
        guard isActive, !activeDays.isEmpty else { return nil }

        let calendar = Calendar.current

        // Check up to 7 days ahead
        for dayOffset in 0..<7 {
            guard let checkDate = calendar.date(byAdding: .day, value: dayOffset, to: date) else { continue }

            let weekday = calendar.component(.weekday, from: checkDate)
            guard activeDays.contains(weekday) else { continue }

            let startOfDay = calendar.startOfDay(for: checkDate)
            guard let scheduleTime = calendar.date(
                bySettingHour: startHour,
                minute: startMinute,
                second: 0,
                of: startOfDay
            ) else { continue }

            // If it's today, only return if the time hasn't passed yet
            if dayOffset == 0 && scheduleTime <= date {
                continue
            }

            return scheduleTime
        }

        return nil
    }
}
