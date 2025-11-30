import SwiftUI

/// Container view that manages the 3-step quit flow:
/// 1. Delay Timer (10 seconds)
/// 2. Challenge (type phrase)
/// 3. Streak Warning
struct QuitFlowView: View {
    let settings: AppSettings
    let currentStreak: Int
    let onConfirmQuit: () -> Void
    let onCancel: () -> Void

    @State private var currentStep: QuitFlowStep = .delay

    /// The 3 steps in the quit flow
    enum QuitFlowStep {
        case delay
        case challenge
        case streakWarning
    }

    /// Get a random challenge phrase based on settings
    private var challengePhrase: String {
        switch settings.strictModeTone {
        case .custom:
            // Use custom phrase if available, otherwise fall back to neutral
            return settings.customChallengePhrase ?? StrictModeTone.neutral.phrases.randomElement() ?? "End session early"
        case .gentle, .neutral, .strict:
            return settings.strictModeTone.phrases.randomElement() ?? "End session early"
        }
    }

    var body: some View {
        Group {
            switch currentStep {
            case .delay:
                DelayTimerView(
                    onComplete: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            currentStep = .challenge
                        }
                    },
                    onCancel: onCancel
                )
                .transition(.asymmetric(
                    insertion: .opacity,
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))

            case .challenge:
                ChallengeView(
                    challengePhrase: challengePhrase,
                    onComplete: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            currentStep = .streakWarning
                        }
                    },
                    onGoBack: {
                        // Going back from challenge cancels the whole flow
                        onCancel()
                    }
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))

            case .streakWarning:
                if currentStreak > 0 {
                    StreakWarningView(
                        currentStreak: currentStreak,
                        onConfirmQuit: onConfirmQuit,
                        onKeepGoing: onCancel
                    )
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .opacity
                    ))
                } else {
                    NoStreakWarningView(
                        onConfirmQuit: onConfirmQuit,
                        onKeepGoing: onCancel
                    )
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .opacity
                    ))
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: currentStep)
        .interactiveDismissDisabled()  // Prevent swipe-to-dismiss during flow
    }
}

#Preview("Full Flow - Strict Tone") {
    let settings = AppSettings(
        strictModeEnabled: true,
        strictModeTone: .strict
    )

    QuitFlowView(
        settings: settings,
        currentStreak: 12,
        onConfirmQuit: { print("Quit confirmed") },
        onCancel: { print("Cancelled") }
    )
}

#Preview("Full Flow - Gentle Tone") {
    let settings = AppSettings(
        strictModeEnabled: true,
        strictModeTone: .gentle
    )

    QuitFlowView(
        settings: settings,
        currentStreak: 5,
        onConfirmQuit: { print("Quit confirmed") },
        onCancel: { print("Cancelled") }
    )
}

#Preview("Full Flow - No Streak") {
    let settings = AppSettings(
        strictModeEnabled: true,
        strictModeTone: .neutral
    )

    QuitFlowView(
        settings: settings,
        currentStreak: 0,
        onConfirmQuit: { print("Quit confirmed") },
        onCancel: { print("Cancelled") }
    )
}
