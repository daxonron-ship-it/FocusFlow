import SwiftUI

/// Hold button challenge view where user must hold a button for 5 seconds
/// Provides visual feedback with a filling ring animation
struct HoldButtonChallengeView: View {
    let onComplete: () -> Void
    let onGoBack: () -> Void

    @State private var holdProgress: CGFloat = 0
    @State private var isHolding: Bool = false
    @State private var isComplete: Bool = false
    @State private var hapticTimer: Timer?

    private let holdDuration: TimeInterval = 5.0
    private let buttonSize: CGFloat = 180

    var body: some View {
        VStack(spacing: AppSpacing.lg) {
            Spacer()

            // Header
            VStack(spacing: AppSpacing.sm) {
                Image(systemName: "hand.point.up.fill")
                    .font(.system(size: 44))
                    .foregroundColor(AppColors.accent)

                Text("Hold Challenge")
                    .font(.system(size: AppFontSize.title, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.textPrimary)

                Text("Press and hold the button\nfor 5 seconds to continue")
                    .font(.system(size: AppFontSize.body, weight: .regular, design: .rounded))
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            // Hold button with progress ring
            ZStack {
                // Background ring
                Circle()
                    .stroke(AppColors.secondaryBackground, lineWidth: 12)
                    .frame(width: buttonSize, height: buttonSize)

                // Progress ring
                Circle()
                    .trim(from: 0, to: holdProgress)
                    .stroke(
                        isComplete ? AppColors.success : AppColors.accent,
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .frame(width: buttonSize, height: buttonSize)
                    .rotationEffect(.degrees(-90))

                // Inner button
                Circle()
                    .fill(
                        isComplete ? AppColors.success :
                            (isHolding ? AppColors.accent : AppColors.primary)
                    )
                    .frame(width: buttonSize - 40, height: buttonSize - 40)
                    .shadow(
                        color: (isHolding ? AppColors.accent : AppColors.primary).opacity(0.4),
                        radius: isHolding ? 15 : 5
                    )

                // Progress text
                VStack(spacing: 4) {
                    if isComplete {
                        Image(systemName: "checkmark")
                            .font(.system(size: 48, weight: .bold))
                            .foregroundColor(AppColors.textPrimary)
                    } else {
                        Text(String(format: "%.1f", holdProgress * holdDuration))
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundColor(AppColors.textPrimary)

                        Text("seconds")
                            .font(.system(size: AppFontSize.caption, weight: .medium, design: .rounded))
                            .foregroundColor(AppColors.textPrimary.opacity(0.8))
                    }
                }
            }
            .contentShape(Circle())
            .gesture(holdGesture)
            .animation(.easeInOut(duration: 0.2), value: isHolding)
            .animation(.easeInOut(duration: 0.2), value: isComplete)

            // Instructions
            Text(instructionText)
                .font(.system(size: AppFontSize.caption, weight: .medium, design: .rounded))
                .foregroundColor(isComplete ? AppColors.success : AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .frame(height: 40) // Fixed height to prevent layout shift

            Spacer()

            // Action buttons
            VStack(spacing: AppSpacing.md) {
                Button(action: completeChallenge) {
                    Text("Continue")
                        .font(.system(size: AppFontSize.headline, weight: .semibold, design: .rounded))
                        .foregroundColor(isComplete ? AppColors.textPrimary : AppColors.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppSpacing.md + 4)
                        .background(
                            RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                                .fill(isComplete ? AppColors.danger : AppColors.cardBackground)
                        )
                }
                .buttonStyle(.plain)
                .disabled(!isComplete)

                Button(action: {
                    HapticManager.shared.lightTap()
                    onGoBack()
                }) {
                    Text("Go Back")
                        .font(.system(size: AppFontSize.body, weight: .medium, design: .rounded))
                        .foregroundColor(AppColors.textSecondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, AppSpacing.xl)
            .padding(.bottom, AppSpacing.xl)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.background.ignoresSafeArea())
    }

    private var instructionText: String {
        if isComplete {
            return "Button held successfully!"
        } else if isHolding {
            return "Keep holding..."
        } else if holdProgress > 0 {
            return "Released too early. Try again."
        } else {
            return "Press and hold the circle above"
        }
    }

    private var holdGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { _ in
                if !isHolding && !isComplete {
                    startHolding()
                }
            }
            .onEnded { _ in
                if !isComplete {
                    stopHolding()
                }
            }
    }

    private func startHolding() {
        isHolding = true
        HapticManager.shared.mediumImpact()

        // Start progress animation
        withAnimation(.linear(duration: holdDuration)) {
            holdProgress = 1.0
        }

        // Start haptic feedback every second
        hapticTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            guard isHolding else {
                stopHaptics()
                return
            }
            HapticManager.shared.lightTap()
        }

        // Complete after hold duration
        DispatchQueue.main.asyncAfter(deadline: .now() + holdDuration) { [self] in
            guard isHolding else { return }
            completeHold()
        }
    }

    private func stopHolding() {
        isHolding = false
        stopHaptics()

        // Reset progress if not complete
        if !isComplete {
            withAnimation(.easeOut(duration: 0.3)) {
                holdProgress = 0
            }
            HapticManager.shared.error()
        }
    }

    private func completeHold() {
        isHolding = false
        isComplete = true
        stopHaptics()
        HapticManager.shared.success()
    }

    private func stopHaptics() {
        hapticTimer?.invalidate()
        hapticTimer = nil
    }

    private func completeChallenge() {
        guard isComplete else { return }
        HapticManager.shared.warning()
        onComplete()
    }
}

#Preview {
    HoldButtonChallengeView(
        onComplete: { print("Complete") },
        onGoBack: { print("Go Back") }
    )
}
