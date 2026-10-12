import FactoryKit
import SwiftUI

/// The Table tab: the deal, and moving the cards.
struct TableView: View {
    @EnvironmentObject private var desk: Desk
    @Environment(\.brand) private var brand
    @State private var confirmGather = false

    var body: some View {
        VStack(spacing: 0) {
            DeskEdge(top: true)
            ZStack(alignment: .topLeading) {
                content
                BrassCorner().padding(.leading, 6).padding(.top, 4)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay(alignment: .bottomTrailing) {
                BrassCorner(flipped: true).padding(.trailing, 6).padding(.bottom, 4)
            }
            DeskEdge(top: false)
        }
        .baize(swell: desk.lampSwell)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(title).brandFont(.headline).foregroundStyle(brand.palette.ink)
            }
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    desk.takeBack()
                } label: {
                    Image(systemName: "arrow.uturn.backward")
                }
                .disabled(desk.saved?.moves.isEmpty ?? true || desk.sweeping || desk.won != nil)
                .accessibilityLabel("Take it back")
            }
            ToolbarItem(placement: .topBarTrailing) { menu }
        }
        .alert("Gather the cards?", isPresented: $confirmGather) {
            Button("Gather them", role: .destructive) { desk.gather() }
            Button("Leave them", role: .cancel) {}
        } message: {
            Text("The same deal, laid again from the start.")
        }
        .dynamicTypeSize(...DynamicTypeSize.accessibility2)
    }

    private var title: String {
        if desk.table == nil && desk.won == nil { return "Today" }
        switch desk.won?.kind ?? desk.saved?.kind ?? .today {
        case .today: return "Today"
        case .ledger(let n): return "No. \(n)"
        case .loose: return "Loose"
        case .again: return "Again"
        }
    }

    @ViewBuilder
    private var content: some View {
        if let won = desk.won {
            WinView(entry: won)
        } else if let table = desk.table, let saved = desk.saved {
            VStack(spacing: 0) {
                TableHead(saved: saved, table: table)
                    .padding(.horizontal, 20)
                    .padding(.top, 18)
                    .padding(.bottom, 14)
                GeometryReader { geo in
                    CardsView(table: table, layout: TableLayout(size: geo.size, leftHanded: desk.record.leftHanded && desk.isPro))
                }
                TableFoot(saved: saved)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)
            }
        } else if case .out = desk.todayState {
            DoneToday()
        } else {
            TodayWaits()
        }
    }

    private var menu: some View {
        Menu {
            if desk.table != nil && desk.won == nil {
                Button { confirmGather = true } label: { Label("Gather the cards", systemImage: "arrow.counterclockwise") }
            }
            Button { desk.lay(.loose(draw: 1)) } label: { Label("A loose deal · draw one", systemImage: "rectangle.portrait") }
            Button { desk.lay(.loose(draw: 3)) } label: { Label("A loose deal · draw three", systemImage: "rectangle.portrait.on.rectangle.portrait") }
            switch desk.todayState {
            case .notLaid, .yesterdayLaid:
                Button { desk.lay(.today) } label: { Label("Lay today's deal", systemImage: "calendar") }
            case .laid where desk.which == .other:
                Button { desk.show(.today) } label: { Label("Back to today's", systemImage: "calendar") }
            default:
                EmptyView()
            }
            if desk.which == .today || desk.won != nil {
                Button { desk.lay(.ledger) } label: { Label("Lay No. \(desk.record.rung)", systemImage: "book.closed") }
            }
            if desk.record.hasEarned("claret") || desk.isPro {
                Picker("Cloth", selection: Binding(get: { desk.cloth }, set: { c in desk.update { $0.cloth = c } })) {
                    ForEach(Cloth.allCases.filter { $0 == .blue || ($0 == .claret && desk.record.hasEarned("claret")) || desk.isPro }, id: \.self) {
                        Text($0.rawValue.capitalized).tag($0)
                    }
                }
            }
        } label: {
            Image(systemName: "ellipsis")
        }
        .accessibilityLabel("The deal")
    }
}

