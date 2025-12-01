import SwiftUI
import SwiftData
import Combine

/// Settings view for Strict Mode configuration
/// Includes challenge type selection and delayed disable functionality
struct StrictModeSettingsView: View {
    @Bindable var settings: AppSettings
    @State private var showDisableConfirmation: Bool = false
    @State private var showBuyersRemorseAlert: Bool = false
    @State private var showEnableConfirmation: Bool = false
    @State private var showStrictModePreview: Bool = false

    /// Track if user has seen the Strict Mode preview
    @AppStorage("hasSeenStrictModePreview") private var hasSeenStrictModePreview: Bool = false

    /// Timer for updating the countdown display
    @State private var refreshTrigger: Bool = false
    private let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    var body: some View {
        List {
            // Strict Mode Toggle Section
            Section {
                strictModeToggle
            } header: {
                Text("Strict Mode")
            } footer: {
                Text("When enabled, you'll need to complete a challenge to quit focus sessions early.")
            }

            // Pending Disable Section (if applicable)
            if settings.strictModeDisablePending {
                pendingDisableSection
            }

            // Challenge Type Section (only show if strict mode is enabled)
            if settings.strictModeEnabled {
                challengeTypeSection

                // Tone Section (only for phrase challenge)
                if settings.challengeType == .phrase {
                    toneSection
                }
            }
        }
        .navigationTitle("Strict Mode")
        .navigationBarTitleDisplayMode(.inline)
        .onReceive(timer) { _ in
            // Trigger refresh to update countdown
            refreshTrigger.toggle()
        }
        .alert("Enable Strict Mode?", isPresented: $showEnableConfirmation) {
            Button("Enable", role: .destructive) {
                enableStrictMode()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Strict Mode adds friction when quitting sessions early. You can disable instantly for the next 15 minutes. After that, disabling takes 24 hours.")
        }
        .alert("Disable Strict Mode?", isPresented: $showBuyersRemorseAlert) {
            Button("Disable Now", role: .destructive) {
                disableStrictModeInstantly()
            }
            Button("Keep Enabled", role: .cancel) {}
        } message: {
            Text("You're still in the 15-minute grace period. This will disable Strict Mode immediately.")
        }
        .alert("24-Hour Cooling Off", isPresented: $showDisableConfirmation) {
            Button("Confirm Disable", role: .destructive) {
                scheduleStrictModeDisable()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Strict Mode will be disabled tomorrow at \(scheduledDisableTimeString). Active sessions will still use Strict Mode until then.")
        }
        .fullScreenCover(isPresented: $showStrictModePreview) {
            StrictModePreview(isPresented: $showStrictModePreview) { challengeType, tone in
                // Apply settings from preview
                settings.challengeType = challengeType
                settings.strictModeTone = tone
                enableStrictMode()
                hasSeenStrictModePreview = true
            }
        }
    }

    // MARK: - Strict Mode Toggle

    @ViewBuilder
    private var strictModeToggle: some View {
        Toggle(isOn: Binding(
            get: { settings.strictModeEnabled },
            set: { newValue in
                if newValue {
                    // Show preview if user hasn't seen it, otherwise show confirmation
                    if !hasSeenStrictModePreview {
                        showStrictModePreview = true
                    } else {
                        showEnableConfirmation = true
                    }
                } else {
                    handleDisableRequest()
                }
            }
        )) {
            HStack {
                Image(systemName: "lock.shield.fill")
                    .foregroundColor(AppColors.accent)
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Strict Mode")
                        .font(.system(size: AppFontSize.body, weight: .medium))

                    if settings.strictModeEnabled {
                        if settings.isInBuyersRemorseWindow {
                            Text("Can disable instantly for \(buyersRemorseRemainingTime)")
                                .font(.system(size: AppFontSize.small))
                                .foregroundColor(AppColors.success)
                        } else {
                            Text("Active")
                                .font(.system(size: AppFontSize.small))
                                .foregroundColor(AppColors.textSecondary)
                        }
                    }
                }
            }
        }
        .tint(AppColors.accent)
    }

    // MARK: - Pending Disable Section

    @ViewBuilder
    private var pendingDisableSection: some View {
        Section {
            HStack {
                Image(systemName: "clock.fill")
                    .foregroundColor(AppColors.accent)
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Disabling in \(pendingDisableRemainingTime)")
                        .font(.system(size: AppFontSize.body, weight: .medium))

                    if let disableTime = settings.strictModeDisableTime {
                        Text("Will disable at \(formattedTime(disableTime))")
                            .font(.system(size: AppFontSize.small))
                            .foregroundColor(AppColors.textSecondary)
                    }
                }

                Spacer()
            }

            Button(action: cancelPendingDisable) {
                HStack {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(AppColors.danger)
                        .frame(width: 28)

                    Text("Cancel Disable")
                        .foregroundColor(AppColors.danger)
                }
            }
        } header: {
            Text("Pending Disable")
        }
    }

    // MARK: - Challenge Type Section

