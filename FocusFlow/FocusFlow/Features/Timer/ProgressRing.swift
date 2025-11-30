import SwiftUI

struct ProgressRing: View {
    let progress: Double
    let remainingTime: TimeInterval
    let sessionType: SessionType
    let lineWidth: CGFloat

    init(
        progress: Double,
        remainingTime: TimeInterval,
        sessionType: SessionType = .work,
        lineWidth: CGFloat = 12
    ) {
        self.progress = progress
        self.remainingTime = remainingTime
        self.sessionType = sessionType
        self.lineWidth = lineWidth
    }

    private var ringColor: Color {
        sessionType == .work ? AppColors.primary : AppColors.success
    }

    private var trackColor: Color {
        ringColor.opacity(0.2)
    }

    var body: some View {
        ZStack {
            // Background track
            Circle()
                .stroke(trackColor, lineWidth: lineWidth)

            // Progress ring
            Circle()
                .trim(from: 0, to: CGFloat(min(progress, 1.0)))
                .stroke(
                    ringColor,
                    style: StrokeStyle(
                        lineWidth: lineWidth,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.1), value: progress)

            // Center content
            VStack(spacing: AppSpacing.sm) {
                Text(remainingTime.formattedTime)
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundColor(AppColors.textPrimary)

                Text(sessionType.displayName.uppercased())
                    .font(.system(size: AppFontSize.caption, weight: .semibold, design: .rounded))
                    .foregroundColor(AppColors.textSecondary)
                    .tracking(1.5)
            }
        }
        .accessibilityElement()
        .accessibilityLabel("Focus timer")
        .accessibilityValue("\(Int(remainingTime / 60)) minutes \(Int(remainingTime.truncatingRemainder(dividingBy: 60))) seconds remaining, \(Int(progress * 100)) percent complete")
    }
}

#Preview {
    ZStack {
        AppColors.background.ignoresSafeArea()

        ProgressRing(
            progress: 0.65,
            remainingTime: 15 * 60 + 30,
            sessionType: .work
        )
        .frame(width: 280, height: 280)
    }
}
