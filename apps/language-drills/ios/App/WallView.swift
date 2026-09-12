import FactoryKit
import SwiftUI

/// The wall: twelve panels, one per theme, and every word in the deck is a tile in one of
/// them. Its job is to show that the thousand is a real, finite, visible object — and to let
/// any word in it be found.
struct WallView: View {
    @EnvironmentObject private var store: Store
    @EnvironmentObject private var library: Library
    @Environment(\.brand) private var brand
    @Binding var showPaywall: Bool

    @State private var query = ""
    @State private var opened: Word?
    @State private var liftedPanel: Int?

    private var isOpen: Bool { store.isPro || LaunchOptions.forcePro }

    private var matches: Set<Int> {
        let q = query.trimmingCharacters(in: .whitespaces).lowercased()
        guard !q.isEmpty else { return [] }
        return Set(Deck.words.filter {
            $0.word.lowercased().contains(q) || $0.translation.lowercased().contains(q)
        }.map(\.rank))
    }

    private var searching: Bool {
        !query.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 26) {
                if searching && matches.isEmpty {
                    noTile
                }
                ForEach(0..<Deck.themes.count, id: \.self) { theme in
                    PanelView(theme: theme,
                              locked: !isOpen && theme >= Deck.freePanels,
                              lifted: liftedPanel == theme,
                              matches: matches,
                              searching: searching,
                              onOpen: open(_:),
                              onLocked: { lift(theme) })
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .brandBackground(drift: true)
        .navigationTitle("Wall")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $query, prompt: "Find a word")
        .sheet(item: $opened) { word in
            WordSheet(word: word) { opened = nil }
                .brand(AppBrand.brand)
        }
    }

    private var noTile: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("No tile by that name.")
                .brandFont(.title3)
                .foregroundStyle(brand.palette.ink)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 10)
    }

    private func open(_ word: Word) {
        if !isOpen && !Deck.isFree(word) {
            showPaywall = true
            return
        }
        Haptics.tap()
        opened = word
    }

    /// A corner of the dust sheet lifts before the paywall rises: the panel is under a cloth,
    /// not behind a wall.
    private func lift(_ theme: Int) {
        Haptics.soft()
        withMotion(Motion.gentle) { liftedPanel = theme }
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 420_000_000)
            showPaywall = true
            try? await Task.sleep(nanoseconds: 500_000_000)
            withMotion(Motion.gentle) { liftedPanel = nil }
        }
    }
}

/// One theme's panel: its name, how much of it is standing, a mortar line in its own glaze,
/// and its tiles.
struct PanelView: View {
    @EnvironmentObject private var library: Library
    @Environment(\.brand) private var brand

    let theme: Int
    let locked: Bool
    let lifted: Bool
    let matches: Set<Int>
    let searching: Bool
    let onOpen: (Word) -> Void
    let onLocked: () -> Void

    private let tile: CGFloat = 44
    private let gap: CGFloat = 3

    private var words: [Word] { Deck.panel(theme) }
    private var glaze: Color { AppBrand.glaze(theme) }
    private var set: Int { library.setCount(theme: theme) }

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(alignment: .firstTextBaseline) {
                Mark(Deck.themeName(theme).uppercased())
                    .foregroundStyle(brand.palette.ink)
                Spacer(minLength: 10)
                Mark("\(set) OF \(words.count)")
                    .foregroundStyle(brand.palette.inkSoft)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(brand.palette.surface)
                    Capsule()
                        .fill(glaze)
                        .frame(width: geo.size.width * CGFloat(Double(set) / Double(max(words.count, 1))))
                }
                .frame(height: 2)
            }
            .frame(height: 2)

            grid
        }
        .accessibilityElement(children: .contain)
    }

    private var grid: some View {
        GeometryReader { geo in
            let cols = max(1, Int((geo.size.width + gap) / (tile + gap)))
            ZStack(alignment: .topTrailing) {
                rows(cols: cols, freeOnly: false)
                    .opacity(locked ? 0.3 : 1)
                if locked {
                    DustSheet(lifted: lifted)
                        .onTapGesture(perform: onLocked)
                    // The hundred that are open anyway show through the cloth.
                    rows(cols: cols, freeOnly: true)
                        .allowsHitTesting(true)
                }
            }
            .frame(width: geo.size.width, alignment: .leading)
        }
        .frame(height: height)
    }

    private var height: CGFloat {
        // Laid out against the phone's width less the screen's own padding.
        let usable = UIScreen.main.bounds.width - 32
        let cols = max(1, Int((usable + gap) / (tile + gap)))
        let rowCount = Int(ceil(Double(words.count) / Double(cols)))
        return CGFloat(rowCount) * (tile + gap) - gap
    }

    private func rows(cols: Int, freeOnly: Bool) -> some View {
        VStack(alignment: .leading, spacing: gap) {
            ForEach(0..<rowCount(cols), id: \.self) { row in
                HStack(spacing: gap) {
                    ForEach(0..<cols, id: \.self) { col in
                        let i = row * cols + col
                        if i < words.count {
                            cell(words[i], freeOnly: freeOnly)
                        } else {
                            Color.clear.frame(width: tile, height: tile)
                        }
                    }
                    Spacer(minLength: 0)
                }
            }
        }
    }

    private func rowCount(_ cols: Int) -> Int {
        max(1, Int(ceil(Double(words.count) / Double(cols))))
    }

    @ViewBuilder
    private func cell(_ word: Word, freeOnly: Bool) -> some View {
        if freeOnly && !Deck.isFree(word) {
            Color.clear.frame(width: tile, height: tile)
        } else {
            Button {
                onOpen(word)
            } label: {
                WallTile(firing: library.firing(word),
                         glaze: glaze,
                         radius: 6,
                         freshMortar: false,
                         bevel: 1.5)
                    .frame(width: tile, height: tile)
            }
            .buttonStyle(.pressable(scale: 0.92))
            // Nothing re-flows while you search: a word that does not match fades where it
            // lives, so you can see where it lives.
            .opacity(searching && !matches.contains(word.rank) ? 0.15 : 1)
            .animation(Motion.resolved(.easeInOut(duration: 0.2)), value: searching)
            .accessibilityLabel("\(word.word), \(word.translation)")
            .accessibilityValue(firingLabel(word))
        }
    }

    private func firingLabel(_ word: Word) -> String {
        switch library.firing(word) {
        case .set: return "in the wall"
        case .drying: return "drying"
        case .bare: return "bare clay"
        }
    }
}

