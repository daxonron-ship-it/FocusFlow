//
//  LiveActivityService.swift
//  FocusFlow
//
//  Service for managing Live Activities during focus sessions.
//

import Foundation
import ActivityKit
import Combine

@MainActor
final class LiveActivityService {
    static let shared = LiveActivityService()

    private var currentActivity: Activity<FocusActivityAttributes>?

    private init() {}

    // MARK: - Public Properties

    var areActivitiesEnabled: Bool {
        ActivityAuthorizationInfo().areActivitiesEnabled
    }

    var hasActiveActivity: Bool {
        currentActivity != nil
    }

    var currentSessionId: UUID? {
        currentActivity?.content.state.sessionId
    }

    // MARK: - Public Methods

    /// Start a Live Activity for a focus session
    func startActivity(
        sessionId: UUID,
        startTime: Date,
        endTime: Date,
        sessionType: SessionType
    ) {
        // Check if Live Activities are enabled
        guard areActivitiesEnabled else {
            print("Live Activities are not enabled")
            return
        }

        // End any existing activity first
        if currentActivity != nil {
            endActivity()
        }

        let attributes = FocusActivityAttributes(
            startTime: startTime,
            endTime: endTime,
            duration: endTime.timeIntervalSince(startTime)
        )

        let state = FocusActivityAttributes.ContentState(
            sessionId: sessionId,
            sessionType: sessionType == .work ? "Focus" : "Break"
        )

        let content = ActivityContent(state: state, staleDate: endTime)

        do {
            currentActivity = try Activity.request(
                attributes: attributes,
                content: content,
                pushType: nil
            )
            print("Live Activity started for session: \(sessionId)")
        } catch {
            print("Failed to start Live Activity: \(error)")
        }
    }

    /// End the current Live Activity
    func endActivity() {
        Task {
            guard let activity = currentActivity else { return }

            await activity.end(
                ActivityContent(state: activity.content.state, staleDate: nil),
                dismissalPolicy: .immediate
            )

            currentActivity = nil
            print("Live Activity ended")
        }
    }

    /// Update the Live Activity state (if needed for future features)
    func updateActivity(sessionType: SessionType) {
        Task {
            guard let activity = currentActivity else { return }

            let updatedState = FocusActivityAttributes.ContentState(
                sessionId: activity.content.state.sessionId,
                sessionType: sessionType == .work ? "Focus" : "Break"
            )

            let updatedContent = ActivityContent(
                state: updatedState,
                staleDate: activity.attributes.endTime
            )

            await activity.update(updatedContent)
        }
    }

    /// Clean up stale Live Activities (call on app launch and foreground)
    /// - Parameter activeSessionId: The ID of the currently active session (if any)
    func cleanupStaleActivities(activeSessionId: UUID? = nil) async {
        for activity in Activity<FocusActivityAttributes>.activities {
            let activitySessionId = activity.content.state.sessionId

            // If no active session, or this activity doesn't match the active session, end it
            if activeSessionId == nil || activitySessionId != activeSessionId {
                await activity.end(
                    ActivityContent(state: activity.content.state, staleDate: nil),
                    dismissalPolicy: .immediate
                )
                print("Cleaned up stale activity for session: \(activitySessionId)")
            }
        }

        // If we ended all activities, clear our reference
        if activeSessionId == nil {
            currentActivity = nil
        }
    }

    /// Check if a specific session has an active Live Activity
    func isSessionActive(sessionId: UUID) -> Bool {
        for activity in Activity<FocusActivityAttributes>.activities {
            if activity.content.state.sessionId == sessionId {
                return true
            }
        }
        return false
    }

    /// Get all active Live Activity session IDs
    func getActiveSessionIds() -> [UUID] {
        Activity<FocusActivityAttributes>.activities.map { $0.content.state.sessionId }
    }
}
