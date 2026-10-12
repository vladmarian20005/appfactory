import FactoryKit
import SwiftUI

/// It came out. The table has taken itself off; the four foundations bloom into fans and
/// overlap at the centre, pips fall, the moves count up, and the diary is written.
struct WinView: View {
    @EnvironmentObject private var desk: Desk
    @Environment(\.brand) private var brand
    let entry: Entry

    @State private var bloom = Motion.isStill
    @State private var shown = Motion.isStill
    @State private var lineUp = Motion.isStill
    @State private var gilt = Motion.isStill

    private var tier: Run.Tier { entry.runTier }

    var body: some View {
        GeometryReader { geo in
            ScrollView {
                VStack(spacing: 0) {
                    head
                        .padding(.horizontal, 20)
                        .padding(.top, 18)
                    Fans(spread: bloom ? spread : 0, gilt: gilt && tier == .best, width: min(78, geo.size.width * 0.19))
                        .frame(height: min(230, geo.size.height * 0.3))
                        .padding(.top, 6)
                        .confetti(trigger: entry.id, colors: pips, from: UnitPoint(x: 0.5, y: 0.3),
                                  count: pipCount, power: pipPower, onAppear: pipCount > 0)
                    count
                    Text(Voice.headline(tier, takenBack: entry.takenBack))
                        .brandDisplay(size: 30, relativeTo: .title)
                        .foregroundStyle(brand.palette.highlight)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .padding(.top, 14)
                        .opacity(shown ? 1 : 0)
                        .offset(y: shown ? 0 : 10)
                    Text(clerkLine)
                        .scaledFont(size: 17, relativeTo: .body)
                        .italic()
                        .foregroundStyle(brand.palette.inkSoft)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .padding(.top, 6)
                        .opacity(shown ? 1 : 0)
                    Spacer(minLength: 18)
                    DiaryLine(entry: entry)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 12)
                        .opacity(lineUp ? 1 : 0)
                        .offset(y: lineUp ? 0 : 40)
                }
                .frame(minHeight: geo.size.height)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .task { await play() }
    }

    private var head: some View {
        HStack {
            Caps(entry.kind == .today ? "Today · \(Voice.dateCaps(entry.date))" : (entry.ledgerNumber.map { "Ledger · No. \($0)" } ?? "Loose"))
                .lineLimit(1)
            Spacer()
            Caps(entry.isClean ? "Clean · 52 up" : "52 up", color: entry.isClean ? brand.palette.success : brand.palette.inkSoft)
        }
    }

    private var count: some View {
        VStack(spacing: 4) {
            HStack(alignment: .lastTextBaseline, spacing: 10) {
                CountUp(to: entry.moves, duration: 0.6) { n in
                    Haptics.impact(0.25 + 0.03 * CGFloat(n % 20))
                }
                .brandDisplay(size: 96)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .foregroundStyle(brand.palette.ink)
                Caps("Moves")
            }
            Caps(markCaps, color: entry.underMark ? brand.palette.success : brand.palette.inkSoft)
        }
        .padding(.top, 4)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(entry.moves) moves. \(markCaps)")
    }

    private var markCaps: String {
        if entry.moves == entry.mark { return "The mark \(entry.mark) · on it" }
        return entry.underMark ? "The mark \(entry.mark) · under by \(entry.mark - entry.moves)"
                               : "The mark \(entry.mark) · over by \(entry.moves - entry.mark)"
    }

    private var clerkLine: String {
        if let m = desk.justEarned { return m.blurb }
        return Voice.praiseLine(for: entry, salt: entry.id + entry.moves)
    }

    // MARK: - Tiers

    private var spread: Double {
        switch tier {
        case .best: return 6
        case .clean: return 4
        default: return 3
        }
    }

    private var pips: [Color] {
        [AppBrand.CardBox.stock, AppBrand.CardBox.red, brand.palette.accent, AppBrand.CardBox.ink]
    }

    private var pipCount: Int {
        if entry.gathered && tier == .finished { return 0 }
        switch tier {
        case .best: return 72
        case .clean: return 56
        case .good: return 40
        case .finished: return 26
        }
    }

    private var pipPower: CGFloat {
        switch tier {
        case .best: return 1.1
        case .clean: return 0.8
        case .good: return 0.5
        case .finished: return 0.4
        }
    }

    /// The fans bloom, the headline sets, then the diary line rises.
    private func play() async {
        guard !Motion.isStill else { return }
        try? await Task.sleep(nanoseconds: 50_000_000)
        withMotion(Motion.bouncy) { bloom = true }
        if tier == .best {
            try? await Task.sleep(nanoseconds: 200_000_000)
            withMotion(Motion.pop) { gilt = true }
        }
        try? await Task.sleep(nanoseconds: 250_000_000)
        withMotion(Motion.gentle) { shown = true }
        try? await Task.sleep(nanoseconds: 200_000_000)
        withMotion(Motion.gentle) { lineUp = true }
    }
}

/// Four fans of thirteen cards, spade · heart · club · diamond, kings on top, overlapping at
/// the centre of the cloth: the picture of a deal that came out.
struct Fans: View {
    let spread: Double
    var gilt = false
    let width: CGFloat

