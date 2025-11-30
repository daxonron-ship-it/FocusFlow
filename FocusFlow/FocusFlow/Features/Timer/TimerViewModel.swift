import Foundation
import SwiftUI
import SwiftData
import Combine

@MainActor
final class TimerViewModel: ObservableObject {
    @Published var selectedPreset: TimerPreset = .pomodoro25
    @Published var sessionType: SessionType = .work
    @Published var showCompletionView: Bool = false
    @Published var completedSession: FocusSession?
    @Published var currentStreak: Int = 0
    @Published var hasRequestedNotificationPermission: Bool = false

    let timerService: TimerService
    private var modelContext: ModelContext?
    private var cancellables = Set<AnyCancellable>()

    init(timerService: TimerService? = nil) {
        self.timerService = timerService ?? TimerService()
        setupCompletionHandler()
        setupTimerServiceObserver()
    }

    private func setupTimerServiceObserver() {
        // Forward TimerService changes to trigger view updates
        timerService.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }

    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        loadUserStats()
    }

    // MARK: - Computed Properties

    var state: TimerState {
        timerService.state
    }

    var remainingTime: TimeInterval {
        timerService.isIdle ? selectedDuration : timerService.remainingTime
    }

    var progress: Double {
        timerService.progress
    }

    var selectedDuration: TimeInterval {
        sessionType == .work ? selectedPreset.workDuration : selectedPreset.breakDuration
    }

    var canStart: Bool {
        timerService.isIdle
    }

    var canPause: Bool {
        timerService.isRunning
    }

    var canResume: Bool {
        timerService.isPaused
    }

    var isSessionActive: Bool {
        timerService.isRunning || timerService.isPaused
    }

    var pausedDuration: TimeInterval {
        timerService.pausedDuration
    }

    var primaryButtonTitle: String {
        switch timerService.state {
        case .idle:
            return sessionType == .work ? "Start Focus" : "Start Break"
        case .running:
            return "Pause"
        case .paused:
            return "Resume"
        case .completed:
            return sessionType == .work ? "Start Break" : "Start Focus"
        }
    }

    var showStopButton: Bool {
        isSessionActive
    }

    // MARK: - Actions

    func primaryButtonTapped() {
        switch timerService.state {
        case .idle:
            startSession()
        case .running:
            timerService.pause()
        case .paused:
            timerService.resume()
        case .completed:
            dismissCompletionAndContinue()
        }
    }

    func stopSession() {
        if let session = timerService.currentSession {
            // Record quit in stats
            recordQuit(session: session)
        }
        timerService.stop()
        timerService.reset()
    }

    func onAppear() {
        timerService.recalculateTime()
    }

    func onBackground() {
        timerService.onBackground()
    }

    func onForeground() {
        timerService.onForeground()

        // Check if session completed while backgrounded
        if timerService.isCompleted && !showCompletionView {
            if let session = timerService.currentSession {
                completedSession = session
                showCompletionView = true
            }
        }
    }

    func dismissCompletionView() {
        showCompletionView = false
        completedSession = nil
    }

    func dismissCompletionAndContinue() {
        // Toggle session type after completion
        if sessionType == .work {
            sessionType = .rest
        } else {
            sessionType = .work
        }

        showCompletionView = false
        completedSession = nil
        timerService.reset()
    }

    func startBreakAfterCompletion() {
        sessionType = .rest
        showCompletionView = false
        completedSession = nil
        timerService.reset()
        startSession()
    }

    func skipBreak() {
        sessionType = .work
        showCompletionView = false
        completedSession = nil
        timerService.reset()
    }

    // MARK: - Notification Permission

    func requestNotificationPermissionIfNeeded() async {
        guard !hasRequestedNotificationPermission else { return }
        hasRequestedNotificationPermission = true

        _ = await NotificationService.shared.requestPermission()
    }

    // MARK: - Private Methods

    private func setupCompletionHandler() {
        timerService.onSessionCompleted = { [weak self] session in
            self?.handleSessionCompletion(session)
        }
    }

    private func startSession() {
        timerService.startSession(
            duration: selectedDuration,
            sessionType: sessionType,
            strictModeEnabled: false // Will be connected to settings in later milestone
        )

        // Request notification permission on first session
        Task {
            await requestNotificationPermissionIfNeeded()
        }
    }

    private func handleSessionCompletion(_ session: FocusSession) {
        // Save to SwiftData
        saveSession(session)

        // Update stats
        recordCompletion(session: session)

        // Show completion view
        completedSession = session
        showCompletionView = true
    }

    // MARK: - SwiftData Persistence

    private func saveSession(_ session: FocusSession) {
        guard let context = modelContext else { return }

        context.insert(session)

        do {
            try context.save()
        } catch {
            print("Failed to save session: \(error)")
        }
    }

    private func recordCompletion(session: FocusSession) {
        guard let context = modelContext else { return }

        let stats = fetchOrCreateUserStats(context: context)
        stats.recordCompletion()
        currentStreak = stats.currentStreak

        do {
            try context.save()
        } catch {
            print("Failed to save stats: \(error)")
        }
    }

    private func recordQuit(session: FocusSession) {
        guard let context = modelContext else { return }

        // Save the quit session
        let quitSession = FocusSession(
            id: session.id,
            startTime: session.startTime,
            plannedDuration: session.plannedDuration,
            sessionType: session.sessionType,
            completionStatus: .quitEarly,
            strictModeEnabled: session.strictModeEnabled,
            quitTimestamp: Date()
        )
        quitSession.actualDuration = Date().timeIntervalSince(session.startTime)
        context.insert(quitSession)

        // Update stats
        let stats = fetchOrCreateUserStats(context: context)
        stats.recordQuit()
        currentStreak = stats.currentStreak

        do {
            try context.save()
        } catch {
            print("Failed to save quit: \(error)")
        }
    }

    private func loadUserStats() {
        guard let context = modelContext else { return }

        let stats = fetchOrCreateUserStats(context: context)
        currentStreak = stats.currentStreak
    }

    private func fetchOrCreateUserStats(context: ModelContext) -> UserStats {
        let descriptor = FetchDescriptor<UserStats>()

        do {
            let results = try context.fetch(descriptor)
            if let existing = results.first {
                return existing
            }
        } catch {
            print("Failed to fetch stats: \(error)")
        }

        // Create new stats if none exist
        let newStats = UserStats()
        context.insert(newStats)
        return newStats
    }
}
