import FactoryKit
import SwiftUI

/// One number that only goes up, and where the work is.
///
/// No calendar. No streak. No days-in-a-row anything — and no sentence pointing out that they
/// are missing.
struct ProgressWallView: View {
    @EnvironmentObject private var store: Store
    @EnvironmentObject private var library: Library
    @Environment(\.brand) private var brand

    @State private var drawn = false

    private var isOpen: Bool { store.isPro || LaunchOptions.forcePro }
    private var known: Int { library.setCount }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 30) {
                hero
                kilnShelf
                panels
            }
            .padding(.horizontal, 22)
            .padding(.top, 6)
            .padding(.bottom, 32)
        }
        .brandBackground(drift: true)
        .navigationTitle("Progress")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            withMotion(Motion.gentle) { drawn = true }
        }
    }

    // MARK: - The count

    private var hero: some View {
        VStack(spacing: 3) {
            if known == 0 {
                Text("Bare plaster.")
                    .brandFont(.largeTitle)
                    .foregroundStyle(brand.palette.ink)
                Text("The first course goes in today.")
                    .font(.body)
                    .foregroundStyle(brand.palette.inkSoft)
                    .padding(.top, 4)
            } else {
                CountUp(to: known, duration: 0.6)
                    .brandDisplay(size: 104)
                    .foregroundStyle(brand.palette.ink)
                Mark(Deck.totalMark)
                    .foregroundStyle(brand.palette.inkSoft)
            }

            WallLine(known: known)
                .padding(.top, 18)

            Text(Voice.standing(panels: library.panelsStanding, of: Deck.themes.count))
                .font(.footnote)
                .foregroundStyle(brand.palette.inkSoft)
                .multilineTextAlignment(.center)
                .padding(.top, 14)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }

    // MARK: - The kiln shelf

    /// Due today and due tomorrow, drawn as what they are: two stacks of tiles, at true scale,
    /// in their own glazes. Never a row of identical number tiles with grey captions.
    private var kilnShelf: some View {
        VStack(alignment: .leading, spacing: 0) {
            Mark("THE KILN SHELF")
                .foregroundStyle(brand.palette.inkSoft)
                .padding(.bottom, 14)

            HStack(alignment: .bottom, spacing: 20) {
                KilnStack(words: dueToday, caption: "DUE TODAY", drawn: drawn)
                KilnStack(words: dueTomorrow, caption: "TOMORROW", drawn: drawn)
            }
        }
    }

    private var dueToday: [Word] {
        library.dueNow(pro: isOpen)
    }

    private var dueTomorrow: [Word] {
        guard let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) else { return [] }
        let cal = Calendar.current
        let start = cal.startOfDay(for: tomorrow)
        guard let end = cal.date(byAdding: .day, value: 1, to: start) else { return [] }
        return (isOpen ? Deck.words : Deck.freeWords).filter { word in
            guard let state = library.state(word.rank) else { return false }
            return state.due >= start && state.due < end
        }
    }

    // MARK: - The twelve panels

    private var panels: some View {
        VStack(alignment: .leading, spacing: 13) {
            Mark("THE TWELVE PANELS")
                .foregroundStyle(brand.palette.inkSoft)
                .padding(.bottom, 2)

            ForEach(Array(ordered.enumerated()), id: \.element) { i, theme in
                MortarBar(theme: theme,
                          set: library.setCount(theme: theme),
                          total: Deck.panel(theme).count,
                          drawn: drawn,
                          delay: 0.04 * Double(i))
            }
        }
    }

    /// Longest first: the wall reads as courses that have got somewhere, not as a table.
    private var ordered: [Int] {
        (0..<Deck.themes.count).sorted { library.setCount(theme: $0) > library.setCount(theme: $1) }
    }
}

/// A stack of tiles waiting on the kiln shelf: one tile per word, in its own glaze, seen the
/// way a pile of tiles is seen — edge on, each showing a sliver of the face above it.
///
/// Never a number tile with a grey caption under it: the number is the height of the pile.
struct KilnStack: View {
    @Environment(\.brand) private var brand
    let words: [Word]
    let caption: String
    let drawn: Bool

    private let tileW: CGFloat = 74
    private let tileH: CGFloat = 11
    private let overlap: CGFloat = 4
    private let cap = 22

    private var step: CGFloat { tileH - overlap }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Spacer(minLength: 0)

            ZStack(alignment: .bottom) {
                ForEach(Array(words.prefix(cap).enumerated()).reversed(), id: \.element.rank) { i, word in
                    tile(word)
                        .offset(x: CGFloat((word.rank % 5) - 2),
                                y: drawn ? -CGFloat(i) * step : 0)
                        .animation(Motion.resolved(Motion.gentle.delay(0.02 * Double(i))), value: drawn)
                }
            }
            .frame(width: tileW + 8,
                   height: max(tileH, CGFloat(max(min(words.count, cap) - 1, 0)) * step + tileH),
                   alignment: .bottom)

            // The plank they are stacked on.
            RoundedRectangle(cornerRadius: 1, style: .continuous)
                .fill(AppBrand.clayEdge.opacity(0.5))
                .frame(width: tileW + 14, height: 2)

            VStack(alignment: .leading, spacing: 2) {
                Text("\(words.count)")
                    .brandDisplay(size: 36)
                    .foregroundStyle(brand.palette.ink)
                Mark(caption)
                    .foregroundStyle(brand.palette.inkSoft)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(words.count) \(caption.lowercased())")
    }

    private func tile(_ word: Word) -> some View {
        let glaze = AppBrand.glaze(word.theme)
        return RoundedRectangle(cornerRadius: 2.5, style: .continuous)
            .fill(LinearGradient(colors: [glaze, glaze.shaded(0.3)], startPoint: .top, endPoint: .bottom))
            .overlay(alignment: .top) {
                // The lit face of the tile below the one above it.
                Rectangle()
                    .fill(.white.opacity(0.3))
                    .frame(height: 1.5)
                    .padding(.horizontal, 2.5)
            }
            .frame(width: tileW, height: tileH)
            .shadow(color: .black.opacity(0.09), radius: 1.5, y: 0.5)
    }
}

/// One theme's mastery, as the line of mortar its tiles are set into.
struct MortarBar: View {
    @Environment(\.brand) private var brand
    let theme: Int
    let set: Int
    let total: Int
    let drawn: Bool
    let delay: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(alignment: .firstTextBaseline) {
                Text(Deck.themeName(theme))
                    .brandFont(.subheadline)
                    .foregroundStyle(brand.palette.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Spacer(minLength: 10)
                Mark("\(set) / \(total)")
                    .foregroundStyle(brand.palette.inkSoft)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(brand.palette.surface)
                    Capsule()
                        .fill(AppBrand.glaze(theme))
                        .frame(width: drawn ? geo.size.width * fraction : 0)
                        .animation(Motion.resolved(Motion.gentle.delay(delay)), value: drawn)
                }
                .frame(height: 6)
                .frame(height: geo.size.height, alignment: .center)
            }
            .frame(height: 6)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(Deck.themeName(theme)): \(set) of \(total) set.")
    }

    private var fraction: CGFloat {
        CGFloat(Double(set) / Double(max(total, 1)))
    }
}
