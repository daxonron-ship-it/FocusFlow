import SwiftUI

/// Explains what permissions FocusFlow needs and why, displayed before the system permission dialog.
/// Addresses user concerns about privacy and explains that Face ID is Apple's requirement.
struct PermissionExplanationView: View {
    let onEnableBlocking: () -> Void
    let onMaybeLater: () -> Void

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: AppSpacing.xl) {
                    Spacer(minLength: AppSpacing.xl)

                    // Header
                    VStack(spacing: AppSpacing.md) {
                        Image(systemName: "lock.shield")
                            .font(.system(size: 50))
                            .foregroundColor(AppColors.primary)

                        Text("Enable App Blocking")
                            .font(.system(size: AppFontSize.title, weight: .bold, design: .rounded))
                            .foregroundColor(AppColors.textPrimary)

                        Text("To enable app blocking, FocusFlow needs Screen Time access.")
                            .font(.system(size: AppFontSize.body, weight: .regular, design: .rounded))
                            .foregroundColor(AppColors.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, AppSpacing.lg)
                    }

                    // Privacy info cards
                    VStack(spacing: AppSpacing.md) {
                        // What we CAN'T see
                        privacyCard(
                            icon: "eye.slash",
                            iconColor: AppColors.danger,
                            title: "What we CAN'T see:",
                            items: [
                                "Your personal data",
                                "Specific app content",
                                "Your browsing history"
                            ]
                        )

                        // What we CAN do
                        privacyCard(
                            icon: "checkmark.shield",
                            iconColor: AppColors.success,
                            title: "What we CAN do:",
                            items: [
                                "Temporarily hide apps",
                                "Show you category usage"
                            ]
                        )
                    }
                    .padding(.horizontal, AppSpacing.lg)

                    // Face ID explanation
                    HStack(spacing: AppSpacing.md) {
                        Image(systemName: "faceid")
                            .font(.system(size: 24))
                            .foregroundColor(AppColors.textSecondary)

                        Text("Apple requires Face ID to confirm you own this device.")
                            .font(.system(size: AppFontSize.caption, weight: .regular, design: .rounded))
                            .foregroundColor(AppColors.textSecondary)
                    }
                    .padding(.horizontal, AppSpacing.xl)

                    Spacer(minLength: AppSpacing.xl)

                    // Buttons
                    VStack(spacing: AppSpacing.md) {
                        Button(action: onEnableBlocking) {
                            Text("Enable Blocking")
                                .font(.system(size: AppFontSize.headline, weight: .semibold, design: .rounded))
                                .foregroundColor(AppColors.textPrimary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, AppSpacing.md + 4)
                                .background(
                                    RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                                        .fill(AppColors.primary)
                                )
                        }
                        .buttonStyle(.plain)

                        Button(action: onMaybeLater) {
                            Text("Maybe Later")
                                .font(.system(size: AppFontSize.body, weight: .medium, design: .rounded))
                                .foregroundColor(AppColors.textSecondary)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, AppSpacing.xl)
                    .padding(.bottom, AppSpacing.xl)
                }
            }
        }
    }

    private func privacyCard(icon: String, iconColor: Color, title: String, items: [String]) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(iconColor)

                Text(title)
                    .font(.system(size: AppFontSize.body, weight: .semibold, design: .rounded))
                    .foregroundColor(AppColors.textPrimary)
            }

            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                ForEach(items, id: \.self) { item in
                    HStack(spacing: AppSpacing.sm) {
                        Text("•")
                            .foregroundColor(AppColors.textSecondary)
                        Text(item)
                            .font(.system(size: AppFontSize.caption, weight: .regular, design: .rounded))
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
            }
            .padding(.leading, AppSpacing.lg + AppSpacing.xs)
        }
        .padding(AppSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                .fill(AppColors.cardBackground)
        )
    }
}

#Preview {
    PermissionExplanationView(
        onEnableBlocking: {},
        onMaybeLater: {}
    )
}
