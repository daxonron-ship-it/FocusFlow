import SwiftUI

struct ScheduleRowView: View {
    let schedule: Schedule
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            // Schedule info
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                HStack {
                    Text(schedule.name.isEmpty ? "Unnamed Schedule" : schedule.name)
                        .font(.system(size: AppFontSize.body, weight: .semibold, design: .rounded))
                        .foregroundColor(schedule.isActive ? AppColors.textPrimary : AppColors.textSecondary)

                    if schedule.strictModeEnabled {
                        Image(systemName: "lock.fill")
                            .font(.system(size: AppFontSize.small))
                            .foregroundColor(AppColors.accent)
                    }
                }

                HStack(spacing: AppSpacing.xs) {
                    Text(schedule.daysDescription)
                        .font(.system(size: AppFontSize.caption, design: .rounded))
                        .foregroundColor(AppColors.textSecondary)

                    Text("•")
                        .foregroundColor(AppColors.textSecondary)

                    Text(schedule.formattedStartTime)
                        .font(.system(size: AppFontSize.caption, design: .rounded))
                        .foregroundColor(AppColors.textSecondary)

                    Text("•")
                        .foregroundColor(AppColors.textSecondary)

                    Text(schedule.formattedDuration)
                        .font(.system(size: AppFontSize.caption, design: .rounded))
                        .foregroundColor(AppColors.textSecondary)
                }
            }

            Spacer()

            // Toggle button
            Button(action: onToggle) {
                Image(systemName: schedule.isActive ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24))
                    .foregroundColor(schedule.isActive ? AppColors.success : AppColors.textSecondary)
            }
            .buttonStyle(.plain)
        }
        .padding(AppSpacing.md)
        .background(AppColors.cardBackground)
        .cornerRadius(AppCornerRadius.medium)
        .opacity(schedule.isActive ? 1.0 : 0.7)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint("Tap to edit, double tap to toggle active status")
    }

    private var accessibilityLabel: String {
        let status = schedule.isActive ? "Active" : "Inactive"
        let strict = schedule.strictModeEnabled ? ", strict mode enabled" : ""
        return "\(schedule.name.isEmpty ? "Unnamed schedule" : schedule.name), \(schedule.daysDescription) at \(schedule.formattedStartTime), \(schedule.formattedDuration), \(status)\(strict)"
    }
}

#Preview {
    VStack(spacing: AppSpacing.md) {
        ScheduleRowView(
            schedule: {
                let s = Schedule(
                    name: "Morning Deep Work",
                    activeDays: [2, 3, 4, 5, 6],  // Mon-Fri
                    startHour: 9,
                    startMinute: 0,
                    duration: 3 * 60 * 60,
                    strictModeEnabled: true,
                    isActive: true
                )
                return s
            }(),
            onToggle: {}
        )

        ScheduleRowView(
            schedule: {
                let s = Schedule(
                    name: "Evening Focus",
                    activeDays: [1, 2, 3, 4, 5, 6, 7],  // Daily
                    startHour: 19,
                    startMinute: 0,
                    duration: 60 * 60,
                    strictModeEnabled: false,
                    isActive: true
                )
                return s
            }(),
            onToggle: {}
        )

        ScheduleRowView(
            schedule: {
                let s = Schedule(
                    name: "Weekend Study",
                    activeDays: [1, 7],  // Sat-Sun
                    startHour: 10,
                    startMinute: 0,
                    duration: 2 * 60 * 60,
                    strictModeEnabled: false,
                    isActive: false
                )
                return s
            }(),
            onToggle: {}
        )
    }
    .padding()
    .background(AppColors.background)
}
