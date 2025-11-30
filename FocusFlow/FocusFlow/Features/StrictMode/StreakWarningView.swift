import SwiftUI

/// Final warning before quitting - shows streak that will be lost
/// Implements loss aversion to make quitting feel costly
struct StreakWarningView: View {
    let currentStreak: Int
    let onConfirmQuit: () -> Void
    let onKeepGoing: () -> Void

    @State private var showingConfirmation: Bool = false

    var body: some View {
        VStack(spacing: AppSpacing.xl) {
            Spacer()

            // Warning icon
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 64))
                .foregroundColor(AppColors.accent)
                .symbolRenderingMode(.multicolor)

            // Header
            Text("Warning")
                .font(.system(size: AppFontSize.title, weight: .bold, design: .rounded))
                .foregroundColor(AppColors.textPrimary)

            // Message
            VStack(spacing: AppSpacing.md) {
                Text("You're about to lose your current streak:")
                    .font(.system(size: AppFontSize.body, weight: .regular, design: .rounded))
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)

                // Streak display
                HStack(spacing: AppSpacing.sm) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 32))
                        .foregroundColor(AppColors.accent)

                    Text("\(currentStreak) \(currentStreak == 1 ? "day" : "days")")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(AppColors.textPrimary)
                }
                .padding(.vertical, AppSpacing.md)
                .padding(.horizontal, AppSpacing.xl)
                .background(
                    RoundedRectangle(cornerRadius: AppCornerRadius.large)
                        .fill(AppColors.cardBackground)
                )

                Text("This cannot be undone.")
                    .font(.system(size: AppFontSize.caption, weight: .medium, design: .rounded))
                    .foregroundColor(AppColors.danger)
            }
            .padding(.horizontal, AppSpacing.lg)

            Spacer()

            // Action buttons
            VStack(spacing: AppSpacing.md) {
                // Keep Going - Primary action (encourages staying)
                Button(action: {
                    HapticManager.shared.success()
                    onKeepGoing()
                }) {
                    Text("Keep Going")
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

                // Reset Streak - Destructive action
                Button(action: {
                    showingConfirmation = true
                }) {
                    Text("Reset Streak")
                        .font(.system(size: AppFontSize.body, weight: .medium, design: .rounded))
                        .foregroundColor(AppColors.danger)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppSpacing.md)
                        .background(
                            RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                                .stroke(AppColors.danger, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, AppSpacing.xl)
            .padding(.bottom, AppSpacing.xl)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.background.ignoresSafeArea())
        .confirmationDialog(
            "Are you sure?",
            isPresented: $showingConfirmation,
            titleVisibility: .visible
        ) {
            Button("Reset Streak & End Session", role: .destructive) {
                HapticManager.shared.warning()
                onConfirmQuit()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Your \(currentStreak)-day streak will be reset to 0. This action cannot be undone.")
        }
    }
}

/// Simplified version for when there's no streak to lose
struct NoStreakWarningView: View {
    let onConfirmQuit: () -> Void
    let onKeepGoing: () -> Void

    var body: some View {
        VStack(spacing: AppSpacing.xl) {
            Spacer()

            // Warning icon
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 64))
                .foregroundColor(AppColors.accent)

            // Header
            Text("End Session Early?")
                .font(.system(size: AppFontSize.title, weight: .bold, design: .rounded))
                .foregroundColor(AppColors.textPrimary)

            // Message
            VStack(spacing: AppSpacing.sm) {
                Text("Quitting early will be recorded in your history.")
                    .font(.system(size: AppFontSize.body, weight: .regular, design: .rounded))
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)

                Text("You can do this!")
                    .font(.system(size: AppFontSize.body, weight: .medium, design: .rounded))
                    .foregroundColor(AppColors.success)
            }
            .padding(.horizontal, AppSpacing.lg)

            Spacer()

            // Action buttons
            VStack(spacing: AppSpacing.md) {
                // Keep Going - Primary action
                Button(action: {
                    HapticManager.shared.success()
                    onKeepGoing()
                }) {
                    Text("Keep Going")
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

                // End Session - Destructive action
                Button(action: {
                    HapticManager.shared.warning()
                    onConfirmQuit()
                }) {
                    Text("End Session")
                        .font(.system(size: AppFontSize.body, weight: .medium, design: .rounded))
                        .foregroundColor(AppColors.danger)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppSpacing.md)
                        .background(
                            RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                                .stroke(AppColors.danger, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, AppSpacing.xl)
            .padding(.bottom, AppSpacing.xl)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.background.ignoresSafeArea())
    }
}

#Preview("With Streak") {
    StreakWarningView(
        currentStreak: 12,
        onConfirmQuit: { print("Quit confirmed") },
        onKeepGoing: { print("Keep going") }
    )
}

#Preview("No Streak") {
    NoStreakWarningView(
        onConfirmQuit: { print("Quit confirmed") },
        onKeepGoing: { print("Keep going") }
    )
}
