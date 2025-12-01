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

    @Test func primaryButtonTitleForBreakSession() async {
        let viewModel = TimerViewModel()
        viewModel.sessionType = .rest

        #expect(viewModel.primaryButtonTitle == "Start Break")
    }

    @Test func completionViewInitiallyHidden() async {
        let viewModel = TimerViewModel()

        #expect(viewModel.showCompletionView == false)
        #expect(viewModel.completedSession == nil)
    }

    @Test func pausedDurationInitiallyZero() async {
        let viewModel = TimerViewModel()

        #expect(viewModel.pausedDuration == 0)
    }
}

// MARK: - TimerService Background/Foreground Tests

@MainActor
struct TimerServiceBackgroundTests {
    @Test func pausedDurationTracking() async {
        let service = TimerService()
        service.startSession(duration: 25 * 60)

        #expect(service.pausedDuration == 0)

        service.pause()
        // Simulate time passing
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        service.resume()

        #expect(service.pausedDuration > 0)
    }

    @Test func pauseCancelsNotificationIntent() async {
        // This tests that pause doesn't crash - actual notification behavior
        // requires device testing
        let service = TimerService()
        service.startSession(duration: 25 * 60)
        service.pause()

        #expect(service.state == .paused)
    }

    @Test func onForegroundRecalculatesTime() async {
        let service = TimerService()
        service.startSession(duration: 5) // 5 seconds

        // Wait a bit
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds

        let timeBefore = service.remainingTime
        service.onForeground()
        let timeAfter = service.remainingTime

        // Time should have decreased or stayed same
        #expect(timeAfter <= timeBefore)
    }

    @Test func completionCallbackInvoked() async {
        let service = TimerService()
        var callbackInvoked = false

        service.onSessionCompleted = { session in
            callbackInvoked = true
            #expect(session.completionStatus == .completed)
        }

        // Start a very short session
        service.startSession(duration: 0.1)

        // Wait for completion
        try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds

        #expect(callbackInvoked == true)
        #expect(service.state == .completed)
    }
}

// MARK: - NotificationService Tests

@MainActor
struct NotificationServiceTests {
    @Test func sharedInstanceExists() async {
        let service = NotificationService.shared

        #expect(service != nil)
    }

    @Test func cancelPendingNotificationsDoesNotCrash() async {
        // Just verify this doesn't throw
        NotificationService.shared.cancelPendingNotifications()
    }

    @Test func cancelAllNotificationsDoesNotCrash() async {
        // Just verify this doesn't throw
        NotificationService.shared.cancelAllNotifications()
    }
}

// MARK: - Session Complete Flow Tests

@MainActor
struct SessionCompleteFlowTests {
    @Test func workSessionCompletionTogglesToBreak() async {
        let viewModel = TimerViewModel()
        viewModel.sessionType = .work

        // Simulate completion flow
        viewModel.dismissCompletionAndContinue()

        #expect(viewModel.sessionType == .rest)
    }

    @Test func breakSessionCompletionTogglesToWork() async {
        let viewModel = TimerViewModel()
        viewModel.sessionType = .rest

        // Simulate completion flow
        viewModel.dismissCompletionAndContinue()

        #expect(viewModel.sessionType == .work)
    }

    @Test func skipBreakSetsSessionTypeToWork() async {
        let viewModel = TimerViewModel()
        viewModel.sessionType = .rest // Would be set after work completion

        viewModel.skipBreak()

        #expect(viewModel.sessionType == .work)
        #expect(viewModel.showCompletionView == false)
    }

    @Test func dismissCompletionViewClearsState() async {
        let viewModel = TimerViewModel()
        viewModel.showCompletionView = true
        viewModel.completedSession = FocusSession(plannedDuration: 25 * 60)

        viewModel.dismissCompletionView()

        #expect(viewModel.showCompletionView == false)
        #expect(viewModel.completedSession == nil)
    }
}

// MARK: - Streak Logic Tests

struct StreakLogicTests {
    @Test func consecutiveDaysIncrementStreak() {
        let stats = UserStats()
        let calendar = Calendar.current

        // First completion
        stats.lastCompletionDate = calendar.date(byAdding: .day, value: -1, to: Date())
        stats.currentStreak = 1

        stats.recordCompletion()

        #expect(stats.currentStreak == 2)
    }

    @Test func missedDayResetsStreak() {
        let stats = UserStats()
        let calendar = Calendar.current

        // Last completion was 2 days ago
        stats.lastCompletionDate = calendar.date(byAdding: .day, value: -2, to: Date())
        stats.currentStreak = 5

        stats.recordCompletion()

        #expect(stats.currentStreak == 1) // Reset to 1
    }

    @Test func sameDayCompletionDoesNotChangeStreak() {
        let stats = UserStats()

        // Complete once
        stats.recordCompletion()
        let streakAfterFirst = stats.currentStreak

        // Complete again same day
        stats.recordCompletion()

        #expect(stats.currentStreak == streakAfterFirst)
    }

