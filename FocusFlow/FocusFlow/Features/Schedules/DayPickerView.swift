import SwiftUI

struct DayPickerView: View {
    @Binding var selectedDays: Set<Weekday>

    // Display days starting from Monday
    private let orderedDays: [Weekday] = [
        .monday, .tuesday, .wednesday, .thursday, .friday, .saturday, .sunday
    ]

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            ForEach(orderedDays, id: \.self) { day in
                DayButton(
                    day: day,
                    isSelected: selectedDays.contains(day),
                    action: { toggleDay(day) }
                )
            }
        }
    }

    private func toggleDay(_ day: Weekday) {
        if selectedDays.contains(day) {
            selectedDays.remove(day)
        } else {
            selectedDays.insert(day)
        }
        HapticManager.shared.lightTap()
    }
}

struct DayButton: View {
    let day: Weekday
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(day.singleLetter)
                .font(.system(size: AppFontSize.caption, weight: .semibold, design: .rounded))
                .foregroundColor(isSelected ? AppColors.background : AppColors.textSecondary)
                .frame(width: 36, height: 36)
                .background(isSelected ? AppColors.primary : AppColors.cardBackground)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(isSelected ? AppColors.primary : AppColors.textSecondary.opacity(0.3), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(day.fullName), \(isSelected ? "selected" : "not selected")")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Quick Selection Buttons

struct DayQuickSelectView: View {
    @Binding var selectedDays: Set<Weekday>

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            QuickSelectButton(title: "Weekdays", action: selectWeekdays)
            QuickSelectButton(title: "Weekends", action: selectWeekends)
            QuickSelectButton(title: "Daily", action: selectDaily)
        }
    }

    private func selectWeekdays() {
        selectedDays = [.monday, .tuesday, .wednesday, .thursday, .friday]
        HapticManager.shared.lightTap()
    }

    private func selectWeekends() {
        selectedDays = [.saturday, .sunday]
        HapticManager.shared.lightTap()
    }

    private func selectDaily() {
        selectedDays = Set(Weekday.allCases)
        HapticManager.shared.lightTap()
    }
}

struct QuickSelectButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: AppFontSize.small, design: .rounded))
                .foregroundColor(AppColors.textSecondary)
                .padding(.horizontal, AppSpacing.sm)
                .padding(.vertical, AppSpacing.xs)
                .background(AppColors.cardBackground)
                .cornerRadius(AppCornerRadius.small)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    VStack(spacing: AppSpacing.lg) {
        DayPickerView(selectedDays: .constant([.monday, .wednesday, .friday]))
        DayPickerView(selectedDays: .constant([.monday, .tuesday, .wednesday, .thursday, .friday]))
        DayPickerView(selectedDays: .constant(Set(Weekday.allCases)))
        DayQuickSelectView(selectedDays: .constant([]))
    }
    .padding()
    .background(AppColors.background)
}
