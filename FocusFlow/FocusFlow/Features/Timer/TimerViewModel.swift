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
    @Published var showBlockingFlow: Bool = false
    @Published var showQuitFlow: Bool = false
    @Published private(set) var appSettings: AppSettings?

    let timerService: TimerService
    let blockingManager: BlockingManager
    private var modelContext: ModelContext?
    private var cancellables = Set<AnyCancellable>()

    init(timerService: TimerService? = nil, blockingManager: BlockingManager? = nil) {
        self.timerService = timerService ?? TimerService()
        self.blockingManager = blockingManager ?? BlockingManager.shared
        setupCompletionHandler()
        setupTimerServiceObserver()
        setupBlockingManagerObserver()

        // Load saved app selection
        self.blockingManager.loadSelection()
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

    private func setupBlockingManagerObserver() {
        // Forward BlockingManager changes to trigger view updates
        blockingManager.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }

    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        loadUserStats()
        loadAppSettings()
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

    // MARK: - Blocking Properties

    var blockedAppsDescription: String {
        if blockingManager.hasSelectedApps {
            return blockingManager.blockingDescription
        } else {
            return "None"
        }
    }

    var isBlockingAuthorized: Bool {
        blockingManager.isAuthorized
    }

    var hasBlockedApps: Bool {
        blockingManager.hasSelectedApps
    }

    // MARK: - Strict Mode Properties

    var isStrictModeEnabled: Bool {
        appSettings?.isStrictModeActive ?? false
    }

    var strictModeDisplayValue: String {
        isStrictModeEnabled ? "Strict" : "Normal"
    }

    // MARK: - Strict Mode Actions

    func toggleStrictMode() {
        guard let settings = appSettings, let context = modelContext else { return }

        if settings.strictModeEnabled {
            // Disable strict mode
            settings.strictModeEnabled = false
            settings.strictModeEnabledAt = nil
        } else {
            // Enable strict mode
            settings.strictModeEnabled = true
            settings.strictModeEnabledAt = Date()
        }

        do {
            try context.save()
            objectWillChange.send()
            HapticManager.shared.mediumImpact()
        } catch {
            print("Failed to save strict mode setting: \(error)")
        }
    }

    // MARK: - Blocking Actions

    func blockingCardTapped() {
        if blockingManager.isAuthorized {
            // Already authorized, show app picker directly
            showBlockingFlow = true
        } else {
            // Not authorized, show full permission flow
            showBlockingFlow = true
        }
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

    /// Attempts to stop the session - shows quit flow if strict mode is enabled
    func attemptStopSession() {
        if isStrictModeEnabled {
            // Show quit flow
            showQuitFlow = true
        } else {
            // Direct stop without friction
            confirmStopSession()
        }
    }

    /// Confirms session stop after completing quit flow (or when strict mode is off)
    func confirmStopSession() {
        // Stop app blocking
        blockingManager.stopBlocking()

        if let session = timerService.currentSession {
            // Record quit in stats
            recordQuit(session: session)
        }
        timerService.stop()
        timerService.reset()
        showQuitFlow = false
    }

    /// Cancel quit flow and return to timer
    func cancelQuitFlow() {
        showQuitFlow = false
    }

    /// Legacy method for backwards compatibility
    func stopSession() {
        attemptStopSession()
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
            strictModeEnabled: isStrictModeEnabled
        )

        // Start app blocking for work sessions
        if sessionType == .work && blockingManager.hasSelectedApps {
            blockingManager.startBlocking()
        }

        // Request notification permission on first session
        Task {
            await requestNotificationPermissionIfNeeded()
        }
    }

    private func handleSessionCompletion(_ session: FocusSession) {
        // Stop app blocking
        blockingManager.stopBlocking()

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

    private func loadAppSettings() {
        guard let context = modelContext else { return }
        appSettings = fetchOrCreateAppSettings(context: context)
    }

    private func fetchOrCreateAppSettings(context: ModelContext) -> AppSettings {
        let descriptor = FetchDescriptor<AppSettings>()

        do {
            let results = try context.fetch(descriptor)
            if let existing = results.first {
                return existing
            }
        } catch {
            print("Failed to fetch app settings: \(error)")
        }

        // Create new settings if none exist
        let newSettings = AppSettings()
        context.insert(newSettings)

        do {
            try context.save()
        } catch {
            print("Failed to save new app settings: \(error)")
        }

        return newSettings
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
