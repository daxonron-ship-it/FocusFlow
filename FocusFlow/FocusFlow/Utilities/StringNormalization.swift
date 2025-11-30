import Foundation

/// Utilities for normalizing strings for comparison in challenge typing
enum StringNormalization {
    /// Normalize text for comparison - handles smart quotes, apostrophes, and whitespace
    /// Used to validate challenge phrases without being blocked by iOS autocorrect quirks
    static func normalizeForComparison(_ text: String) -> String {
        text.lowercased()
            // Curly/smart apostrophes to straight
            .replacingOccurrences(of: "\u{2019}", with: "'")  // Right single quote '
            .replacingOccurrences(of: "\u{2018}", with: "'")  // Left single quote '
            .replacingOccurrences(of: "`", with: "'")  // Backtick
            // Smart double quotes to straight
            .replacingOccurrences(of: "\u{201C}", with: "\"") // Left double quote "
            .replacingOccurrences(of: "\u{201D}", with: "\"") // Right double quote "
            // En/em dashes to hyphen
            .replacingOccurrences(of: "\u{2013}", with: "-")  // En dash –
            .replacingOccurrences(of: "\u{2014}", with: "-")  // Em dash —
            // Trim whitespace
            .trimmingCharacters(in: .whitespaces)
    }

    /// Check if user input matches the challenge phrase (normalized comparison)
    static func matches(userInput: String, challengePhrase: String) -> Bool {
        normalizeForComparison(userInput) == normalizeForComparison(challengePhrase)
    }

    /// Character status for inline feedback display
    enum CharacterStatus {
        case correct    // Green - character matches
        case incorrect  // Red - first mismatched character
        case pending    // Gray - after first error or not yet typed
    }

    /// Get the status of each character in user input compared to challenge
    /// Returns array of statuses, one per character in userInput
    static func characterStatuses(userInput: String, challengePhrase: String) -> [CharacterStatus] {
        var statuses: [CharacterStatus] = []
        var foundError = false

        let inputChars = Array(userInput)
        let challengeChars = Array(challengePhrase)

        for (index, inputChar) in inputChars.enumerated() {
            if foundError {
                // Everything after first error is pending
                statuses.append(.pending)
            } else if index >= challengeChars.count {
                // Input is longer than challenge - error
                statuses.append(.incorrect)
                foundError = true
            } else if inputChar == challengeChars[index] {
                // Exact match (case-sensitive for visual feedback)
                statuses.append(.correct)
            } else {
                // Mismatch - this is the first error
                statuses.append(.incorrect)
                foundError = true
            }
        }

        return statuses
    }

    /// Find the index of the first mismatch between user input and challenge
    /// Returns nil if input matches challenge so far (or input is empty)
    static func firstMismatchIndex(userInput: String, challengePhrase: String) -> Int? {
        let inputChars = Array(userInput)
        let challengeChars = Array(challengePhrase)

        for (index, inputChar) in inputChars.enumerated() {
            if index >= challengeChars.count {
                // Input is longer than expected
                return index
            }
            if inputChar != challengeChars[index] {
                return index
            }
        }

        return nil
    }

    /// Check if user input is complete and matches (for enabling submit button)
    static func isComplete(userInput: String, challengePhrase: String) -> Bool {
        // Use normalized comparison for actual validation
        matches(userInput: userInput, challengePhrase: challengePhrase)
    }
}