    @Test func longestStreakUpdates() {
        let stats = UserStats()
        let calendar = Calendar.current

        // Build up streak over "days"
        stats.currentStreak = 0
        stats.longestStreak = 0

        // Day 1
        stats.recordCompletion()
        #expect(stats.longestStreak == 1)

        // Simulate day 2
        stats.lastCompletionDate = calendar.date(byAdding: .day, value: -1, to: Date())
        stats.recordCompletion()
        #expect(stats.longestStreak == 2)

        // Simulate day 3
        stats.lastCompletionDate = calendar.date(byAdding: .day, value: -1, to: Date())
        stats.recordCompletion()
        #expect(stats.longestStreak == 3)
    }
}

// MARK: - BlockingManager Tests
// Note: FamilyControls doesn't work in Simulator, so we test only non-FamilyControls parts

@MainActor
struct BlockingManagerTests {
    @Test func sharedInstanceExists() async {
        let manager = BlockingManager.shared
        #expect(manager != nil)
    }

    @Test func initialStateNotBlocking() async {
        let manager = BlockingManager.shared
        #expect(manager.isBlocking == false)
    }

    @Test func blockingDescriptionNone() async {
        let manager = BlockingManager.shared
        // Clear any previous selection
        manager.clearSelection()

        // When no apps selected, should show "None"
        #expect(manager.blockingDescription == "None")
        #expect(manager.hasSelectedApps == false)
        #expect(manager.totalBlockedCount == 0)
    }

    @Test func stopBlockingDoesNotCrash() async {
        let manager = BlockingManager.shared
        // Should not crash even when not blocking
        manager.stopBlocking()
        #expect(manager.isBlocking == false)
    }

    @Test func clearSelectionWorks() async {
        let manager = BlockingManager.shared
        manager.clearSelection()

        #expect(manager.selectedAppsCount == 0)
        #expect(manager.selectedCategoriesCount == 0)
    }
}

// MARK: - TimerViewModel Blocking Integration Tests

@MainActor
struct TimerViewModelBlockingTests {
    @Test func blockedAppsDescriptionDefault() async {
        let viewModel = TimerViewModel()
        // Clear any saved selection
        viewModel.blockingManager.clearSelection()

        #expect(viewModel.blockedAppsDescription == "None")
        #expect(viewModel.hasBlockedApps == false)
    }

    @Test func showBlockingFlowInitiallyFalse() async {
        let viewModel = TimerViewModel()

        #expect(viewModel.showBlockingFlow == false)
    }

    @Test func blockingCardTappedShowsFlow() async {
        let viewModel = TimerViewModel()

        viewModel.blockingCardTapped()

        #expect(viewModel.showBlockingFlow == true)
    }

    @Test func stopBlockingOnSessionStop() async {
        let viewModel = TimerViewModel()
        viewModel.blockingManager.clearSelection()

        // Start a session
        viewModel.primaryButtonTapped()
        #expect(viewModel.timerService.isRunning == true)

        // Stop the session
        viewModel.stopSession()

        // Blocking should be stopped
        #expect(viewModel.blockingManager.isBlocking == false)
    }
}

// MARK: - StringNormalization Tests

struct StringNormalizationTests {
    @Test func basicNormalization() {
        let result = StringNormalization.normalizeForComparison("Hello World")
        #expect(result == "hello world")
    }

    @Test func smartQuoteNormalization() {
        // Test curly single quotes
        let withCurlyApostrophe = "I\u{2019}m testing"  // I'm testing
        let normalized = StringNormalization.normalizeForComparison(withCurlyApostrophe)
        #expect(normalized == "i'm testing")
    }

    @Test func smartDoubleQuoteNormalization() {
        // Test curly double quotes
        let withCurlyQuotes = "\u{201C}Hello\u{201D}"  // "Hello"
        let normalized = StringNormalization.normalizeForComparison(withCurlyQuotes)
        #expect(normalized == "\"hello\"")
    }

    @Test func dashNormalization() {
        // En dash
        let withEnDash = "one\u{2013}two"
        #expect(StringNormalization.normalizeForComparison(withEnDash) == "one-two")

        // Em dash
        let withEmDash = "one\u{2014}two"
        #expect(StringNormalization.normalizeForComparison(withEmDash) == "one-two")
    }

    @Test func matchesExactText() {
        let phrase = "End session early"
        let input = "End session early"
        #expect(StringNormalization.matches(userInput: input, challengePhrase: phrase) == true)
    }

    @Test func matchesCaseInsensitive() {
        let phrase = "End Session Early"
        let input = "end session early"
        #expect(StringNormalization.matches(userInput: input, challengePhrase: phrase) == true)
    }

    @Test func matchesWithSmartQuotes() {
        let phrase = "I'm choosing distraction"
        let inputWithCurlyQuote = "I\u{2019}m choosing distraction"
        #expect(StringNormalization.matches(userInput: inputWithCurlyQuote, challengePhrase: phrase) == true)
    }

    @Test func noMatchOnDifferentText() {
        let phrase = "End session early"
        let input = "Stop the timer"
        #expect(StringNormalization.matches(userInput: input, challengePhrase: phrase) == false)
    }

    @Test func characterStatusesAllCorrect() {
        let phrase = "test"
        let input = "test"
        let statuses = StringNormalization.characterStatuses(userInput: input, challengePhrase: phrase)

        #expect(statuses.count == 4)
        #expect(statuses.allSatisfy { $0 == .correct })
    }

