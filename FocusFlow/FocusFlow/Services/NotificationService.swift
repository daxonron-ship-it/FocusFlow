import Foundation
import UserNotifications
import Combine

@MainActor
final class NotificationService: ObservableObject {
    static let shared = NotificationService()

    @Published private(set) var isAuthorized: Bool = false

    private let notificationCenter = UNUserNotificationCenter.current()
    private let sessionCompleteIdentifier = "session-complete"

    private init() {
        Task {
            await checkAuthorizationStatus()
        }
    }

    // MARK: - Permission Handling

    func requestPermission() async -> Bool {
        do {
            let granted = try await notificationCenter.requestAuthorization(options: [.alert, .sound, .badge])
            await MainActor.run {
                isAuthorized = granted
            }
            return granted
        } catch {
            print("Notification permission error: \(error)")
            return false
        }
    }

    func checkAuthorizationStatus() async {
        let settings = await notificationCenter.notificationSettings()
        await MainActor.run {
            isAuthorized = settings.authorizationStatus == .authorized
        }
    }

    // MARK: - Session Notifications

    func scheduleSessionComplete(at date: Date, duration: TimeInterval, sessionType: SessionType) {
        // Cancel any existing notification first
        cancelPendingNotifications()

        let content = UNMutableNotificationContent()

        let minutes = Int(duration / 60)
        let sessionName = sessionType == .work ? "Focus" : "Break"

        content.title = "\(sessionName) Session Complete 🎉"
        content.body = "Great work! You focused for \(minutes) minutes."
        content.sound = .default
        content.badge = nil

        // Calculate time interval from now
        let timeInterval = date.timeIntervalSinceNow
        guard timeInterval > 0 else { return }

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
        let request = UNNotificationRequest(
            identifier: sessionCompleteIdentifier,
            content: content,
            trigger: trigger
        )

        notificationCenter.add(request) { error in
            if let error = error {
                print("Failed to schedule notification: \(error)")
            }
        }
    }

    func cancelPendingNotifications() {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [sessionCompleteIdentifier])
    }

    func cancelAllNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
        notificationCenter.removeAllDeliveredNotifications()
    }
}
