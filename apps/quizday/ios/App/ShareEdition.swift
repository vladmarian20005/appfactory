import FactoryKit
import SwiftUI

/// What she sends to someone: the front page at 1080 × 1350, not a line of text nobody taps.
/// The text line stays as the fallback, in the paper's own squares.
enum ShareEdition {
    /// Rendered at the card's real pixel size, so every measurement here is the one in
    /// DESIGN.md's share-card spec. Outside the view hierarchy it inherits nothing: the brand
    /// and the light scheme are applied inside, so the card looks the same in every chat.
    @MainActor
    static func card(score: Int, total: Int, flags: [Bool], roundNumber: Int,
                     playedAt: Date, streak: Int, tier: Tier) -> Image? {
        ShareImage.render(size: CGSize(width: 1080, height: 1350), scale: 1) {
            EditionCard(score: score, total: total, flags: flags, roundNumber: roundNumber,
                        playedAt: playedAt, streak: streak, tier: tier)
                .brand(AppBrand.brand)
                .environment(\.colorScheme, .light)
        }
    }

    /// The fallback, in the stamp's red on paper.
    static func line(roundNumber: Int, flags: [Bool], streak: Int) -> String {
        let squares = flags.map { $0 ? "\u{1F7E5}" : "\u{2B1C}" }.joined()
        let score = flags.filter { $0 }.count
        var lines = ["Quizday · Round \(roundNumber)", "\(squares)  \(score)/\(flags.count)"]
        if streak > 1 { lines.append("Streak \(streak) days") }
        return lines.joined(separator: "\n")
    }
}

/// The front page as it will arrive in a group chat, on screen at the size it will be seen,
/// so the one thing in the app that nobody can screenshot from the share sheet can still be
/// looked at. Reached with `-screen share`; there is no way into it from the UI.
struct ShareCardPreview: View {
    @Environment(\.brand) private var brand
    let flags: [Bool]
    let roundNumber: Int
    let streak: Int

    private var score: Int { flags.filter { $0 }.count }

    var body: some View {
        VStack(spacing: 16) {
            Text("The edition, as it travels")
                .dateline(10, tracking: 2)
            EditionCard(score: score, total: flags.count, flags: flags,
                        roundNumber: roundNumber, playedAt: .now, streak: streak,
                        tier: Tier.forScore(score, total: flags.count))
                .scaleEffect(0.31, anchor: .center)
                .frame(width: 1080 * 0.31, height: 1350 * 0.31)
                .environment(\.colorScheme, .light)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .paper()
    }
}

/// The card itself. Fixed point sizes on purpose: an `ImageRenderer` at 1080 × 1350 has no
/// Dynamic Type to scale against, and the layout is the picture.
struct EditionCard: View {
    let score: Int
    let total: Int
    let flags: [Bool]
    let roundNumber: Int
    let playedAt: Date
    let streak: Int
    let tier: Tier

    private let ink = Color(hex: 0x1B2027)
    private let inkSoft = Color(hex: 0x5E6470)
    private let paper = Color(hex: 0xF5EFE2)
    private let accent = Color(hex: 0xC1362C)
    private let brass = Color(hex: 0x8E6214)

    private static func press(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight, design: .serif)
    }

    var body: some View {
        ZStack {
            paper
            PaperGrain(ink: ink, opacity: 0.03)
            // The ivory margin, then the rule that frames the page.
            Rectangle().strokeBorder(ink, lineWidth: 3).padding(24)

            VStack(spacing: 0) {
                Rectangle().fill(ink.opacity(0.35)).frame(height: 1)
                Text("QUIZDAY")
                    .font(Self.press(96))
                    .tracking(22)
                    .foregroundStyle(ink)
                    .padding(.top, 18)
                Rectangle().fill(ink).frame(height: 5).padding(.top, 14)

                Text(dateline)
                    .font(AppBrand.dateline(30))
                    .tracking(5)
                    .foregroundStyle(inkSoft)
                    .padding(.top, 26)

                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Text("\(score)")
                        .font(Self.press(320))
                        .foregroundStyle(ink)
                    Text("/\(total)")
                        .font(Self.press(96))
                        .foregroundStyle(inkSoft)
                }
                .padding(.top, 6)

                HStack(spacing: 12) {
                    ForEach(0..<total, id: \.self) { index in
                        let hit = index < flags.count && flags[index]
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(hit ? ink : Color.clear)
                            .frame(height: 72)
                            .overlay {
                                if !hit {
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .stroke(ink, lineWidth: 3)
                                }
                            }
                    }
                }
                .padding(.top, 22)

                Text(tier.headline.uppercased())
                    .font(Self.press(54).italic())
                    .tracking(4)
                    .foregroundStyle(accent)
                    .padding(.horizontal, 34)
                    .padding(.vertical, 18)
                    .overlay {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(accent, lineWidth: 4)
                    }
                    .rotationEffect(.degrees(-3))
                    .padding(.top, 54)

                Spacer(minLength: 0)

                if streak > 1 {
                    HStack {
                        Spacer(minLength: 0)
                        HStack(alignment: .firstTextBaseline, spacing: 14) {
                            Text("\(streak)")
                                .font(Self.press(72))
                                .foregroundStyle(Color(hex: 0xFFF8EC))
                            Text("DAYS\nRUNNING")
                                .font(AppBrand.dateline(26))
                                .tracking(3)
                                .foregroundStyle(Color(hex: 0xFFF8EC).opacity(0.9))
                        }
                        .padding(.leading, 60)
                        .padding(.trailing, 34)
                        .padding(.vertical, 20)
                        .background(RibbonShape(notch: 34).fill(brass))
                    }
                    .padding(.bottom, 34)
                }

                Rectangle().fill(ink.opacity(0.35)).frame(height: 1)
                Text("QUIZDAY · A NEW EDITION EVERY MORNING")
                    .font(AppBrand.dateline(24))
                    .tracking(4)
                    .foregroundStyle(inkSoft)
                    .padding(.top, 16)
            }
            .padding(.horizontal, 54)
            .padding(.vertical, 44)
        }
        .frame(width: 1080, height: 1350)
    }

    private var dateline: String {
        let day = playedAt.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated))
        return "ROUND \(roundNumber) · \(day)".uppercased()
    }
}