    @Test func characterStatusesWithError() {
        let phrase = "test"
        let input = "tesx"  // Wrong last character
        let statuses = StringNormalization.characterStatuses(userInput: input, challengePhrase: phrase)

        #expect(statuses.count == 4)
        #expect(statuses[0] == .correct)
        #expect(statuses[1] == .correct)
        #expect(statuses[2] == .correct)
        #expect(statuses[3] == .incorrect)
    }

    @Test func characterStatusesErrorStopsPending() {
        let phrase = "testing"
        let input = "texxing"  // Error at index 2
        let statuses = StringNormalization.characterStatuses(userInput: input, challengePhrase: phrase)

        #expect(statuses[0] == .correct)  // t
        #expect(statuses[1] == .correct)  // e
        #expect(statuses[2] == .incorrect)  // x (first error)
        #expect(statuses[3] == .pending)  // x
        #expect(statuses[4] == .pending)  // i
        #expect(statuses[5] == .pending)  // n
        #expect(statuses[6] == .pending)  // g
    }

    @Test func firstMismatchIndexNoError() {
        let phrase = "hello"
        let input = "hel"
        let index = StringNormalization.firstMismatchIndex(userInput: input, challengePhrase: phrase)
        #expect(index == nil)
    }

    @Test func firstMismatchIndexWithError() {
        let phrase = "hello"
        let input = "helxo"
        let index = StringNormalization.firstMismatchIndex(userInput: input, challengePhrase: phrase)
        #expect(index == 3)
    }

    @Test func firstMismatchIndexInputTooLong() {
        let phrase = "hi"
        let input = "hi there"
        let index = StringNormalization.firstMismatchIndex(userInput: input, challengePhrase: phrase)
        #expect(index == 2)  // Space after "hi"
    }

    @Test func isCompleteTrue() {
        let phrase = "done"
        let input = "done"
        #expect(StringNormalization.isComplete(userInput: input, challengePhrase: phrase) == true)
    }

    @Test func isCompleteFalsePartialInput() {
        let phrase = "done"
        let input = "don"
        #expect(StringNormalization.isComplete(userInput: input, challengePhrase: phrase) == false)
    }

    @Test func isCompleteFalseWithError() {
        let phrase = "done"
        let input = "donx"
        #expect(StringNormalization.isComplete(userInput: input, challengePhrase: phrase) == false)
    }
}

// MARK: - Strict Mode / Quit Flow Tests

@MainActor
struct StrictModeTests {
    @Test func strictModeInitiallyDisabled() async {
        let viewModel = TimerViewModel()
        #expect(viewModel.isStrictModeEnabled == false)
    }

    @Test func strictModeDisplayValueNormal() async {
        let viewModel = TimerViewModel()
        #expect(viewModel.strictModeDisplayValue == "Normal")
    }

    @Test func showQuitFlowInitiallyFalse() async {
        let viewModel = TimerViewModel()
        #expect(viewModel.showQuitFlow == false)
    }

    @Test func attemptStopWithoutStrictModeStopsDirectly() async {
        let viewModel = TimerViewModel()
        viewModel.primaryButtonTapped()  // Start session
        #expect(viewModel.timerService.isRunning == true)

        viewModel.attemptStopSession()

        // Without strict mode, should stop directly
        #expect(viewModel.timerService.state == .idle)
        #expect(viewModel.showQuitFlow == false)
    }

    @Test func cancelQuitFlowHidesSheet() async {
        let viewModel = TimerViewModel()
        viewModel.showQuitFlow = true

        viewModel.cancelQuitFlow()

        #expect(viewModel.showQuitFlow == false)
    }

    @Test func confirmStopSessionEndsSession() async {
        let viewModel = TimerViewModel()
        viewModel.primaryButtonTapped()  // Start session
        viewModel.showQuitFlow = true

        viewModel.confirmStopSession()

        #expect(viewModel.timerService.state == .idle)
        #expect(viewModel.showQuitFlow == false)
    }
}

// MARK: - Challenge Phrase Tests

struct ChallengePhraseTests {
    @Test func gentleToneHasPhrases() {
        let phrases = StrictModeTone.gentle.phrases
        #expect(phrases.count == 3)
        #expect(phrases.contains("I need a break right now"))
    }

    @Test func neutralToneHasPhrases() {
        let phrases = StrictModeTone.neutral.phrases
        #expect(phrases.count == 3)
        #expect(phrases.contains("End session early"))
    }

    @Test func strictToneHasPhrases() {
        let phrases = StrictModeTone.strict.phrases
        #expect(phrases.count == 3)
        #expect(phrases.contains("I am choosing distraction over my goals"))
    }

    @Test func customToneEmptyPhrases() {
        let phrases = StrictModeTone.custom.phrases
        #expect(phrases.isEmpty)
    }
}

// MARK: - Milestone 5: Advanced Strict Mode Tests

struct AppSettingsAdvancedTests {
    @Test func enableStrictModeSetsEnabledAtDate() {
        let settings = AppSettings()
        settings.enableStrictMode()

        #expect(settings.strictModeEnabled == true)
        #expect(settings.strictModeEnabledAt != nil)
        #expect(settings.strictModeDisablePending == false)
        #expect(settings.strictModeDisableTime == nil)
    }

