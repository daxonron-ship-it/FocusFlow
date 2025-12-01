//
//  QuitLogView.swift
//  FocusFlow
//
//  Detailed view showing all quit sessions for failure analysis.
//

import SwiftUI
import SwiftData

struct QuitLogView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \FocusSession.startTime, order: .reverse) private var allSessions: [FocusSession]

    private var quitSessions: [FocusSession] {
        allSessions.filter { $0.completionStatus == .quitEarly }
    }

    private let calendar = Calendar.current

    private var groupedSessions: [(String, [FocusSession])] {
        let grouped = Dictionary(grouping: quitSessions) { session -> String in
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

    // Pattern analysis
    private var quitsByTimeOfDay: [String: Int] {
        var counts: [String: Int] = ["Morning": 0, "Afternoon": 0, "Evening": 0, "Night": 0]

        for session in quitSessions {
            let hour = calendar.component(.hour, from: session.startTime)
            let period: String
            switch hour {
            case 5..<12: period = "Morning"
            case 12..<17: period = "Afternoon"
            case 17..<21: period = "Evening"
            default: period = "Night"
            }
            counts[period, default: 0] += 1
        }

        return counts
    }

    private var mostCommonQuitTime: String? {
        quitsByTimeOfDay.max { $0.value < $1.value }?.key
    }

    private var averageQuitPercentage: Double {
        guard !quitSessions.isEmpty else { return 0 }

        let percentages = quitSessions.compactMap { session -> Double? in
            guard let actualDuration = session.actualDuration else { return nil }
            return (actualDuration / session.plannedDuration) * 100
        }

        guard !percentages.isEmpty else { return 0 }
        return percentages.reduce(0, +) / Double(percentages.count)
    }

    var body: some View {
        VStack(spacing: 0) {
            if quitSessions.isEmpty {
                emptyStateView
            } else {
                ScrollView {
                    VStack(spacing: AppSpacing.lg) {
                        // Pattern insights
                        patternInsightsCard

                        // Quit list
                        quitListSection
                    }
                    .padding(AppSpacing.md)
                }
            }
        }
        .background(AppColors.background)
        .navigationTitle("Quit Log")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Pattern Insights

    private var patternInsightsCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Pattern Analysis")
                .font(.system(size: AppFontSize.caption, weight: .semibold, design: .rounded))
                .foregroundColor(AppColors.textSecondary)

            VStack(spacing: AppSpacing.sm) {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(AppColors.danger)
                        .font(.system(size: 14))
                    Text("Total Quit Sessions")
                        .font(.system(size: AppFontSize.body, design: .rounded))
                        .foregroundColor(AppColors.textSecondary)
                    Spacer()
                    Text("\(quitSessions.count)")
                        .font(.system(size: AppFontSize.body, weight: .semibold, design: .rounded))
                        .foregroundColor(AppColors.textPrimary)
                }

                Divider()
                    .background(AppColors.textSecondary.opacity(0.3))

                HStack {
                    Image(systemName: "percent")
                        .foregroundColor(AppColors.accent)
                        .font(.system(size: 14))
                    Text("Avg. Progress Before Quit")
                        .font(.system(size: AppFontSize.body, design: .rounded))
                        .foregroundColor(AppColors.textSecondary)
                    Spacer()
                    Text(String(format: "%.0f%%", averageQuitPercentage))
                        .font(.system(size: AppFontSize.body, weight: .semibold, design: .rounded))
                        .foregroundColor(AppColors.textPrimary)
                }

                if let commonTime = mostCommonQuitTime, quitsByTimeOfDay[commonTime] ?? 0 > 1 {
                    Divider()
                        .background(AppColors.textSecondary.opacity(0.3))

                    HStack {
                        Image(systemName: "clock.fill")
                            .foregroundColor(AppColors.primary)
                            .font(.system(size: 14))
                        Text("Most Common Quit Time")
                            .font(.system(size: AppFontSize.body, design: .rounded))
                            .foregroundColor(AppColors.textSecondary)
                        Spacer()
                        Text(commonTime)
                            .font(.system(size: AppFontSize.body, weight: .semibold, design: .rounded))
                            .foregroundColor(AppColors.textPrimary)
                    }
                }
            }
            .padding(AppSpacing.md)
            .background(AppColors.cardBackground)
            .cornerRadius(AppCornerRadius.large)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Pattern analysis. Total quit sessions: \(quitSessions.count). Average progress before quit: \(String(format: "%.0f", averageQuitPercentage)) percent.")
    }

    // MARK: - Quit List

    private var quitListSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Quit History")
                .font(.system(size: AppFontSize.caption, weight: .semibold, design: .rounded))
                .foregroundColor(AppColors.textSecondary)

            LazyVStack(spacing: AppSpacing.md, pinnedViews: [.sectionHeaders]) {
                ForEach(groupedSessions, id: \.0) { dateString, sessions in
                    Section {
                        ForEach(sessions) { session in
                            QuitSessionCard(session: session)
                        }
                    } header: {
                        sectionHeader(dateString)
                    }
                }
            }
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: AppFontSize.small, weight: .medium, design: .rounded))
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

            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 48))
                .foregroundColor(AppColors.success)

            Text("No Quit Sessions")
                .font(.system(size: AppFontSize.headline, weight: .semibold, design: .rounded))
                .foregroundColor(AppColors.textPrimary)

            Text("Great job! You haven't quit any sessions early.")
                .font(.system(size: AppFontSize.body, design: .rounded))
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)

            Spacer()
        }
        .padding(AppSpacing.xl)
    }
}

