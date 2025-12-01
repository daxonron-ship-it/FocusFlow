import SwiftUI

/// Challenge view where user must type the phrase to quit
/// Uses keyboard-aware layout with ScrollViewReader to keep input visible
/// Shows emergency bypass hint after 3 failed attempts
struct ChallengeView: View {
    let challengePhrase: String
    let onComplete: () -> Void
    let onGoBack: () -> Void

    @State private var userInput: String = ""
    @State private var failedAttempts: Int = 0
    @State private var previousErrorCount: Int = 0
    @FocusState private var isInputFocused: Bool

    private var isMatchComplete: Bool {
        StringNormalization.isComplete(userInput: userInput, challengePhrase: challengePhrase)
    }

    private var hasError: Bool {
        StringNormalization.firstMismatchIndex(userInput: userInput, challengePhrase: challengePhrase) != nil
    }

    /// Show hint after 3 failed attempts
    private var showBypassHint: Bool {
        failedAttempts >= 3
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

                    // Emergency bypass hint (after 3 failed attempts)
                    if showBypassHint {
                        HStack(spacing: AppSpacing.sm) {
                            Image(systemName: "lightbulb.fill")
                                .foregroundColor(AppColors.textSecondary)

                            Text("Stuck? Long-press the countdown timer.")
                                .font(.system(size: AppFontSize.caption, weight: .regular, design: .rounded))
                                .foregroundColor(AppColors.textSecondary)
                        }
                        .padding(.horizontal, AppSpacing.md)
                        .padding(.vertical, AppSpacing.sm)
                        .background(
                            RoundedRectangle(cornerRadius: AppCornerRadius.small)
                                .fill(AppColors.cardBackground)
                        )
                        .transition(.opacity.combined(with: .move(edge: .top)))
                        .id("hint")
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
                                } else {
                                    // User pressed submit with incorrect text - count as failed attempt
                                    trackFailedAttempt()
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
                        Button(action: {
                            if isMatchComplete {
                                completeChallenge()
                            } else {
                                // Tapping button with incorrect text counts as failed attempt
                                trackFailedAttempt()
                            }
                        }) {
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
            .onChange(of: userInput) { oldValue, newValue in
                // Light haptic on each keystroke
                if !newValue.isEmpty {
                    HapticManager.shared.selectionChanged()
                }

                // Track failed attempts when user makes a significant error
                // (types wrong character after having a correct prefix)
                let currentErrorCount = countErrors(in: newValue)
                if currentErrorCount > previousErrorCount && newValue.count >= oldValue.count {
                    // User typed a wrong character (not just deleting)
                    trackFailedAttempt()
                }
                previousErrorCount = currentErrorCount
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.background.ignoresSafeArea())
        .animation(.easeInOut(duration: 0.3), value: showBypassHint)
        .onAppear {
            // Auto-focus the text field
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isInputFocused = true
            }
        }
    }

    private func countErrors(in input: String) -> Int {
        // Count how many times user has had an error at the current position
        // For simplicity, just check if there's currently an error
        return StringNormalization.firstMismatchIndex(userInput: input, challengePhrase: challengePhrase) != nil ? 1 : 0
    }

    private func trackFailedAttempt() {
        // Only increment if user has typed something substantial (at least 3 chars)
        // to avoid counting early typos
        if userInput.count >= 3 {
            failedAttempts += 1
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
