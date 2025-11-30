import SwiftUI
import FamilyControls

/// Manages the full blocking permission flow:
/// 1. Shield Preview (shows what blocked apps look like)
/// 2. Permission Explanation (why we need access)
/// 3. System Permission Dialog (Face ID + authorization)
/// 4. App Picker (select apps to block)
struct BlockingFlowView: View {
    @ObservedObject var blockingManager: BlockingManager
    @Environment(\.dismiss) private var dismiss

    @State private var flowStep: FlowStep = .shieldPreview
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""

    enum FlowStep {
        case shieldPreview
        case permissionExplanation
        case requestingPermission
        case appPicker
    }

    var body: some View {
        ZStack {
            switch flowStep {
            case .shieldPreview:
                ShieldPreviewView(onContinue: {
                    withAnimation {
                        flowStep = .permissionExplanation
                    }
                })

            case .permissionExplanation:
                PermissionExplanationView(
                    onEnableBlocking: {
                        requestPermission()
                    },
                    onMaybeLater: {
                        dismiss()
                    }
                )

            case .requestingPermission:
                // Loading state while system permission is being requested
                ZStack {
                    AppColors.background.ignoresSafeArea()
                    VStack(spacing: AppSpacing.lg) {
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(AppColors.primary)
                        Text("Requesting permission...")
                            .font(.system(size: AppFontSize.body, weight: .medium, design: .rounded))
                            .foregroundColor(AppColors.textSecondary)
                    }
                }

            case .appPicker:
                AppPickerView(blockingManager: blockingManager)
            }
        }
        .alert("Permission Required", isPresented: $showError) {
            Button("Try Again") {
                requestPermission()
            }
            Button("Skip for Now", role: .cancel) {
                dismiss()
            }
        } message: {
            Text(errorMessage)
        }
        .onChange(of: blockingManager.authorizationStatus) { _, newStatus in
            if newStatus == .approved && flowStep == .requestingPermission {
                withAnimation {
                    flowStep = .appPicker
                }
            }
        }
    }

    private func requestPermission() {
        flowStep = .requestingPermission

        Task {
            do {
                try await blockingManager.requestAuthorization()

                await MainActor.run {
                    if blockingManager.isAuthorized {
                        withAnimation {
                            flowStep = .appPicker
                        }
                    } else {
                        showPermissionDeniedError()
                    }
                }
            } catch {
                await MainActor.run {
                    showPermissionError(error)
                }
            }
        }
    }

    private func showPermissionDeniedError() {
        errorMessage = "FocusFlow needs Screen Time access to block apps during focus sessions. You can enable this in Settings > Screen Time > FocusFlow."
        flowStep = .permissionExplanation
        showError = true
    }

    private func showPermissionError(_ error: Error) {
        errorMessage = "Could not request permission: \(error.localizedDescription)"
        flowStep = .permissionExplanation
        showError = true
    }
}

/// View shown when user already has permission and just wants to manage apps
struct AppSelectionView: View {
    @ObservedObject var blockingManager: BlockingManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        AppPickerView(blockingManager: blockingManager)
    }
}

#Preview {
    BlockingFlowView(blockingManager: BlockingManager.shared)
}