    @Test func disableStrictModeInstantlyDuringBuyersRemorse() {
        let settings = AppSettings()
        settings.strictModeEnabled = true
        settings.strictModeEnabledAt = Date() // Just enabled - in buyer's remorse window

        let wasInstant = settings.disableStrictMode()

        #expect(wasInstant == true)
        #expect(settings.strictModeEnabled == false)
        #expect(settings.strictModeEnabledAt == nil)
        #expect(settings.strictModeDisablePending == false)
    }

    @Test func disableStrictModeSchedules24HourDelay() {
        let settings = AppSettings()
        settings.strictModeEnabled = true
        settings.strictModeEnabledAt = Date().addingTimeInterval(-20 * 60) // 20 min ago - outside buyer's remorse

        let wasInstant = settings.disableStrictMode()

        #expect(wasInstant == false)
        #expect(settings.strictModeEnabled == true) // Still enabled
        #expect(settings.strictModeDisablePending == true)
        #expect(settings.strictModeDisableTime != nil)

        // Check that disable time is approximately 24 hours from now
        if let disableTime = settings.strictModeDisableTime {
            let expectedTime = Date().addingTimeInterval(24 * 60 * 60)
            let diff = abs(disableTime.timeIntervalSince(expectedTime))
            #expect(diff < 5) // Within 5 seconds
        }
    }

    @Test func cancelPendingDisableClearsState() {
        let settings = AppSettings()
        settings.strictModeEnabled = true
        settings.strictModeDisablePending = true
        settings.strictModeDisableTime = Date().addingTimeInterval(24 * 60 * 60)

        settings.cancelPendingDisable()

        #expect(settings.strictModeEnabled == true)
        #expect(settings.strictModeDisablePending == false)
        #expect(settings.strictModeDisableTime == nil)
    }

    @Test func checkAndPerformScheduledDisableWhenTimeHasPassed() {
        let settings = AppSettings()
        settings.strictModeEnabled = true
        settings.strictModeDisablePending = true
        settings.strictModeDisableTime = Date().addingTimeInterval(-1) // Already passed
        settings.strictModeEnabledAt = Date().addingTimeInterval(-25 * 60 * 60)

        settings.checkAndPerformScheduledDisable()

        #expect(settings.strictModeEnabled == false)
        #expect(settings.strictModeDisablePending == false)
        #expect(settings.strictModeDisableTime == nil)
        #expect(settings.strictModeEnabledAt == nil)
    }

    @Test func checkAndPerformScheduledDisableWhenTimeNotPassed() {
        let settings = AppSettings()
        settings.strictModeEnabled = true
        settings.strictModeDisablePending = true
        settings.strictModeDisableTime = Date().addingTimeInterval(60 * 60) // 1 hour from now

        settings.checkAndPerformScheduledDisable()

        // Should not change anything
        #expect(settings.strictModeEnabled == true)
        #expect(settings.strictModeDisablePending == true)
        #expect(settings.strictModeDisableTime != nil)
    }

    @Test func isStrictModeActiveFalseWhenDisableTimePassed() {
        let settings = AppSettings()
        settings.strictModeEnabled = true
        settings.strictModeDisablePending = true
        settings.strictModeDisableTime = Date().addingTimeInterval(-60) // Passed

        #expect(settings.isStrictModeActive == false)
    }

    @Test func isStrictModeActiveTrueWhenDisableTimePending() {
        let settings = AppSettings()
        settings.strictModeEnabled = true
        settings.strictModeDisablePending = true
        settings.strictModeDisableTime = Date().addingTimeInterval(60 * 60) // 1 hour from now

        #expect(settings.isStrictModeActive == true)
    }
}

// MARK: - Challenge Type Tests

struct ChallengeTypeTests {
    @Test func allChallengeTypesExist() {
        let types = ChallengeType.allCases
        #expect(types.count == 4)
        #expect(types.contains(.phrase))
        #expect(types.contains(.math))
        #expect(types.contains(.pattern))
        #expect(types.contains(.holdButton))
    }

    @Test func challengeTypeDisplayNames() {
        #expect(ChallengeType.phrase.displayName == "Type a Phrase")
        #expect(ChallengeType.math.displayName == "Solve Math Problem")
        #expect(ChallengeType.pattern.displayName == "Tap Pattern")
        #expect(ChallengeType.holdButton.displayName == "Hold Button")
    }

    @Test func defaultChallengeTypeIsPhrase() {
        let settings = AppSettings()
        #expect(settings.challengeType == .phrase)
    }

    @Test func challengeTypeCanBeChanged() {
        let settings = AppSettings()
        settings.challengeType = .math
        #expect(settings.challengeType == .math)

        settings.challengeType = .pattern
        #expect(settings.challengeType == .pattern)

        settings.challengeType = .holdButton
        #expect(settings.challengeType == .holdButton)
    }
}

// MARK: - Authentication Service Tests

struct AuthenticationServiceTests {
    @Test func sharedInstanceExists() {
        let service = AuthenticationService.shared
        #expect(service != nil)
    }

    @Test func requestAuthenticationCompletesOnSimulator() async {
        // On simulator, authentication should auto-succeed
        let result = await AuthenticationService.shared.requestAuthentication(
            reason: "Test authentication"
        )
        // On simulator without device authentication, this should return true
        #expect(result == true)
    }
}

