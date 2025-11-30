import SwiftUI

/// Displays the challenge phrase with color-coded character feedback
/// Green = correct, Red = first error, Gray = after error/not yet typed
struct CharacterFeedbackView: View {
    let challengePhrase: String
    let userInput: String

    private var statuses: [StringNormalization.CharacterStatus] {
        StringNormalization.characterStatuses(userInput: userInput, challengePhrase: challengePhrase)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            // Display phrase with character-by-character coloring
            Text(attributedPhrase)
                .font(.system(size: AppFontSize.headline, weight: .medium, design: .monospaced))
                .multilineTextAlignment(.leading)
                .lineSpacing(4)
        }
        .padding(AppSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                .fill(AppColors.secondaryBackground)
        )
    }

    private var attributedPhrase: AttributedString {
        var result = AttributedString()

        let phraseChars = Array(challengePhrase)

        for (index, char) in phraseChars.enumerated() {
            var charString = AttributedString(String(char))

            if index < statuses.count {
                // We have a status for this character
                switch statuses[index] {
                case .correct:
                    charString.foregroundColor = AppColors.success
                case .incorrect:
                    charString.foregroundColor = AppColors.danger
                    charString.backgroundColor = AppColors.danger.opacity(0.2)
                case .pending:
                    charString.foregroundColor = AppColors.textSecondary
                }
            } else {
                // Character not yet typed - show as pending (gray)
                charString.foregroundColor = AppColors.textSecondary
            }

            result += charString
        }

        return result
    }
}

/// Simplified view that shows just the challenge phrase (before typing starts)
struct ChallengePhraseDisplayView: View {
    let phrase: String

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text("Type the following exactly:")
                .font(.system(size: AppFontSize.caption, weight: .regular, design: .rounded))
                .foregroundColor(AppColors.textSecondary)

            Text("\"\(phrase)\"")
                .font(.system(size: AppFontSize.headline, weight: .medium, design: .monospaced))
                .foregroundColor(AppColors.textPrimary)
                .multilineTextAlignment(.leading)
                .lineSpacing(4)
        }
        .padding(AppSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                .fill(AppColors.secondaryBackground)
        )
    }
}

#Preview("Character Feedback - Typing") {
    VStack(spacing: 20) {
        CharacterFeedbackView(
            challengePhrase: "I am choosing distraction over my goals",
            userInput: "I am choosing dis"
        )

        CharacterFeedbackView(
            challengePhrase: "I am choosing distraction over my goals",
            userInput: "I am choosing disttaction"  // Error at second 't'
        )

        CharacterFeedbackView(
            challengePhrase: "I am choosing distraction over my goals",
            userInput: ""
        )
    }
    .padding()
    .background(AppColors.background)
}

#Preview("Challenge Phrase Display") {
    ChallengePhraseDisplayView(phrase: "I am choosing distraction over my goals")
        .padding()
        .background(AppColors.background)
}
