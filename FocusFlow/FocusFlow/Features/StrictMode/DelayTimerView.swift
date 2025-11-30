import SwiftUI

/// 10-second delay timer view shown before the challenge
/// Purpose: Prevent impulsive rage-quitting by forcing a pause
struct DelayTimerView: View {
    let onComplete: () -> Void
    let onCancel: () -> Void

    @State private var countdown: Int = 10
    @State private var isPulsing: Bool = false
    @State private var timer: Timer?

    private let totalDuration: Int = 10

    var body: some View {
        VStack(spacing: AppSpacing.xl) {
            Spacer()

            // Header
            VStack(spacing: AppSpacing.sm) {
                Image(systemName: "clock.badge.questionmark")
                    .font(.system(size: 44))
                    .foregroundColor(AppColors.accent)

                Text("Hold On")
                    .font(.system(size: AppFontSize.title, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.textPrimary)
            }

            // Countdown circle
            ZStack {
                // Background circle
                Circle()
                    .stroke(AppColors.secondaryBackground, lineWidth: 8)
                    .frame(width: 160, height: 160)

                // Progress circle
                Circle()
                    .trim(from: 0, to: CGFloat(countdown) / CGFloat(totalDuration))
                    .stroke(
                        AppColors.accent,
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 160, height: 160)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 0.5), value: countdown)

                // Countdown number
                Text("\(countdown)")
                    .font(.system(size: 64, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.textPrimary)
                    .scaleEffect(isPulsing ? 1.1 : 1.0)
                    .animation(
                        .easeInOut(duration: 0.5).repeatForever(autoreverses: true),
                        value: isPulsing
                    )
            }

            // Message
            VStack(spacing: AppSpacing.sm) {
                Text("Take a moment to reconsider.")
                    .font(.system(size: AppFontSize.body, weight: .medium, design: .rounded))
                    .foregroundColor(AppColors.textPrimary)

                Text("Challenge unlocks in \(countdown) second\(countdown == 1 ? "" : "s")...")
                    .font(.system(size: AppFontSize.caption, weight: .regular, design: .rounded))
                    .foregroundColor(AppColors.textSecondary)
            }
            .multilineTextAlignment(.center)

            Spacer()

            // Cancel button
            Button(action: {
                stopTimer()
                HapticManager.shared.lightTap()
                onCancel()
            }) {
                Text("Cancel")
                    .font(.system(size: AppFontSize.body, weight: .medium, design: .rounded))
                    .foregroundColor(AppColors.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                            .stroke(AppColors.textSecondary.opacity(0.5), lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            .padding(.horizontal, AppSpacing.xl)
            .padding(.bottom, AppSpacing.xl)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.background.ignoresSafeArea())
        .onAppear {
            startTimer()
            isPulsing = true
        }
        .onDisappear {
            stopTimer()
        }
    }

    private func startTimer() {
        // Initial haptic
        HapticManager.shared.lightTap()

        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if countdown > 1 {
                countdown -= 1
                // Subtle haptic each second
                HapticManager.shared.lightTap()
            } else {
                stopTimer()
                // Final haptic before proceeding
                HapticManager.shared.mediumImpact()
                onComplete()
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}

#Preview {
    DelayTimerView(
        onComplete: { print("Complete") },
        onCancel: { print("Cancel") }
    )
}