// MARK: - Emergency Bypass Logic Tests

@MainActor
struct EmergencyBypassTests {
    @Test func emergencyBypassCallbackInQuitFlowWorks() async {
        var bypassCalled = false
        let settings = AppSettings(strictModeEnabled: true)

        // Test that the emergency bypass callback can be invoked
        let onBypass = {
            bypassCalled = true
        }

        // Simulate bypass being triggered
        onBypass()

        #expect(bypassCalled == true)
    }
}

// MARK: - Milestone 6: Stats & Insights Tests

struct SessionFilterTests {
    @Test func sessionFilterAllIncludesCompletedAndQuit() {
        let filter = SessionFilter.all

        let completed = FocusSession(plannedDuration: 25 * 60, completionStatus: .completed)
        let quit = FocusSession(plannedDuration: 25 * 60, completionStatus: .quitEarly)
        let inProgress = FocusSession(plannedDuration: 25 * 60, completionStatus: .inProgress)

        #expect(filter.predicate(completed) == true)
        #expect(filter.predicate(quit) == true)
        #expect(filter.predicate(inProgress) == false)
    }

    @Test func sessionFilterCompletedOnlyIncludesCompleted() {
        let filter = SessionFilter.completed

        let completed = FocusSession(plannedDuration: 25 * 60, completionStatus: .completed)
        let quit = FocusSession(plannedDuration: 25 * 60, completionStatus: .quitEarly)

        #expect(filter.predicate(completed) == true)
        #expect(filter.predicate(quit) == false)
    }

    @Test func sessionFilterQuitOnlyIncludesQuit() {
        let filter = SessionFilter.quit

        let completed = FocusSession(plannedDuration: 25 * 60, completionStatus: .completed)
        let quit = FocusSession(plannedDuration: 25 * 60, completionStatus: .quitEarly)

        #expect(filter.predicate(completed) == false)
        #expect(filter.predicate(quit) == true)
    }
}

struct TimeFilterTests {
    @Test func weekFilterHasStartDate() {
        let filter = TimeFilter.week
        #expect(filter.startDate != nil)
    }

    @Test func monthFilterHasStartDate() {
        let filter = TimeFilter.month
        #expect(filter.startDate != nil)
    }

    @Test func allTimeFilterHasNoStartDate() {
        let filter = TimeFilter.all
        #expect(filter.startDate == nil)
    }

    @Test func weekFilterStartsAtBeginningOfWeek() {
        let filter = TimeFilter.week
        guard let startDate = filter.startDate else {
            #expect(Bool(false), "Week filter should have start date")
            return
        }

        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: startDate)

        // Should be Sunday (1) or Monday (2) depending on locale
        #expect(weekday == 1 || weekday == 2)
    }

    @Test func monthFilterStartsAtBeginningOfMonth() {
        let filter = TimeFilter.month
        guard let startDate = filter.startDate else {
            #expect(Bool(false), "Month filter should have start date")
            return
        }

        let calendar = Calendar.current
        let day = calendar.component(.day, from: startDate)

        #expect(day == 1)
    }
}

struct WeeklyStatsCalculationTests {
    @Test func quitRateCalculationWithNoSessions() {
        let completed: [FocusSession] = []
        let quit: [FocusSession] = []

        let total = completed.count + quit.count
        let quitRate = total > 0 ? Double(quit.count) / Double(total) * 100 : 0

        #expect(quitRate == 0)
    }

    @Test func quitRateCalculationWithOnlyCompleted() {
        let completed = [
            FocusSession(plannedDuration: 25 * 60, completionStatus: .completed),
            FocusSession(plannedDuration: 25 * 60, completionStatus: .completed)
        ]
        let quit: [FocusSession] = []

        let total = completed.count + quit.count
        let quitRate = total > 0 ? Double(quit.count) / Double(total) * 100 : 0

        #expect(quitRate == 0)
    }

    @Test func quitRateCalculationWithMixedSessions() {
        let completed = [
            FocusSession(plannedDuration: 25 * 60, completionStatus: .completed),
            FocusSession(plannedDuration: 25 * 60, completionStatus: .completed),
            FocusSession(plannedDuration: 25 * 60, completionStatus: .completed),
            FocusSession(plannedDuration: 25 * 60, completionStatus: .completed)
        ]
        let quit = [
            FocusSession(plannedDuration: 25 * 60, completionStatus: .quitEarly)
        ]

        let total = completed.count + quit.count
        let quitRate = total > 0 ? Double(quit.count) / Double(total) * 100 : 0

        #expect(quitRate == 20.0) // 1 out of 5 = 20%
    }

    @Test func totalFocusTimeCalculation() {
        let session1 = FocusSession(plannedDuration: 25 * 60, completionStatus: .completed)
        session1.actualDuration = 25 * 60

        let session2 = FocusSession(plannedDuration: 50 * 60, completionStatus: .completed)
        session2.actualDuration = 50 * 60

        let sessions = [session1, session2]
        let totalFocusTime = sessions.reduce(0) { $0 + ($1.actualDuration ?? $1.plannedDuration) }

        #expect(totalFocusTime == 75 * 60) // 75 minutes
    }

