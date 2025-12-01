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

enum Weekday: Int, Codable, CaseIterable, Comparable {
    case sunday = 1
    case monday = 2
    case tuesday = 3
    case wednesday = 4
    case thursday = 5
    case friday = 6
    case saturday = 7

    var shortName: String {
        switch self {
        case .sunday: return "Su"
        case .monday: return "Mo"
        case .tuesday: return "Tu"
        case .wednesday: return "We"
        case .thursday: return "Th"
        case .friday: return "Fr"
        case .saturday: return "Sa"
        }
    }

    var fullName: String {
        switch self {
        case .sunday: return "Sunday"
        case .monday: return "Monday"
        case .tuesday: return "Tuesday"
        case .wednesday: return "Wednesday"
        case .thursday: return "Thursday"
        case .friday: return "Friday"
        case .saturday: return "Saturday"
        }
    }

    var singleLetter: String {
        switch self {
        case .sunday: return "S"
        case .monday: return "M"
        case .tuesday: return "T"
        case .wednesday: return "W"
        case .thursday: return "T"
        case .friday: return "F"
        case .saturday: return "S"
        }
    }

    static func < (lhs: Weekday, rhs: Weekday) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
