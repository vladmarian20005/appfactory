import FactoryKit
import SwiftUI

/// The bed: the plate, the clues, and the cut. Its one job.
struct BedView: View {
    @ObservedObject var bench: Bench
    @Binding var showPaywall: Bool
    @Environment(\.brand) private var brand
    @State private var confirmWipe = false

    var body: some View {
        NavigationStack {
            ZStack {
                if let session = bench.session, bench.stage == .none {
                    plate(session)
                } else if bench.session == nil {
                    BareBed(bench: bench, showPaywall: $showPaywall)
                }
                if bench.stage != .none, let session = bench.session {
                    // The clue list slides off, the plate is alone on the bed, and the shop
                    // dims: the whole room gives way to the press.
                    brand.palette.ink.opacity(0.12)
                        .ignoresSafeArea()
                        .transition(.opacity)
                    PullView(bench: bench, session: session, showPaywall: $showPaywall)
                }
            }
            .shopBackground()
            .navigationTitle(bench.session?.plate.title ?? "The bench")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbar }
            .alert("Wipe the plate?", isPresented: $confirmWipe) {
                Button("Wipe it", role: .destructive) { bench.wipe() }
                Button("Leave it", role: .cancel) { }
            } message: {
                Text("Every mark comes off and the copper goes back to bare. The plate is the same one.")
            }
        }
    }

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                Button("Wipe the plate") { confirmWipe = true }
                if bench.isPro {
                    Toggle("Muted ink", isOn: Binding(get: { bench.record.calmInk }, set: bench.setCalm))
                }
                Button(bench.session?.isDaily == true ? "Rule the next plate" : "Set today's plate on the bed") {
                    if bench.session?.isDaily == true {
                        if bench.runIsLocked { showPaywall = true } else { bench.rule(daily: false) }
                    } else {
                        bench.openBed(daily: true)
                    }
                }
            } label: {
                Image(systemName: "ellipsis")
                    .accessibilityLabel("The bench")
            }
        }
    }

    // MARK: The paper, the plate and the clues

    private func plate(_ session: Session) -> some View {
        GeometryReader { geo in
            ScrollView {
                VStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: 14) {
                        Legend(plate: session.plate, muted: bench.record.calmInk && bench.isPro)
                        PlateView(bench: bench, session: session, width: geo.size.width - 34)
                            .frame(maxWidth: .infinity, alignment: .center)
                        if let line = bench.marginLine {
                            Text(line)
                                .brandFont(.subheadline, weight: .regular)
                                .foregroundStyle(brand.palette.miss)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .transition(.opacity)
                        }
                        LozengeRule(count: 3, color: brand.palette.ink.opacity(0.35), width: 11)
                            .frame(maxWidth: .infinity, alignment: .center)
                        ClueList(bench: bench, session: session)
                    }
                    .padding(17)
                    .background {
                        RoundedRectangle(cornerRadius: 3, style: .continuous)
                            .fill(brand.palette.surface)
                            .shadow(color: .black.opacity(0.10), radius: 10, x: 0, y: 5)
                    }
                    .padding(.horizontal, 10)
                    .padding(.top, 6)
                    .padding(.bottom, 26)
                }
            }
        }
    }
}

/// The legend, on the paper mount above the plate: one row per category, its name in the plate
/// caps in its cast ink, then its members. This is where the names live, so nothing inside the
/// grid has to be set at eight points on its side.
struct Legend: View {
    let plate: Plate
    var muted = false
    @Environment(\.brand) private var brand

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            ForEach(0..<plate.categories, id: \.self) { category in
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Text(plate.block(category).caps)
                        .plateCaps(size: 9.5)
                        .foregroundStyle(ink(category))
                        .frame(width: 66, alignment: .leading)
                    Text((0..<plate.members).map { plate.block(category).members[$0].short }.joined(separator: " · "))
                        .scaledFont(size: 13, weight: .semibold, relativeTo: .footnote)
                        .foregroundStyle(brand.palette.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                }
            }
        }
        .accessibilityElement(children: .combine)
    }

    private func ink(_ category: Int) -> Color {
        let inks = brand.palette.extras
        if muted || inks.isEmpty { return brand.palette.inkSoft }
        return inks[category % inks.count]
    }
}