    var body: some View {
        ZStack {
            ForEach(0..<4, id: \.self) { s in
                fan(Suit(rawValue: s)!, base: Double(s) * 16 - 24)
                    .offset(x: CGFloat(s) * width * 0.62 - width * 0.93)
                    .animation(Motion.resolved(Motion.bouncy.delay(0.06 * Double(s))), value: spread)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            Ellipse()
                .fill(AppBrand.CardBox.ink.opacity(0.35))
                .frame(width: width * 4.6, height: 22)
                .blur(radius: 10)
                .offset(y: width * 0.55)
        }
        .environment(\.cardStyle.gilt, gilt)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Fifty-two cards up, four kings on top")
    }

    private func fan(_ suit: Suit, base: Double) -> some View {
        ZStack {
            ForEach(1...13, id: \.self) { rank in
                CardFace(card: Card(suit: suit, rank: rank), width: width)
                    .rotationEffect(.degrees(base * (spread > 0 ? 1 : 0.2) + Double(rank - 7) * spread),
                                    anchor: UnitPoint(x: 0.5, y: 1.15))
                    .shadow(color: AppBrand.CardBox.ink.opacity(rank == 13 ? 0.3 : 0.08), radius: rank == 13 ? 6 : 1, y: 2)
            }
        }
    }
}

/// The diary line under the cleared table: the ending's two lines, a strip of the week with
/// today's slot being written, and the buttons.
struct DiaryLine: View {
    @EnvironmentObject private var desk: Desk
    @Environment(\.brand) private var brand
    let entry: Entry

    var body: some View {
        let entries = desk.record.entries.count
        VStack(alignment: .leading, spacing: 12) {
            Text(Voice.ending(entry, entries: entries, daysRunning: desk.record.daysRunning()))
                .font(.body)
                .foregroundStyle(brand.palette.ink)
                .fixedSize(horizontal: false, vertical: true)
            Text(Voice.nextLine(after: entry, next: desk.nextLedger))
                .font(.body)
                .foregroundStyle(brand.palette.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
            WeekStrip(entry: entry)
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 12) { lay; send }
                VStack(spacing: 10) { lay; send }
            }
        }
        .padding(18)
        .background(brand.palette.surface, in: RoundedRectangle(cornerRadius: brand.corner, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: brand.corner, style: .continuous).strokeBorder(.white.opacity(0.06)))
    }

    private var lay: some View {
        Button {
            Haptics.tap()
            if entry.kind == .today || desk.todayState != .notLaid { desk.lay(.ledger) } else { desk.lay(.today) }
        } label: {
            Text(entry.kind == .today || desk.todayState != .notLaid ? "Lay No. \(desk.nextLedger.number)" : "Lay today's deal")
                .font(.headline)
                .lineLimit(1)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)
        }
        .brandProminent()
    }

    @ViewBuilder
    private var send: some View {
        let text = ShareCard.text(entry, daysRunning: desk.record.daysRunning())
        if let image = ShareCard.render(entry: entry, desk: desk) {
            ShareLink(item: image, message: Text(text), preview: SharePreview("Baize", image: image)) {
                Text("Send the card").font(.headline).frame(maxWidth: .infinity).padding(.vertical, 4)
            }
            .buttonStyle(.bordered)
            .buttonBorderShape(.capsule)
            .controlSize(.large)
        } else {
            ShareLink(item: text) {
                Text("Send the card").font(.headline).frame(maxWidth: .infinity).padding(.vertical, 4)
            }
            .buttonStyle(.bordered)
            .buttonBorderShape(.capsule)
            .controlSize(.large)
        }
    }
}

/// The week to today: a small card of what each day asked for, today's being written.
struct WeekStrip: View {
    @EnvironmentObject private var desk: Desk
    @Environment(\.brand) private var brand
    let entry: Entry

    var body: some View {
        let today = desk.today
        HStack(alignment: .bottom, spacing: 8) {
            ForEach((today - 6)...today, id: \.self) { d in
                slot(day: d, isToday: d == today)
            }
            Spacer(minLength: 4)
            VStack(alignment: .leading, spacing: 2) {
                Caps(weekdayCaps(today))
                Caps(dayCaps(today))
            }
            .fixedSize()
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("This week: \(desk.record.daysRunning()) days running")
    }

    @ViewBuilder
    private func slot(day: Int, isToday: Bool) -> some View {
        let w: CGFloat = 26
        let e = isToday && entry.kind == .today ? entry : desk.record.entry(forDay: day)
        ZStack {
            if let e {
                CardFace(card: e.buried, width: w)
                    .popIn(delay: isToday ? 0.5 : 0)
            } else {
                RoundedRectangle(cornerRadius: w * 0.08, style: .continuous)
                    .strokeBorder(brand.palette.inkSoft.opacity(0.35), lineWidth: 1)
                    .frame(width: w, height: w * 1.4)
            }
        }
        .padding(2)
        .overlay {
            if isToday {
                RoundedRectangle(cornerRadius: 4, style: .continuous).strokeBorder(brand.palette.accent, lineWidth: 1.5)
            }
        }
    }

    private func weekdayCaps(_ d: Int) -> String {
        let f = DateFormatter(); f.locale = Locale(identifier: "en_GB"); f.dateFormat = "EEEE"
        return f.string(from: Play.date(ofDay: d))
    }

    private func dayCaps(_ d: Int) -> String {
        let f = DateFormatter(); f.locale = Locale(identifier: "en_GB"); f.dateFormat = "d MMM"
        return f.string(from: Play.date(ofDay: d))
    }
}
