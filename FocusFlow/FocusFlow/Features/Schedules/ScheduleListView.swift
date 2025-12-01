import SwiftUI
import SwiftData

struct ScheduleListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Schedule.startHour) private var schedules: [Schedule]

    @StateObject private var scheduleManager = ScheduleManager.shared

    @State private var showingEditor: Bool = false
    @State private var selectedSchedule: Schedule?
    @State private var scheduleToDelete: Schedule?
    @State private var showingDeleteConfirmation: Bool = false

    var body: some View {
        NavigationStack {
            Group {
                if schedules.isEmpty {
                    emptyStateView
                } else {
                    scheduleListView
                }
            }
            .background(AppColors.background)
            .navigationTitle("Schedules")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showingEditor = true }) {
                        Image(systemName: "plus")
                            .foregroundColor(AppColors.accent)
                    }
                }
            }
            .sheet(isPresented: $showingEditor) {
                ScheduleEditorView(schedule: selectedSchedule) { schedule in
                    handleScheduleSave(schedule)
                }
            }
            .sheet(item: $selectedSchedule) { schedule in
                ScheduleEditorView(schedule: schedule) { updatedSchedule in
                    handleScheduleUpdate(updatedSchedule)
                }
            }
            .alert("Delete Schedule", isPresented: $showingDeleteConfirmation) {
                Button("Cancel", role: .cancel) {
                    scheduleToDelete = nil
                }
                Button("Delete", role: .destructive) {
                    if let schedule = scheduleToDelete {
                        deleteSchedule(schedule)
                    }
                }
            } message: {
                if let schedule = scheduleToDelete {
                    Text("Are you sure you want to delete \"\(schedule.name.isEmpty ? "this schedule" : schedule.name)\"?")
                }
            }
            .onAppear {
                scheduleManager.setModelContext(modelContext)
            }
        }
    }

    // MARK: - Views

    private var emptyStateView: some View {
        VStack(spacing: AppSpacing.lg) {
            Spacer()

            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 64))
                .foregroundColor(AppColors.textSecondary)

            Text("No Schedules Yet")
                .font(.system(size: AppFontSize.headline, weight: .semibold, design: .rounded))
                .foregroundColor(AppColors.textPrimary)

            Text("Create recurring focus sessions to build consistent habits.")
                .font(.system(size: AppFontSize.body, design: .rounded))
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppSpacing.xl)

            Button(action: { showingEditor = true }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Create Schedule")
                }
                .font(.system(size: AppFontSize.body, weight: .semibold, design: .rounded))
                .foregroundColor(AppColors.background)
                .padding(.horizontal, AppSpacing.lg)
                .padding(.vertical, AppSpacing.md)
                .background(AppColors.accent)
                .cornerRadius(AppCornerRadius.medium)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var scheduleListView: some View {
        ScrollView {
            VStack(spacing: AppSpacing.md) {
                // Active schedules section
                if !activeSchedules.isEmpty {
                    scheduleSection(title: "Active", schedules: activeSchedules)
                }

                // Inactive schedules section
                if !inactiveSchedules.isEmpty {
                    scheduleSection(title: "Inactive", schedules: inactiveSchedules)
                }

                // Next scheduled session info
                if let nextSchedule = nextUpcomingSchedule {
                    nextSessionCard(schedule: nextSchedule)
                }
            }
            .padding(AppSpacing.md)
        }
    }

    private func scheduleSection(title: String, schedules: [Schedule]) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text(title)
                .font(.system(size: AppFontSize.caption, weight: .medium, design: .rounded))
                .foregroundColor(AppColors.textSecondary)
                .padding(.leading, AppSpacing.xs)

            ForEach(schedules) { schedule in
                ScheduleRowView(
                    schedule: schedule,
                    onToggle: { toggleSchedule(schedule) }
                )
                .onTapGesture {
                    selectedSchedule = schedule
                }
                .contextMenu {
                    Button {
                        selectedSchedule = schedule
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }

                    Button {
                        toggleSchedule(schedule)
                    } label: {
                        Label(
                            schedule.isActive ? "Disable" : "Enable",
                            systemImage: schedule.isActive ? "pause.circle" : "play.circle"
                        )
                    }

                    Divider()

                    Button(role: .destructive) {
                        scheduleToDelete = schedule
                        showingDeleteConfirmation = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        scheduleToDelete = schedule
                        showingDeleteConfirmation = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
    }

    private func nextSessionCard(schedule: Schedule) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Next Scheduled Session")
                .font(.system(size: AppFontSize.caption, weight: .medium, design: .rounded))
                .foregroundColor(AppColors.textSecondary)
                .padding(.leading, AppSpacing.xs)

            if let nextTime = schedule.nextScheduledTime(from: Date()) {
                HStack {
                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        Text(schedule.name.isEmpty ? "Scheduled Session" : schedule.name)
                            .font(.system(size: AppFontSize.body, weight: .semibold, design: .rounded))
                            .foregroundColor(AppColors.textPrimary)

                        Text(formatNextTime(nextTime))
                            .font(.system(size: AppFontSize.caption, design: .rounded))
                            .foregroundColor(AppColors.primary)
                    }

                    Spacer()

                    Image(systemName: "clock.fill")
                        .font(.system(size: 24))
                        .foregroundColor(AppColors.primary)
                }
                .padding(AppSpacing.md)
                .background(AppColors.primary.opacity(0.15))
                .cornerRadius(AppCornerRadius.medium)
            }
        }
    }

    // MARK: - Computed Properties

    private var activeSchedules: [Schedule] {
        schedules.filter { $0.isActive }
    }

    private var inactiveSchedules: [Schedule] {
        schedules.filter { !$0.isActive }
    }

    private var nextUpcomingSchedule: Schedule? {
        let now = Date()
        return activeSchedules
            .compactMap { schedule -> (Schedule, Date)? in
                guard let nextTime = schedule.nextScheduledTime(from: now) else { return nil }
                return (schedule, nextTime)
            }
            .sorted { $0.1 < $1.1 }
            .first?.0
    }

    // MARK: - Actions

    private func handleScheduleSave(_ schedule: Schedule) {
        modelContext.insert(schedule)

        do {
            try modelContext.save()
            scheduleManager.scheduleNotifications(for: schedule)
            HapticManager.shared.success()
        } catch {
            print("Failed to save schedule: \(error)")
        }

        selectedSchedule = nil
    }

    private func handleScheduleUpdate(_ schedule: Schedule) {
        do {
            try modelContext.save()

            if schedule.isActive {
                scheduleManager.scheduleNotifications(for: schedule)
            } else {
                scheduleManager.cancelNotifications(for: schedule)
            }

            HapticManager.shared.success()
        } catch {
            print("Failed to update schedule: \(error)")
        }

        selectedSchedule = nil
    }

    private func toggleSchedule(_ schedule: Schedule) {
        schedule.isActive.toggle()

        do {
            try modelContext.save()

            if schedule.isActive {
                scheduleManager.scheduleNotifications(for: schedule)
            } else {
                scheduleManager.cancelNotifications(for: schedule)
            }

            HapticManager.shared.lightTap()
        } catch {
            print("Failed to toggle schedule: \(error)")
        }
    }

    private func deleteSchedule(_ schedule: Schedule) {
        scheduleManager.cancelNotifications(for: schedule)
        modelContext.delete(schedule)

        do {
            try modelContext.save()
            HapticManager.shared.mediumImpact()
        } catch {
            print("Failed to delete schedule: \(error)")
        }

        scheduleToDelete = nil
    }

    // MARK: - Helpers

    private func formatNextTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        let calendar = Calendar.current

        if calendar.isDateInToday(date) {
            formatter.dateFormat = "'Today at' h:mm a"
        } else if calendar.isDateInTomorrow(date) {
            formatter.dateFormat = "'Tomorrow at' h:mm a"
        } else {
            formatter.dateFormat = "EEEE 'at' h:mm a"
        }

        return formatter.string(from: date)
    }
}

#Preview {
    ScheduleListView()
        .modelContainer(for: [Schedule.self], inMemory: true)
}