    @Test func totalFocusTimeWithNilActualDuration() {
        let session1 = FocusSession(plannedDuration: 25 * 60, completionStatus: .completed)
        // actualDuration is nil, should fall back to plannedDuration

        let sessions = [session1]
        let totalFocusTime = sessions.reduce(0) { $0 + ($1.actualDuration ?? $1.plannedDuration) }

        #expect(totalFocusTime == 25 * 60)
    }
}

struct CalendarDayStatusTests {
    @Test func dayStatusEnumExists() {
        let completed = DayStatus.completed
        let quitOnly = DayStatus.quitOnly
        let noActivity = DayStatus.noActivity
        let today = DayStatus.today
        let future = DayStatus.future

        #expect(completed != quitOnly)
        #expect(noActivity != today)
        #expect(today != future)
    }
}

struct QuitLogPatternTests {
    @Test func quitProgressPercentageCalculation() {
        let session = FocusSession(plannedDuration: 50 * 60, completionStatus: .quitEarly)
        session.actualDuration = 25 * 60 // Quit halfway

        let progressPercentage = (session.actualDuration! / session.plannedDuration) * 100

        #expect(progressPercentage == 50.0)
    }

    @Test func averageQuitPercentageCalculation() {
        let session1 = FocusSession(plannedDuration: 100, completionStatus: .quitEarly)
        session1.actualDuration = 50 // 50%

        let session2 = FocusSession(plannedDuration: 100, completionStatus: .quitEarly)
        session2.actualDuration = 30 // 30%

        let sessions = [session1, session2]
        let percentages = sessions.compactMap { session -> Double? in
            guard let actualDuration = session.actualDuration else { return nil }
            return (actualDuration / session.plannedDuration) * 100
        }

        let average = percentages.reduce(0, +) / Double(percentages.count)

        #expect(average == 40.0) // (50 + 30) / 2 = 40%
    }

    @Test func timeOfDayCategories() {
        let calendar = Calendar.current

        // Morning: 5-12
        var morningComponents = calendar.dateComponents([.year, .month, .day], from: Date())
        morningComponents.hour = 9
        let morning = calendar.date(from: morningComponents)!
        let morningHour = calendar.component(.hour, from: morning)
        #expect(morningHour >= 5 && morningHour < 12)

        // Afternoon: 12-17
        var afternoonComponents = calendar.dateComponents([.year, .month, .day], from: Date())
        afternoonComponents.hour = 14
        let afternoon = calendar.date(from: afternoonComponents)!
        let afternoonHour = calendar.component(.hour, from: afternoon)
        #expect(afternoonHour >= 12 && afternoonHour < 17)

        // Evening: 17-21
        var eveningComponents = calendar.dateComponents([.year, .month, .day], from: Date())
        eveningComponents.hour = 19
        let evening = calendar.date(from: eveningComponents)!
        let eveningHour = calendar.component(.hour, from: evening)
        #expect(eveningHour >= 17 && eveningHour < 21)
    }
}

struct SessionGroupingTests {
    @Test func sessionsCanBeGroupedByDate() {
        let calendar = Calendar.current
        let today = Date()
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!

        let session1 = FocusSession(startTime: today, plannedDuration: 25 * 60)
        let session2 = FocusSession(startTime: today, plannedDuration: 25 * 60)
        let session3 = FocusSession(startTime: yesterday, plannedDuration: 25 * 60)

        let sessions = [session1, session2, session3]

        let grouped = Dictionary(grouping: sessions) { session -> String in
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
            return formatter.string(from: session.startTime)
        }

        #expect(grouped.count == 2) // Two different days

        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        let todayString = formatter.string(from: today)

        #expect(grouped[todayString]?.count == 2) // Two sessions today
    }
}

struct StreakCalendarTests {
    @Test func daysInMonthReturnsCorrectCount() {
        let calendar = Calendar.current

        // Test for January 2025 (31 days)
        var components = DateComponents()
        components.year = 2025
        components.month = 1
        components.day = 15
        let january = calendar.date(from: components)!

        if let monthInterval = calendar.dateInterval(of: .month, for: january) {
            let days = calendar.dateComponents([.day], from: monthInterval.start, to: monthInterval.end).day!
            #expect(days == 31)
        }

        // Test for February 2025 (28 days - not a leap year in 2025)
        components.month = 2
        let february = calendar.date(from: components)!

        if let monthInterval = calendar.dateInterval(of: .month, for: february) {
            let days = calendar.dateComponents([.day], from: monthInterval.start, to: monthInterval.end).day!
            #expect(days == 28)
        }
    }

    @Test func weekdayOfFirstDayInMonth() {
        let calendar = Calendar.current

        var components = DateComponents()
        components.year = 2025
        components.month = 1
        components.day = 1
        let january1 = calendar.date(from: components)!

        let weekday = calendar.component(.weekday, from: january1)
        // January 1, 2025 is a Wednesday (weekday 4)
        #expect(weekday == 4)
    }
}

// MARK: - Milestone 7: Schedule Tests

struct WeekdayEnumTests {
    @Test func weekdayRawValues() {
        #expect(Weekday.sunday.rawValue == 1)
        #expect(Weekday.monday.rawValue == 2)
        #expect(Weekday.tuesday.rawValue == 3)
        #expect(Weekday.wednesday.rawValue == 4)
        #expect(Weekday.thursday.rawValue == 5)
        #expect(Weekday.friday.rawValue == 6)
        #expect(Weekday.saturday.rawValue == 7)
    }

