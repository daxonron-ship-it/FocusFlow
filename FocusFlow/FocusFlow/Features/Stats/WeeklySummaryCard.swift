//
//  WeeklySummaryCard.swift
//  FocusFlow
//
//  Weekly summary view showing key metrics with trend comparison.
//

import SwiftUI
import SwiftData

struct WeeklySummaryCard: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \FocusSession.startTime, order: .reverse) private var allSessions: [FocusSession]

    @State private var selectedWeekOffset: Int = 0

    private let calendar = Calendar.current

    // MARK: - Date Range Calculations

    private var currentWeekStart: Date {
        let today = Date()
        let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)) ?? today
        return calendar.date(byAdding: .weekOfYear, value: -selectedWeekOffset, to: weekStart) ?? weekStart
    }

    private var currentWeekEnd: Date {
        calendar.date(byAdding: .day, value: 7, to: currentWeekStart) ?? currentWeekStart
    }

    private var previousWeekStart: Date {
        calendar.date(byAdding: .weekOfYear, value: -1, to: currentWeekStart) ?? currentWeekStart
    }

    private var previousWeekEnd: Date {
        currentWeekStart
    }

    private var weekRangeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        let start = formatter.string(from: currentWeekStart)
        let end = formatter.string(from: calendar.date(byAdding: .day, value: 6, to: currentWeekStart) ?? currentWeekStart)
        return "Week of \(start) - \(end)"
    }

    // MARK: - Session Filtering

    private var thisWeekSessions: [FocusSession] {
        allSessions.filter { session in
            session.startTime >= currentWeekStart &&
            session.startTime < currentWeekEnd &&
            (session.completionStatus == .completed || session.completionStatus == .quitEarly)
        }
    }

    private var lastWeekSessions: [FocusSession] {
        allSessions.filter { session in
            session.startTime >= previousWeekStart &&
            session.startTime < previousWeekEnd &&
            (session.completionStatus == .completed || session.completionStatus == .quitEarly)
        }
    }

    // MARK: - Weekly Stats

    private var thisWeekCompleted: [FocusSession] {
        thisWeekSessions.filter { $0.completionStatus == .completed }
    }

    private var thisWeekQuit: [FocusSession] {
        thisWeekSessions.filter { $0.completionStatus == .quitEarly }
    }

    private var lastWeekCompleted: [FocusSession] {
        lastWeekSessions.filter { $0.completionStatus == .completed }
    }

    private var lastWeekQuit: [FocusSession] {
        lastWeekSessions.filter { $0.completionStatus == .quitEarly }
    }

    private var totalFocusTime: TimeInterval {
        thisWeekCompleted.reduce(0) { $0 + ($1.actualDuration ?? $1.plannedDuration) }
    }

    private var quitRate: Double {
        let total = thisWeekCompleted.count + thisWeekQuit.count
        guard total > 0 else { return 0 }
        return Double(thisWeekQuit.count) / Double(total) * 100
    }

    private var lastWeekQuitRate: Double {
        let total = lastWeekCompleted.count + lastWeekQuit.count
        guard total > 0 else { return 0 }
        return Double(lastWeekQuit.count) / Double(total) * 100
    }

    private var quitRateTrend: Double {
        quitRate - lastWeekQuitRate
    }

    private var mostProductiveDay: String? {
        let grouped = Dictionary(grouping: thisWeekCompleted) { session -> Int in
            calendar.component(.weekday, from: session.startTime)
        }

        let dayWithMostFocus = grouped.max { first, second in
            let firstTotal = first.value.reduce(0) { $0 + ($1.actualDuration ?? $1.plannedDuration) }
            let secondTotal = second.value.reduce(0) { $0 + ($1.actualDuration ?? $1.plannedDuration) }
            return firstTotal < secondTotal
        }

        guard let day = dayWithMostFocus?.key else { return nil }

        let formatter = DateFormatter()
        formatter.weekdaySymbols = formatter.weekdaySymbols
        return formatter.weekdaySymbols[day - 1]
    }

    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.lg) {
                // Week navigation
                weekNavigationHeader

                // Main stats card
                mainStatsCard

                // Trend indicators
                trendSection

                // Calendar view
                calendarSection
            }
            .padding(AppSpacing.md)
        }
        .background(AppColors.background)
        .navigationTitle("Weekly Summary")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Week Navigation

    private var weekNavigationHeader: some View {
        HStack {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    selectedWeekOffset += 1
                }
            } label: {
                Image(systemName: "chevron.left")
                    .foregroundColor(AppColors.primary)
                    .frame(width: 44, height: 44)
            }

            Spacer()

            Text(weekRangeString)
                .font(.system(size: AppFontSize.headline, weight: .semibold, design: .rounded))
                .foregroundColor(AppColors.textPrimary)

            Spacer()

            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    selectedWeekOffset = max(0, selectedWeekOffset - 1)
                }
            } label: {
                Image(systemName: "chevron.right")
                    .foregroundColor(selectedWeekOffset > 0 ? AppColors.primary : AppColors.textSecondary.opacity(0.3))
                    .frame(width: 44, height: 44)
            }
            .disabled(selectedWeekOffset == 0)
        }
        .padding(.horizontal, AppSpacing.sm)
    }

    // MARK: - Main Stats Card

    private var mainStatsCard: some View {
        VStack(spacing: AppSpacing.md) {
            // Total focus time - hero stat
            VStack(spacing: AppSpacing.xs) {
                Text("Total Focus Time")
                    .font(.system(size: AppFontSize.caption, weight: .medium, design: .rounded))
                    .foregroundColor(AppColors.textSecondary)

                Text(formatFocusTime(totalFocusTime))
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.textPrimary)
            }
            .padding(.vertical, AppSpacing.md)

            Divider()
                .background(AppColors.textSecondary.opacity(0.3))

            // Stats grid
            HStack(spacing: AppSpacing.lg) {
                statColumn(title: "Completed", value: "\(thisWeekCompleted.count)", icon: "checkmark.circle.fill", color: AppColors.success)

                Divider()
                    .frame(height: 40)
                    .background(AppColors.textSecondary.opacity(0.3))

                statColumn(title: "Quit", value: "\(thisWeekQuit.count)", icon: "xmark.circle.fill", color: AppColors.danger)

                Divider()
                    .frame(height: 40)
                    .background(AppColors.textSecondary.opacity(0.3))

                statColumn(title: "Quit Rate", value: String(format: "%.0f%%", quitRate), icon: "percent", color: AppColors.accent)
            }
        }
        .padding(AppSpacing.lg)
        .background(AppColors.cardBackground)
        .cornerRadius(AppCornerRadius.large)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Weekly summary. Total focus time \(formatFocusTime(totalFocusTime)). \(thisWeekCompleted.count) sessions completed. \(thisWeekQuit.count) sessions quit. \(String(format: "%.0f", quitRate)) percent quit rate.")
    }

    private func statColumn(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: AppSpacing.xs) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.system(size: 16))

            Text(value)
                .font(.system(size: AppFontSize.headline, weight: .bold, design: .rounded))
                .foregroundColor(AppColors.textPrimary)

            Text(title)
                .font(.system(size: AppFontSize.small, design: .rounded))
                .foregroundColor(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Trend Section

    private var trendSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Insights")
                .font(.system(size: AppFontSize.caption, weight: .semibold, design: .rounded))
                .foregroundColor(AppColors.textSecondary)

            VStack(spacing: AppSpacing.sm) {
                // Quit rate trend
                trendRow(
                    title: "Quit Rate vs Last Week",
                    trend: quitRateTrend,
                    isLowerBetter: true
                )

                if let productiveDay = mostProductiveDay {
                    HStack {
                        Image(systemName: "star.fill")
                            .foregroundColor(AppColors.accent)
                            .font(.system(size: 14))

                        Text("Most Productive Day")
                            .font(.system(size: AppFontSize.body, design: .rounded))
                            .foregroundColor(AppColors.textSecondary)

                        Spacer()

                        Text(productiveDay)
                            .font(.system(size: AppFontSize.body, weight: .semibold, design: .rounded))
                            .foregroundColor(AppColors.textPrimary)
                    }
                }
            }
            .padding(AppSpacing.md)
            .background(AppColors.cardBackground)
            .cornerRadius(AppCornerRadius.large)
        }
    }

    private func trendRow(title: String, trend: Double, isLowerBetter: Bool) -> some View {
        HStack {
            Image(systemName: trendIcon(for: trend, isLowerBetter: isLowerBetter))
                .foregroundColor(trendColor(for: trend, isLowerBetter: isLowerBetter))
                .font(.system(size: 14))

            Text(title)
                .font(.system(size: AppFontSize.body, design: .rounded))
                .foregroundColor(AppColors.textSecondary)

            Spacer()

            Text(trendString(for: trend))
                .font(.system(size: AppFontSize.body, weight: .semibold, design: .rounded))
                .foregroundColor(trendColor(for: trend, isLowerBetter: isLowerBetter))
        }
    }

    private func trendIcon(for trend: Double, isLowerBetter: Bool) -> String {
        if abs(trend) < 0.1 {
            return "minus"
        }
        let isImproving = isLowerBetter ? trend < 0 : trend > 0
        return isImproving ? "arrow.down.right" : "arrow.up.right"
    }

    private func trendColor(for trend: Double, isLowerBetter: Bool) -> Color {
        if abs(trend) < 0.1 {
            return AppColors.textSecondary
        }
        let isImproving = isLowerBetter ? trend < 0 : trend > 0
        return isImproving ? AppColors.success : AppColors.danger
    }

    private func trendString(for trend: Double) -> String {
        if abs(trend) < 0.1 {
            return "No change"
        }
        let sign = trend > 0 ? "+" : ""
        return "\(sign)\(String(format: "%.1f", trend))%"
    }

    // MARK: - Calendar Section

    private var calendarSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Activity Calendar")
                .font(.system(size: AppFontSize.caption, weight: .semibold, design: .rounded))
                .foregroundColor(AppColors.textSecondary)

            StreakCalendarView()
        }
    }

    // MARK: - Helpers

    private func formatFocusTime(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

#Preview {
    NavigationStack {
        WeeklySummaryCard()
            .modelContainer(for: [FocusSession.self, UserStats.self, AppSettings.self], inMemory: true)
    }
}
