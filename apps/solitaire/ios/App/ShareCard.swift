import FactoryKit
import SwiftUI

/// What travels to a group chat: a page laid on the baize at 1.5°, the moves at 240 pt on the
/// 1080 × 1350 card, the card that was dug for, and the days running. It spoils nothing: the
/// deal itself is never shown.
enum ShareCard {
    @MainActor
    static func render(entry: Entry, desk: Desk) -> Image? {
        let view = CardPage(entry: entry, daysRunning: desk.record.daysRunning(),
                            gilt: desk.record.gilt, sealed: desk.record.sealed)
            .brand(desk.brand)
            .environment(\.colorScheme, .light)
        return ShareImage.render { view }
    }

    @MainActor
    static func renderPage(month: Date, desk: Desk) -> Image? {
        let view = ZStack {
            ShareBaize()
            MonthPage(month: month, record: desk.record, today: desk.today, compact: true)
                .padding(18)
                .rotationEffect(.degrees(1.5))
                .shadow(color: .black.opacity(0.35), radius: 10, y: 6)
        }
        .brand(desk.brand)
        .environment(\.colorScheme, .light)
        .environmentObject(desk)
        return ShareImage.render { view }
    }

    static func text(_ e: Entry, daysRunning: Int) -> String {
        let no: String
        switch e.kind {
        case .ledger(let n): no = "No. \(n)"
        case .today: no = e.day >= 0 ? "No. \(e.day + 1)" : "Today's"
        default: no = "A loose deal"
        }
        let how = e.isClean ? "came out clean" : "came out"
        let mark = e.underMark ? ", under the mark" : ""
        let days = daysRunning > 1 ? " · \(daysRunning) days running" : ""
        return "Baize \(no) · \(Voice.shortDate(e.date)) · \(how) in \(e.moves) moves\(mark)\(days)"
    }
}

/// The baize for a share card: the canvas, the lamp's glow and the nap.
struct ShareBaize: View {
    var body: some View {
        ZStack {
            BrandBackground()
            Nap()
        }
    }
}

private struct CardPage: View {
    let entry: Entry
    let daysRunning: Int
    let gilt: Bool
    let sealed: Bool
    @Environment(\.brand) private var brand

    private let ink = AppBrand.CardBox.ink

    var body: some View {
        ZStack {
            ShareBaize()
            page
                .padding(20)
                .rotationEffect(.degrees(1.5))
                .shadow(color: .black.opacity(0.35), radius: 10, y: 6)
        }
    }

    private var page: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Rectangle().fill(ink.opacity(0.25)).frame(height: 0.75)
                Text("Baize").textCase(.uppercase).tracking(3)
                    .scaledFont(size: 9, weight: .medium, relativeTo: .caption2)
                    .foregroundStyle(ink.opacity(0.7))
                CardFace(card: entry.buried, faceUp: false, width: 8)
                Rectangle().fill(ink.opacity(0.25)).frame(height: 0.75)
            }
            Text(running)
                .textCase(.uppercase).tracking(1.5)
                .scaledFont(size: 7.5, weight: .medium, relativeTo: .caption2)
                .foregroundStyle(ink.opacity(0.65))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            HStack(alignment: .lastTextBaseline, spacing: 6) {
                Text("\(entry.moves)")
                    .brandDisplay(size: 80)
                    .foregroundStyle(ink)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                Text("Moves").textCase(.uppercase).tracking(2)
                    .scaledFont(size: 8, weight: .medium, relativeTo: .caption2)
                    .foregroundStyle(ink.opacity(0.65))
            }
            Text(markLine).textCase(.uppercase).tracking(1.5)
                .scaledFont(size: 7.5, weight: .medium, relativeTo: .caption2)
                .foregroundStyle(ink.opacity(0.65))
            HStack(alignment: .bottom, spacing: 18) {
                VStack(spacing: 6) {
                    CardFace(card: entry.buried, width: 66)
                        .shadow(color: ink.opacity(0.2), radius: 3, y: 2)
                    Text("The one to dig for").textCase(.uppercase).tracking(1.2)
                        .scaledFont(size: 6.5, weight: .medium, relativeTo: .caption2)
                        .foregroundStyle(ink.opacity(0.6))
                }
                ZStack {
                    ForEach(0..<4, id: \.self) { s in
                        CardFace(card: Card(suit: Suit(rawValue: s)!, rank: 13), width: 34)
                            .rotationEffect(.degrees(Double(s - 2) * 9 + 4), anchor: .bottom)
                    }
                }
                .frame(width: 70, height: 60)
            }
            .padding(.top, 4)
            Text(entry.isClean ? "Came out clean" : "Came out · \(Words.number(entry.takenBack)) taken back")
                .textCase(.uppercase).tracking(1.5)
                .scaledFont(size: 8, weight: .semibold, relativeTo: .caption2)
                .foregroundStyle(entry.isClean ? AppBrand.CardBox.green : ink)
            if daysRunning > 1 {
                Text("\(daysRunning) days running").textCase(.uppercase).tracking(1.5)
                    .scaledFont(size: 7.5, weight: .medium, relativeTo: .caption2)
                    .foregroundStyle(ink.opacity(0.65))
            }
            HStack(spacing: 6) {
                Rectangle().fill(ink.opacity(0.25)).frame(width: 24, height: 0.75)
                if sealed { SealMark(size: 18) } else {
                    RoundedRectangle(cornerRadius: 1).fill(ink.opacity(0.6)).frame(width: 6, height: 8.4)
                }
                Rectangle().fill(ink.opacity(0.25)).frame(width: 24, height: 0.75)
            }
            .padding(.top, 2)
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(AppBrand.CardBox.stock, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(gilt ? brand.palette.accent : ink.opacity(0.12), lineWidth: gilt ? 1.2 : 0.5)
        }
    }

    private var running: String {
        var parts: [String] = []
        switch entry.kind {
        case .ledger(let n): parts.append("No. \(n)")
        case .today: if entry.day >= 0 { parts.append("No. \(entry.day + 1)") }
        default: break
        }
        parts.append(Voice.shortDate(entry.date))
        parts.append("Draw \(Words.draw(entry.draw))")
        parts.append("Grade \(entry.grade)")
        return parts.joined(separator: " · ")
    }

    private var markLine: String {
        entry.underMark ? "The mark \(entry.mark) · under by \(entry.mark - entry.moves)" : "The mark \(entry.mark)"
    }
}

/// The brass seal: the four pips in a ring.
struct SealMark: View {
    let size: CGFloat
    var body: some View {
        ZStack {
            Circle().strokeBorder(AppBrand.CardBox.brassDeep, lineWidth: size * 0.08)
            ForEach(0..<4, id: \.self) { i in
                let a = -Double.pi / 2 + Double(i) * .pi / 2
                PipShape(suit: Suit(rawValue: i)!)
                    .fill(AppBrand.CardBox.brassDeep)
                    .frame(width: size * 0.24, height: size * 0.24)
                    .offset(x: cos(a) * size * 0.24, y: sin(a) * size * 0.24)
            }
        }
        .frame(width: size, height: size)
        .accessibilityLabel("The seal")
    }
}
