import Foundation
import SwiftUI
import SwiftData
import Combine

@MainActor
final class TimerViewModel: ObservableObject {
    @Published var selectedPreset: TimerPreset = .pomodoro25
    @Published var sessionType: SessionType = .work

    let timerService: TimerService

    private var cancellables = Set<AnyCancellable>()

    init(timerService: TimerService? = nil) {
        self.timerService = timerService ?? TimerService()
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

    var primaryButtonTitle: String {
        switch timerService.state {
        case .idle:
            return "Start Focus"
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
            handleCompletion()
        }
    }

    func stopSession() {
        timerService.stop()
        timerService.reset()
    }

    func onAppear() {
        // Recalculate time when view appears (e.g., returning from background)
        timerService.recalculateTime()
    }

    // MARK: - Private Methods

    private func startSession() {
        timerService.startSession(
            duration: selectedDuration,
            sessionType: sessionType,
            strictModeEnabled: false // Will be connected to settings in later milestone
        )
    }

    private func handleCompletion() {
        // Toggle session type after completion
        if sessionType == .work {
            sessionType = .rest
        } else {
            sessionType = .work
        }

        timerService.reset()
    }
}
