import SwiftUI

struct PresetPicker: View {
    @Binding var selectedPreset: TimerPreset

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            ForEach(TimerPreset.allCases) { preset in
                PresetPill(
                    preset: preset,
                    isSelected: selectedPreset == preset
                ) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedPreset = preset
                    }
                    HapticManager.shared.selectionChanged()
                }
            }
        }
    }
}

struct PresetPill: View {
    let preset: TimerPreset
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(preset.displayName)
                .font(.system(size: AppFontSize.body, weight: .semibold, design: .rounded))
                .foregroundColor(isSelected ? AppColors.textPrimary : AppColors.textSecondary)
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, AppSpacing.sm)
                .background(
                    Capsule()
                        .fill(isSelected ? AppColors.primary : AppColors.cardBackground)
                )
                .overlay(
                    Capsule()
                        .stroke(isSelected ? AppColors.primary : Color.clear, lineWidth: 2)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(preset.displayName) preset")
        .accessibilityHint(preset.description)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview {
    ZStack {
        AppColors.background.ignoresSafeArea()

        PresetPicker(selectedPreset: .constant(.pomodoro25))
    }
}
