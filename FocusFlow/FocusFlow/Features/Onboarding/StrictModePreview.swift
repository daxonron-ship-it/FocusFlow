//
//  StrictModePreview.swift
//  FocusFlow
//
//  Interactive walkthrough shown when user first enables Strict Mode.
//  Helps users understand the friction system before committing.
//

import SwiftUI

struct StrictModePreview: View {
    @Binding var isPresented: Bool
    let onEnable: (ChallengeType, StrictModeTone) -> Void

    @State private var step = 0
    @State private var selectedChallengeType: ChallengeType = .phrase
    @State private var selectedTone: StrictModeTone = .neutral

    private let totalSteps = 6

    var body: some View {
        ZStack {
            AppColors.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Progress indicator
                HStack(spacing: 4) {
                    ForEach(0..<totalSteps, id: \.self) { index in
                        Rectangle()
                            .fill(index <= step ? AppColors.accent : AppColors.cardBackground)
                            .frame(height: 3)
                            .cornerRadius(1.5)
                    }
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.top, AppSpacing.md)

                // Content
                Group {
                    switch step {
                    case 0:
                        IntroStepView()
                    case 1:
                        DelayDemoView()
                    case 2:
                        ChallengeTypeSelectionView(selectedType: $selectedChallengeType)
                    case 3:
                        PhraseDemoView(tone: selectedTone)
                    case 4:
                        StreakWarningDemoView()
                    case 5:
                        ConfirmationView()
                    default:
                        EmptyView()
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))

                Spacer()

                // Navigation
                HStack {
                    if step > 0 {
                        Button("Back") {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                step -= 1
                            }
                        }
                        .foregroundColor(AppColors.textSecondary)
                    }

                    Spacer()

                    if step < totalSteps - 1 {
                        Button("Next") {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                step += 1
                            }
                        }
                        .fontWeight(.semibold)
                        .foregroundColor(AppColors.accent)
                    } else {
                        Button("Enable Strict Mode") {
                            onEnable(selectedChallengeType, selectedTone)
                            isPresented = false
                        }
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, AppSpacing.lg)
                        .padding(.vertical, AppSpacing.sm)
                        .background(AppColors.accent)
                        .cornerRadius(AppCornerRadius.medium)
                    }
                }
                .padding(.horizontal, AppSpacing.xl)
                .padding(.bottom, AppSpacing.xl)

                // Cancel button
                Button("Cancel") {
                    isPresented = false
                }
                .font(.system(size: AppFontSize.caption))
                .foregroundColor(AppColors.textSecondary)
                .padding(.bottom, AppSpacing.lg)
            }
        }
    }
}

// MARK: - Step Views

struct IntroStepView: View {
    var body: some View {
        VStack(spacing: AppSpacing.xl) {
            Spacer()

            ZStack {
                Circle()
                    .fill(AppColors.accent.opacity(0.2))
                    .frame(width: 120, height: 120)

                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 50))
                    .foregroundColor(AppColors.accent)
            }

            VStack(spacing: AppSpacing.md) {
                Text("Strict Mode")
                    .font(.system(size: AppFontSize.title, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.textPrimary)

                Text("Makes quitting hard on purpose.")
                    .font(.system(size: AppFontSize.headline, weight: .medium))
                    .foregroundColor(AppColors.textPrimary)

                Text("It adds friction when you try to end a session early, helping you stay committed to your focus goals.")
                    .font(.system(size: AppFontSize.body))
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppSpacing.lg)
            }

            Spacer()
        }
        .padding()
    }
}

struct DelayDemoView: View {
    @State private var countdown = 10
    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: AppSpacing.xl) {
            Spacer()

            Text("Step 1: Wait 10 Seconds")
                .font(.system(size: AppFontSize.headline, weight: .semibold))
                .foregroundColor(AppColors.textSecondary)

            ZStack {
                Circle()
                    .stroke(AppColors.cardBackground, lineWidth: 8)
                    .frame(width: 140, height: 140)

                Circle()
                    .trim(from: 0, to: isAnimating ? 0 : 1)
                    .stroke(AppColors.accent, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 140, height: 140)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 10), value: isAnimating)

                Text("\(countdown)")
                    .font(.system(size: 48, weight: .bold, design: .monospaced))
                    .foregroundColor(AppColors.textPrimary)
            }

            VStack(spacing: AppSpacing.sm) {
                Text("Take a moment to reconsider.")
                    .font(.system(size: AppFontSize.body, weight: .medium))
                    .foregroundColor(AppColors.textPrimary)

                Text("This delay prevents impulsive quitting and gives you time to refocus.")
                    .font(.system(size: AppFontSize.caption))
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppSpacing.lg)
            }

            Spacer()
        }
        .padding()
        .onAppear {
            startDemo()
        }
    }

    private func startDemo() {
        isAnimating = true

        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            if countdown > 0 {
                countdown -= 1
            } else {
                timer.invalidate()
                // Reset for re-viewing
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    countdown = 10
                    isAnimating = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        startDemo()
                    }
                }
            }
        }
    }
}

