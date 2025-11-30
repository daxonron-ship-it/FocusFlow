import Foundation
import Combine

@MainActor
final class TimerService: ObservableObject {
    @Published private(set) var state: TimerState = .idle
    @Published private(set) var currentSession: FocusSession?
    @Published private(set) var remainingTime: TimeInterval = 0
    @Published private(set) var progress: Double = 0

    private var timer: Timer?
    private var pausedTimeRemaining: TimeInterval = 0

    // MARK: - Computed Properties

    var isRunning: Bool {
        state == .running
    }

    var isPaused: Bool {
        state == .paused
    }

    var isIdle: Bool {
        state == .idle
    }

    var isCompleted: Bool {
        state == .completed
    }

    // MARK: - Public Methods

    func startSession(duration: TimeInterval, sessionType: SessionType = .work, strictModeEnabled: Bool = false) {
        let session = FocusSession(
            startTime: Date(),
            plannedDuration: duration,
            sessionType: sessionType,
            completionStatus: .inProgress,
            strictModeEnabled: strictModeEnabled
        )

        currentSession = session
        remainingTime = duration
        progress = 0
        state = .running

        startTimer()
        HapticManager.shared.mediumImpact()
    }

    func pause() {
        guard state == .running, let session = currentSession else { return }

        pausedTimeRemaining = session.endTime.timeIntervalSince(Date())
        stopTimer()
        state = .paused
        HapticManager.shared.lightTap()
    }

    func resume() {
        guard state == .paused, let session = currentSession else { return }

        // Adjust start time to account for pause
        let newStartTime = Date().addingTimeInterval(-session.plannedDuration + pausedTimeRemaining)
        currentSession = FocusSession(
            id: session.id,
            startTime: newStartTime,
            plannedDuration: session.plannedDuration,
            sessionType: session.sessionType,
            completionStatus: .inProgress,
            strictModeEnabled: session.strictModeEnabled
        )

        state = .running
        startTimer()
        HapticManager.shared.lightTap()
    }

    func stop() {
        stopTimer()
        if let session = currentSession {
            currentSession = FocusSession(
                id: session.id,
                startTime: session.startTime,
                plannedDuration: session.plannedDuration,
                sessionType: session.sessionType,
                completionStatus: .quitEarly,
                strictModeEnabled: session.strictModeEnabled,
                quitTimestamp: Date()
            )
        }
        state = .idle
        HapticManager.shared.warning()
    }

    func reset() {
        stopTimer()
        currentSession = nil
        remainingTime = 0
        progress = 0
        pausedTimeRemaining = 0
        state = .idle
    }

    /// Called when app returns to foreground to recalculate time
    func recalculateTime() {
        guard state == .running, let session = currentSession else { return }

        let remaining = session.endTime.timeIntervalSince(Date())

        if remaining <= 0 {
            completeSession()
        } else {
            remainingTime = remaining
            progress = session.progress
        }
    }

    // MARK: - Private Methods

    private func startTimer() {
        stopTimer()

        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tick()
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func tick() {
        guard state == .running, let session = currentSession else { return }

        let remaining = session.endTime.timeIntervalSince(Date())

        if remaining <= 0 {
            completeSession()
        } else {
            remainingTime = remaining
            progress = session.progress
        }
    }

    private func completeSession() {
        stopTimer()

        if let session = currentSession {
            let completedSession = FocusSession(
                id: session.id,
                startTime: session.startTime,
                plannedDuration: session.plannedDuration,
                sessionType: session.sessionType,
                completionStatus: .completed,
                strictModeEnabled: session.strictModeEnabled
            )
            completedSession.actualDuration = session.plannedDuration
            currentSession = completedSession
        }

        remainingTime = 0
        progress = 1.0
        state = .completed
        HapticManager.shared.success()
    }
}