/// A panel that has not been paid for is under a cloth, not behind a wall. Tapping it lifts a
/// corner before the paywall rises.
struct DustSheet: View {
    @Environment(\.brand) private var brand
    let lifted: Bool

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Rectangle()
                .fill(LinearGradient(colors: [brand.palette.canvas.opacity(0.86),
                                              brand.palette.canvas.opacity(0.7),
                                              brand.palette.canvas.opacity(0.8)],
                                     startPoint: .top, endPoint: .bottom))
                .overlay {
                    // Two soft folds where the cloth hangs.
                    GeometryReader { geo in
                        ForEach([0.34, 0.68], id: \.self) { at in
                            LinearGradient(colors: [.clear, brand.palette.ink.opacity(0.07), .clear],
                                           startPoint: .leading, endPoint: .trailing)
                                .frame(width: 34)
                                .offset(x: geo.size.width * at - 17)
                        }
                    }
                }

            // The corner, turned back.
            FoldedCorner()
                .fill(brand.palette.surface)
                .overlay {
                    FoldedCorner().stroke(AppBrand.clayEdge.opacity(0.5), lineWidth: 1)
                }
                .frame(width: lifted ? 58 : 26, height: lifted ? 58 : 26)
                .shadow(color: .black.opacity(0.14), radius: 5, x: -2, y: 3)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Under the dust sheet")
        .accessibilityHint("Opens what one payment buys.")
        .accessibilityAddTraits(.isButton)
    }
}

/// The turned-back corner of a cloth.
struct FoldedCorner: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.maxY),
                          control: CGPoint(x: rect.midX * 1.1, y: rect.midY * 0.6))
        path.closeSubpath()
        return path
    }
}

/// A word opened from the wall: the tile large, what it means, how it is said, and a way to
/// bring it to the bench now.
struct WordSheet: View {
    @EnvironmentObject private var library: Library
    @Environment(\.brand) private var brand
    let word: Word
    let onDone: () -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 26) {
                Spacer(minLength: 0)
                TurningTile(angle: 180,
                            word: word,
                            glaze: AppBrand.glaze(word.theme),
                            showRank: true,
                            onChime: { Speech.shared.say(word) })
                    .frame(width: 300, height: 300)
                    .shadow(color: .black.opacity(0.14), radius: 16, y: 10)
                    .popIn()

                Mark("\(Deck.themeName(word.theme).uppercased()) · \(firingLabel.uppercased())")
                    .foregroundStyle(brand.palette.inkSoft)

                Spacer(minLength: 0)

                Button {
                    Haptics.tap()
                    library.summon(word)
                    onDone()
                } label: {
                    Text("Set it now")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                }
                .brandProminent()
                .padding(.horizontal, 40)
                .padding(.bottom, 20)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .brandBackground(drift: true)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { onDone() } label: { Image(systemName: "xmark") }
                        .accessibilityLabel("Close")
                }
            }
        }
    }

    private var firingLabel: String {
        switch library.firing(word) {
        case .set: return "in the wall"
        case .drying: return "drying"
        case .bare: return "bare clay"
        }
    }
}
