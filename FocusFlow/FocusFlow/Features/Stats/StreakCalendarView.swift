//
//  StreakCalendarView.swift
//  FocusFlow
//
//  Visual calendar showing completion status for each day.
//  Legend: checkmark (green) = completed, X (red) = quit only, dot (blue) = today
//

import SwiftUI
import SwiftData

struct StreakCalendarView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \FocusSession.startTime, order: .reverse) private var allSessions: [FocusSession]

    @State private var currentMonth: Date = Date()

    private let calendar = Calendar.current
    private let daysOfWeek = ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"]
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)

    private var monthString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: currentMonth)
    }

    private var daysInMonth: [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: currentMonth),
              let firstWeekday = calendar.dateComponents([.weekday], from: monthInterval.start).weekday else {
            return []
        }

        var days: [Date?] = []

        // Add empty days for padding at start
        let paddingDays = firstWeekday - 1
        days.append(contentsOf: Array(repeating: nil as Date?, count: paddingDays))

        // Add actual days
        var currentDate = monthInterval.start
        while currentDate < monthInterval.end {
            days.append(currentDate)
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }

        return days
    }

    private func sessionsForDay(_ date: Date) -> [FocusSession] {
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? startOfDay

        return allSessions.filter { session in
            session.startTime >= startOfDay && session.startTime < endOfDay &&
            (session.completionStatus == .completed || session.completionStatus == .quitEarly)
        }
    }

    private func dayStatus(for date: Date) -> DayStatus {
        let today = calendar.startOfDay(for: Date())
        let dayStart = calendar.startOfDay(for: date)

        if dayStart == today {
            return .today
        }

        if dayStart > today {
            return .future
        }

        let sessions = sessionsForDay(date)
        if sessions.isEmpty {
            return .noActivity
        }

        let hasCompleted = sessions.contains { $0.completionStatus == .completed }
        if hasCompleted {
            return .completed
        }

        return .quitOnly
    }

    var body: some View {
        VStack(spacing: AppSpacing.md) {
            // Month navigation
            monthNavigationHeader

            // Day of week headers
            dayOfWeekHeader

            // Calendar grid
            calendarGrid

            // Legend
            legendView
        }
        .padding(AppSpacing.md)
        .background(AppColors.cardBackground)
        .cornerRadius(AppCornerRadius.large)
    }

    // MARK: - Month Navigation

    private var monthNavigationHeader: some View {
        HStack {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    currentMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
                }
            } label: {
                Image(systemName: "chevron.left")
                    .foregroundColor(AppColors.primary)
                    .frame(width: 44, height: 44)
            }

            Spacer()

            Text(monthString)
                .font(.system(size: AppFontSize.headline, weight: .semibold, design: .rounded))
                .foregroundColor(AppColors.textPrimary)

            Spacer()

            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    currentMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
                }
            } label: {
                Image(systemName: "chevron.right")
                    .foregroundColor(canGoForward ? AppColors.primary : AppColors.textSecondary.opacity(0.3))
                    .frame(width: 44, height: 44)
            }
            .disabled(!canGoForward)
        }
    }

    private var canGoForward: Bool {
        let thisMonth = calendar.dateComponents([.year, .month], from: Date())
        let displayMonth = calendar.dateComponents([.year, .month], from: currentMonth)
        return displayMonth.year! < thisMonth.year! ||
               (displayMonth.year! == thisMonth.year! && displayMonth.month! < thisMonth.month!)
    }

    // MARK: - Day of Week Header

    private var dayOfWeekHeader: some View {
        HStack(spacing: 0) {
            ForEach(daysOfWeek, id: \.self) { day in
                Text(day)
                    .font(.system(size: AppFontSize.small, weight: .medium, design: .rounded))
                    .foregroundColor(AppColors.textSecondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Calendar Grid

    private var calendarGrid: some View {
        LazyVGrid(columns: columns, spacing: AppSpacing.xs) {
            ForEach(Array(daysInMonth.enumerated()), id: \.offset) { _, date in
                if let date = date {
                    CalendarDayCell(date: date, status: dayStatus(for: date))
                } else {
                    Color.clear
                        .frame(height: 36)
                }
            }
        }
    }

    // MARK: - Legend

    private var legendView: some View {
        HStack(spacing: AppSpacing.lg) {
            legendItem(color: AppColors.success, text: "Completed")
            legendItem(color: AppColors.danger, text: "Quit Only")
            legendItem(color: AppColors.primary, text: "Today")
        }
        .padding(.top, AppSpacing.sm)
    }

    private func legendItem(color: Color, text: String) -> some View {
        HStack(spacing: AppSpacing.xs) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(text)
                .font(.system(size: AppFontSize.small, design: .rounded))
                .foregroundColor(AppColors.textSecondary)
        }
    }
}

// MARK: - Day Status

enum DayStatus {
    case completed
    case quitOnly
    case noActivity
    case today
    case future
}

// MARK: - Calendar Day Cell

struct CalendarDayCell: View {
    let date: Date
    let status: DayStatus

    private let calendar = Calendar.current

    private var dayNumber: Int {
        calendar.component(.day, from: date)
    }

    private var backgroundColor: Color {
        switch status {
        case .completed:
            return AppColors.success.opacity(0.2)
        case .quitOnly:
            return AppColors.danger.opacity(0.2)
        case .today:
            return AppColors.primary.opacity(0.3)
        default:
            return Color.clear
        }
    }

    private var textColor: Color {
        switch status {
        case .completed:
            return AppColors.success
        case .quitOnly:
            return AppColors.danger
        case .today:
            return AppColors.primary
        case .future:
            return AppColors.textSecondary.opacity(0.3)
        case .noActivity:
            return AppColors.textSecondary
        }
    }

    private var icon: String? {
        switch status {
        case .completed:
            return "checkmark"
        case .quitOnly:
            return "xmark"
        case .today:
            return nil
        default:
            return nil
        }
    }

    var body: some View {
        VStack(spacing: 2) {
            Text("\(dayNumber)")
                .font(.system(size: AppFontSize.caption, weight: status == .today ? .bold : .regular, design: .rounded))
                .foregroundColor(textColor)

            if let iconName = icon {
                Image(systemName: iconName)
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(textColor)
            } else if status == .today {
                Circle()
                    .fill(AppColors.primary)
                    .frame(width: 4, height: 4)
            } else {
                Color.clear
                    .frame(width: 4, height: 4)
            }
        }
        .frame(height: 36)
        .frame(maxWidth: .infinity)
        .background(backgroundColor)
        .cornerRadius(AppCornerRadius.small)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
    }

    private var accessibilityDescription: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long

        var description = formatter.string(from: date)

        switch status {
        case .completed:
            description += ", completed session"
        case .quitOnly:
            description += ", quit session"
        case .today:
            description += ", today"
        case .future:
            description += ", future"
        case .noActivity:
            description += ", no activity"
        }

        return description
    }
}

#Preview {
    ScrollView {
        StreakCalendarView()
            .padding()
    }
    .background(AppColors.background)
    .modelContainer(for: [FocusSession.self, UserStats.self, AppSettings.self], inMemory: true)
}
