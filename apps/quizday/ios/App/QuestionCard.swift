import FactoryKit
import SwiftUI

/// The question view shared by the daily round and by practice.
///
/// Tapping an answer reveals the result straight away: the right answer turns green, a wrong
/// pick turns red, and the explanation and source appear underneath. There is no timer and
/// nothing to spend, so the only thing to do next is read and move on.
struct QuestionCard: View {
    let item: QuizItem
    let position: Int
    let total: Int
    let selected: Int?
    let reported: Bool
    let onAnswer: (Int) -> Void
    let onReport: () -> Void
    let onNext: () -> Void

    private var isRevealed: Bool { selected != nil }
    private var isCorrect: Bool { selected == item.correct }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                Text(item.question)
                    .font(.title2.weight(.semibold))
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)

                VStack(spacing: 10) {
                    ForEach(Array(item.answers.enumerated()), id: \.offset) { index, answer in
                        answerButton(index: index, answer: answer)
                    }
                }

                if isRevealed {
                    reveal
                        .transition(.opacity)
                }
            }
            .padding(FactoryTheme.padding)
        }
        .background(Color(.systemGroupedBackground))
        .safeAreaInset(edge: .bottom) {
            if isRevealed {
                Button(position == total ? "See your score" : "Next question") {
                    Haptics.tap()
                    onNext()
                }
                .buttonStyle(.factoryPrimary)
                .padding(.horizontal, FactoryTheme.padding)
                .padding(.top, 8)
                .padding(.bottom, 12)
                .background(.bar)
            }
        }
        .animation(.easeOut(duration: 0.18), value: selected)
    }

    private var header: some View {
        HStack(spacing: 8) {
            Text("\(position) of \(total)")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Color.accentColor)
            Text(item.category)
                .font(.footnote)
                .foregroundStyle(.secondary)
            Spacer()
            Text(item.difficulty.capitalized)
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Color(.tertiarySystemFill), in: Capsule())
        }
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private func answerButton(index: Int, answer: String) -> some View {
        let state = state(for: index)
        Button {
            guard !isRevealed else { return }
            Haptics.tap()
            onAnswer(index)
        } label: {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text(answer)
                    .font(.body)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 8)
                if let symbol = state.symbol {
                    Image(systemName: symbol).font(.body.weight(.semibold))
                }
            }
            .foregroundStyle(state.foreground)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(state.background, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(state.border, lineWidth: state.border == .clear ? 0 : 2)
            )
        }
        .buttonStyle(.plain)
        .disabled(isRevealed)
        .accessibilityLabel(answer)
        .accessibilityHint(isRevealed ? state.accessibilityHint : "Tap to answer")
    }

    private struct AnswerState {
        var foreground: Color
        var background: Color
        var border: Color
        var symbol: String?
        var accessibilityHint: String
    }

    private func state(for index: Int) -> AnswerState {
        guard let selected else {
            return AnswerState(foreground: .primary,
                               background: Color(.secondarySystemGroupedBackground),
                               border: .clear, symbol: nil, accessibilityHint: "")
        }
        if index == item.correct {
            return AnswerState(foreground: .primary,
                               background: Color.green.opacity(0.16),
                               border: .green, symbol: "checkmark.circle.fill",
                               accessibilityHint: "Correct answer")
        }
        if index == selected {
            return AnswerState(foreground: .primary,
                               background: Color.red.opacity(0.14),
                               border: .red, symbol: "xmark.circle.fill",
                               accessibilityHint: "Your answer, incorrect")
        }
        return AnswerState(foreground: .secondary,
                           background: Color(.secondarySystemGroupedBackground),
                           border: .clear, symbol: nil, accessibilityHint: "")
    }

    private var reveal: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(isCorrect ? "Correct" : "Not this time",
                  systemImage: isCorrect ? "checkmark.seal.fill" : "info.circle.fill")
                .font(.headline)
                .foregroundStyle(isCorrect ? Color.green : Color.orange)

            if let explanation = item.explanation {
                Text(explanation)
                    .font(.callout)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text("The answer is \(item.correctAnswer).")
                    .font(.callout)
            }

            if let source = item.source {
                Label("Source: \(source)", systemImage: "text.book.closed")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Divider()

            Button {
                Haptics.tap()
                onReport()
            } label: {
                Label(reported ? "Flagged for review" : "Report a problem",
                      systemImage: reported ? "flag.fill" : "flag")
                    .font(.footnote)
            }
            .disabled(reported)
            .foregroundStyle(reported ? Color.secondary : Color.accentColor)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .factoryCard()
    }
}
