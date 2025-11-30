import SwiftUI

/// Shows a preview of what blocked apps will look like before requesting FamilyControls permission.
/// This helps users understand the value before seeing the scary system permission dialog.
struct ShieldPreviewView: View {
    let onContinue: () -> Void

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            VStack(spacing: AppSpacing.xl) {
                Spacer()

                // Header text
                VStack(spacing: AppSpacing.md) {
                    Text("Here's what happens when you try to open a blocked app during a focus session:")
                        .font(.system(size: AppFontSize.body, weight: .regular, design: .rounded))
                        .foregroundColor(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, AppSpacing.lg)
                }

                // Shield mockup
                shieldMockup
                    .padding(.vertical, AppSpacing.xl)

                Text("This is the shield you'll see instead of distracting apps.")
                    .font(.system(size: AppFontSize.caption, weight: .regular, design: .rounded))
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppSpacing.lg)

                Spacer()

                // Continue button
                Button(action: onContinue) {
                    HStack {
                        Text("Continue")
                            .font(.system(size: AppFontSize.headline, weight: .semibold, design: .rounded))
                        Image(systemName: "arrow.right")
                            .font(.system(size: AppFontSize.headline, weight: .semibold))
                    }
                    .foregroundColor(AppColors.textPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.md + 4)
                    .background(
                        RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                            .fill(AppColors.primary)
                    )
                }
                .buttonStyle(.plain)
                .padding(.horizontal, AppSpacing.xl)
                .padding(.bottom, AppSpacing.xl)
            }
        }
    }

    private var shieldMockup: some View {
        VStack(spacing: AppSpacing.lg) {
            // Shield icon
            ZStack {
                Circle()
                    .fill(AppColors.primary.opacity(0.2))
                    .frame(width: 80, height: 80)

                Image(systemName: "shield.fill")
                    .font(.system(size: 40))
                    .foregroundColor(AppColors.primary)
            }

            // Title
            Text("Blocked")
                .font(.system(size: AppFontSize.title, weight: .bold, design: .rounded))
                .foregroundColor(AppColors.textPrimary)

            // Subtitle
            Text("Stay focused. You've got this!")
                .font(.system(size: AppFontSize.body, weight: .regular, design: .rounded))
                .foregroundColor(AppColors.textSecondary)

            // Info text
            Text("Open FocusFlow to check\nremaining time.")
                .font(.system(size: AppFontSize.caption, weight: .regular, design: .rounded))
                .foregroundColor(AppColors.textSecondary.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.top, AppSpacing.sm)
        }
        .padding(.vertical, AppSpacing.xxl)
        .padding(.horizontal, AppSpacing.xl)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: AppCornerRadius.extraLarge)
                .fill(AppColors.cardBackground)
                .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
        )
        .padding(.horizontal, AppSpacing.xl)
    }
}

#Preview {
    ShieldPreviewView(onContinue: {})
}