/// The head, two columns so nothing wraps: where this deal is from and the count at the left;
/// the draw, the grade, the mark and the run at the right.
struct TableHead: View {
    @EnvironmentObject private var desk: Desk
    @Environment(\.brand) private var brand
    let saved: SavedTable
    let table: Table

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .top) {
                left
                Spacer(minLength: 12)
                right(alignment: .trailing)
            }
            VStack(alignment: .leading, spacing: 8) {
                left
                right(alignment: .leading)
            }
        }
    }

    private var where_: String {
        switch saved.kind {
        case .today:
            return saved.day == desk.today ? "Today · \(Voice.dateCaps(Play.date(ofDay: saved.day)))" : "Yesterday's · still laid"
        case .ledger(let n): return "Ledger · No. \(n)"
        case .loose: return "Loose · draw \(Words.draw(saved.draw))"
        case .again(let d): return "Again · \(Voice.shortDate(Play.date(ofDay: d)))"
        }
    }

    private var left: some View {
        VStack(alignment: .leading, spacing: 2) {
            Caps(where_).lineLimit(1).fixedSize()
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("\(saved.moves.count)")
                    .brandDisplay(size: 34)
                    .monospacedDigit()
                    .contentTransition(.numericText(value: Double(saved.moves.count)))
                    .animation(Motion.resolved(Motion.snappy), value: saved.moves.count)
                    .foregroundStyle(brand.palette.ink)
                Caps("Moves")
            }
            .accessibilityElement(children: .combine)
        }
    }

    private func right(alignment: HorizontalAlignment) -> some View {
        VStack(alignment: alignment, spacing: 5) {
            Caps("Draw \(Words.draw(saved.draw)) · Grade \(saved.grade)").fixedSize()
            Caps("The mark \(saved.mark)").fixedSize()
            Caps(runCaps, color: saved.takenBack == 0 && !saved.gathered ? brand.palette.success : brand.palette.miss)
                .fixedSize()
                .contentTransition(.opacity)
                .animation(Motion.resolved(Motion.snappy), value: runCaps)
            if desk.record.showClock {
                TimelineView(.periodic(from: .now, by: 1)) { _ in
                    let s = desk.elapsed
                    Text(String(format: "%d:%02d", s / 60, s % 60))
                        .scaledFont(size: 12, weight: .medium, design: .monospaced, relativeTo: .caption2)
                        .tracking(2)
                        .foregroundStyle(brand.palette.inkSoft)
                }
            }
        }
    }

    private var runCaps: String {
        let up = "\(table.cardsUp) up"
        if saved.gathered && saved.takenBack == 0 { return "Gathered · \(up)" }
        switch saved.takenBack {
        case 0: return "Clean · \(up)"
        case 1: return "One taken back · \(up)"
        default: return "\(Words.capitalised(saved.takenBack)) taken back · \(up)"
        }
    }
}

/// The foot: the clerk's most recent line, and the seed typed small.
struct TableFoot: View {
    @EnvironmentObject private var desk: Desk
    @Environment(\.brand) private var brand
    let saved: SavedTable

    var body: some View {
        VStack(spacing: 8) {
            Text(desk.clerk ?? " ")
                .scaledFont(size: 15, relativeTo: .subheadline)
                .italic()
                .foregroundStyle(brand.palette.inkSoft)
                .multilineTextAlignment(.center)
                .frame(minHeight: 20)
                .id(desk.clerk ?? "")
                .transition(.opacity.combined(with: .offset(y: 4)))
                .animation(Motion.resolved(Motion.gentle), value: desk.clerk)
            Text(seedLine(saved))
                .scaledFont(size: 11, weight: .medium, design: .monospaced, relativeTo: .caption2)
                .tracking(2)
                .foregroundStyle(brand.palette.inkSoft.opacity(0.75))
                .lineLimit(1)
                .truncationMode(.middle)
                .accessibilityLabel("Deal \(saved.printed)")
        }
        .frame(maxWidth: .infinity)
    }
}

