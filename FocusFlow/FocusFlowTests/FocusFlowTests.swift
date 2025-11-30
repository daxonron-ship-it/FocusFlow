//
//  FocusFlowTests.swift
//  FocusFlowTests
//
//  Created by Rabindra Yadav on 11/30/25.
//

import Testing
import Foundation
@testable import FocusFlow

// MARK: - Enum Tests

struct EnumTests {
    @Test func sessionTypeDisplayNames() {
        #expect(SessionType.work.displayName == "Focus Time")
        #expect(SessionType.rest.displayName == "Break Time")
    }

    @Test func strictModeTonePhrases() {
        #expect(StrictModeTone.gentle.phrases.count == 3)
        #expect(StrictModeTone.neutral.phrases.count == 3)
        #expect(StrictModeTone.strict.phrases.count == 3)
        #expect(StrictModeTone.custom.phrases.isEmpty)
    }

    @Test func challengeTypeDisplayNames() {
        #expect(ChallengeType.phrase.displayName == "Type a Phrase")
        #expect(ChallengeType.math.displayName == "Solve Math Problem")
        #expect(ChallengeType.pattern.displayName == "Tap Pattern")
        #expect(ChallengeType.holdButton.displayName == "Hold Button")
    }

    @Test func timerStateEquality() {
        #expect(TimerState.idle == TimerState.idle)
        #expect(TimerState.running == TimerState.running)
        #expect(TimerState.paused == TimerState.paused)
        #expect(TimerState.completed == TimerState.completed)
        #expect(TimerState.idle != TimerState.running)
    }
}

// MARK: - Timer Preset Tests

struct TimerPresetTests {
    @Test func presetDurations() {
        #expect(TimerPreset.pomodoro25.workDuration == 25 * 60)
        #expect(TimerPreset.pomodoro25.breakDuration == 5 * 60)

        #expect(TimerPreset.pomodoro50.workDuration == 50 * 60)
        #expect(TimerPreset.pomodoro50.breakDuration == 10 * 60)

        #expect(TimerPreset.pomodoro90.workDuration == 90 * 60)
        #expect(TimerPreset.pomodoro90.breakDuration == 20 * 60)
    }

    @Test func presetDisplayNames() {
        #expect(TimerPreset.pomodoro25.displayName == "25/5")
        #expect(TimerPreset.pomodoro50.displayName == "50/10")
        #expect(TimerPreset.pomodoro90.displayName == "90/20")
    }

    @Test func presetCaseIterable() {
        #expect(TimerPreset.allCases.count == 3)
    }
}

// MARK: - FocusSession Tests

struct FocusSessionTests {
    @Test func sessionInitialization() {
        let session = FocusSession(
            plannedDuration: 25 * 60,
            sessionType: .work
        )

        #expect(session.plannedDuration == 25 * 60)
        #expect(session.sessionType == .work)
        #expect(session.completionStatus == .inProgress)
        #expect(session.strictModeEnabled == false)
        #expect(session.actualDuration == nil)
    }

    @Test func sessionEndTimeCalculation() {
        let startTime = Date()
        let duration: TimeInterval = 25 * 60

        let session = FocusSession(
            startTime: startTime,
            plannedDuration: duration
        )

        let expectedEndTime = startTime.addingTimeInterval(duration)
        #expect(abs(session.endTime.timeIntervalSince(expectedEndTime)) < 0.001)
    }

    @Test func sessionProgress() {
        let startTime = Date().addingTimeInterval(-12.5 * 60) // Started 12.5 min ago
        let session = FocusSession(
            startTime: startTime,
            plannedDuration: 25 * 60
        )

        // Progress should be approximately 50%
        #expect(session.progress >= 0.49 && session.progress <= 0.51)
    }

    @Test func sessionIsExpired() {
        let pastSession = FocusSession(
            startTime: Date().addingTimeInterval(-30 * 60), // Started 30 min ago
            plannedDuration: 25 * 60 // 25 min duration
        )
        #expect(pastSession.isExpired == true)

        let activeSession = FocusSession(
            startTime: Date(),
            plannedDuration: 25 * 60
        )
        #expect(activeSession.isExpired == false)
    }
}