// MARK: - Quit Session Card

struct QuitSessionCard: View {
    let session: FocusSession

    private var timeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter.string(from: session.startTime)
    }

    private var progressPercentage: Double {
        guard let actualDuration = session.actualDuration else { return 0 }
        return (actualDuration / session.plannedDuration) * 100
    }

    private var quitTimeIntoSession: String {
        guard let actualDuration = session.actualDuration else { return "Unknown" }
        return actualDuration.formattedTime
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            // Header
            HStack {
                Text(timeString)
                    .font(.system(size: AppFontSize.caption, weight: .medium, design: .rounded))
                    .foregroundColor(AppColors.textSecondary)

                Spacer()

                HStack(spacing: AppSpacing.xs) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(AppColors.danger)
                    Text("Quit")
                        .font(.system(size: AppFontSize.small, weight: .medium, design: .rounded))
                        .foregroundColor(AppColors.danger)
                }
            }

            // Progress info
            HStack(spacing: AppSpacing.md) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Quit at")
                        .font(.system(size: AppFontSize.small, design: .rounded))
                        .foregroundColor(AppColors.textSecondary)
                    Text(quitTimeIntoSession)
                        .font(.system(size: AppFontSize.body, weight: .semibold, design: .rounded))
                        .foregroundColor(AppColors.textPrimary)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("of")
                        .font(.system(size: AppFontSize.small, design: .rounded))
                        .foregroundColor(AppColors.textSecondary)
                    Text(session.plannedDuration.formattedTimeVerbose)
                        .font(.system(size: AppFontSize.body, weight: .semibold, design: .rounded))
                        .foregroundColor(AppColors.textPrimary)
                }

                Spacer()

                // Progress ring
                ZStack {
                    Circle()
                        .stroke(AppColors.danger.opacity(0.2), lineWidth: 4)

                    Circle()
                        .trim(from: 0, to: progressPercentage / 100)
                        .stroke(AppColors.danger, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .rotationEffect(.degrees(-90))

                    Text(String(format: "%.0f%%", progressPercentage))
                        .font(.system(size: AppFontSize.small, weight: .bold, design: .rounded))
                        .foregroundColor(AppColors.danger)
                }
                .frame(width: 50, height: 50)
            }

            // Strict mode badge and phrase
            HStack(spacing: AppSpacing.sm) {
                if session.strictModeEnabled {
                    HStack(spacing: 2) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 10))
                        Text("Strict Mode")
                            .font(.system(size: AppFontSize.small, weight: .medium, design: .rounded))
                    }
                    .foregroundColor(AppColors.accent)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(AppColors.accent.opacity(0.15))
                    .cornerRadius(4)
                }
            }

            // Challenge phrase if available
            if let phrase = session.challengePhraseUsed {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Typed to quit:")
                        .font(.system(size: AppFontSize.small, design: .rounded))
                        .foregroundColor(AppColors.textSecondary)
                    Text("\"\(phrase)\"")
                        .font(.system(size: AppFontSize.caption, weight: .medium, design: .rounded))
                        .foregroundColor(AppColors.textPrimary)
                        .italic()
                }
                .padding(.top, AppSpacing.xs)
            }
        }
        .padding(AppSpacing.md)
        .background(AppColors.cardBackground)
        .cornerRadius(AppCornerRadius.large)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
    }

    private var accessibilityDescription: String {
        var description = "Quit session at \(timeString). Quit \(quitTimeIntoSession) into a \(session.plannedDuration.formattedTimeVerbose) session. \(String(format: "%.0f", progressPercentage)) percent completed."

        if session.strictModeEnabled {
            description += " Strict mode was enabled."
        }

        if let phrase = session.challengePhraseUsed {
            description += " Typed: \(phrase)"
        }

        return description
    }
}

#Preview {
    NavigationStack {
        QuitLogView()
            .modelContainer(for: [FocusSession.self, UserStats.self, AppSettings.self], inMemory: true)
    }
}
