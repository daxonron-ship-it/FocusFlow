import Foundation
import SwiftUI
import SwiftData
import UserNotifications
import FamilyControls
import Combine

@MainActor
final class ScheduleManager: ObservableObject {
    static let shared = ScheduleManager()

    @Published var activeSchedule: Schedule?
    @Published private(set) var isScheduleTriggered: Bool = false

    private var modelContext: ModelContext?
    private let notificationCenter = UNUserNotificationCenter.current()

    private init() {}

    // MARK: - Configuration

    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }

    // MARK: - Schedule Checking

    /// Check if any schedule should be active now and return it
    func checkForActiveSchedule() -> Schedule? {
        guard let context = modelContext else { return nil }

        let descriptor = FetchDescriptor<Schedule>(
            predicate: #Predicate<Schedule> { $0.isActive }
        )

        do {
            let schedules = try context.fetch(descriptor)
            let now = Date()

            for schedule in schedules {
                if schedule.isWithinWindow(at: now) {
                    return schedule
                }
            }
        } catch {
            print("Failed to fetch schedules: \(error)")
        }

        return nil
    }

    /// Check and activate any due schedules on app launch/foreground
    func checkAndActivateSchedules() {
        if let schedule = checkForActiveSchedule() {
            activeSchedule = schedule
            isScheduleTriggered = true
        }
    }

    /// Reset the schedule triggered state
    func clearActiveSchedule() {
        activeSchedule = nil
        isScheduleTriggered = false
    }

    // MARK: - Notification Scheduling

    /// Schedule notifications for a specific schedule
    func scheduleNotifications(for schedule: Schedule) {
        guard schedule.isActive else { return }

        // Cancel existing notifications for this schedule first
        cancelNotifications(for: schedule)

        let scheduleId = schedule.id.uuidString

        for day in schedule.activeDaysSet {
            scheduleWarningNotification(for: schedule, on: day, scheduleId: scheduleId)
            scheduleStartNotification(for: schedule, on: day, scheduleId: scheduleId)
        }
    }

    private func scheduleWarningNotification(for schedule: Schedule, on day: Weekday, scheduleId: String) {
        var warningComponents = DateComponents()
        warningComponents.weekday = day.rawValue

        // Calculate 5 minutes before start
        var warningMinute = schedule.startMinute - 5
        var warningHour = schedule.startHour

        if warningMinute < 0 {
            warningMinute += 60
            warningHour -= 1
            if warningHour < 0 {
                warningHour = 23
            }
        }

        warningComponents.hour = warningHour
        warningComponents.minute = warningMinute

        let content = UNMutableNotificationContent()
        content.title = "Focus session starting in 5 minutes"
        content.body = schedule.name.isEmpty ? "Get ready to focus!" : schedule.name
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(dateMatching: warningComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: "\(scheduleId)-warning-\(day.rawValue)",
            content: content,
            trigger: trigger
        )

        notificationCenter.add(request) { error in
            if let error = error {
                print("Failed to schedule warning notification: \(error)")
            }
        }
    }

    private func scheduleStartNotification(for schedule: Schedule, on day: Weekday, scheduleId: String) {
        var startComponents = DateComponents()
        startComponents.weekday = day.rawValue
        startComponents.hour = schedule.startHour
        startComponents.minute = schedule.startMinute

        let content = UNMutableNotificationContent()
        content.title = "Focus session active"
        content.body = schedule.name.isEmpty ? "Stay focused!" : "\(schedule.name) • Stay focused!"
        content.sound = .default
        content.categoryIdentifier = "SCHEDULE_START"

        let trigger = UNCalendarNotificationTrigger(dateMatching: startComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: "\(scheduleId)-start-\(day.rawValue)",
            content: content,
            trigger: trigger
        )

        notificationCenter.add(request) { error in
            if let error = error {
                print("Failed to schedule start notification: \(error)")
            }
        }
    }

    /// Cancel all notifications for a specific schedule
    func cancelNotifications(for schedule: Schedule) {
        let scheduleId = schedule.id.uuidString
        var identifiers: [String] = []

        for day in Weekday.allCases {
            identifiers.append("\(scheduleId)-warning-\(day.rawValue)")
            identifiers.append("\(scheduleId)-start-\(day.rawValue)")
        }

        notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    /// Reschedule all active schedules' notifications
    func rescheduleAllNotifications() {
        guard let context = modelContext else { return }

        let descriptor = FetchDescriptor<Schedule>(
            predicate: #Predicate<Schedule> { $0.isActive }
        )

        do {
            let schedules = try context.fetch(descriptor)
            for schedule in schedules {
                scheduleNotifications(for: schedule)
            }
        } catch {
            print("Failed to fetch schedules for rescheduling: \(error)")
        }
    }

    /// Cancel all schedule-related notifications
    func cancelAllScheduleNotifications() {
        guard let context = modelContext else { return }

        let descriptor = FetchDescriptor<Schedule>()

        do {
            let schedules = try context.fetch(descriptor)
            for schedule in schedules {
                cancelNotifications(for: schedule)
            }
        } catch {
            print("Failed to fetch schedules for cancellation: \(error)")
        }
    }

    // MARK: - Schedule CRUD Operations

    func createSchedule(
        name: String,
        activeDays: Set<Weekday>,
        startHour: Int,
        startMinute: Int,
        duration: TimeInterval,
        strictModeEnabled: Bool,
        blockedAppsData: Data?
    ) -> Schedule? {
        guard let context = modelContext else { return nil }

        let schedule = Schedule(
            name: name,
            activeDays: activeDays.map { $0.rawValue }.sorted(),
            startHour: startHour,
            startMinute: startMinute,
            duration: duration,
            strictModeEnabled: strictModeEnabled,
            isActive: true,
            blockedAppsData: blockedAppsData
        )

        context.insert(schedule)

        do {
            try context.save()
            scheduleNotifications(for: schedule)
            return schedule
        } catch {
            print("Failed to create schedule: \(error)")
            return nil
        }
    }

    func updateSchedule(_ schedule: Schedule) {
        guard let context = modelContext else { return }

        do {
            try context.save()

            // Update notifications
            if schedule.isActive {
                scheduleNotifications(for: schedule)
            } else {
                cancelNotifications(for: schedule)
            }
        } catch {
            print("Failed to update schedule: \(error)")
        }
    }

    func deleteSchedule(_ schedule: Schedule) {
        guard let context = modelContext else { return }

        cancelNotifications(for: schedule)
        context.delete(schedule)

        do {
            try context.save()
        } catch {
            print("Failed to delete schedule: \(error)")
        }
    }

    func toggleScheduleActive(_ schedule: Schedule) {
        schedule.isActive.toggle()
        updateSchedule(schedule)
    }

    // MARK: - Blocked Apps Encoding/Decoding

    func encodeBlockedApps(_ selection: FamilyActivitySelection) -> Data? {
        try? JSONEncoder().encode(selection)
    }

    func decodeBlockedApps(_ data: Data?) -> FamilyActivitySelection? {
        guard let data = data else { return nil }
        return try? JSONDecoder().decode(FamilyActivitySelection.self, from: data)
    }
}
