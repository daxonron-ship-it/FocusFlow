import SwiftUI

struct TimerView: View {
    @StateObject private var viewModel = TimerViewModel()
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            VStack(spacing: AppSpacing.xl) {
                Spacer()

                // Preset picker (only show when idle)
                if viewModel.timerService.isIdle {
                    PresetPicker(selectedPreset: $viewModel.selectedPreset)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }

                // Progress ring
                ProgressRing(
                    progress: viewModel.progress,
                    remainingTime: viewModel.remainingTime,
                    sessionType: viewModel.sessionType
                )
                .frame(width: 280, height: 280)
                .padding(.vertical, AppSpacing.lg)

                // Primary action button
                Button(action: viewModel.primaryButtonTapped) {
                    Text(viewModel.primaryButtonTitle)
                        .font(.system(size: AppFontSize.headline, weight: .semibold, design: .rounded))
                        .foregroundColor(AppColors.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppSpacing.md)
                        .background(
                            RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                                .fill(buttonColor)
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

                Spacer()

                // Bottom action buttons (placeholders for future milestones)
                HStack(spacing: AppSpacing.lg) {
                    PlaceholderButton(
                        icon: "square.grid.2x2",
                        label: "Apps",
                        isDisabled: true
                    )

                    PlaceholderButton(
                        icon: "shield",
                        label: "Mode",
                        isDisabled: true
                    )
                }
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

    private var buttonColor: Color {
        switch viewModel.timerService.state {
        case .idle, .paused:
            return AppColors.primary
        case .running:
            return AppColors.accent
        case .completed:
            return viewModel.sessionType == .work ? AppColors.success : AppColors.primary
        }
    }
}

struct PlaceholderButton: View {
    let icon: String
    let label: String
    let isDisabled: Bool

    var body: some View {
        VStack(spacing: AppSpacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 24))
            Text(label)
                .font(.system(size: AppFontSize.small, weight: .medium, design: .rounded))
        }
        .foregroundColor(isDisabled ? AppColors.textSecondary.opacity(0.5) : AppColors.textSecondary)
        .frame(width: 80, height: 60)
        .background(
            RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                .fill(AppColors.cardBackground.opacity(isDisabled ? 0.5 : 1))
        )
    }
}

#Preview {
    TimerView()
}
