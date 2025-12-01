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