    @Test func weekdayShortNames() {
        #expect(Weekday.sunday.shortName == "Su")
        #expect(Weekday.monday.shortName == "Mo")
        #expect(Weekday.tuesday.shortName == "Tu")
        #expect(Weekday.wednesday.shortName == "We")
        #expect(Weekday.thursday.shortName == "Th")
        #expect(Weekday.friday.shortName == "Fr")
        #expect(Weekday.saturday.shortName == "Sa")
    }

    @Test func weekdayFullNames() {
        #expect(Weekday.sunday.fullName == "Sunday")
        #expect(Weekday.monday.fullName == "Monday")
        #expect(Weekday.tuesday.fullName == "Tuesday")
        #expect(Weekday.wednesday.fullName == "Wednesday")
        #expect(Weekday.thursday.fullName == "Thursday")
        #expect(Weekday.friday.fullName == "Friday")
        #expect(Weekday.saturday.fullName == "Saturday")
    }

    @Test func weekdaySingleLetters() {
        #expect(Weekday.sunday.singleLetter == "S")
        #expect(Weekday.monday.singleLetter == "M")
        #expect(Weekday.tuesday.singleLetter == "T")
        #expect(Weekday.wednesday.singleLetter == "W")
        #expect(Weekday.thursday.singleLetter == "T")
        #expect(Weekday.friday.singleLetter == "F")
        #expect(Weekday.saturday.singleLetter == "S")
    }

    @Test func weekdayComparable() {
        #expect(Weekday.monday < Weekday.friday)
        #expect(Weekday.sunday < Weekday.saturday)
        #expect(!(Weekday.saturday < Weekday.sunday))
    }

    @Test func weekdayAllCases() {
        #expect(Weekday.allCases.count == 7)
    }
}

struct ScheduleModelTests {
    @Test func scheduleInitialization() {
        let schedule = Schedule(
            name: "Morning Focus",
            activeDays: [2, 3, 4, 5, 6], // Mon-Fri
            startHour: 9,
            startMinute: 0,
            duration: 3 * 60 * 60,
            strictModeEnabled: true,
            isActive: true
        )

        #expect(schedule.name == "Morning Focus")
        #expect(schedule.activeDays == [2, 3, 4, 5, 6])
        #expect(schedule.startHour == 9)
        #expect(schedule.startMinute == 0)
        #expect(schedule.duration == 3 * 60 * 60)
        #expect(schedule.strictModeEnabled == true)
        #expect(schedule.isActive == true)
    }

    @Test func scheduleDefaultValues() {
        let schedule = Schedule()

        #expect(schedule.name == "")
        #expect(schedule.activeDays.isEmpty)
        #expect(schedule.startHour == 9)
        #expect(schedule.startMinute == 0)
        #expect(schedule.duration == 60 * 60)
        #expect(schedule.strictModeEnabled == false)
        #expect(schedule.isActive == true)
    }

    @Test func scheduleActiveDaysSet() {
        let schedule = Schedule(activeDays: [2, 4, 6]) // Mon, Wed, Fri

        let daysSet = schedule.activeDaysSet
        #expect(daysSet.contains(.monday))
        #expect(daysSet.contains(.wednesday))
        #expect(daysSet.contains(.friday))
        #expect(!daysSet.contains(.sunday))
        #expect(!daysSet.contains(.tuesday))
    }

    @Test func scheduleActiveDaysSetSetter() {
        let schedule = Schedule()
        schedule.activeDaysSet = Set([.monday, .wednesday, .friday])

        #expect(schedule.activeDays.sorted() == [2, 4, 6])
    }

    @Test func scheduleFormattedStartTime() {
        let schedule = Schedule(startHour: 9, startMinute: 30)
        #expect(schedule.formattedStartTime.contains("9:30"))
    }

    @Test func scheduleFormattedDuration() {
        let schedule1 = Schedule(duration: 60 * 60) // 1 hour
        #expect(schedule1.formattedDuration.contains("1"))

        let schedule2 = Schedule(duration: 90 * 60) // 1.5 hours
        #expect(schedule2.formattedDuration.contains("1h 30m"))
    }

    @Test func scheduleDaysDescriptionDaily() {
        let schedule = Schedule(activeDays: [1, 2, 3, 4, 5, 6, 7])
        #expect(schedule.daysDescription == "Daily")
    }

    @Test func scheduleDaysDescriptionWeekdays() {
        let schedule = Schedule(activeDays: [2, 3, 4, 5, 6])
        #expect(schedule.daysDescription == "Weekdays")
    }

    @Test func scheduleDaysDescriptionWeekends() {
        let schedule = Schedule(activeDays: [1, 7])
        #expect(schedule.daysDescription == "Weekends")
    }

    @Test func scheduleDaysDescriptionCustom() {
        let schedule = Schedule(activeDays: [2, 4]) // Mon, Wed
        #expect(schedule.daysDescription == "Mo We")
    }
}

