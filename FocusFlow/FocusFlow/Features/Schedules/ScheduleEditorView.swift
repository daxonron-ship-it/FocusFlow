import SwiftUI
import SwiftData
import FamilyControls

struct ScheduleEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let schedule: Schedule?
    let onSave: (Schedule) -> Void

    @State private var name: String = ""
    @State private var selectedDays: Set<Weekday> = []
    @State private var startTime: Date = Date()
    @State private var duration: TimeInterval = 60 * 60  // 1 hour default
    @State private var strictModeEnabled: Bool = false
    @State private var showingAppPicker: Bool = false
    @State private var activitySelection = FamilyActivitySelection()

    @StateObject private var blockingManager = BlockingManager.shared

    private var isEditing: Bool { schedule != nil }
    private var canSave: Bool { !selectedDays.isEmpty }

    init(schedule: Schedule? = nil, onSave: @escaping (Schedule) -> Void) {
        self.schedule = schedule
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    // Name Section
                    nameSection

                    // Days Section
                    daysSection

                    // Time Section
                    timeSection

                    // Duration Section
                    durationSection

                    // Blocked Apps Section
                    blockedAppsSection

                    // Strict Mode Section
                    strictModeSection
                }
                .padding(AppSpacing.md)
            }
            .background(AppColors.background)
            .navigationTitle(isEditing ? "Edit Schedule" : "New Schedule")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(AppColors.textSecondary)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveSchedule()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(canSave ? AppColors.accent : AppColors.textSecondary)
                    .disabled(!canSave)
                }
            }
            .onAppear {
                loadScheduleData()
            }
            .familyActivityPicker(
                isPresented: $showingAppPicker,
                selection: $activitySelection
            )
        }
    }

    // MARK: - Sections

    private var nameSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Name")
                .font(.system(size: AppFontSize.caption, weight: .medium, design: .rounded))
                .foregroundColor(AppColors.textSecondary)

            TextField("e.g., Morning Deep Work", text: $name)
                .font(.system(size: AppFontSize.body, design: .rounded))
                .foregroundColor(AppColors.textPrimary)
                .padding(AppSpacing.md)
                .background(AppColors.cardBackground)
                .cornerRadius(AppCornerRadius.medium)
        }
    }

    private var daysSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Days")
                .font(.system(size: AppFontSize.caption, weight: .medium, design: .rounded))
                .foregroundColor(AppColors.textSecondary)

            VStack(spacing: AppSpacing.md) {
                DayPickerView(selectedDays: $selectedDays)
                DayQuickSelectView(selectedDays: $selectedDays)
            }
            .padding(AppSpacing.md)
            .background(AppColors.cardBackground)
            .cornerRadius(AppCornerRadius.medium)

            if selectedDays.isEmpty {
                Text("Select at least one day")
                    .font(.system(size: AppFontSize.small, design: .rounded))
                    .foregroundColor(AppColors.danger)
            }
        }
    }

    private var timeSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Start Time")
                .font(.system(size: AppFontSize.caption, weight: .medium, design: .rounded))
                .foregroundColor(AppColors.textSecondary)

            DatePicker(
                "Start Time",
                selection: $startTime,
                displayedComponents: .hourAndMinute
            )
            .datePickerStyle(.wheel)
            .labelsHidden()
            .frame(maxWidth: .infinity)
            .padding(AppSpacing.sm)
            .background(AppColors.cardBackground)
            .cornerRadius(AppCornerRadius.medium)
            .colorScheme(.dark)
        }
    }

    private var durationSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Duration")
                .font(.system(size: AppFontSize.caption, weight: .medium, design: .rounded))
                .foregroundColor(AppColors.textSecondary)

            DurationPickerView(duration: $duration)
                .padding(AppSpacing.md)
                .background(AppColors.cardBackground)
                .cornerRadius(AppCornerRadius.medium)
        }
    }

    private var blockedAppsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Blocked Apps")
                .font(.system(size: AppFontSize.caption, weight: .medium, design: .rounded))
                .foregroundColor(AppColors.textSecondary)

            Button(action: {
                if blockingManager.isAuthorized {
                    showingAppPicker = true
                }
            }) {
                HStack {
                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        Text(blockedAppsDescription)
                            .font(.system(size: AppFontSize.body, design: .rounded))
                            .foregroundColor(AppColors.textPrimary)

                        if !blockingManager.isAuthorized {
                            Text("Enable app blocking in Settings first")
                                .font(.system(size: AppFontSize.small, design: .rounded))
                                .foregroundColor(AppColors.textSecondary)
                        }
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: AppFontSize.caption))
                        .foregroundColor(AppColors.textSecondary)
                }
                .padding(AppSpacing.md)
                .background(AppColors.cardBackground)
                .cornerRadius(AppCornerRadius.medium)
            }
            .buttonStyle(.plain)
            .disabled(!blockingManager.isAuthorized)
            .opacity(blockingManager.isAuthorized ? 1.0 : 0.6)
        }
    }

    private var strictModeSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Strict Mode")
                .font(.system(size: AppFontSize.caption, weight: .medium, design: .rounded))
                .foregroundColor(AppColors.textSecondary)

            HStack {
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text("Enable Strict Mode")
                        .font(.system(size: AppFontSize.body, design: .rounded))
                        .foregroundColor(AppColors.textPrimary)

                    Text("Requires completing a challenge to end early")
                        .font(.system(size: AppFontSize.small, design: .rounded))
                        .foregroundColor(AppColors.textSecondary)
                }

                Spacer()

                Toggle("", isOn: $strictModeEnabled)
                    .tint(AppColors.accent)
                    .labelsHidden()
            }
            .padding(AppSpacing.md)
            .background(AppColors.cardBackground)
            .cornerRadius(AppCornerRadius.medium)
        }
    }

    // MARK: - Computed Properties

    private var blockedAppsDescription: String {
        let appsCount = activitySelection.applicationTokens.count
        let categoriesCount = activitySelection.categoryTokens.count

        if appsCount == 0 && categoriesCount == 0 {
            return "None selected"
        } else if categoriesCount > 0 && appsCount > 0 {
            return "\(appsCount) apps, \(categoriesCount) categories"
        } else if categoriesCount > 0 {
            return "\(categoriesCount) \(categoriesCount == 1 ? "category" : "categories")"
        } else {
            return "\(appsCount) \(appsCount == 1 ? "app" : "apps")"
        }
    }

    // MARK: - Actions

    private func loadScheduleData() {
        guard let schedule = schedule else { return }

        name = schedule.name
        selectedDays = schedule.activeDaysSet
        strictModeEnabled = schedule.strictModeEnabled

        // Load start time
        var components = DateComponents()
        components.hour = schedule.startHour
        components.minute = schedule.startMinute
        if let date = Calendar.current.date(from: components) {
            startTime = date
        }

        duration = schedule.duration

        // Load blocked apps
        if let data = schedule.blockedAppsData,
           let selection = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data) {
            activitySelection = selection
        }
    }

    private func saveSchedule() {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: startTime)
        let minute = calendar.component(.minute, from: startTime)

        let blockedAppsData = try? JSONEncoder().encode(activitySelection)

        if let existingSchedule = schedule {
            // Update existing schedule
            existingSchedule.name = name
            existingSchedule.activeDaysSet = selectedDays
            existingSchedule.startHour = hour
            existingSchedule.startMinute = minute
            existingSchedule.duration = duration
            existingSchedule.strictModeEnabled = strictModeEnabled
            existingSchedule.blockedAppsData = blockedAppsData

            onSave(existingSchedule)
        } else {
            // Create new schedule
            let newSchedule = Schedule(
                name: name,
                activeDays: selectedDays.map { $0.rawValue }.sorted(),
                startHour: hour,
                startMinute: minute,
                duration: duration,
                strictModeEnabled: strictModeEnabled,
                isActive: true,
                blockedAppsData: blockedAppsData
            )

            onSave(newSchedule)
        }

        HapticManager.shared.mediumImpact()
        dismiss()
    }
}

