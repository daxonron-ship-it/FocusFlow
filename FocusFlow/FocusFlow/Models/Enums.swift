import Foundation

enum SessionType: String, Codable, CaseIterable {
    case work
    case rest

    var displayName: String {
        switch self {
        case .work: return "Focus Time"
        case .rest: return "Break Time"
        }
    }
}

enum CompletionStatus: String, Codable {
    case completed
    case quitEarly
    case interrupted
    case inProgress
}

enum StrictModeTone: String, Codable, CaseIterable {
    case gentle
    case neutral
    case strict
    case custom

    var phrases: [String] {
        switch self {
        case .gentle:
            return [
                "I need a break right now",
                "Pausing for self-care",
                "Rest is productive too"
            ]
        case .neutral:
            return [
                "End session early",
                "Stop the timer",
                "Session incomplete"
            ]
        case .strict:
            return [
                "I am choosing distraction over my goals",
                "I am breaking my commitment",
                "Giving up on myself"
            ]
        case .custom:
            return []
        }
    }
}

enum ChallengeType: String, Codable, CaseIterable {
    case phrase
    case math
    case pattern
    case holdButton

    var displayName: String {
        switch self {
        case .phrase: return "Type a Phrase"
        case .math: return "Solve Math Problem"
        case .pattern: return "Tap Pattern"
        case .holdButton: return "Hold Button"
        }
    }
}

enum TimerState: Equatable {
    case idle
    case running
    case paused
    case completed
}