/// `№ 285 · 2026-10-12 · 7C3A-19B2` — a serial is typed, not lettered.
func seedLine(_ s: SavedTable) -> String {
    var parts: [String] = []
    switch s.kind {
    case .today, .again: if s.day >= 0 { parts.append("№ \(s.day + 1)") }
    case .ledger(let n): parts.append("№ \(n)")
    case .loose: parts.append("LOOSE")
    }
    parts.append(Voice.isoDate(Play.date(ofDay: s.day)))
    parts.append(s.printed)
    return parts.joined(separator: " · ")
}

/// Nothing on the cloth and today's not yet out: the date, today's dials, and one way to lay it.
struct TodayWaits: View {
    @EnvironmentObject private var desk: Desk
    @Environment(\.brand) private var brand
    @Environment(\.dynamicTypeSize) private var type

    var body: some View {
        let dials = desk.todayDials
        ScrollView {
            VStack(spacing: 18) {
                Image("Desk")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: type.isAccessibilitySize ? 150 : 260)
                    .ambientFloat(distance: 4, period: 5)
                    .accessibilityHidden(true)
                    .padding(.top, 24)
                Caps(Voice.dateCaps(Play.date(ofDay: desk.today)))
                Text("Today's deal is face down")
                    .brandFont(.title)
                    .foregroundStyle(brand.palette.ink)
                    .multilineTextAlignment(.center)
                Caps("Draw \(Words.draw(dials.draw)) · Grade \(dials.grade)")
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 24)
        }
        .safeAreaInset(edge: .bottom) {
            OneAction(title: "Lay today's deal") {
                if case .laid = desk.todayState { desk.show(.today) } else { desk.lay(.today) }
            }
        }
    }
}

/// The screen's one action, held under the scroll so it is on the first screen at every text
/// size.
private struct OneAction: View {
    let title: String
    let action: () -> Void
    @Environment(\.brand) private var brand

    var body: some View {
        Button(action: action) {
            Text(title).font(.headline).lineLimit(2).frame(maxWidth: .infinity).padding(.vertical, 4)
        }
        .brandProminent()
        .padding(.horizontal, 28)
        .padding(.top, 20)
        .padding(.bottom, 16)
        // The cloth thickens under the button, so what scrolls beneath it goes quiet.
        .background {
            LinearGradient(stops: [.init(color: brand.palette.canvas.opacity(0), location: 0),
                                   .init(color: brand.palette.canvas.opacity(0.92), location: 0.35)],
                           startPoint: .top, endPoint: .bottom)
        }
    }
}

/// Today's is out and nothing else is laid: the fans, the line, and the next deal in the ledger.
struct DoneToday: View {
    @EnvironmentObject private var desk: Desk
    @Environment(\.brand) private var brand
    @Environment(\.dynamicTypeSize) private var type

    var body: some View {
        let next = desk.nextLedger
        ScrollView {
            VStack(spacing: 18) {
                Image("Fans")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: type.isAccessibilitySize ? 150 : 280)
                    .ambientFloat(distance: 4, period: 5)
                    .accessibilityHidden(true)
                    .padding(.top, 24)
                Text("Today's is in the diary")
                    .brandFont(.title)
                    .foregroundStyle(brand.palette.ink)
                    .multilineTextAlignment(.center)
                Text("The ledger has the next one ready: No. \(next.number), draw \(Words.draw(next.draw)).")
                    .font(.body)
                    .foregroundStyle(brand.palette.inkSoft)
                    .multilineTextAlignment(.center)
                VStack(spacing: 6) {
                    LedgerNumber(number: next.number, size: 76)
                    Caps("Draw \(Words.draw(next.draw)) · Grade \(next.grade)")
                }
                .padding(.top, 6)
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 24)
        }
        .safeAreaInset(edge: .bottom) {
            OneAction(title: "Lay No. \(next.number)") { desk.lay(.ledger) }
        }
    }
}