struct ChallengeTypeSelectionView: View {
    @Binding var selectedType: ChallengeType

    var body: some View {
        VStack(spacing: AppSpacing.lg) {
            Spacer()

            Text("Step 2: Complete a Challenge")
                .font(.system(size: AppFontSize.headline, weight: .semibold))
                .foregroundColor(AppColors.textSecondary)

            Text("Choose your challenge type:")
                .font(.system(size: AppFontSize.title, weight: .bold, design: .rounded))
                .foregroundColor(AppColors.textPrimary)

            VStack(spacing: AppSpacing.md) {
                ForEach(ChallengeType.allCases, id: \.self) { type in
                    ChallengeTypeCard(
                        type: type,
                        isSelected: selectedType == type
                    )
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedType = type
                            HapticManager.shared.lightTap()
                        }
                    }
                }
            }
            .padding(.horizontal, AppSpacing.lg)

            Spacer()
        }
        .padding()
    }
}

struct ChallengeTypeCard: View {
    let type: ChallengeType
    let isSelected: Bool

    private var icon: String {
        switch type {
        case .phrase: return "pencil.line"
        case .math: return "number"
        case .pattern: return "circle.grid.3x3"
        case .holdButton: return "hand.tap"
        }
    }

    private var description: String {
        switch type {
        case .phrase: return "\"I am choosing distraction...\""
        case .math: return "\"What is 47 + 38?\""
        case .pattern: return "\"Tap circles 1-5 in order\""
        case .holdButton: return "\"Hold for 10 seconds\""
        }
    }

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            ZStack {
                Circle()
                    .fill(isSelected ? AppColors.accent.opacity(0.2) : AppColors.cardBackground)
                    .frame(width: 44, height: 44)

                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(isSelected ? AppColors.accent : AppColors.textSecondary)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(type.displayName)
                    .font(.system(size: AppFontSize.body, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)

                Text(description)
                    .font(.system(size: AppFontSize.caption))
                    .foregroundColor(AppColors.textSecondary)
            }

            Spacer()

            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(AppColors.accent)
            }
        }
        .padding(AppSpacing.md)
        .background(isSelected ? AppColors.accent.opacity(0.1) : AppColors.cardBackground)
        .cornerRadius(AppCornerRadius.medium)
        .overlay(
            RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                .stroke(isSelected ? AppColors.accent : Color.clear, lineWidth: 2)
        )
    }
}

struct PhraseDemoView: View {
    let tone: StrictModeTone
    @State private var userInput = ""
    @State private var demoPhrase = "End session early"

    var body: some View {
        VStack(spacing: AppSpacing.lg) {
            Spacer()

            Text("Try It Out")
                .font(.system(size: AppFontSize.headline, weight: .semibold))
                .foregroundColor(AppColors.textSecondary)

            Text("Type the phrase exactly:")
                .font(.system(size: AppFontSize.body))
                .foregroundColor(AppColors.textPrimary)

            // Challenge phrase display
            Text("\"\(demoPhrase)\"")
                .font(.system(size: AppFontSize.headline, weight: .bold, design: .monospaced))
                .foregroundColor(AppColors.accent)
                .padding()
                .background(AppColors.cardBackground)
                .cornerRadius(AppCornerRadius.small)

            // Input field
            TextField("Type here...", text: $userInput)
                .font(.system(size: AppFontSize.body))
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .padding()
                .background(AppColors.cardBackground)
                .cornerRadius(AppCornerRadius.small)
                .padding(.horizontal, AppSpacing.lg)

            // Feedback
            if !userInput.isEmpty {
                if userInput.lowercased() == demoPhrase.lowercased() {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(AppColors.success)
                        Text("Perfect! You can proceed.")
                            .foregroundColor(AppColors.success)
                    }
                    .font(.system(size: AppFontSize.caption))
                } else {
                    HStack {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(AppColors.danger)
                        Text("Keep typing...")
                            .foregroundColor(AppColors.danger)
                    }
                    .font(.system(size: AppFontSize.caption))
                }
            }

            Text("This makes quitting a conscious decision, not an impulsive one.")
                .font(.system(size: AppFontSize.caption))
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppSpacing.xl)