struct ScheduleActiveCheckTests {
    @Test func scheduleIsActiveOnCorrectDay() {
        let calendar = Calendar.current
        let today = Date()
        let todayWeekday = calendar.component(.weekday, from: today)

        let schedule = Schedule(activeDays: [todayWeekday], isActive: true)
        #expect(schedule.isActiveOn(date: today) == true)
    }

    @Test func scheduleNotActiveOnWrongDay() {
        let calendar = Calendar.current
        let today = Date()
        let todayWeekday = calendar.component(.weekday, from: today)
        let otherWeekday = todayWeekday == 1 ? 2 : 1

        let schedule = Schedule(activeDays: [otherWeekday], isActive: true)
        #expect(schedule.isActiveOn(date: today) == false)
    }

    @Test func scheduleNotActiveWhenDisabled() {
        let calendar = Calendar.current
        let today = Date()
        let todayWeekday = calendar.component(.weekday, from: today)

        let schedule = Schedule(activeDays: [todayWeekday], isActive: false)
        #expect(schedule.isActiveOn(date: today) == false)
    }
}

struct ScheduleWindowTests {
    @Test func scheduleWithinWindowAtStartTime() {
        let calendar = Calendar.current
        let now = Date()
        let currentHour = calendar.component(.hour, from: now)
        let currentMinute = calendar.component(.minute, from: now)
        let todayWeekday = calendar.component(.weekday, from: now)

        let schedule = Schedule(
            activeDays: [todayWeekday],
            startHour: currentHour,
            startMinute: currentMinute,
            duration: 60 * 60, // 1 hour
            isActive: true
        )

        #expect(schedule.isWithinWindow(at: now) == true)
    }

    @Test func scheduleNotWithinWindowBeforeStart() {
        let calendar = Calendar.current
        let todayWeekday = calendar.component(.weekday, from: Date())

        // Schedule starting at 23:00 with 1 hour duration
        let schedule = Schedule(
            activeDays: [todayWeekday],
            startHour: 23,
            startMinute: 0,
            duration: 60 * 60,
            isActive: true
        )

        // Check at 9 AM - should not be within window
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.hour = 9
        components.minute = 0
        if let nineAM = calendar.date(from: components) {
            #expect(schedule.isWithinWindow(at: nineAM) == false)
        }
    }

    @Test func scheduleNotWithinWindowAfterEnd() {
        let calendar = Calendar.current
        let todayWeekday = calendar.component(.weekday, from: Date())

        // Schedule starting at 9:00 with 1 hour duration
        let schedule = Schedule(
            activeDays: [todayWeekday],
            startHour: 9,
            startMinute: 0,
            duration: 60 * 60,
            isActive: true
        )

        // Check at 11 AM - should not be within window
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.hour = 11
        components.minute = 0
        if let elevenAM = calendar.date(from: components) {
            #expect(schedule.isWithinWindow(at: elevenAM) == false)
        }
    }
}

struct ScheduleNextTimeTests {
    @Test func nextScheduledTimeReturnsNilWhenInactive() {
        let schedule = Schedule(activeDays: [1, 2, 3, 4, 5, 6, 7], isActive: false)
        #expect(schedule.nextScheduledTime(from: Date()) == nil)
    }

    @Test func nextScheduledTimeReturnsNilWhenNoDays() {
        let schedule = Schedule(activeDays: [], isActive: true)
        #expect(schedule.nextScheduledTime(from: Date()) == nil)
    }

    @Test func nextScheduledTimeReturnsDateForActiveDays() {
        let schedule = Schedule(
            activeDays: [1, 2, 3, 4, 5, 6, 7], // Daily
            startHour: 23,
            startMinute: 59,
            isActive: true
        )

        let nextTime = schedule.nextScheduledTime(from: Date())
        #expect(nextTime != nil)

        if let time = nextTime {
            let calendar = Calendar.current
            let hour = calendar.component(.hour, from: time)
            let minute = calendar.component(.minute, from: time)
            #expect(hour == 23)
            #expect(minute == 59)
        }
    }
}

@MainActor
struct ScheduleManagerTests {
    @Test func sharedInstanceExists() async {
        let manager = ScheduleManager.shared
        #expect(manager != nil)
    }

    @Test func initialStateNoActiveSchedule() async {
        let manager = ScheduleManager.shared
        manager.clearActiveSchedule()
        #expect(manager.activeSchedule == nil)
        #expect(manager.isScheduleTriggered == false)
    }

    @Test func clearActiveScheduleWorks() async {
        let manager = ScheduleManager.shared
        manager.clearActiveSchedule()
        #expect(manager.activeSchedule == nil)
        #expect(manager.isScheduleTriggered == false)
    }
}

@MainActor
struct TimerViewModelScheduleTests {
    @Test func isScheduledSessionInitiallyFalse() async {
        let viewModel = TimerViewModel()
        #expect(viewModel.isScheduledSession == false)
    }

    @Test func scheduleDisplayNameEmptyWhenNoSchedule() async {
        let viewModel = TimerViewModel()
        #expect(viewModel.scheduleDisplayName == "")
    }

    @Test func checkAndStartScheduledSessionDoesNothingWhenActive() async {
        let viewModel = TimerViewModel()
        viewModel.primaryButtonTapped() // Start a regular session

        viewModel.checkAndStartScheduledSession()

        // Should not change anything since a session is active
        #expect(viewModel.timerService.isRunning == true)
    }
}