// MARK: - Duration Picker

struct DurationPickerView: View {
    @Binding var duration: TimeInterval

    private let presets: [(String, TimeInterval)] = [
        ("30m", 30 * 60),
        ("1h", 60 * 60),
        ("1.5h", 90 * 60),
        ("2h", 2 * 60 * 60),
        ("3h", 3 * 60 * 60),
        ("4h", 4 * 60 * 60)
    ]

    var body: some View {
        VStack(spacing: AppSpacing.md) {
            // Preset buttons
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: AppSpacing.sm) {
                ForEach(presets, id: \.1) { preset in
                    Button(action: {
                        duration = preset.1
                        HapticManager.shared.lightTap()
                    }) {
                        Text(preset.0)
                            .font(.system(size: AppFontSize.body, weight: .medium, design: .rounded))
                            .foregroundColor(duration == preset.1 ? AppColors.background : AppColors.textPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, AppSpacing.sm)
                            .background(duration == preset.1 ? AppColors.primary : AppColors.secondaryBackground)
                            .cornerRadius(AppCornerRadius.small)
                    }
                    .buttonStyle(.plain)
                }
            }

            // Current selection display
            Text("Duration: \(duration.formattedTimeVerbose)")
                .font(.system(size: AppFontSize.caption, design: .rounded))
                .foregroundColor(AppColors.textSecondary)
        }
    }
}

#Preview {
    ScheduleEditorView(schedule: nil) { _ in }
        .modelContainer(for: [Schedule.self], inMemory: true)
}
