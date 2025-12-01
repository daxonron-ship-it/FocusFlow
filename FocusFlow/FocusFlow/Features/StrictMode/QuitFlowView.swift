import SwiftUI

/// Container view that manages the 3-step quit flow:
/// 1. Delay Timer (10 seconds)
/// 2. Challenge (type phrase, math, pattern, or hold button)
/// 3. Streak Warning
struct QuitFlowView: View {
    let settings: AppSettings
    let currentStreak: Int
    let onConfirmQuit: () -> Void
    let onCancel: () -> Void
    let onEmergencyBypass: () -> Void

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
                    onCancel: onCancel,
                    onEmergencyBypass: onEmergencyBypass
                )
                .transition(.asymmetric(
                    insertion: .opacity,
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))

            case .challenge:
                challengeView
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

    /// Returns the appropriate challenge view based on settings
    @ViewBuilder
    private var challengeView: some View {
        switch settings.challengeType {
        case .phrase:
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

        case .math:
            MathChallengeView(
                onComplete: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        currentStep = .streakWarning
                    }
                },
                onGoBack: {
                    onCancel()
                }
            )

        case .pattern:
            PatternChallengeView(
                onComplete: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        currentStep = .streakWarning
                    }
                },
                onGoBack: {
                    onCancel()
                }
            )

        case .holdButton:
            HoldButtonChallengeView(
                onComplete: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        currentStep = .streakWarning
                    }
                },
                onGoBack: {
                    onCancel()
                }
            )
        }
    }
}

// MARK: - Convenience initializer for backward compatibility

extension QuitFlowView {
    /// Convenience initializer without emergency bypass callback
    init(
        settings: AppSettings,
        currentStreak: Int,
        onConfirmQuit: @escaping () -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.settings = settings
        self.currentStreak = currentStreak
        self.onConfirmQuit = onConfirmQuit
        self.onCancel = onCancel
        self.onEmergencyBypass = onConfirmQuit // Default: same as confirm quit
    }
}

#Preview("Full Flow - Phrase Challenge") {
    let settings = AppSettings(
        strictModeEnabled: true,
        strictModeTone: .strict,
        challengeType: .phrase
    )

    QuitFlowView(
        settings: settings,
        currentStreak: 12,
        onConfirmQuit: { print("Quit confirmed") },
        onCancel: { print("Cancelled") },
        onEmergencyBypass: { print("Emergency bypass") }
    )
}

#Preview("Full Flow - Math Challenge") {
    let settings = AppSettings(
        strictModeEnabled: true,
        strictModeTone: .neutral,
        challengeType: .math
    )

    QuitFlowView(
        settings: settings,
        currentStreak: 5,
        onConfirmQuit: { print("Quit confirmed") },
        onCancel: { print("Cancelled") },
        onEmergencyBypass: { print("Emergency bypass") }
    )
}

#Preview("Full Flow - Pattern Challenge") {
    let settings = AppSettings(
        strictModeEnabled: true,
        strictModeTone: .gentle,
        challengeType: .pattern
    )

    QuitFlowView(
        settings: settings,
        currentStreak: 3,
        onConfirmQuit: { print("Quit confirmed") },
        onCancel: { print("Cancelled") },
        onEmergencyBypass: { print("Emergency bypass") }
    )
}

#Preview("Full Flow - Hold Button Challenge") {
    let settings = AppSettings(
        strictModeEnabled: true,
        strictModeTone: .neutral,
        challengeType: .holdButton
    )

    QuitFlowView(
        settings: settings,
        currentStreak: 0,
        onConfirmQuit: { print("Quit confirmed") },
        onCancel: { print("Cancelled") },
        onEmergencyBypass: { print("Emergency bypass") }
    )
}
