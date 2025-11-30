import SwiftUI

struct TimerView: View {
    @StateObject private var viewModel = TimerViewModel()
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            VStack(spacing: AppSpacing.lg) {
                // App title
                Text("FocusFlow")
                    .font(.system(size: AppFontSize.headline, weight: .semibold, design: .rounded))
                    .foregroundColor(AppColors.textPrimary)
                    .padding(.top, AppSpacing.lg)

                // Preset picker (only show when idle)
                if viewModel.timerService.isIdle {
                    PresetPicker(selectedPreset: $viewModel.selectedPreset)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }

                Spacer()

                // Progress ring
                ProgressRing(
                    progress: viewModel.progress,
                    remainingTime: viewModel.remainingTime,
                    sessionType: viewModel.sessionType
                )
                .frame(width: 300, height: 300)

                Spacer()

                // Primary action button
                Button(action: viewModel.primaryButtonTapped) {
                    Text(viewModel.primaryButtonTitle)
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
                .padding(.horizontal, AppSpacing.xl)

                // Stop button (only show during active session)
                if viewModel.showStopButton {
                    Button(action: viewModel.stopSession) {
                        Text("End Session")
                            .font(.system(size: AppFontSize.body, weight: .medium, design: .rounded))
                            .foregroundColor(AppColors.danger)
                    }
                    .buttonStyle(.plain)
                    .transition(.opacity)
                }

                // Bottom info cards
                HStack(spacing: AppSpacing.md) {
                    InfoCard(
                        icon: "square.grid.2x2",
                        title: "Blocking",
                        value: "Social",
                        iconColor: AppColors.textSecondary,
                        valueColor: AppColors.textPrimary,
                        isPlaceholder: true
                    )

                    InfoCard(
                        icon: "lock.fill",
                        title: "Mode",
                        value: "Strict",
                        iconColor: Color.yellow,
                        valueColor: AppColors.accent,
                        isPlaceholder: true
                    )
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.bottom, AppSpacing.xl)
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: viewModel.timerService.state)
        }
        .onAppear {
            viewModel.onAppear()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                viewModel.onAppear()
            }
        }
    }
}

struct InfoCard: View {
    let icon: String
    let title: String
    let value: String
    let iconColor: Color
    let valueColor: Color
    var isPlaceholder: Bool = false

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(iconColor)
                .frame(width: 36, height: 36)
                .background(
                    RoundedRectangle(cornerRadius: AppCornerRadius.small)
                        .fill(AppColors.secondaryBackground)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: AppFontSize.caption, weight: .regular, design: .rounded))
                    .foregroundColor(AppColors.textSecondary)

                Text(value)
                    .font(.system(size: AppFontSize.body, weight: .semibold, design: .rounded))
                    .foregroundColor(valueColor)
            }

            Spacer()
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.sm + 4)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                .fill(AppColors.cardBackground)
        )
        .opacity(isPlaceholder ? 0.7 : 1.0)
    }
}

#Preview {
    TimerView()
}
