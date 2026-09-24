import FactoryKit
import SwiftUI

/// Screen 3 · Packs. The ladder, pattern by pattern, and what is waiting.
struct BookView: View {
    @Binding var tab: RootView.Tab
    @Binding var showPaywall: Bool
    @EnvironmentObject private var bench: Bench
    @Environment(\.brand) private var brand

    private var record: Record { bench.record }
    private var locked: Bool { !bench.bookOpen }
    private var pro: Bool { bench.isPro || LaunchOptions.forcePro }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 26) {
                    stack
                    actions
                    PinRule()
                    chapters
                    PinRule()
                    Cushion(pieces: record.pieces.count)
                    PinRule()
                    ledger
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .linen(ticking: record.ticking)
            .navigationTitle("The book")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: Piece.self) { PieceView(piece: $0) }
        }
    }

    // MARK: - The stack of cards

    /// The pattern book: a stack of pricked cards, the next one on top with its number.
    private var stack: some View {
        let d = Play.dials(at: record.rung)
        let ground = bench.nextBookGround
        return Button {
            if locked { showPaywall = true } else { pin() }
        } label: {
            ZStack {
                ForEach(0..<3, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(brand.palette.surface)
                        .shadow(color: .black.opacity(0.08), radius: 3, x: 1, y: 2)
                        .rotationEffect(.degrees(Double(i) * 2.2 - 3))
                        .offset(x: CGFloat(i) * 4, y: CGFloat(i) * 5)
                }
                .opacity(0.9)
                VStack(alignment: .leading, spacing: 8) {
                    if locked {
                        Spacer()
                        Text("The book goes on")
                            .caps(.headline, tracking: 4)
                            .frame(maxWidth: .infinity)
                        Spacer()
                    } else {
                        HStack(alignment: .top) {
                            Text("\(record.rung)")
                                .brandDisplay(size: 76)
                                .foregroundStyle(brand.palette.ink)
                            Spacer()
                            PrickPreview(side: d.side, shape: d.shape)
                                .frame(width: 96, height: 96)
                        }
                        Spacer(minLength: 0)
                        Text("Pattern \(record.rung) · \(Words.size(d.side)) · the \(ground.name) ground")
                            .caps()
                        Text(looseLine(d.loose))
                            .font(.subheadline.italic())
                            .foregroundStyle(brand.palette.inkSoft)
                    }
                }
                .padding(22)
                .background {
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(brand.palette.surface)
                        .shadow(color: .black.opacity(0.14), radius: 8, x: 2, y: 5)
                }
                .overlay(alignment: .topLeading) {
                    PinHead(color: AppBrand.Workbox.brass, size: 9).offset(x: 6, y: 6)
                }
                .rotationEffect(.degrees(-1.2))
            }
            .frame(height: 250)
        }
        .buttonStyle(.pressable(scale: 0.98))
        .accessibilityLabel(locked ? "The book goes on. See the whole book." :
                                "Pattern \(record.rung), \(Words.size(d.side)), the \(ground.name) ground")
    }

    private func looseLine(_ loose: Int) -> String {
        switch loose {
        case 0: "Both ends pinned."
        case 1: "Only the start is pinned."
        default: "Neither end is pinned. Find where it begins."
        }
    }

    private var actions: some View {
        VStack(spacing: 10) {
            Button {
                Haptics.tap()
                if locked { showPaywall = true } else { pin() }
            } label: {
                Text(locked ? "See the whole book" : "Pin the next pattern")
                    .font(.headline).frame(maxWidth: .infinity).padding(.vertical, 4)
            }
            .brandProminent()
            if pro {
                Button {
                    Haptics.tap()
                    bench.workLoose()
                    tab = .pillow
                } label: {
                    Text("Work a loose pattern").font(.headline).frame(maxWidth: .infinity).padding(.vertical, 4)
                }
                .buttonStyle(.bordered)
                .buttonBorderShape(.capsule)
                .controlSize(.large)
            }
        }
    }

    private func pin() {
        bench.pinNext()
        tab = .pillow
    }

    // MARK: - Chapters

    /// One chapter per side, five through fourteen; the chapter the rung is in has its tab out.
    private var chapters: some View {
        let current = Play.dials(at: record.rung).side
        return VStack(alignment: .leading, spacing: 18) {
            Text("Chapters").brandFont(.title2).foregroundStyle(brand.palette.ink)
            ForEach(5...14, id: \.self) { side in
                let pieces = record.pieces.filter { $0.side == side }
                let clean = pieces.filter(\.isClean).count
                if !pieces.isEmpty || side <= current {
                    HStack(alignment: .top, spacing: 12) {
                        Capsule()
                            .fill(side == current ? brand.palette.accent : brand.palette.ink.opacity(0.15))
                            .frame(width: 4, height: 60)
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(Words.size(side)).caps()
                                Spacer()
                                Text("\(pieces.count) worked · \(clean) clean").caps()
                            }
                            if pieces.isEmpty {
                                Text(side == current ? "The book is in this chapter now." : "")
                                    .font(.subheadline.italic())
                                    .foregroundStyle(brand.palette.inkSoft)
                            } else {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    LazyHStack(spacing: 10) {
                                        ForEach(pieces.reversed().prefix(40)) { p in
                                            NavigationLink(value: p) { SmallLace(piece: p, size: 40) }
                                                .buttonStyle(.pressable)
                                                .accessibilityLabel("Piece \(p.id)")
                                        }
                                    }
                                }
                                .frame(height: 44)
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - The ledger

    /// Pieces by size and by ground — the same records the next pattern is chosen from.
    @ViewBuilder
    private var ledger: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("The ledger").brandFont(.title2).foregroundStyle(brand.palette.ink)
            if pro {
                ledgerTable(title: "By ground", rows: Ground.allCases.compactMap { g in
                    let ps = record.pieces.filter { $0.ground == g }
                    guard !ps.isEmpty else { return nil }
                    return (g.name.capitalized, ps, record.mastery.strength(of: g))
                })
                ledgerTable(title: "By size", rows: (5...14).compactMap { s in
                    let ps = record.pieces.filter { $0.side == s }
                    guard !ps.isEmpty else { return nil }
                    return ("\(s) × \(s)", ps, nil)
                })
            } else {
                Text("Your pieces by size and by ground, ruled on parchment, open with the book.")
                    .foregroundStyle(brand.palette.inkSoft)
                Button("See the whole book") { showPaywall = true }
                    .font(.headline)
            }
        }
    }

    private func ledgerTable(title: String, rows: [(String, [Piece], Double?)]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(title).caps()
                Spacer()
                Text("worked · clean · longest").caps()
            }
            .padding(.bottom, 8)
            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                Rectangle().fill(brand.palette.ink.opacity(0.15)).frame(height: 0.5)
                HStack {
                    Text(row.0).foregroundStyle(brand.palette.ink)
                    if let s = row.2 {
                        // How well the record says this ground is known: the rule the next
                        // pattern is chosen by, made visible.
                        Capsule().fill(brand.palette.accent.opacity(0.18)).frame(width: 40, height: 3)
                            .overlay(alignment: .leading) {
                                Capsule().fill(brand.palette.accent).frame(width: 40 * s, height: 3)
                            }
                            .accessibilityLabel("known \(Int(s * 100)) percent")
                    }
                    Spacer()
                    Text("\(row.1.count) · \(row.1.filter(\.isClean).count) · \(row.1.map(\.longestThread).max() ?? 0)")
                        .monospacedDigit()
                        .foregroundStyle(brand.palette.inkSoft)
                }
                .padding(.vertical, 9)
            }
        }
        .padding(16)
        .background(brand.palette.surface, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

/// The next card's pricking, as pins only: its shape, and nothing of its answer.
struct PrickPreview: View {
    let side: Int
    let shape: Int
    @Environment(\.brand) private var brand

    var body: some View {
        Canvas { gc, size in
            var rng = SplitMix64(seed: UInt64(side * 10 + shape))
            let mask = Generator.mask(side: side, shape: shape, ground: .spider, rng: &rng)
            let layout = CardLayout(side: side, size: size.width)
            for c in 0..<(side * side) where mask[c] {
                let p = layout.centre(c)
                let d = max(1.6, min(3, layout.pitch * 0.3))
                gc.fill(Path(ellipseIn: CGRect(x: p.x - d / 2, y: p.y - d / 2, width: d, height: d)),
                        with: .color(AppBrand.Workbox.steel))
            }
        }
        .accessibilityHidden(true)
    }
}

/// The cushion: what playing has put in the workbox, each a small object, greyed until it
/// arrives, with the count under the next one.
struct Cushion: View {
    let pieces: Int
    @Environment(\.brand) private var brand

    var body: some View {
        let next = Play.earned.next(after: pieces)
        VStack(alignment: .leading, spacing: 14) {
            Text("The cushion").brandFont(.title2).foregroundStyle(brand.palette.ink)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 18) {
                ForEach(Play.earned.milestones) { m in
                    let have = m.at <= pieces
                    VStack(spacing: 6) {
                        CushionObject(id: m.id)
                            .frame(width: 44, height: 44)
                            .saturation(have ? 1 : 0)
                            .opacity(have ? 1 : 0.35)
                        Text(m.title)
                            .font(.caption)
                            .foregroundStyle(have ? brand.palette.ink : brand.palette.inkSoft)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                        if m.id == next?.id {
                            Text("at \(m.at)").caps(.caption2, tracking: 1)
                        }
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(have ? "\(m.title), earned" : "\(m.title), at \(m.at) pieces")
                }
            }
            .padding(16)
            .background(AppBrand.Pillow.cloth, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
            if let next {
                Text(Play.horizon(next)).font(.subheadline.italic()).foregroundStyle(brand.palette.inkSoft)
            }
        }
    }
}

/// Each thing on the cushion, drawn small.
struct CushionObject: View {
    let id: String
    @Environment(\.brand) private var brand

    var body: some View {
        switch id {
        case "sampler":
            RoundedRectangle(cornerRadius: 2).fill(brand.palette.surface)
                .overlay { Image(systemName: "square.grid.3x3").font(.caption).foregroundStyle(brand.palette.accent) }
                .padding(6)
        case "silk":
            bobbin(AppBrand.Workbox.rose)
        case "pin":
            ZStack {
                Rectangle().fill(AppBrand.Workbox.steel).frame(width: 1.5, height: 26).offset(y: 6)
                PinHead(color: brand.palette.success, size: 12).offset(y: -8)
            }
        case "gold":
            bobbin(AppBrand.Workbox.gold)
        case "ticking":
            HStack(spacing: 4) {
                ForEach(0..<4, id: \.self) { _ in Rectangle().fill(brand.palette.accent.opacity(0.7)).frame(width: 4) }
            }
            .padding(6)
            .background(AppBrand.Pillow.highlight, in: RoundedRectangle(cornerRadius: 4))
        case "initials":
            Text("AB")
                .font(.system(.footnote, design: .monospaced, weight: .bold))
                .foregroundStyle(brand.palette.highlight)
                .padding(6)
                .background(brand.palette.surface, in: RoundedRectangle(cornerRadius: 2))
        default:
            RoundedRectangle(cornerRadius: 2)
                .strokeBorder(AppBrand.Workbox.walnut, lineWidth: 3)
                .background(brand.palette.surface)
                .padding(4)
        }
    }

    private func bobbin(_ thread: Color) -> some View {
        ZStack {
            Capsule().fill(AppBrand.Workbox.walnut).frame(width: 10, height: 38)
            Capsule().fill(thread).frame(width: 13, height: 14).offset(y: -5)
        }
        .rotationEffect(.degrees(20))
    }
}