/// The clue list, on the paper below the plate. A clue used up by what has been cut strikes
/// itself through with one fine verdigris rule; a sealed one is crosshatched over and
/// unreadable until it bites open.
struct ClueList: View {
    @ObservedObject var bench: Bench
    let session: Session
    @Environment(\.brand) private var brand

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(session.plate.clues) { clue in
                row(clue)
                if clue.id < session.plate.clues.count - 1 {
                    Rectangle()
                        .fill(brand.palette.ink.opacity(0.12))
                        .frame(height: 0.5)
                }
            }
        }
    }

    @ViewBuilder
    private func row(_ clue: Clue) -> some View {
        let sealed = clue.sealed && !session.opened.contains(clue.id)
        let spent = !sealed && Spent.isSpent(clue, in: session.grid)
        let named = bench.loupe?.clue == clue.id
        HStack(alignment: .top, spacing: 11) {
            ZStack {
                Lozenge()
                    .fill(ink(clue.leadCategory).opacity(sealed ? 0.35 : 1))
                    .frame(width: 20, height: 12)
                Text("\(clue.id + 1)")
                    .plateCaps(size: 8)
                    .foregroundStyle(brand.palette.surface)
            }
            .padding(.top, 4)
            ZStack(alignment: .leading) {
                Text(sealed ? placeholder(clue) : clue.text)
                    .brandFont(.body, weight: .regular)
                    .foregroundStyle(spent ? brand.palette.inkSoft : brand.palette.ink)
                    .strikethrough(spent, pattern: .solid, color: brand.palette.success)
                    .opacity(sealed ? 0 : 1)
                    .fixedSize(horizontal: false, vertical: true)
                if sealed {
                    CutShading(progress: 1, spacing: 3.6, weight: 1, tone: 0.9)
                        .frame(height: 22)
                        .accessibilityLabel("A sealed clue. It bites open when the plate runs out of forced moves without it.")
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 10)
        .background {
            if named {
                Rectangle().fill(brand.palette.highlight.opacity(0.16))
            }
        }
        .popIn(delay: Double(clue.id) * 0.04)
        .accessibilityElement(children: .combine)
    }

    /// A sealed clue has the room it will take when it bites open, so the list does not jump
    /// under her hand when the acid comes through.
    private func placeholder(_ clue: Clue) -> String {
        String(repeating: "m", count: min(58, max(24, clue.text.count)))
    }

    private func ink(_ category: Int) -> Color {
        let inks = brand.palette.extras
        if bench.record.calmInk && bench.isPro || inks.isEmpty { return brand.palette.inkSoft }
        return inks[category % inks.count]
    }
}

/// Whether a clue has been used up by what is already cut.
enum Spent {
    static func isSpent(_ clue: Clue, in grid: Grid) -> Bool {
        func settled(_ x: Cell, _ y: Cell) -> Bool { grid.at(x, y) != .blank }
        func fixed(_ cell: Cell, in ordered: Int) -> Bool {
            (0..<grid.members).contains { grid.at(cell.category, cell.member, ordered, $0) == .point }
        }
        switch clue.kind {
        case .direct, .negative:
            return settled(clue.a, clue.b)
        case .either:
            guard let c = clue.c else { return true }
            return settled(clue.a, clue.b) && settled(clue.a, c)
        case .relational, .arithmetic, .adjacency:
            return fixed(clue.a, in: clue.ordered) && fixed(clue.b, in: clue.ordered)
        case .exclusive:
            guard let c = clue.c, let d = clue.d else { return true }
            return settled(clue.a, clue.b) && settled(c, d)
        }
    }
}

/// Nothing is on the bed: the press is wound back and the paper is damp under the board.
struct BareBed: View {
    @ObservedObject var bench: Bench
    @Binding var showPaywall: Bool
    @Environment(\.brand) private var brand

    var body: some View {
        VStack(spacing: 22) {
            Image("Press")
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 220)
                .ambientFloat(distance: 3, period: 4.2)
            VStack(spacing: 10) {
                Text("The line is empty")
                    .brandFont(.largeTitle)
                    .foregroundStyle(brand.palette.ink)
                Text("The press is wound back, there is damp paper under the board, and today's plate is already on the bed.")
                    .brandFont(.body, weight: .regular)
                    .foregroundStyle(brand.palette.inkSoft)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Button {
                bench.openBed(daily: true)
            } label: {
                Text("Set it on the bed")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
            }
            .brandProminent()
        }
        .padding(28)
    }
}
