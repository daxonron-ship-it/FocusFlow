import SwiftUI

/// Math challenge view where user must solve a simple arithmetic problem
/// Uses random 2-digit addition or subtraction
struct MathChallengeView: View {
    let onComplete: () -> Void
    let onGoBack: () -> Void

    @State private var num1: Int
    @State private var num2: Int
    @State private var isAddition: Bool
    @State private var userAnswer: String = ""
    @FocusState private var isInputFocused: Bool

    private var correctAnswer: Int {
        isAddition ? num1 + num2 : num1 - num2
    }

    private var isCorrect: Bool {
        guard let answer = Int(userAnswer.trimmingCharacters(in: .whitespaces)) else {
            return false
        }
        return answer == correctAnswer
    }

    private var operatorSymbol: String {
        isAddition ? "+" : "−"
    }

    init(onComplete: @escaping () -> Void, onGoBack: @escaping () -> Void) {
        self.onComplete = onComplete
        self.onGoBack = onGoBack

        // Initialize with random values
        let addition = Bool.random()
        let n1 = Int.random(in: 10...99)
        let n2 = Int.random(in: 10...99)

        // For subtraction, ensure the result is positive
        if addition {
            _num1 = State(initialValue: n1)
            _num2 = State(initialValue: n2)
        } else {
            _num1 = State(initialValue: max(n1, n2))
            _num2 = State(initialValue: min(n1, n2))
        }
        _isAddition = State(initialValue: addition)
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    // Header
                    VStack(spacing: AppSpacing.sm) {
                        Image(systemName: "number.circle.fill")
                            .font(.system(size: 44))
                            .foregroundColor(AppColors.accent)

                        Text("Math Challenge")
                            .font(.system(size: AppFontSize.title, weight: .bold, design: .rounded))
                            .foregroundColor(AppColors.textPrimary)

                        Text("Solve the problem to continue:")
                            .font(.system(size: AppFontSize.body, weight: .regular, design: .rounded))
                            .foregroundColor(AppColors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, AppSpacing.xl)
                    .id("header")

                    // Math problem display
                    VStack(spacing: AppSpacing.md) {
                        HStack(spacing: AppSpacing.lg) {
                            Text("\(num1)")
                                .font(.system(size: 56, weight: .bold, design: .rounded))
                                .foregroundColor(AppColors.textPrimary)

                            Text(operatorSymbol)
                                .font(.system(size: 48, weight: .bold, design: .rounded))
                                .foregroundColor(AppColors.accent)

                            Text("\(num2)")
                                .font(.system(size: 56, weight: .bold, design: .rounded))
                                .foregroundColor(AppColors.textPrimary)
                        }

                        Text("= ?")
                            .font(.system(size: 36, weight: .medium, design: .rounded))
                            .foregroundColor(AppColors.textSecondary)
                    }
                    .padding(.vertical, AppSpacing.xl)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: AppCornerRadius.large)
                            .fill(AppColors.cardBackground)
                    )
                    .padding(.horizontal, AppSpacing.md)
                    .id("problem")

                    // Answer input
                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        TextField("Your answer", text: $userAnswer)
                            .font(.system(size: AppFontSize.headline, weight: .regular, design: .rounded))
                            .foregroundColor(AppColors.textPrimary)
                            .padding(AppSpacing.md)
                            .frame(minHeight: 56)
                            .background(
                                RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                                    .fill(AppColors.secondaryBackground)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                                    .stroke(
                                        isCorrect ? AppColors.success :
                                            (isInputFocused ? AppColors.primary : Color.clear),
                                        lineWidth: 2
                                    )
                            )
                            .keyboardType(.numberPad)
                            .focused($isInputFocused)
                    }
                    .padding(.horizontal, AppSpacing.md)
                    .id("input")

                    // Status indicator
                    HStack {
                        if !userAnswer.isEmpty {
                            if isCorrect {
                                HStack(spacing: 4) {
                                    Image(systemName: "checkmark.circle.fill")
                                    Text("Correct!")
                                }
                                .font(.system(size: AppFontSize.caption, weight: .medium, design: .rounded))
                                .foregroundColor(AppColors.success)
                            } else {
                                HStack(spacing: 4) {
                                    Image(systemName: "xmark.circle.fill")
                                    Text("Try again")
                                }
                                .font(.system(size: AppFontSize.caption, weight: .medium, design: .rounded))
                                .foregroundColor(AppColors.danger)
                            }
                        }
                        Spacer()
                    }
                    .padding(.horizontal, AppSpacing.md + AppSpacing.md)

                    Spacer(minLength: AppSpacing.xl)

                    // Action buttons
                    VStack(spacing: AppSpacing.md) {
                        Button(action: completeChallenge) {
                            Text("Continue")
                                .font(.system(size: AppFontSize.headline, weight: .semibold, design: .rounded))
                                .foregroundColor(isCorrect ? AppColors.textPrimary : AppColors.textSecondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, AppSpacing.md + 4)
                                .background(
                                    RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                                        .fill(isCorrect ? AppColors.danger : AppColors.cardBackground)
                                )
                        }
                        .buttonStyle(.plain)
                        .disabled(!isCorrect)

                        Button(action: {
                            isInputFocused = false
                            HapticManager.shared.lightTap()
                            onGoBack()
                        }) {
                            Text("Go Back")
                                .font(.system(size: AppFontSize.body, weight: .medium, design: .rounded))
                                .foregroundColor(AppColors.textSecondary)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, AppSpacing.xl)
                    .padding(.bottom, AppSpacing.xl)
                    .id("buttons")
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .onChange(of: isInputFocused) { _, isFocused in
                if isFocused {
                    withAnimation(.easeOut(duration: 0.25)) {
                        proxy.scrollTo("input", anchor: .center)
                    }
                }
            }
            .onChange(of: userAnswer) { _, _ in
                if !userAnswer.isEmpty {
                    HapticManager.shared.selectionChanged()
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.background.ignoresSafeArea())
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isInputFocused = true
            }
        }
    }

    private func completeChallenge() {
        guard isCorrect else { return }
        isInputFocused = false
        HapticManager.shared.warning()
        onComplete()
    }
}

#Preview {
    MathChallengeView(
        onComplete: { print("Complete") },
        onGoBack: { print("Go Back") }
    )
}
