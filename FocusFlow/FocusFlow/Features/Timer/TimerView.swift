import SwiftUI
import SwiftData

struct TimerView: View {
    @StateObject private var viewModel = TimerViewModel()
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        ZStack {
            // Main timer content
            mainContent
                .opacity(viewModel.showCompletionView ? 0 : 1)

            // Completion view overlay
            if viewModel.showCompletionView, let session = viewModel.completedSession {
                SessionCompleteView(
                    session: session,
                    currentStreak: viewModel.currentStreak,
                    onStartBreak: {
                        if session.sessionType == .work {
                            viewModel.startBreakAfterCompletion()
                        } else {
                            // After break, "Start Focus" goes back to work
                            viewModel.skipBreak()
                            viewModel.primaryButtonTapped()
                        }
                    },
                    onSkipBreak: viewModel.skipBreak,
                    onDone: viewModel.dismissCompletionView
                )
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.showCompletionView)
        .onAppear {
            viewModel.setModelContext(modelContext)
            viewModel.onAppear()
        }
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .active:
                viewModel.onForeground()
            case .background:
                viewModel.onBackground()
            default:
                break
            }
        }
        .sheet(isPresented: $viewModel.showBlockingFlow) {
            if viewModel.isBlockingAuthorized {
                // Already authorized, show app picker directly
                AppPickerView(blockingManager: viewModel.blockingManager)
            } else {
                // Not authorized, show full permission flow
                BlockingFlowView(blockingManager: viewModel.blockingManager)
            }
        }
        .sheet(isPresented: $viewModel.showQuitFlow) {
            if let settings = viewModel.appSettings {
                QuitFlowView(
                    settings: settings,
                    currentStreak: viewModel.currentStreak,
                    onConfirmQuit: viewModel.confirmStopSession,
                    onCancel: viewModel.cancelQuitFlow
                )
            }
        }
    }

    private var mainContent: some View {
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

                // Pause duration indicator
                if viewModel.timerService.isPaused {
                    HStack(spacing: AppSpacing.sm) {
                        Image(systemName: "pause.circle.fill")
                            .foregroundColor(AppColors.textSecondary)

                        Text("Paused for \(formatPauseDuration(viewModel.pausedDuration))")
                            .font(.system(size: AppFontSize.body, weight: .medium, design: .rounded))
                            .foregroundColor(AppColors.textSecondary)
                    }
                    .padding(.top, AppSpacing.sm)
                    .transition(.opacity)
                }

                Spacer()

                // Primary action button
                Button(action: viewModel.primaryButtonTapped) {
                    Text(viewModel.primaryButtonTitle)
                        .font(.system(size: AppFontSize.headline, weight: .semibold, design: .rounded))
                        .foregroundColor(AppColors.textPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 44) // Ensure 44pt minimum touch target
                        .padding(.vertical, AppSpacing.md + 4)
                        .background(
                            RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                                .fill(primaryButtonColor)
                        )
                }
                .buttonStyle(.plain)
                .padding(.horizontal, AppSpacing.xl)
                .accessibilityLabel(viewModel.primaryButtonTitle)
                .accessibilityHint(primaryButtonAccessibilityHint)

                // Stop button (only show during active session)
                if viewModel.showStopButton {
                    Button(action: viewModel.attemptStopSession) {
                        Text("End Session")
                            .font(.system(size: AppFontSize.body, weight: .medium, design: .rounded))
                            .foregroundColor(AppColors.danger)
                            .frame(minHeight: 44) // Ensure 44pt minimum touch target
                    }
                    .buttonStyle(.plain)
                    .transition(.opacity)
                    .accessibilityLabel("End session early")
                    .accessibilityHint(viewModel.isStrictModeEnabled ? "Strict Mode is enabled. Will show challenge before ending." : "Ends your current focus session")
                }

                // Bottom info cards
                HStack(spacing: AppSpacing.md) {
                    // Blocking card - tappable to select apps
                    Button(action: {
                        // Only allow changing blocked apps when not in active session
                        if !viewModel.isSessionActive {
                            viewModel.blockingCardTapped()
                        }
                    }) {
                        InfoCard(
                            icon: "square.grid.2x2",
                            title: "Blocking",
                            value: viewModel.blockedAppsDescription,
                            iconColor: viewModel.hasBlockedApps ? AppColors.primary : AppColors.textSecondary,
                            valueColor: viewModel.hasBlockedApps ? AppColors.textPrimary : AppColors.textSecondary,
                            isPlaceholder: !viewModel.hasBlockedApps,
                            showChevron: !viewModel.isSessionActive
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(viewModel.isSessionActive)

                    // Mode card - toggle Strict Mode (only when idle)
                    Button(action: {
                        if !viewModel.isSessionActive {
                            viewModel.toggleStrictMode()
                        }
                    }) {
                        InfoCard(
                            icon: viewModel.isStrictModeEnabled ? "lock.fill" : "lock.open.fill",
                            title: "Mode",
                            value: viewModel.strictModeDisplayValue,
                            iconColor: viewModel.isStrictModeEnabled ? AppColors.accent : AppColors.textSecondary,
                            valueColor: viewModel.isStrictModeEnabled ? AppColors.accent : AppColors.textSecondary,
                            isPlaceholder: !viewModel.isStrictModeEnabled,
                            showChevron: !viewModel.isSessionActive
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(viewModel.isSessionActive)
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.bottom, AppSpacing.xl)
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: viewModel.timerService.state)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: viewModel.sessionType)
        }
    }

    private var primaryButtonColor: Color {
        switch viewModel.sessionType {
        case .work:
            return AppColors.accent
        case .rest:
            return AppColors.success
        }
    }

    private var primaryButtonAccessibilityHint: String {
        switch viewModel.timerService.state {
        case .idle:
            return viewModel.sessionType == .work ?
                "Starts a \(Int(viewModel.selectedDuration / 60)) minute focus session" :
                "Starts a \(Int(viewModel.selectedDuration / 60)) minute break"
        case .running:
            return "Pauses the current session"
        case .paused:
            return "Resumes the paused session"
        case .completed:
            return "Starts the next session"
        }
    }

    private func formatPauseDuration(_ duration: TimeInterval) -> String {
        let totalSeconds = Int(duration)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60

        if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        } else {
            return "\(seconds)s"
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
    var showChevron: Bool = false

    @ScaledMetric(relativeTo: .body) private var iconSize: CGFloat = 20
    @ScaledMetric(relativeTo: .body) private var iconFrameSize: CGFloat = 36

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            Image(systemName: icon)
                .font(.system(size: iconSize))
                .foregroundColor(iconColor)
                .frame(width: iconFrameSize, height: iconFrameSize)
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
                    .lineLimit(1)
            }

            Spacer()

            if showChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(AppColors.textSecondary)
            }
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.sm + 4)
        .frame(maxWidth: .infinity)
        .frame(minHeight: 44) // Ensure 44pt minimum touch target
        .background(
            RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                .fill(AppColors.cardBackground)
        )
        .opacity(isPlaceholder ? 0.7 : 1.0)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)")
        .accessibilityHint(showChevron ? "Double tap to configure" : "")
    }
}

#Preview {
    TimerView()
        .modelContainer(for: [FocusSession.self, UserStats.self, AppSettings.self])
}
