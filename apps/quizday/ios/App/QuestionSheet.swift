import FactoryKit
import SwiftUI

/// The sheet one question is printed on, shared by the daily edition and the composing room —
/// and the ink press, which is the verb she performs a hundred times a week.
///
/// Pressing an answer is pressing ink into paper: the box fills left to right, the type knocks
/// out to paper colour as the ink passes under it, the impression lands in the hand, the
/// verdict stamp drops off-axis, and on a miss a pencil circles the right line and strikes out
/// the wrong one. No green pill, no red border, no buzzer.
struct QuestionSheet: View {
    @Environment(\.brand) private var brand
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let item: QuizItem
    let position: Int
    let total: Int
    /// One entry per answer so far in this round, this one included once it is pressed.
    var flags: [Bool] = []
    let selected: Int?
    let stampLine: String
    let reported: Bool
    /// The very first question of a player's first round teaches itself, without a word.
    var teaching = false
    /// The composing room has no tally and its own header.
    var header: String?
    let onAnswer: (Int) -> Void
    let onReport: () -> Void
    let onNext: () -> Void

    @State private var ink: CGFloat = 0
    @State private var printedInk: CGFloat = 0
    @State private var stamped = false
    @State private var pencil: CGFloat = 0
    @State private var footnote = false
    @State private var footnoteRule: CGFloat = 0
    @State private var tallyInked = false
    @State private var shakes = 0
    @State private var teach: CGFloat = 0

    private var isRevealed: Bool { selected != nil }
    private var isCorrect: Bool { selected == item.correct }
    private let letters = ["A", "B", "C", "D", "E", "F"]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                sectionMark

                if header == nil {
                    Tally(flags: tallyFlags, total: total, height: 26)
                }

