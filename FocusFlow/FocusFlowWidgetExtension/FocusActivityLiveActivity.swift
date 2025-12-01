//
//  FocusActivityLiveActivity.swift
//  FocusFlowWidgetExtension
//
//  Live Activity for Dynamic Island and Lock Screen during focus sessions.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct FocusActivityLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: FocusActivityAttributes.self) { context in
            // Lock Screen / Banner UI
            LockScreenView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded region - shown when long-pressing Dynamic Island
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 4) {
                        Image(systemName: "target")
                            .foregroundColor(context.state.sessionType == "Focus" ? .blue : .green)
                        Text(context.state.sessionType)
                            .font(.caption.weight(.semibold))
                    }
                }

                DynamicIslandExpandedRegion(.trailing) {
                    Text("FocusFlow")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                DynamicIslandExpandedRegion(.center) {
                    // Auto-updating countdown - NO background updates needed!
                    Text(timerInterval: context.attributes.startTime...context.attributes.endTime,
                         countsDown: true)
                        .font(.system(size: 32, weight: .bold, design: .monospaced))
                        .foregroundColor(.primary)
                }

                DynamicIslandExpandedRegion(.bottom) {
                    // Progress bar
                    ProgressView(
                        timerInterval: context.attributes.startTime...context.attributes.endTime,
                        countsDown: false
                    ) {
                        EmptyView()
                    } currentValueLabel: {
                        EmptyView()
                    }
                    .progressViewStyle(.linear)
                    .tint(context.state.sessionType == "Focus" ? .blue : .green)
                }
            } compactLeading: {
                // Compact leading - left side of pill
                Image(systemName: "target")
                    .foregroundColor(context.state.sessionType == "Focus" ? .blue : .green)
            } compactTrailing: {
                // Compact trailing - right side of pill with countdown
                Text(timerInterval: context.attributes.startTime...context.attributes.endTime,
                     countsDown: true)
                    .font(.caption.monospacedDigit())
                    .frame(minWidth: 36)
            } minimal: {
                // Minimal - just the icon when other activities compete
                Image(systemName: "target")
                    .foregroundColor(context.state.sessionType == "Focus" ? .blue : .green)
            }
        }
    }
}

// MARK: - Lock Screen View

struct LockScreenView: View {
    let context: ActivityViewContext<FocusActivityAttributes>

    private var progressColor: Color {
        context.state.sessionType == "Focus" ? .blue : .green
    }

    private var progress: Double {
        let total = context.attributes.duration
        guard total > 0 else { return 0 }

        let elapsed = Date().timeIntervalSince(context.attributes.startTime)
        return min(1.0, max(0.0, elapsed / total))
    }

    var body: some View {
        HStack(spacing: 16) {
            // App icon / indicator
            ZStack {
                Circle()
                    .fill(progressColor.opacity(0.2))
                    .frame(width: 44, height: 44)

                Image(systemName: "target")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(progressColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                // App name
                Text("FocusFlow")
                    .font(.caption.weight(.medium))
                    .foregroundColor(.secondary)

                // Auto-updating countdown - NO background updates needed!
                Text(timerInterval: context.attributes.startTime...context.attributes.endTime,
                     countsDown: true)
                    .font(.system(size: 24, weight: .bold, design: .monospaced))
                    .foregroundColor(.primary)

                // Session type
                Text("\(context.state.sessionType) Time")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Circular progress indicator
            ZStack {
                Circle()
                    .stroke(progressColor.opacity(0.3), lineWidth: 4)
                    .frame(width: 44, height: 44)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(progressColor, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 44, height: 44)
                    .rotationEffect(.degrees(-90))

                Image(systemName: context.state.sessionType == "Focus" ? "brain.head.profile" : "cup.and.saucer")
                    .font(.system(size: 16))
                    .foregroundColor(progressColor)
            }
        }
        .padding()
        .background(Color(uiColor: .systemBackground))
        .activityBackgroundTint(Color(uiColor: .systemBackground))
    }
}

// MARK: - Previews

#Preview("Lock Screen", as: .content, using: FocusActivityAttributes(
    startTime: Date(),
    endTime: Date().addingTimeInterval(25 * 60),
    duration: 25 * 60
)) {
    FocusActivityLiveActivity()
} contentStates: {
    FocusActivityAttributes.ContentState(
        sessionId: UUID(),
        sessionType: "Focus"
    )
}

#Preview("Dynamic Island Compact", as: .dynamicIsland(.compact), using: FocusActivityAttributes(
    startTime: Date(),
    endTime: Date().addingTimeInterval(25 * 60),
    duration: 25 * 60
)) {
    FocusActivityLiveActivity()
} contentStates: {
    FocusActivityAttributes.ContentState(
        sessionId: UUID(),
        sessionType: "Focus"
    )
}

#Preview("Dynamic Island Expanded", as: .dynamicIsland(.expanded), using: FocusActivityAttributes(
    startTime: Date(),
    endTime: Date().addingTimeInterval(25 * 60),
    duration: 25 * 60
)) {
    FocusActivityLiveActivity()
} contentStates: {
    FocusActivityAttributes.ContentState(
        sessionId: UUID(),
        sessionType: "Focus"
    )
}