// MARK: - UserStats Tests

struct UserStatsTests {
    @Test func statsInitialization() {
        let stats = UserStats()

        #expect(stats.currentStreak == 0)
        #expect(stats.longestStreak == 0)
        #expect(stats.totalSessionsCompleted == 0)
        #expect(stats.totalSessionsQuit == 0)
        #expect(stats.lastCompletionDate == nil)
    }

    @Test func quitRateCalculation() {
        let stats = UserStats(
            totalSessionsCompleted: 90,
            totalSessionsQuit: 10
        )

        #expect(stats.quitRate == 10.0)
    }

    @Test func quitRateWithZeroSessions() {
        let stats = UserStats()
        #expect(stats.quitRate == 0)
    }

    @Test func recordFirstCompletion() {
        let stats = UserStats()
        stats.recordCompletion()

        #expect(stats.currentStreak == 1)
        #expect(stats.longestStreak == 1)
        #expect(stats.totalSessionsCompleted == 1)
        #expect(stats.lastCompletionDate != nil)
    }

    @Test func recordQuit() {
        let stats = UserStats(currentStreak: 5, longestStreak: 10)
        stats.recordQuit()

        #expect(stats.currentStreak == 0)
        #expect(stats.longestStreak == 10) // Should not change
        #expect(stats.totalSessionsQuit == 1)
    }

    @Test func streakResetsOnQuit() {
        let stats = UserStats()
        stats.recordCompletion()
        stats.recordCompletion()
        #expect(stats.currentStreak >= 1)

        stats.recordQuit()
        #expect(stats.currentStreak == 0)
    }
}

// MARK: - AppSettings Tests

struct AppSettingsTests {
    @Test func settingsInitialization() {
        let settings = AppSettings()

        #expect(settings.strictModeEnabled == false)
        #expect(settings.strictModeTone == .neutral)
        #expect(settings.challengeType == .phrase)
        #expect(settings.strictModeDisablePending == false)
    }

    @Test func buyersRemorseWindowActive() {
        let settings = AppSettings()
        settings.strictModeEnabled = true
        settings.strictModeEnabledAt = Date() // Just enabled

        #expect(settings.isInBuyersRemorseWindow == true)
    }

    @Test func buyersRemorseWindowExpired() {
        let settings = AppSettings()
        settings.strictModeEnabled = true
        settings.strictModeEnabledAt = Date().addingTimeInterval(-20 * 60) // 20 min ago

        #expect(settings.isInBuyersRemorseWindow == false)
    }

    @Test func strictModeActiveStatus() {
        let settings = AppSettings()
        settings.strictModeEnabled = true

        #expect(settings.isStrictModeActive == true)
    }

    @Test func strictModeWithPendingDisable() {
        let settings = AppSettings()
        settings.strictModeEnabled = true
        settings.strictModeDisablePending = true
        settings.strictModeDisableTime = Date().addingTimeInterval(-1) // Already passed

        #expect(settings.isStrictModeActive == false)
    }
}

// MARK: - TimeInterval Extension Tests

struct TimeIntervalExtensionTests {
    @Test func formattedTimeMinutesAndSeconds() {
        let time: TimeInterval = 5 * 60 + 30 // 5:30
        #expect(time.formattedTime == "05:30")
    }

    @Test func formattedTimeZero() {
        let time: TimeInterval = 0
        #expect(time.formattedTime == "00:00")
    }

    @Test func formattedTimeVerboseMinutes() {
        let time: TimeInterval = 25 * 60
        #expect(time.formattedTimeVerbose == "25 min")
    }

    @Test func formattedTimeVerboseHours() {
        let time: TimeInterval = 90 * 60 // 1.5 hours
        #expect(time.formattedTimeVerbose == "1h 30m")
    }
}

// MARK: - TimerService Tests