            Spacer()
        }
        .padding()
    }
}

struct StreakWarningDemoView: View {
    @State private var streakValue = 12
    @State private var isShaking = false

    var body: some View {
        VStack(spacing: AppSpacing.xl) {
            Spacer()

            Text("Step 3: See What You'll Lose")
                .font(.system(size: AppFontSize.headline, weight: .semibold))
                .foregroundColor(AppColors.textSecondary)

            // Warning card mock
            VStack(spacing: AppSpacing.lg) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(AppColors.danger)

                Text("Warning")
                    .font(.system(size: AppFontSize.title, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)

                Text("You're about to lose your current streak:")
                    .font(.system(size: AppFontSize.body))
                    .foregroundColor(AppColors.textSecondary)

                HStack(spacing: AppSpacing.sm) {
                    Image(systemName: "flame.fill")
                        .foregroundColor(AppColors.accent)
                    Text("\(streakValue) days")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(AppColors.accent)
                }
                .modifier(ShakeEffect(animatableData: isShaking ? 1 : 0))

                Text("This cannot be undone.")
                    .font(.system(size: AppFontSize.caption, weight: .semibold))
                    .foregroundColor(AppColors.danger)
            }
            .padding(AppSpacing.xl)
            .background(AppColors.cardBackground)
            .cornerRadius(AppCornerRadius.large)
            .padding(.horizontal, AppSpacing.lg)

            Text("Loss aversion is powerful. Seeing your streak at risk makes quitting much harder.")
                .font(.system(size: AppFontSize.caption))
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppSpacing.xl)

            Spacer()
        }
        .padding()
        .onAppear {
            withAnimation(.default.repeatForever(autoreverses: true)) {
                isShaking = true
            }
        }
    }
}

struct ShakeEffect: GeometryEffect {
    var animatableData: CGFloat

    func effectValue(size: CGSize) -> ProjectionTransform {
        let shake = sin(animatableData * .pi * 4) * 3
        return ProjectionTransform(CGAffineTransform(translationX: shake, y: 0))
    }
}

struct ConfirmationView: View {
    var body: some View {
        VStack(spacing: AppSpacing.xl) {
            Spacer()

            ZStack {
                Circle()
                    .fill(AppColors.success.opacity(0.2))
                    .frame(width: 120, height: 120)

                Image(systemName: "checkmark.shield.fill")
                    .font(.system(size: 50))
                    .foregroundColor(AppColors.success)
            }

            VStack(spacing: AppSpacing.md) {
                Text("Ready to Commit?")
                    .font(.system(size: AppFontSize.title, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.textPrimary)

                Text("With Strict Mode enabled:")
                    .font(.system(size: AppFontSize.body))
                    .foregroundColor(AppColors.textPrimary)
            }

            VStack(alignment: .leading, spacing: AppSpacing.md) {
                FeatureRow(icon: "clock", text: "10-second delay before quitting")
                FeatureRow(icon: "pencil", text: "Challenge to prove intent")
                FeatureRow(icon: "flame", text: "Streak warning before reset")
                FeatureRow(icon: "clock.badge.exclamationmark", text: "24-hour wait to disable")
            }
            .padding(.horizontal, AppSpacing.lg)

            Text("You can change settings anytime (with a 24-hour delay after the first 15 minutes).")
                .font(.system(size: AppFontSize.caption))
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppSpacing.xl)

            Spacer()
        }
        .padding()
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(AppColors.success)
                .frame(width: 24)

            Text(text)
                .font(.system(size: AppFontSize.body))
                .foregroundColor(AppColors.textPrimary)
        }
    }
}

// MARK: - Previews

#Preview("Strict Mode Preview") {
    StrictModePreview(isPresented: .constant(true)) { _, _ in }
}

#Preview("Intro Step") {
    IntroStepView()
        .background(AppColors.background)
}

#Preview("Delay Demo") {
    DelayDemoView()
        .background(AppColors.background)
}

#Preview("Challenge Selection") {
    ChallengeTypeSelectionView(selectedType: .constant(.phrase))
        .background(AppColors.background)
}

#Preview("Phrase Demo") {
    PhraseDemoView(tone: .neutral)
        .background(AppColors.background)
}

#Preview("Streak Warning") {
    StreakWarningDemoView()
        .background(AppColors.background)
}

#Preview("Confirmation") {
    ConfirmationView()
        .background(AppColors.background)
}
