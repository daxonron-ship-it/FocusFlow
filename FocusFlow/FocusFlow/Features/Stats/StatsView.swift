//
//  StatsView.swift
//  FocusFlow
//
//  Stats dashboard showing session history, streaks, and usage insights.
//

import SwiftUI
import SwiftData

struct StatsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \FocusSession.startTime, order: .reverse) private var allSessions: [FocusSession]
    @Query private var userStatsArray: [UserStats]

    @State private var showSessionHistory = false
    @State private var showWeeklySummary = false
    @State private var showQuitLog = false

    private var userStats: UserStats? {
        userStatsArray.first
    }

    private var thisWeekSessions: [FocusSession] {
        let calendar = Calendar.current
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())) ?? Date()
        return allSessions.filter { $0.startTime >= startOfWeek }
    }

    private var completedSessions: [FocusSession] {
        thisWeekSessions.filter { $0.completionStatus == .completed }
    }

    private var quitSessions: [FocusSession] {
        thisWeekSessions.filter { $0.completionStatus == .quitEarly }
    }

    private var totalFocusTime: TimeInterval {
        completedSessions.reduce(0) { $0 + ($1.actualDuration ?? $1.plannedDuration) }
    }

    private var weeklyQuitRate: Double {
        let total = completedSessions.count + quitSessions.count
        guard total > 0 else { return 0 }
        return Double(quitSessions.count) / Double(total) * 100
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    // Weekly summary card
                    weekSummarySection

                    // Streak section
                    streakSection

                    // Lifetime stats
                    lifetimeStatsSection

                    // Navigation buttons
                    navigationSection
                }
                .padding(AppSpacing.md)
            }
            .background(AppColors.background)
            .navigationTitle("Stats")
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(isPresented: $showSessionHistory) {
                SessionHistoryView()
            }
            .navigationDestination(isPresented: $showWeeklySummary) {
                WeeklySummaryCard()
            }
            .navigationDestination(isPresented: $showQuitLog) {
                QuitLogView()
            }
        }
    }

    // MARK: - Week Summary Section

    private var weekSummarySection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("This Week")
                .font(.system(size: AppFontSize.headline, weight: .semibold, design: .rounded))
                .foregroundColor(AppColors.textPrimary)

            VStack(spacing: AppSpacing.sm) {
                statsRow(title: "Total Focus", value: totalFocusTime.formattedTimeVerbose)
                statsRow(title: "Sessions", value: "\(completedSessions.count)")
                statsRow(title: "Quit Rate", value: String(format: "%.0f%%", weeklyQuitRate))
            }
            .padding(AppSpacing.md)
            .background(AppColors.cardBackground)
            .cornerRadius(AppCornerRadius.large)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("This week summary. Total focus time \(totalFocusTime.formattedTimeVerbose). \(completedSessions.count) sessions completed. Quit rate \(String(format: "%.0f", weeklyQuitRate)) percent.")
    }

    // MARK: - Streak Section

    private var streakSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack(spacing: AppSpacing.md) {
                streakCard(
                    icon: "flame.fill",
                    iconColor: AppColors.accent,
                    title: "Current Streak",
                    value: "\(userStats?.currentStreak ?? 0) days"
                )

                streakCard(
                    icon: "chart.line.uptrend.xyaxis",
                    iconColor: AppColors.success,
                    title: "Longest Streak",
                    value: "\(userStats?.longestStreak ?? 0) days"
                )
            }
        }
    }

    private func streakCard(icon: String, iconColor: Color, title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack(spacing: AppSpacing.xs) {
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                    .font(.system(size: AppFontSize.headline))
                Text(title)
                    .font(.system(size: AppFontSize.caption, weight: .medium, design: .rounded))
                    .foregroundColor(AppColors.textSecondary)
            }

            Text(value)
                .font(.system(size: AppFontSize.headline, weight: .bold, design: .rounded))
                .foregroundColor(AppColors.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.md)
        .background(AppColors.cardBackground)
        .cornerRadius(AppCornerRadius.large)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)")
    }

    // MARK: - Lifetime Stats Section

    private var lifetimeStatsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Lifetime")
                .font(.system(size: AppFontSize.headline, weight: .semibold, design: .rounded))
                .foregroundColor(AppColors.textPrimary)

            VStack(spacing: AppSpacing.sm) {
                HStack {
                    Text("Sessions Completed")
                        .font(.system(size: AppFontSize.body, design: .rounded))
                        .foregroundColor(AppColors.textSecondary)
                    Spacer()
                    HStack(spacing: AppSpacing.xs) {
                        Text("\(userStats?.totalSessionsCompleted ?? 0)")
                            .font(.system(size: AppFontSize.body, weight: .semibold, design: .rounded))
                            .foregroundColor(AppColors.textPrimary)
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(AppColors.success)
                    }
                }

                Divider()
                    .background(AppColors.textSecondary.opacity(0.3))

                HStack {
                    Text("Sessions Quit Early")
                        .font(.system(size: AppFontSize.body, design: .rounded))
                        .foregroundColor(AppColors.textSecondary)
                    Spacer()
                    HStack(spacing: AppSpacing.xs) {
                        Text("\(userStats?.totalSessionsQuit ?? 0)")
                            .font(.system(size: AppFontSize.body, weight: .semibold, design: .rounded))
                            .foregroundColor(AppColors.textPrimary)
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(AppColors.danger)
                    }
                }

                Divider()
                    .background(AppColors.textSecondary.opacity(0.3))

                HStack {
                    Text("Quit Rate")
                        .font(.system(size: AppFontSize.body, design: .rounded))
                        .foregroundColor(AppColors.textSecondary)
                    Spacer()
                    Text(String(format: "%.1f%%", userStats?.quitRate ?? 0))
                        .font(.system(size: AppFontSize.body, weight: .semibold, design: .rounded))
                        .foregroundColor(AppColors.textPrimary)
                }
            }
            .padding(AppSpacing.md)
            .background(AppColors.cardBackground)
            .cornerRadius(AppCornerRadius.large)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Lifetime stats. Sessions completed: \(userStats?.totalSessionsCompleted ?? 0). Sessions quit early: \(userStats?.totalSessionsQuit ?? 0) out of \(((userStats?.totalSessionsCompleted ?? 0) + (userStats?.totalSessionsQuit ?? 0))) total. \(String(format: "%.1f", userStats?.quitRate ?? 0)) percent quit rate.")
    }

    // MARK: - Navigation Section

    private var navigationSection: some View {
        VStack(spacing: AppSpacing.sm) {
            navigationButton(title: "View History", icon: "clock.arrow.circlepath") {
                showSessionHistory = true
            }

            navigationButton(title: "Weekly Summary", icon: "calendar") {
                showWeeklySummary = true
            }

            navigationButton(title: "Quit Log", icon: "exclamationmark.triangle") {
                showQuitLog = true
            }
        }
    }

    private func navigationButton(title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(AppColors.primary)
                    .frame(width: 24)
                Text(title)
                    .font(.system(size: AppFontSize.body, weight: .medium, design: .rounded))
                    .foregroundColor(AppColors.textPrimary)
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(AppColors.textSecondary)
                    .font(.system(size: AppFontSize.caption))
            }
            .padding(AppSpacing.md)
            .background(AppColors.cardBackground)
            .cornerRadius(AppCornerRadius.large)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helper Views

    private func statsRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: AppFontSize.body, design: .rounded))
                .foregroundColor(AppColors.textSecondary)
            Spacer()
            Text(value)
                .font(.system(size: AppFontSize.body, weight: .semibold, design: .rounded))
                .foregroundColor(AppColors.textPrimary)
        }
    }
}

#Preview {
    StatsView()
        .modelContainer(for: [FocusSession.self, UserStats.self, AppSettings.self], inMemory: true)
}
