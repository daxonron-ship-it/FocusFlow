//
//  OnboardingFlow.swift
//  FocusFlow
//
//  Paged onboarding flow for first-time users.
//  NO permission requests during onboarding - just-in-time model.
//

import SwiftUI

struct OnboardingFlow: View {
    @State private var currentPage = 0
    let onComplete: () -> Void

    var body: some View {
        ZStack {
            AppColors.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Page content
                TabView(selection: $currentPage) {
                    WelcomeView()
                        .tag(0)

                    PrivacyView()
                        .tag(1)

                    FirstSessionView(onStart: {
                        onComplete()
                    })
                    .tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                // Page indicator and navigation
                VStack(spacing: AppSpacing.lg) {
                    // Custom page indicator
                    HStack(spacing: AppSpacing.sm) {
                        ForEach(0..<3, id: \.self) { index in
                            Circle()
                                .fill(index == currentPage ? AppColors.accent : AppColors.textSecondary.opacity(0.3))
                                .frame(width: 8, height: 8)
                                .animation(.easeInOut(duration: 0.2), value: currentPage)
                        }
                    }

                    // Navigation buttons
                    HStack {
                        if currentPage > 0 {
                            Button("Back") {
                                withAnimation {
                                    currentPage -= 1
                                }
                            }
                            .foregroundColor(AppColors.textSecondary)
                        }

                        Spacer()

                        if currentPage < 2 {
                            Button("Next") {
                                withAnimation {
                                    currentPage += 1
                                }
                            }
                            .fontWeight(.semibold)
                            .foregroundColor(AppColors.accent)
                        }
                    }
                    .padding(.horizontal, AppSpacing.xl)
                }
                .padding(.bottom, AppSpacing.xl)
            }
        }
    }
}

// MARK: - Welcome View

struct WelcomeView: View {
    var body: some View {
        VStack(spacing: AppSpacing.xl) {
            Spacer()

            // App icon
            ZStack {
                Circle()
                    .fill(AppColors.primary.opacity(0.2))
                    .frame(width: 140, height: 140)

                Image(systemName: "target")
                    .font(.system(size: 64, weight: .semibold))
                    .foregroundColor(AppColors.primary)
            }

            VStack(spacing: AppSpacing.md) {
                Text("Welcome to FocusFlow")
                    .font(.system(size: AppFontSize.title, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.textPrimary)

                Text("Stay focused by blocking distracting apps during your work sessions.")
                    .font(.system(size: AppFontSize.body))
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppSpacing.xl)
            }

            Spacer()
            Spacer()
        }
        .padding()
    }
}

// MARK: - Privacy View

struct PrivacyView: View {
    var body: some View {
        VStack(spacing: AppSpacing.xl) {
            Spacer()

            // Privacy icon
            ZStack {
                Circle()
                    .fill(AppColors.success.opacity(0.2))
                    .frame(width: 140, height: 140)

                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 64, weight: .semibold))
                    .foregroundColor(AppColors.success)
            }

            VStack(spacing: AppSpacing.md) {
                Text("Privacy First")
                    .font(.system(size: AppFontSize.title, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.textPrimary)

                Text("Your data never leaves your device.")
                    .font(.system(size: AppFontSize.headline, weight: .medium))
                    .foregroundColor(AppColors.textPrimary)

                Text("No account needed. No sign-up required.")
                    .font(.system(size: AppFontSize.body))
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
            }

            // Privacy features list
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                PrivacyFeatureRow(icon: "iphone", text: "100% offline operation")
                PrivacyFeatureRow(icon: "eye.slash", text: "No tracking or analytics")
                PrivacyFeatureRow(icon: "hand.raised", text: "No data collection")
            }
            .padding(.top, AppSpacing.lg)

            Spacer()
            Spacer()
        }
        .padding()
    }
}

struct PrivacyFeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(AppColors.success)
                .frame(width: 24)

            Text(text)
                .font(.system(size: AppFontSize.body))
                .foregroundColor(AppColors.textPrimary)
        }
    }
}

// MARK: - First Session View

struct FirstSessionView: View {
    let onStart: () -> Void
    @State private var isPulsing = false

    var body: some View {
        VStack(spacing: AppSpacing.xl) {
            Spacer()

            // Timer preview
            ZStack {
                Circle()
                    .stroke(AppColors.primary.opacity(0.3), lineWidth: 8)
                    .frame(width: 160, height: 160)

                Circle()
                    .trim(from: 0, to: 0.75)
                    .stroke(AppColors.primary, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 160, height: 160)
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 4) {
                    Text("25:00")
                        .font(.system(size: 36, weight: .bold, design: .monospaced))
                        .foregroundColor(AppColors.textPrimary)

                    Text("FOCUS TIME")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(AppColors.textSecondary)
                }
            }
            .scaleEffect(isPulsing ? 1.02 : 1.0)
            .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: isPulsing)
            .onAppear { isPulsing = true }

            VStack(spacing: AppSpacing.md) {
                Text("Ready to Focus?")
                    .font(.system(size: AppFontSize.title, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.textPrimary)

                Text("Start your first focus session and see how FocusFlow helps you stay on track.")
                    .font(.system(size: AppFontSize.body))
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppSpacing.lg)
            }

            Spacer()

            // Start button
            Button(action: onStart) {
                HStack(spacing: AppSpacing.sm) {
                    Image(systemName: "play.fill")
                    Text("Start 25-min Timer")
                }
                .font(.system(size: AppFontSize.headline, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppSpacing.md)
                .background(AppColors.accent)
                .cornerRadius(AppCornerRadius.medium)
            }
            .padding(.horizontal, AppSpacing.xl)

            // Skip option
            Button("Skip for now") {
                onStart()
            }
            .font(.system(size: AppFontSize.caption))
            .foregroundColor(AppColors.textSecondary)
            .padding(.bottom, AppSpacing.lg)
        }
        .padding()
    }
}

// MARK: - Previews

#Preview("Onboarding Flow") {
    OnboardingFlow(onComplete: {})
}

#Preview("Welcome") {
    WelcomeView()
        .background(AppColors.background)
}

#Preview("Privacy") {
    PrivacyView()
        .background(AppColors.background)
}

#Preview("First Session") {
    FirstSessionView(onStart: {})
        .background(AppColors.background)
}
