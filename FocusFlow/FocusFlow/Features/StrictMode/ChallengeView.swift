import SwiftUI

/// Challenge view where user must type the phrase to quit
/// Uses keyboard-aware layout with ScrollViewReader to keep input visible
struct ChallengeView: View {
    let challengePhrase: String
    let onComplete: () -> Void
    let onGoBack: () -> Void

    @State private var userInput: String = ""
    @FocusState private var isInputFocused: Bool

    private var isMatchComplete: Bool {
        StringNormalization.isComplete(userInput: userInput, challengePhrase: challengePhrase)
    }

    private var hasError: Bool {
        StringNormalization.firstMismatchIndex(userInput: userInput, challengePhrase: challengePhrase) != nil
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    // Header
                    VStack(spacing: AppSpacing.sm) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 44))
                            .foregroundColor(AppColors.accent)

                        Text("Strict Mode")
                            .font(.system(size: AppFontSize.title, weight: .bold, design: .rounded))
                            .foregroundColor(AppColors.textPrimary)

                        Text("To end this session early,\ntype the following exactly:")
                            .font(.system(size: AppFontSize.body, weight: .regular, design: .rounded))
                            .foregroundColor(AppColors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, AppSpacing.xl)
                    .id("header")

                    // Challenge phrase with character feedback
                    CharacterFeedbackView(
                        challengePhrase: challengePhrase,
                        userInput: userInput
                    )
                    .padding(.horizontal, AppSpacing.md)
                    .id("phrase")

                    // Error indicator
                    if hasError {
                        HStack(spacing: AppSpacing.sm) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(AppColors.danger)

                            Text("Character mismatch detected")
                                .font(.system(size: AppFontSize.caption, weight: .medium, design: .rounded))
                                .foregroundColor(AppColors.danger)
                        }
                        .padding(.horizontal, AppSpacing.md)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                        .id("error")
                    }

                    // Text input field
                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        TextField("Type here...", text: $userInput, axis: .vertical)
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
                                        hasError ? AppColors.danger.opacity(0.5) :
                                            (isInputFocused ? AppColors.primary : Color.clear),
                                        lineWidth: 2
                                    )
                            )
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                            .keyboardType(.asciiCapable)
                            .focused($isInputFocused)
                            .submitLabel(.done)
                            .onSubmit {
                                if isMatchComplete {
                                    completeChallenge()
                                }
                            }
                    }
                    .padding(.horizontal, AppSpacing.md)
                    .id("input")

                    // Character count progress
                    HStack {
                        Text("\(userInput.count) / \(challengePhrase.count) characters")
                            .font(.system(size: AppFontSize.caption, weight: .regular, design: .rounded))
                            .foregroundColor(AppColors.textSecondary)

                        Spacer()

                        if isMatchComplete {
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Match!")
                            }
                            .font(.system(size: AppFontSize.caption, weight: .medium, design: .rounded))
                            .foregroundColor(AppColors.success)
                        }
                    }
                    .padding(.horizontal, AppSpacing.md + AppSpacing.md)

                    Spacer(minLength: AppSpacing.xl)

                    // Action buttons
                    VStack(spacing: AppSpacing.md) {
                        // End Session button (enabled only when phrase matches)
                        Button(action: completeChallenge) {
                            Text("End Session")
                                .font(.system(size: AppFontSize.headline, weight: .semibold, design: .rounded))
                                .foregroundColor(isMatchComplete ? AppColors.textPrimary : AppColors.textSecondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, AppSpacing.md + 4)
                                .background(
                                    RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                                        .fill(isMatchComplete ? AppColors.danger : AppColors.cardBackground)
                                )
                        }
                        .buttonStyle(.plain)
                        .disabled(!isMatchComplete)

                        // Go Back button
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
                    // Scroll to keep input visible when keyboard appears
                    withAnimation(.easeOut(duration: 0.25)) {
                        proxy.scrollTo("input", anchor: .center)
                    }
                }
            }
            .onChange(of: userInput) { _, _ in
                // Light haptic on each keystroke
                if !userInput.isEmpty {
                    HapticManager.shared.selectionChanged()
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.background.ignoresSafeArea())
        .onAppear {
            // Auto-focus the text field
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isInputFocused = true
            }
        }
    }

    private func completeChallenge() {
        guard isMatchComplete else { return }
        isInputFocused = false
        HapticManager.shared.warning()
        onComplete()
    }
}

#Preview("Empty") {
    ChallengeView(
        challengePhrase: "I am choosing distraction over my goals",
        onComplete: { print("Complete") },
        onGoBack: { print("Go Back") }
    )
}

#Preview("Partial Input") {
    ChallengeView(
        challengePhrase: "End session early",
        onComplete: { print("Complete") },
        onGoBack: { print("Go Back") }
    )
}