@MainActor
struct TimerServiceTests {
    @Test func serviceInitialState() async {
        let service = TimerService()

        #expect(service.state == .idle)
        #expect(service.isIdle == true)
        #expect(service.isRunning == false)
        #expect(service.currentSession == nil)
    }

    @Test func startSession() async {
        let service = TimerService()
        service.startSession(duration: 25 * 60, sessionType: .work)

        #expect(service.state == .running)
        #expect(service.isRunning == true)
        #expect(service.currentSession != nil)
        #expect(service.currentSession?.sessionType == .work)
    }

    @Test func pauseSession() async {
        let service = TimerService()
        service.startSession(duration: 25 * 60)
        service.pause()

        #expect(service.state == .paused)
        #expect(service.isPaused == true)
    }

    @Test func resumeSession() async {
        let service = TimerService()
        service.startSession(duration: 25 * 60)
        service.pause()
        service.resume()

        #expect(service.state == .running)
        #expect(service.isRunning == true)
    }

    @Test func stopSession() async {
        let service = TimerService()
        service.startSession(duration: 25 * 60)
        service.stop()

        #expect(service.state == .idle)
        #expect(service.currentSession?.completionStatus == .quitEarly)
    }

    @Test func resetService() async {
        let service = TimerService()
        service.startSession(duration: 25 * 60)
        service.reset()

        #expect(service.state == .idle)
        #expect(service.currentSession == nil)
        #expect(service.remainingTime == 0)
        #expect(service.progress == 0)
    }

    @Test func cannotPauseWhenIdle() async {
        let service = TimerService()
        service.pause() // Should do nothing

        #expect(service.state == .idle)
    }

    @Test func cannotResumeWhenNotPaused() async {
        let service = TimerService()
        service.startSession(duration: 25 * 60)
        service.resume() // Should do nothing since already running

        #expect(service.state == .running)
    }
}

// MARK: - TimerViewModel Tests

@MainActor
struct TimerViewModelTests {
    @Test func viewModelInitialState() async {
        let viewModel = TimerViewModel()

        #expect(viewModel.selectedPreset == .pomodoro25)
        #expect(viewModel.sessionType == .work)
        #expect(viewModel.canStart == true)
        #expect(viewModel.canPause == false)
        #expect(viewModel.isSessionActive == false)
    }

    @Test func primaryButtonTitleIdle() async {
        let viewModel = TimerViewModel()
        #expect(viewModel.primaryButtonTitle == "Start Focus")
    }

    @Test func primaryButtonTitleRunning() async {
        let viewModel = TimerViewModel()
        viewModel.primaryButtonTapped() // Start

        #expect(viewModel.primaryButtonTitle == "Pause")
    }

    @Test func primaryButtonTitlePaused() async {
        let viewModel = TimerViewModel()
        viewModel.primaryButtonTapped() // Start
        viewModel.primaryButtonTapped() // Pause

        #expect(viewModel.primaryButtonTitle == "Resume")
    }

    @Test func selectedDurationForWork() async {
        let viewModel = TimerViewModel()
        viewModel.selectedPreset = .pomodoro50
        viewModel.sessionType = .work

        #expect(viewModel.selectedDuration == 50 * 60)
    }

    @Test func selectedDurationForBreak() async {
        let viewModel = TimerViewModel()
        viewModel.selectedPreset = .pomodoro50
        viewModel.sessionType = .rest

        #expect(viewModel.selectedDuration == 10 * 60)
    }

    @Test func showStopButtonWhenActive() async {
        let viewModel = TimerViewModel()
        #expect(viewModel.showStopButton == false)

        viewModel.primaryButtonTapped() // Start
        #expect(viewModel.showStopButton == true)
    }

    @Test func stopSessionResetsState() async {
        let viewModel = TimerViewModel()
        viewModel.primaryButtonTapped() // Start
        viewModel.stopSession()

        #expect(viewModel.timerService.state == .idle)
        #expect(viewModel.showStopButton == false)
    }
}
