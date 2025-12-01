//
//  SessionRowView.swift
//  FocusFlow
//
//  A row component displaying a single focus session in the history list.
//

import SwiftUI
import SwiftData

struct SessionRowView: View {
    let session: FocusSession

    private var isCompleted: Bool {
        session.completionStatus == .completed
    }

    private var timeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter.string(from: session.startTime)
    }

    private var durationString: String {
        let minutes = Int(session.plannedDuration / 60)
        return "\(minutes) min \(session.sessionType.displayName)"
    }

    private var statusIcon: String {
        isCompleted ? "checkmark.circle.fill" : "xmark.circle.fill"
    }

    private var statusColor: Color {
        isCompleted ? AppColors.success : AppColors.danger
    }

    private var quitTimeInfo: String? {
        guard !isCompleted,
              let actualDuration = session.actualDuration else { return nil }
        return "Quit at \(actualDuration.formattedTime)"
    }

    var body: some View {
        HStack(alignment: .top, spacing: AppSpacing.md) {
            // Status indicator
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
                .padding(.top, 6)

            // Content
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                // Time and duration
                HStack {
                    Text(timeString)
                        .font(.system(size: AppFontSize.caption, weight: .medium, design: .rounded))
                        .foregroundColor(AppColors.textSecondary)

                    Text("•")
                        .foregroundColor(AppColors.textSecondary)

                    Text(durationString)
                        .font(.system(size: AppFontSize.caption, design: .rounded))
                        .foregroundColor(AppColors.textSecondary)
                }

                // Main info
                Text(session.sessionType == .work ? "Focus Session" : "Break Session")
                    .font(.system(size: AppFontSize.body, weight: .semibold, design: .rounded))
                    .foregroundColor(AppColors.textPrimary)

                // Quit info or strict mode badge
                HStack(spacing: AppSpacing.sm) {
                    if let quitInfo = quitTimeInfo {
                        Text(quitInfo)
                            .font(.system(size: AppFontSize.small, design: .rounded))
                            .foregroundColor(AppColors.danger)
                    }

                    if session.strictModeEnabled {
                        HStack(spacing: 2) {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 10))
                            Text("Strict")
                                .font(.system(size: AppFontSize.small, weight: .medium, design: .rounded))
                        }
                        .foregroundColor(AppColors.accent)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(AppColors.accent.opacity(0.15))
                        .cornerRadius(4)
                    }
                }
            }

            Spacer()

            // Status icon
            Image(systemName: statusIcon)
                .foregroundColor(statusColor)
                .font(.system(size: 20))
        }
        .padding(AppSpacing.md)
        .background(AppColors.cardBackground)
        .cornerRadius(AppCornerRadius.large)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
    }

    private var accessibilityDescription: String {
        let status = isCompleted ? "Completed" : "Quit early"
        let duration = Int(session.plannedDuration / 60)
        let type = session.sessionType.displayName
        var description = "\(status) \(duration) minute \(type) at \(timeString)"

        if let quitInfo = quitTimeInfo {
            description += ". \(quitInfo)"
        }

        if session.strictModeEnabled {
            description += ". Strict mode was enabled"
        }

        return description
    }
}

#Preview("Completed Session") {
    SessionRowView(
        session: FocusSession(
            plannedDuration: 25 * 60,
            sessionType: .work,
            completionStatus: .completed,
            strictModeEnabled: true
        )
    )
    .padding()
    .background(AppColors.background)
}

#Preview("Quit Session") {
    let session = FocusSession(
        plannedDuration: 50 * 60,
        sessionType: .work,
        completionStatus: .quitEarly,
        strictModeEnabled: true
    )
    session.actualDuration = 26 * 60 + 19

    return SessionRowView(session: session)
        .padding()
        .background(AppColors.background)
}