    @ViewBuilder
    private var challengeTypeSection: some View {
        Section {
            ForEach(ChallengeType.allCases, id: \.self) { type in
                Button(action: {
                    withAnimation {
                        settings.challengeType = type
                    }
                    HapticManager.shared.selectionChanged()
                }) {
                    HStack {
                        Image(systemName: challengeTypeIcon(for: type))
                            .foregroundColor(settings.challengeType == type ? AppColors.accent : AppColors.textSecondary)
                            .frame(width: 28)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(type.displayName)
                                .font(.system(size: AppFontSize.body, weight: .medium))
                                .foregroundColor(AppColors.textPrimary)

                            Text(challengeTypeDescription(for: type))
                                .font(.system(size: AppFontSize.small))
                                .foregroundColor(AppColors.textSecondary)
                        }

                        Spacer()

                        if settings.challengeType == type {
                            Image(systemName: "checkmark")
                                .foregroundColor(AppColors.accent)
                                .font(.system(size: AppFontSize.body, weight: .semibold))
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        } header: {
            Text("Challenge Type")
        } footer: {
            Text("Choose the challenge you'll complete when trying to quit a session early.")
        }
    }

    // MARK: - Tone Section (for phrase challenge)

    @ViewBuilder
    private var toneSection: some View {
        Section {
            ForEach(StrictModeTone.allCases.filter { $0 != .custom }, id: \.self) { tone in
                Button(action: {
                    withAnimation {
                        settings.strictModeTone = tone
                    }
                    HapticManager.shared.selectionChanged()
                }) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(toneName(for: tone))
                                .font(.system(size: AppFontSize.body, weight: .medium))
                                .foregroundColor(AppColors.textPrimary)

                            Text(toneExample(for: tone))
                                .font(.system(size: AppFontSize.small))
                                .foregroundColor(AppColors.textSecondary)
                                .italic()
                        }

                        Spacer()

                        if settings.strictModeTone == tone {
                            Image(systemName: "checkmark")
                                .foregroundColor(AppColors.accent)
                                .font(.system(size: AppFontSize.body, weight: .semibold))
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        } header: {
            Text("Phrase Tone")
        } footer: {
            Text("Choose the tone for the phrase you'll type when quitting.")
        }
    }

    // MARK: - Helper Functions

    private func handleDisableRequest() {
        if settings.isInBuyersRemorseWindow {
            showBuyersRemorseAlert = true
        } else {
            showDisableConfirmation = true
        }
    }

    private func enableStrictMode() {
        settings.strictModeEnabled = true
        settings.strictModeEnabledAt = Date()
        settings.strictModeDisablePending = false
        settings.strictModeDisableTime = nil
        HapticManager.shared.success()
    }

    private func disableStrictModeInstantly() {
        settings.strictModeEnabled = false
        settings.strictModeEnabledAt = nil
        settings.strictModeDisablePending = false
        settings.strictModeDisableTime = nil
        HapticManager.shared.mediumImpact()
    }

    private func scheduleStrictModeDisable() {
        settings.strictModeDisablePending = true
        settings.strictModeDisableTime = Date().addingTimeInterval(24 * 60 * 60)
        HapticManager.shared.mediumImpact()
    }

    private func cancelPendingDisable() {
        settings.strictModeDisablePending = false
        settings.strictModeDisableTime = nil
        HapticManager.shared.lightTap()
    }

    // MARK: - Formatting

    private var scheduledDisableTimeString: String {
        let disableTime = Date().addingTimeInterval(24 * 60 * 60)
        return formattedTime(disableTime)
    }

    private var buyersRemorseRemainingTime: String {
        guard let enabledAt = settings.strictModeEnabledAt else { return "0m" }
        let elapsed = Date().timeIntervalSince(enabledAt)
        let remaining = max(0, 15 * 60 - elapsed)
        let minutes = Int(remaining / 60)
        return "\(minutes)m"
    }

    private var pendingDisableRemainingTime: String {
        guard let disableTime = settings.strictModeDisableTime else { return "Unknown" }
        let remaining = max(0, disableTime.timeIntervalSinceNow)
        let hours = Int(remaining / 3600)
        let minutes = Int((remaining.truncatingRemainder(dividingBy: 3600)) / 60)

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }

    private func formattedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter.string(from: date)
    }

    private func challengeTypeIcon(for type: ChallengeType) -> String {
        switch type {
        case .phrase: return "text.cursor"
        case .math: return "number.circle"
        case .pattern: return "circle.grid.3x3"
        case .holdButton: return "hand.point.up.fill"
        }
    }

    private func challengeTypeDescription(for type: ChallengeType) -> String {
        switch type {
        case .phrase: return "Type a phrase exactly"
        case .math: return "Solve a math problem"
        case .pattern: return "Tap circles in order"
        case .holdButton: return "Hold for 5 seconds"
        }
    }

    private func toneName(for tone: StrictModeTone) -> String {
        switch tone {
        case .gentle: return "Gentle"
        case .neutral: return "Neutral"
        case .strict: return "Strict"
        case .custom: return "Custom"
        }
    }

    private func toneExample(for tone: StrictModeTone) -> String {
        switch tone {
        case .gentle: return "\"I need a break right now\""
        case .neutral: return "\"End session early\""
        case .strict: return "\"I am choosing distraction...\""
        case .custom: return settings.customChallengePhrase ?? "Custom phrase"
        }
    }
}

#Preview {
    NavigationStack {
        StrictModeSettingsView(
            settings: AppSettings(strictModeEnabled: true)
        )
    }
}

#Preview("Pending Disable") {
    NavigationStack {
        StrictModeSettingsView(
            settings: AppSettings(
                strictModeEnabled: true,
                strictModeDisablePending: true,
                strictModeDisableTime: Date().addingTimeInterval(12 * 60 * 60)
            )
        )
    }
}
