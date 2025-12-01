import SwiftUI

/// 10-second delay timer view shown before the challenge
/// Purpose: Prevent impulsive rage-quitting by forcing a pause
/// Also contains hidden emergency bypass (10-second long-press)
struct DelayTimerView: View {
    let onComplete: () -> Void
    let onCancel: () -> Void
    let onEmergencyBypass: () -> Void

    @State private var countdown: Int = 10
    @State private var isPulsing: Bool = false
    @State private var timer: Timer?

    // Emergency bypass state
    @State private var isHolding: Bool = false
    @State private var holdProgress: CGFloat = 0
    @State private var hapticTimer: Timer?
    @State private var holdStartTime: Date?

    private let totalDuration: Int = 10
    private let emergencyBypassDuration: TimeInterval = 10.0
    private let hapticStartDelay: TimeInterval = 3.0

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

            // Countdown circle with emergency bypass gesture
            ZStack {
                // Background circle
                Circle()
                    .stroke(AppColors.secondaryBackground, lineWidth: 8)
                    .frame(width: 160, height: 160)

                // Emergency bypass ring (shrinks as user holds)
                // Only visible when holding
                if isHolding {
                    Circle()
                        .trim(from: 0, to: 1 - holdProgress)
                        .stroke(
                            AppColors.danger.opacity(0.6),
                            style: StrokeStyle(lineWidth: 4, lineCap: .round)
                        )
                        .frame(width: 180, height: 180)
                        .rotationEffect(.degrees(-90))
                }

                // Progress circle (countdown)
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
            .contentShape(Circle())
            .gesture(
                emergencyBypassGesture
            )

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
                cancelEmergencyBypass()
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
            cancelEmergencyBypass()
        }
    }

    // MARK: - Emergency Bypass Gesture

    private var emergencyBypassGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { _ in
                if !isHolding {
                    startEmergencyBypass()
                }
            }
            .onEnded { _ in
                cancelEmergencyBypass()
            }
    }

    private func startEmergencyBypass() {
        isHolding = true
        holdStartTime = Date()

        // Start the shrinking ring animation immediately
        withAnimation(.linear(duration: emergencyBypassDuration)) {
            holdProgress = 1.0
        }

        // Start progressive haptics after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + hapticStartDelay) { [self] in
            guard isHolding else { return }
            startProgressiveHaptics()
        }

        // Complete bypass after 10 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + emergencyBypassDuration) { [self] in
            guard isHolding else { return }
            completeEmergencyBypass()
        }
    }

    private func cancelEmergencyBypass() {
        isHolding = false
        holdStartTime = nil

        // Reset ring animation
        withAnimation(.easeOut(duration: 0.3)) {
            holdProgress = 0
        }

        // Stop haptics
        stopProgressiveHaptics()
    }

    private func startProgressiveHaptics() {
        // Pulse every second after the initial 3-second delay
        hapticTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            guard isHolding else {
                stopProgressiveHaptics()
                return
            }
            HapticManager.shared.lightTap()
        }
    }

    private func stopProgressiveHaptics() {
        hapticTimer?.invalidate()
        hapticTimer = nil
    }

    private func completeEmergencyBypass() {
        stopTimer()
        stopProgressiveHaptics()
        isHolding = false

        // Strong haptic to indicate bypass activated
        HapticManager.shared.heavyWarning()

        // Request device authentication
        AuthenticationService.shared.requestAuthentication(
            reason: "Confirm emergency session end"
        ) { success in
            if success {
                onEmergencyBypass()
            } else {
                // Authentication failed - reset and continue
                isHolding = false
                holdProgress = 0
            }
        }
    }

    // MARK: - Timer Management

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

// MARK: - Convenience initializer for backward compatibility

extension DelayTimerView {
    /// Convenience initializer without emergency bypass callback
    init(
        onComplete: @escaping () -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.onComplete = onComplete
        self.onCancel = onCancel
        self.onEmergencyBypass = {}
    }
}

#Preview {
    DelayTimerView(
        onComplete: { print("Complete") },
        onCancel: { print("Cancel") },
        onEmergencyBypass: { print("Emergency Bypass") }
    )
}
