import SwiftUI
import FamilyControls

/// Wraps Apple's FamilyActivityPicker to allow users to select apps and categories to block.
/// Note: FamilyActivityPicker is a system-provided UI component that shows installed apps.
struct AppPickerView: View {
    @ObservedObject var blockingManager: BlockingManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Header info
                    VStack(spacing: AppSpacing.sm) {
                        Text("Select apps and categories to block during focus sessions.")
                            .font(.system(size: AppFontSize.caption, weight: .regular, design: .rounded))
                            .foregroundColor(AppColors.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, AppSpacing.lg)
                            .padding(.top, AppSpacing.md)

                        // Selection summary
                        if blockingManager.hasSelectedApps {
                            HStack(spacing: AppSpacing.sm) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(AppColors.success)
                                Text(blockingManager.blockingDescription)
                                    .font(.system(size: AppFontSize.caption, weight: .medium, design: .rounded))
                                    .foregroundColor(AppColors.success)
                            }
                            .padding(.top, AppSpacing.xs)
                        }
                    }
                    .padding(.bottom, AppSpacing.md)

                    // System app picker
                    FamilyActivityPicker(selection: $blockingManager.activitySelection)
                        .onChange(of: blockingManager.activitySelection) { _, _ in
                            // Save selection when it changes
                            blockingManager.saveSelection()
                        }
                }
            }
            .navigationTitle("Select Apps")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(AppColors.textSecondary)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        blockingManager.saveSelection()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(AppColors.primary)
                }
            }
        }
    }
}

#Preview {
    AppPickerView(blockingManager: BlockingManager.shared)
}