                Text(item.question)
                    .brandDisplay(size: 27, relativeTo: .title2)
                    .foregroundStyle(brand.palette.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
                InkRule(weight: 2.5)

                VStack(spacing: 10) {
                    ForEach(Array(item.answers.enumerated()), id: \.offset) { index, answer in
                        answerBox(index: index, answer: answer)
                    }
                }

                if isRevealed, footnote || Motion.isStill {
                    reveal
                }

                PrintersOrnament()
                    .padding(.top, 4)
            }
            .padding(.horizontal, 30)
            .padding(.top, 6)
            .padding(.bottom, 18)
            .shake(trigger: shakes)
        }
        .paper()
        .safeAreaInset(edge: .bottom) {
            if isRevealed {
                VStack(spacing: 0) {
                    InkRule(weight: 1.2)
                    Button {
                        Haptics.tap()
                        onNext()
                    } label: {
                        Text(position == total ? "Print the edition" : "Next question")
                            .frame(maxWidth: .infinity)
                    }
                    .brandProminent()
                    .padding(.horizontal, 30)
                    .padding(.top, 12)
                    .padding(.bottom, 10)
                }
                .background {
                    brand.palette.canvas.opacity(0.96).ignoresSafeArea()
                }
            }
        }
        .onAppear(perform: startTeaching)
        .onChange(of: selected) { _, new in
            guard new != nil else { return }
            press(correct: new == item.correct)
        }
        .task {
            // A screen reached with the answer already pressed (a capture, or the demo flag)
            // arrives with `selected` set, so onChange never fires.
            if isRevealed, ink == 0 { press(correct: isCorrect) }
        }
    }

    /// Until the ink has landed the tally still shows the round as it was, so the square
    /// printing is something that happens rather than something that was already true.
    private var tallyFlags: [Bool] {
        isRevealed && !tallyInked && !Motion.isStill ? Array(flags.dropLast()) : flags
    }

    // MARK: - The head of the sheet

    private var sectionMark: some View {
        HStack(spacing: 8) {
            if let header {
                Text(header).dateline(10, tracking: 2, color: brand.palette.ink.opacity(0.75))
            } else {
                Rectangle()
                    .fill(AppBrand.ink(for: item.category))
                    .frame(width: 3, height: 12)
                Text(item.category)
                    .dateline(10, tracking: 2, color: brand.palette.ink.opacity(0.75))
                Spacer(minLength: 8)
                Text("Q\(position) of \(total) · \(item.difficulty)")
                    .dateline(10, tracking: 2)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: - The ruled boxes

    @ViewBuilder
    private func answerBox(index: Int, answer: String) -> some View {
        let chosen = selected == index
        let correct = index == item.correct
        let shape = RoundedRectangle(cornerRadius: 6, style: .continuous)
        // The box she pressed takes ink — proof green if it was right, graphite if not. On a
        // miss the printed answer inks in too, behind the pencil: that is the line she came
        // to read, and it should be set in proof green, not merely circled.
        let sweep = chosen ? ink
                  : (isRevealed && !isCorrect && correct) ? printedInk
                  : (teaching && !isRevealed && index == 0) ? teach : 0
        let inkColor = chosen && !isCorrect ? brand.palette.miss : brand.palette.success

        Button {
            guard !isRevealed else { return }
            teach = 0
            onAnswer(index)
        } label: {
            ZStack(alignment: .leading) {
                row(answer: answer, letter: letters[min(index, letters.count - 1)],
                    foreground: brand.palette.ink, gutter: brand.palette.ink.opacity(0.06))
                ZStack(alignment: .leading) {
                    inkColor
                    row(answer: answer, letter: letters[min(index, letters.count - 1)],
                        foreground: brand.palette.canvas, gutter: .clear)
                }
                .mask { InkSweep(progress: sweep) }
            }
            .background(shape.fill(brand.palette.surface))
            .clipShape(shape)
            .overlay(shape.stroke(brand.palette.ink.opacity(0.85), lineWidth: 1.2))
            // Over the box she pressed, hanging past the right margin. When she was right it
            // straddles the bottom rule instead of the line — that line is what she came for.
            .overlay(alignment: isCorrect ? .bottomTrailing : .trailing) {
                if chosen, stamped || Motion.isStill {
                    Stamp(text: stampLine)
                        .fixedSize()
                        .rotationEffect(.degrees(-6))
                        .offset(x: 16, y: isCorrect ? 17 : 0)
                        .transition(.scale(scale: 1.6).combined(with: .opacity))
                        .allowsHitTesting(false)
                }
            }
            .overlay {
                // The correction, drawn by hand: the right line circled, the wrong one struck.
                if isRevealed, !isCorrect {
                    if correct {
                        PencilEllipse()
                            .trim(to: pencil)
                            .stroke(brand.palette.miss,
                                    style: StrokeStyle(lineWidth: 2.2, lineCap: .round))
                            .padding(-6)
                            .allowsHitTesting(false)
                    } else if chosen {
                        PencilStrike()
                            .trim(to: pencil)
                            .stroke(brand.palette.canvas.opacity(0.9),
                                    style: StrokeStyle(lineWidth: 2, lineCap: .round))
                            .allowsHitTesting(false)
                    }
                }
            }
            .overlay(alignment: .top) {
                // The ghost of the stamp, hovering over the first box of a first round.
                if teaching, !isRevealed, index == 0 {
                    Image("Stamp")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 92)
                        .opacity(0.4)
                        .offset(y: -52)
                        .ambientFloat(distance: 5, period: 3.4)
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                    }
            }
        }
        .buttonStyle(.pressable(scale: 0.985))
        .disabled(isRevealed)
        .accessibilityLabel(answer)
        // The one place the app is allowed to explain itself: nothing on screen says this.
        .accessibilityHint(isRevealed ? revealedHint(index: index) : "Tap to stamp this answer")
    }

    private func row(answer: String, letter: String, foreground: Color, gutter: Color) -> some View {
        HStack(spacing: 0) {
            Text(letter)
                .dateline(11, tracking: 1.6, color: foreground.opacity(0.75))
                .frame(width: 26)
                .frame(maxHeight: .infinity)
                .background(gutter)
            Rectangle()
                .fill(foreground.opacity(0.22))
                .frame(width: 0.5)
            Text(answer)
                .scaledFont(size: 19, design: .serif, relativeTo: .body)
                .foregroundStyle(foreground)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 14)
                .padding(.vertical, 13)
        }
        .frame(minHeight: 52)
    }

    private func revealedHint(index: Int) -> String {
        if index == item.correct { return "The printed answer" }
        if index == selected { return "Your answer, pencilled out" }
        return ""
    }

    // MARK: - The footnote

    private var reveal: some View {
        VStack(alignment: .leading, spacing: 10) {
            GeometryReader { geo in
                Path { path in
                    path.move(to: CGPoint(x: 0, y: 0.5))
                    path.addLine(to: CGPoint(x: geo.size.width, y: 0.5))
                }
                .trim(to: Motion.isStill ? 1 : footnoteRule)
                .stroke(brand.palette.ink.opacity(0.3), lineWidth: 1)
            }
            .frame(height: 1)

            Text(item.explanation ?? "The printed answer is \(item.correctAnswer).")
                .scaledFont(size: 17, design: .serif, relativeTo: .body)
                .foregroundStyle(brand.palette.ink)
                .fixedSize(horizontal: false, vertical: true)

            HStack(alignment: .firstTextBaseline, spacing: 12) {
                if let source = item.source {
                    Text("Source · \(source)").dateline(10, tracking: 1.6)
                }
                Spacer(minLength: 4)
                Button {
                    Haptics.tap()
                    onReport()
                } label: {
                    Text(reported ? "¶ passed to the desk" : "¶ something wrong here?")
                        .dateline(10, tracking: 1.6,
                                  color: reported ? brand.palette.inkSoft : brand.palette.accent)
                }
                .buttonStyle(.plain)
                .disabled(reported)
            }
        }
        .offset(y: footnote || Motion.isStill ? 0 : 14)
        .opacity(footnote || Motion.isStill ? 1 : 0)
    }

    // MARK: - The press

    /// The four beats. Under `-stillFrames` they all land at once, so a capture shows the
    /// impression rather than a box mid-sweep.
    private func press(correct: Bool) {
        guard Motion.isStill == false else {
            ink = 1
            printedInk = 1
            stamped = true
            pencil = 1
            footnote = true
            footnoteRule = 1
            tallyInked = true
            return
        }
        withAnimation(Motion.resolved(.spring(response: 0.26, dampingFraction: 0.85))) { ink = 1 }
        at(0.20) { Haptics.rigid() }
        at(0.21) { Tones.shared.play(correct ? .pop : .miss) }
        at(0.23) { withMotion(Motion.bouncy) { stamped = true } }
        at(0.38) { Haptics.thud() }
        if !correct {
            at(0.30) {
                shakes += 1
                // The right line prints and the pencil goes round it at the same time.
                withAnimation(Motion.resolved(.spring(response: 0.3, dampingFraction: 0.85))) { printedInk = 1 }
                withAnimation(Motion.resolved(.easeInOut(duration: 0.34))) { pencil = 1 }
            }
        }
        at(0.42) {
            withAnimation(Motion.resolved(.easeOut(duration: 0.2))) { footnoteRule = 1 }
            withMotion(Motion.gentle) { footnote = true }
        }
        at(0.52) {
            Haptics.selection()
            Tones.shared.play(.step(flags.filter { $0 }.count))
            withMotion(Motion.snappy) { tallyInked = true }
        }
    }

    private func at(_ seconds: Double, _ work: @escaping () -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds, execute: work)
    }

    /// No label anywhere says "tap an answer". Box A takes a breath of ink instead, and stops
    /// the instant anything is touched.
    private func startTeaching() {
        guard teaching, !isRevealed, !Motion.isStill, !reduceMotion else { return }
        withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) { teach = 0.12 }
    }
}

/// The mask the ink travels behind: opaque up to `progress`, with a soft leading edge, so the
/// answer fills from the gutter outwards instead of switching colour.
struct InkSweep: View {
    var progress: CGFloat
    /// About 14 pt of the width of an answer box.
    private let soft: CGFloat = 0.045

    var body: some View {
        if progress >= 1 {
            Color.black
        } else {
            gradient
        }
    }

    private var gradient: some View {
        LinearGradient(
            stops: [
                .init(color: .black, location: 0),
                .init(color: .black, location: max(0, min(1, progress - soft))),
                .init(color: .clear, location: max(0, min(1, progress))),
                .init(color: .clear, location: 1),
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}
