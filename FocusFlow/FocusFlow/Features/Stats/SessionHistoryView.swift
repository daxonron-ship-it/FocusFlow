//
//  SessionHistoryView.swift
//  FocusFlow
//
//  Chronological list of all focus sessions with filtering capabilities.
//

import SwiftUI
import SwiftData

enum SessionFilter: String, CaseIterable {
    case all = "All"
    case completed = "Completed"
    case quit = "Quit"

    var predicate: ((FocusSession) -> Bool) {
        switch self {
        case .all:
            return { $0.completionStatus == .completed || $0.completionStatus == .quitEarly }
        case .completed:
            return { $0.completionStatus == .completed }
        case .quit:
            return { $0.completionStatus == .quitEarly }
        }
    }
}

enum TimeFilter: String, CaseIterable {
    case week = "This Week"
    case month = "This Month"
    case all = "All Time"

    var startDate: Date? {
        let calendar = Calendar.current
        switch self {
        case .week:
            return calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date()))
        case .month:
            return calendar.date(from: calendar.dateComponents([.year, .month], from: Date()))
        case .all:
            return nil
        }
    }
}

struct SessionHistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \FocusSession.startTime, order: .reverse) private var allSessions: [FocusSession]

    @State private var sessionFilter: SessionFilter = .all
    @State private var timeFilter: TimeFilter = .week
    @State private var selectedSession: FocusSession?

    private var filteredSessions: [FocusSession] {
        var sessions = allSessions.filter(sessionFilter.predicate)

        if let startDate = timeFilter.startDate {
            sessions = sessions.filter { $0.startTime >= startDate }
        }

        return sessions
    }

    private var groupedSessions: [(String, [FocusSession])] {
        let grouped = Dictionary(grouping: filteredSessions) { session -> String in
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
            return formatter.string(from: session.startTime)
        }

        return grouped.sorted { first, second in
            guard let firstSession = first.value.first,
                  let secondSession = second.value.first else { return false }
            return firstSession.startTime > secondSession.startTime
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Filter pills
            filterSection

            if filteredSessions.isEmpty {
                emptyStateView
            } else {
                sessionList
            }
        }
        .background(AppColors.background)
        .navigationTitle("Session History")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedSession) { session in
            SessionDetailSheet(session: session)
        }
    }

    // MARK: - Filter Section

    private var filterSection: some View {
        VStack(spacing: AppSpacing.sm) {
            // Session type filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSpacing.sm) {
                    ForEach(SessionFilter.allCases, id: \.self) { filter in
                        FilterPill(
                            title: filter.rawValue,
                            isSelected: sessionFilter == filter
                        ) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                sessionFilter = filter
                            }
                        }
                    }
                }
                .padding(.horizontal, AppSpacing.md)
            }

            // Time filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSpacing.sm) {
                    ForEach(TimeFilter.allCases, id: \.self) { filter in
                        FilterPill(
                            title: filter.rawValue,
                            isSelected: timeFilter == filter
                        ) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                timeFilter = filter
                            }
                        }
                    }
                }
                .padding(.horizontal, AppSpacing.md)
            }
        }
        .padding(.vertical, AppSpacing.sm)
        .background(AppColors.secondaryBackground)
    }

    // MARK: - Session List

    private var sessionList: some View {
        ScrollView {
            LazyVStack(spacing: AppSpacing.md, pinnedViews: [.sectionHeaders]) {
                ForEach(groupedSessions, id: \.0) { dateString, sessions in
                    Section {
                        ForEach(sessions) { session in
                            SessionRowView(session: session)
                                .onTapGesture {
                                    selectedSession = session
                                }
                        }
                    } header: {
                        sectionHeader(dateString)
                    }
                }
            }
            .padding(AppSpacing.md)
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: AppFontSize.caption, weight: .semibold, design: .rounded))
                .foregroundColor(AppColors.textSecondary)
            Spacer()
        }
        .padding(.vertical, AppSpacing.xs)
        .background(AppColors.background)
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: AppSpacing.md) {
            Spacer()

            Image(systemName: "clock.badge.questionmark")
                .font(.system(size: 48))
                .foregroundColor(AppColors.textSecondary)

            Text("No Sessions Found")
                .font(.system(size: AppFontSize.headline, weight: .semibold, design: .rounded))
                .foregroundColor(AppColors.textPrimary)

            Text("Complete a focus session to see it here.")
                .font(.system(size: AppFontSize.body, design: .rounded))
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)

            Spacer()
        }
        .padding(AppSpacing.xl)
    }
}

