//
//  FocusFlowApp.swift
//  FocusFlow
//
//  Created by Rabindra Yadav on 11/30/25.
//

import SwiftUI
import SwiftData
import ActivityKit

@main
struct FocusFlowApp: App {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            FocusSession.self,
            UserStats.self,
            AppSettings.self,
            Schedule.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    init() {
        // Clean up any stale Live Activities on app launch
        Task {
            await LiveActivityService.shared.cleanupStaleActivities()
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView(hasCompletedOnboarding: $hasCompletedOnboarding)
                .preferredColorScheme(.dark)
        }
        .modelContainer(sharedModelContainer)
    }
}

// MARK: - Root View (handles onboarding vs main content)

struct RootView: View {
    @Binding var hasCompletedOnboarding: Bool
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        Group {
            if hasCompletedOnboarding {
                ContentView()
            } else {
                OnboardingFlow(onComplete: {
                    hasCompletedOnboarding = true
                })
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                // Clean up stale Live Activities when app returns to foreground
                Task {
                    await LiveActivityService.shared.cleanupStaleActivities()
                }
            }
        }
    }
}
