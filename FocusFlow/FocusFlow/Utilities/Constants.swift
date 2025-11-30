import SwiftUI

enum AppColors {
    static let primary = Color(hex: "1E3A5F")       // Deep Blue - trust, focus, calm
    static let accent = Color(hex: "FF6B35")        // Vibrant Orange - urgency, action
    static let success = Color(hex: "4CAF50")       // Soft Green - completion, streaks
    static let danger = Color(hex: "D64545")        // Muted Red - quit actions, resets
    static let background = Color(hex: "0D1117")    // Near-black
    static let secondaryBackground = Color(hex: "161B22")
    static let cardBackground = Color(hex: "21262D")
    static let textPrimary = Color.white
    static let textSecondary = Color(hex: "8B949E")
}

enum AppSpacing {
    static let unit: CGFloat = 8
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
}

enum AppCornerRadius {
    static let small: CGFloat = 8
    static let medium: CGFloat = 12
    static let large: CGFloat = 16
    static let extraLarge: CGFloat = 24
}

enum AppFontSize {
    static let timerDisplay: CGFloat = 48
    static let title: CGFloat = 28
    static let headline: CGFloat = 20
    static let body: CGFloat = 16
    static let caption: CGFloat = 14
    static let small: CGFloat = 12
}

enum TimerPreset: CaseIterable, Identifiable {
    case pomodoro25
    case pomodoro50
    case pomodoro90

    var id: Self { self }

    var workDuration: TimeInterval {
        switch self {
        case .pomodoro25: return 25 * 60
        case .pomodoro50: return 50 * 60
        case .pomodoro90: return 90 * 60
        }
    }

    var breakDuration: TimeInterval {
        switch self {
        case .pomodoro25: return 5 * 60
        case .pomodoro50: return 10 * 60
        case .pomodoro90: return 20 * 60
        }
    }

    var displayName: String {
        switch self {
        case .pomodoro25: return "25/5"
        case .pomodoro50: return "50/10"
        case .pomodoro90: return "90/20"
        }
    }

    var description: String {
        switch self {
        case .pomodoro25: return "25 min focus, 5 min break"
        case .pomodoro50: return "50 min focus, 10 min break"
        case .pomodoro90: return "90 min focus, 20 min break"
        }
    }
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Time Formatting

extension TimeInterval {
    var formattedTime: String {
        let totalSeconds = Int(self)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var formattedTimeVerbose: String {
        let totalSeconds = Int(self)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes) min"
        }
    }
}
