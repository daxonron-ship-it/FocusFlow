import SwiftUI

struct SessionCompleteView: View {
    let session: FocusSession
    let currentStreak: Int
    let onStartBreak: () -> Void
    let onSkipBreak: () -> Void
    let onDone: () -> Void

    @State private var showCheckmark: Bool = false
    @State private var showContent: Bool = false
    @State private var showButtons: Bool = false

    private var isWorkSession: Bool {
        session.sessionType == .work
    }

    private var sessionDurationMinutes: Int {
        Int(session.plannedDuration / 60)
    }

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            VStack(spacing: AppSpacing.xl) {
                Spacer()

                // Checkmark animation
                ZStack {
                    Circle()
                        .fill(AppColors.success.opacity(0.2))
                        .frame(width: 120, height: 120)

                    Circle()
                        .stroke(AppColors.success, lineWidth: 4)
                        .frame(width: 120, height: 120)
                        .scaleEffect(showCheckmark ? 1 : 0.5)
                        .opacity(showCheckmark ? 1 : 0)

                    Image(systemName: "checkmark")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(AppColors.success)
                        .scaleEffect(showCheckmark ? 1 : 0)
                        .opacity(showCheckmark ? 1 : 0)
                }

                VStack(spacing: AppSpacing.md) {
                    // Title
                    Text(isWorkSession ? "Great Work!" : "Break Complete!")
                        .font(.system(size: AppFontSize.title, weight: .bold, design: .rounded))
                        .foregroundColor(AppColors.textPrimary)

                    // Duration
                    Text("You focused for \(sessionDurationMinutes) minutes")
                        .font(.system(size: AppFontSize.body, weight: .regular, design: .rounded))
                        .foregroundColor(AppColors.textSecondary)

                    // Streak display
                    if currentStreak > 0 {
                        HStack(spacing: AppSpacing.sm) {
                            Image(systemName: "flame.fill")
                                .foregroundColor(AppColors.accent)

                            Text("\(currentStreak) day streak")
                                .font(.system(size: AppFontSize.headline, weight: .semibold, design: .rounded))
                                .foregroundColor(AppColors.accent)
                        }
                        .padding(.top, AppSpacing.sm)
                    }
                }
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 20)

                Spacer()

                // Buttons
                VStack(spacing: AppSpacing.md) {
                    if isWorkSession {
                        // After work session: offer break
                        Button(action: onStartBreak) {
                            Text("Start Break")
                                .font(.system(size: AppFontSize.headline, weight: .semibold, design: .rounded))
                                .foregroundColor(AppColors.textPrimary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, AppSpacing.md + 4)
                                .background(
                                    RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                                        .fill(AppColors.success)
                                )
                        }
                        .buttonStyle(.plain)

                        Button(action: onSkipBreak) {
                            Text("Skip Break")
                                .font(.system(size: AppFontSize.body, weight: .medium, design: .rounded))
                                .foregroundColor(AppColors.textSecondary)
                        }
                        .buttonStyle(.plain)
                    } else {
                        // After break: offer new session or done
                        Button(action: onStartBreak) {
                            Text("Start Focus")
                                .font(.system(size: AppFontSize.headline, weight: .semibold, design: .rounded))
                                .foregroundColor(AppColors.textPrimary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, AppSpacing.md + 4)
                                .background(
                                    RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                                        .fill(AppColors.accent)
                                )
                        }
                        .buttonStyle(.plain)

                        Button(action: onDone) {
                            Text("Done")
                                .font(.system(size: AppFontSize.body, weight: .medium, design: .rounded))
                                .foregroundColor(AppColors.textSecondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, AppSpacing.xl)
                .padding(.bottom, AppSpacing.xxl)
                .opacity(showButtons ? 1 : 0)
                .offset(y: showButtons ? 0 : 20)
            }
        }
        .onAppear {
            animateIn()
        }
    }

    private func animateIn() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.1)) {
            showCheckmark = true
        }

        withAnimation(.easeOut(duration: 0.4).delay(0.4)) {
            showContent = true
        }

        withAnimation(.easeOut(duration: 0.4).delay(0.6)) {
            showButtons = true
        }
    }
}

#Preview("Work Session Complete") {
    SessionCompleteView(
        session: FocusSession(plannedDuration: 25 * 60, sessionType: .work, completionStatus: .completed),
        currentStreak: 5,
        onStartBreak: {},
        onSkipBreak: {},
        onDone: {}
    )
}

#Preview("Break Complete") {
    SessionCompleteView(
        session: FocusSession(plannedDuration: 5 * 60, sessionType: .rest, completionStatus: .completed),
        currentStreak: 5,
        onStartBreak: {},
        onSkipBreak: {},
        onDone: {}
    )
}
