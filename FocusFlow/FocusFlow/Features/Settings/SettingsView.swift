//
//  SettingsView.swift
//  FocusFlow
//
//  Main settings screen with navigation to various settings sections.
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var appSettingsArray: [AppSettings]

    @State private var showStrictModeSettings = false

    private var appSettings: AppSettings {
        if let existing = appSettingsArray.first {
            return existing
        }
        // Create new settings if none exist
        let newSettings = AppSettings()
        modelContext.insert(newSettings)
        try? modelContext.save()
        return newSettings
    }

    var body: some View {
        NavigationStack {
            List {
                // Strict Mode section
                strictModeSection

                // App Info section
                appInfoSection

                // About section
                aboutSection
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(AppColors.background)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(isPresented: $showStrictModeSettings) {
                StrictModeSettingsView(settings: appSettings)
            }
        }
    }

    // MARK: - Strict Mode Section

    private var strictModeSection: some View {
        Section {
            Button {
                showStrictModeSettings = true
            } label: {
                HStack {
                    Image(systemName: "lock.shield.fill")
                        .foregroundColor(AppColors.accent)
                        .frame(width: 28, height: 28)
                        .background(AppColors.accent.opacity(0.15))
                        .cornerRadius(6)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Strict Mode")
                            .font(.system(size: AppFontSize.body, weight: .medium, design: .rounded))
                            .foregroundColor(AppColors.textPrimary)

                        Text(strictModeStatusText)
                            .font(.system(size: AppFontSize.small, design: .rounded))
                            .foregroundColor(AppColors.textSecondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .foregroundColor(AppColors.textSecondary)
                        .font(.system(size: AppFontSize.caption))
                }
            }
            .listRowBackground(AppColors.cardBackground)
        } header: {
            Text("Focus Settings")
                .foregroundColor(AppColors.textSecondary)
        }
    }

    private var strictModeStatusText: String {
        if appSettings.strictModeDisablePending {
            return "Disabling soon..."
        } else if appSettings.strictModeEnabled {
            return "On - \(appSettings.challengeType.displayName)"
        } else {
            return "Off"
        }
    }

    // MARK: - App Info Section

    private var appInfoSection: some View {
        Section {
            HStack {
                Text("Version")
                    .font(.system(size: AppFontSize.body, design: .rounded))
                    .foregroundColor(AppColors.textPrimary)
                Spacer()
                Text(appVersion)
                    .font(.system(size: AppFontSize.body, design: .rounded))
                    .foregroundColor(AppColors.textSecondary)
            }
            .listRowBackground(AppColors.cardBackground)

            HStack {
                Text("Build")
                    .font(.system(size: AppFontSize.body, design: .rounded))
                    .foregroundColor(AppColors.textPrimary)
                Spacer()
                Text(buildNumber)
                    .font(.system(size: AppFontSize.body, design: .rounded))
                    .foregroundColor(AppColors.textSecondary)
            }
            .listRowBackground(AppColors.cardBackground)
        } header: {
            Text("App Info")
                .foregroundColor(AppColors.textSecondary)
        }
    }

    // MARK: - About Section

    private var aboutSection: some View {
        Section {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                HStack {
                    Image(systemName: "lock.shield.fill")
                        .foregroundColor(AppColors.success)
                    Text("Privacy First")
                        .font(.system(size: AppFontSize.body, weight: .medium, design: .rounded))
                        .foregroundColor(AppColors.textPrimary)
                }

                Text("All your data stays on your device. FocusFlow never connects to the internet and doesn't collect any personal information.")
                    .font(.system(size: AppFontSize.small, design: .rounded))
                    .foregroundColor(AppColors.textSecondary)
            }
            .padding(.vertical, AppSpacing.xs)
            .listRowBackground(AppColors.cardBackground)
        } header: {
            Text("About")
                .foregroundColor(AppColors.textSecondary)
        } footer: {
            Text("FocusFlow helps you stay focused by combining Pomodoro timing with app blocking and psychological friction.")
                .foregroundColor(AppColors.textSecondary)
                .font(.system(size: AppFontSize.small, design: .rounded))
        }
    }

    // MARK: - Helpers

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: [FocusSession.self, UserStats.self, AppSettings.self], inMemory: true)
}
