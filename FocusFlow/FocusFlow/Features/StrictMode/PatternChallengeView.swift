import SwiftUI

/// Pattern challenge view where user must tap numbered circles in order
/// Uses a 3x3 grid with 4-5 randomly placed nodes
struct PatternChallengeView: View {
    let onComplete: () -> Void
    let onGoBack: () -> Void

    // Grid positions (0-8 for 3x3 grid)
    @State private var targetPositions: [Int]
    @State private var tappedIndices: [Int] = []
    @State private var showError: Bool = false

    private let gridSize = 3
    private let nodeCount: Int

    private var isComplete: Bool {
        tappedIndices.count == targetPositions.count &&
        tappedIndices == Array(0..<targetPositions.count)
    }

    private var currentTarget: Int {
        tappedIndices.count
    }

    init(onComplete: @escaping () -> Void, onGoBack: @escaping () -> Void) {
        self.onComplete = onComplete
        self.onGoBack = onGoBack

        // Random 4-5 nodes
        let count = Int.random(in: 4...5)
        nodeCount = count

        // Pick random unique positions from 0-8
        var positions = Array(0..<9).shuffled()
        positions = Array(positions.prefix(count))
        _targetPositions = State(initialValue: positions)
    }

    var body: some View {
        VStack(spacing: AppSpacing.lg) {
            // Header
            VStack(spacing: AppSpacing.sm) {
                Image(systemName: "hand.tap.fill")
                    .font(.system(size: 44))
                    .foregroundColor(AppColors.accent)

                Text("Pattern Challenge")
                    .font(.system(size: AppFontSize.title, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.textPrimary)

                Text("Tap the circles in order:")
                    .font(.system(size: AppFontSize.body, weight: .regular, design: .rounded))
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, AppSpacing.xl)

            // Target sequence display
            HStack(spacing: AppSpacing.sm) {
                ForEach(0..<targetPositions.count, id: \.self) { index in
                    ZStack {
                        Circle()
                            .fill(circleDisplayColor(for: index))
                            .frame(width: 36, height: 36)

                        Text("\(index + 1)")
                            .font(.system(size: AppFontSize.caption, weight: .bold, design: .rounded))
                            .foregroundColor(
                                index < tappedIndices.count ? AppColors.textPrimary : AppColors.textSecondary
                            )
                    }
                }
            }
            .padding(.vertical, AppSpacing.md)

            // 3x3 Grid
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: AppSpacing.md), count: gridSize),
                spacing: AppSpacing.md
            ) {
                ForEach(0..<9, id: \.self) { position in
                    gridCell(at: position)
                }
            }
            .padding(AppSpacing.lg)
            .background(
                RoundedRectangle(cornerRadius: AppCornerRadius.large)
                    .fill(AppColors.cardBackground)
            )
            .padding(.horizontal, AppSpacing.md)

            // Error message
            if showError {
                HStack(spacing: AppSpacing.sm) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(AppColors.danger)

                    Text("Wrong order! Try again from the start.")
                        .font(.system(size: AppFontSize.caption, weight: .medium, design: .rounded))
                        .foregroundColor(AppColors.danger)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            // Status
            HStack {
                Text("\(tappedIndices.count) / \(targetPositions.count) tapped")
                    .font(.system(size: AppFontSize.caption, weight: .regular, design: .rounded))
                    .foregroundColor(AppColors.textSecondary)

                Spacer()

                if isComplete {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Complete!")
                    }
                    .font(.system(size: AppFontSize.caption, weight: .medium, design: .rounded))
                    .foregroundColor(AppColors.success)
                }
            }
            .padding(.horizontal, AppSpacing.xl)

            Spacer()

            // Action buttons
            VStack(spacing: AppSpacing.md) {
                Button(action: completeChallenge) {
                    Text("Continue")
                        .font(.system(size: AppFontSize.headline, weight: .semibold, design: .rounded))
                        .foregroundColor(isComplete ? AppColors.textPrimary : AppColors.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppSpacing.md + 4)
                        .background(
                            RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                                .fill(isComplete ? AppColors.danger : AppColors.cardBackground)
                        )
                }
                .buttonStyle(.plain)
                .disabled(!isComplete)

                Button(action: {
                    HapticManager.shared.lightTap()
                    onGoBack()
                }) {
                    Text("Go Back")
                        .font(.system(size: AppFontSize.body, weight: .medium, design: .rounded))
                        .foregroundColor(AppColors.textSecondary)
                }
                .buttonStyle(.plain)

                // Reset button (only show if started)
                if !tappedIndices.isEmpty && !isComplete {
                    Button(action: resetPattern) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.counterclockwise")
                            Text("Reset")
                        }
                        .font(.system(size: AppFontSize.caption, weight: .medium, design: .rounded))
                        .foregroundColor(AppColors.accent)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, AppSpacing.xl)
            .padding(.bottom, AppSpacing.xl)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.background.ignoresSafeArea())
        .animation(.easeInOut(duration: 0.2), value: showError)
        .animation(.easeInOut(duration: 0.2), value: tappedIndices)
    }

    @ViewBuilder
    private func gridCell(at position: Int) -> some View {
        if let nodeIndex = targetPositions.firstIndex(of: position) {
            // This position has a node
            Button(action: {
                handleTap(nodeIndex: nodeIndex)
            }) {
                ZStack {
                    Circle()
                        .fill(cellColor(for: nodeIndex))
                        .frame(width: 70, height: 70)
                        .shadow(
                            color: cellColor(for: nodeIndex).opacity(0.5),
                            radius: nodeIndex == currentTarget ? 8 : 0
                        )

                    Text("\(nodeIndex + 1)")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(AppColors.textPrimary)
                }
            }
            .buttonStyle(.plain)
            .disabled(tappedIndices.contains(nodeIndex))
        } else {
            // Empty cell
            Circle()
                .fill(AppColors.secondaryBackground.opacity(0.3))
                .frame(width: 70, height: 70)
        }
    }

    private func cellColor(for nodeIndex: Int) -> Color {
        if tappedIndices.contains(nodeIndex) {
            return AppColors.success // Already tapped correctly
        } else if nodeIndex == currentTarget {
            return AppColors.accent // Current target (highlighted)
        } else {
            return AppColors.primary // Not yet tapped
        }
    }

    private func circleDisplayColor(for index: Int) -> Color {
        if index < tappedIndices.count {
            return AppColors.success // Completed
        } else if index == currentTarget {
            return AppColors.accent // Current
        } else {
            return AppColors.secondaryBackground // Pending
        }
    }

    private func handleTap(nodeIndex: Int) {
        if nodeIndex == currentTarget {
            // Correct tap
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                tappedIndices.append(nodeIndex)
            }
            showError = false
            HapticManager.shared.lightTap()

            if isComplete {
                HapticManager.shared.success()
            }
        } else {
            // Wrong tap - reset
            HapticManager.shared.error()
            showError = true
            withAnimation(.easeOut(duration: 0.3)) {
                tappedIndices = []
            }

            // Hide error after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                showError = false
            }
        }
    }

    private func resetPattern() {
        HapticManager.shared.lightTap()
        withAnimation(.easeOut(duration: 0.3)) {
            tappedIndices = []
            showError = false
        }
    }

    private func completeChallenge() {
        guard isComplete else { return }
        HapticManager.shared.warning()
        onComplete()
    }
}

#Preview {
    PatternChallengeView(
        onComplete: { print("Complete") },
        onGoBack: { print("Go Back") }
    )
}