// MARK: - Filter Pill

struct FilterPill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: AppFontSize.caption, weight: .medium, design: .rounded))
                .foregroundColor(isSelected ? AppColors.textPrimary : AppColors.textSecondary)
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, AppSpacing.sm)
                .background(isSelected ? AppColors.primary : AppColors.cardBackground)
                .cornerRadius(AppCornerRadius.medium)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Session Detail Sheet

struct SessionDetailSheet: View {
    let session: FocusSession
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    // Status header
                    statusHeader

                    // Time details
                    timeDetailsSection

                    // Session info
                    sessionInfoSection

                    if session.completionStatus == .quitEarly {
                        quitDetailsSection
                    }
                }
                .padding(AppSpacing.lg)
            }
            .background(AppColors.background)
            .navigationTitle("Session Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(AppColors.primary)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private var statusHeader: some View {
        HStack(spacing: AppSpacing.md) {
            Circle()
                .fill(session.completionStatus == .completed ? AppColors.success : AppColors.danger)
                .frame(width: 12, height: 12)

            Text(session.completionStatus == .completed ? "Completed" : "Quit Early")
                .font(.system(size: AppFontSize.headline, weight: .semibold, design: .rounded))
                .foregroundColor(AppColors.textPrimary)

            Spacer()

            Image(systemName: session.completionStatus == .completed ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(session.completionStatus == .completed ? AppColors.success : AppColors.danger)
                .font(.system(size: 24))
        }
        .padding(AppSpacing.md)
        .background(AppColors.cardBackground)
        .cornerRadius(AppCornerRadius.large)
    }

    private var timeDetailsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Time")
                .font(.system(size: AppFontSize.caption, weight: .semibold, design: .rounded))
                .foregroundColor(AppColors.textSecondary)

            VStack(spacing: AppSpacing.sm) {
                detailRow(title: "Date", value: formatDate(session.startTime))
                detailRow(title: "Started", value: formatTime(session.startTime))
                detailRow(title: "Planned Duration", value: session.plannedDuration.formattedTimeVerbose)

                if let actualDuration = session.actualDuration {
                    detailRow(title: "Actual Duration", value: actualDuration.formattedTimeVerbose)
                }
            }
            .padding(AppSpacing.md)
            .background(AppColors.cardBackground)
            .cornerRadius(AppCornerRadius.large)
        }
    }

    private var sessionInfoSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Session Info")
                .font(.system(size: AppFontSize.caption, weight: .semibold, design: .rounded))
                .foregroundColor(AppColors.textSecondary)

            VStack(spacing: AppSpacing.sm) {
                detailRow(title: "Type", value: session.sessionType.displayName)
                detailRow(title: "Strict Mode", value: session.strictModeEnabled ? "Enabled" : "Disabled")
            }
            .padding(AppSpacing.md)
            .background(AppColors.cardBackground)
            .cornerRadius(AppCornerRadius.large)
        }
    }

    private var quitDetailsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Quit Details")
                .font(.system(size: AppFontSize.caption, weight: .semibold, design: .rounded))
                .foregroundColor(AppColors.textSecondary)

            VStack(spacing: AppSpacing.sm) {
                if let quitTime = session.quitTimestamp {
                    detailRow(title: "Quit At", value: formatTime(quitTime))

                    let timeIntoSession = quitTime.timeIntervalSince(session.startTime)
                    detailRow(title: "Time Into Session", value: timeIntoSession.formattedTime)
                }

                if let phrase = session.challengePhraseUsed {
                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        Text("Challenge Phrase")
                            .font(.system(size: AppFontSize.body, design: .rounded))
                            .foregroundColor(AppColors.textSecondary)
                        Text("\"\(phrase)\"")
                            .font(.system(size: AppFontSize.body, weight: .medium, design: .rounded))
                            .foregroundColor(AppColors.textPrimary)
                            .italic()
                    }
                }
            }
            .padding(AppSpacing.md)
            .background(AppColors.cardBackground)
            .cornerRadius(AppCornerRadius.large)
        }
    }

    private func detailRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: AppFontSize.body, design: .rounded))
                .foregroundColor(AppColors.textSecondary)
            Spacer()
            Text(value)
                .font(.system(size: AppFontSize.body, weight: .medium, design: .rounded))
                .foregroundColor(AppColors.textPrimary)
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

#Preview {
    NavigationStack {
        SessionHistoryView()
            .modelContainer(for: [FocusSession.self, UserStats.self, AppSettings.self], inMemory: true)
    }
}
