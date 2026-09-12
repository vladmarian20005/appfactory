import FactoryKit
import SwiftUI

/// The bench is swept and the day's tiles are in the wall.
///
/// Full screen on the plaster, never a sheet and never a checkmark: the course expands into
/// the whole wall, the session's tiles press into it in order, the count runs, and how loud it
/// gets depends on how the session went.
struct WinView: View {
    @EnvironmentObject private var library: Library
    @Environment(\.brand) private var brand

    let setWords: [Word]
    let wentBack: Int
    let startedKnown: Int
    let onDone: () -> Void

    @State private var landed = 0
    @State private var burst = 0
    /// 0…1 while a new hundred lights the wall; below zero the rest of the time.
    @State private var lustreT: Double = -1
    @State private var glow: Double = 0
    @State private var headline = ""
    @State private var subline = ""
    @State private var played = false

    private var known: Int { library.setCount }

    private var tier: Voice.Tier {
        let crossed = known / 100
        if crossed > startedKnown / 100, known >= 100 {
            return .hundred(crossed * 100)
        }
        return wentBack == 0 ? .clean : .set
    }

    /// Ranks the session put into the wall, in the order they were set.
    private var freshRanks: [Int] {
        setWords.map(\.rank).filter { library.state($0)?.firing == .set }
    }

    private var pending: Set<Int> {
        Set(freshRanks.dropFirst(landed))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                hero
                    .padding(.top, 8)

                wall
                    .frame(height: 300)
                    .padding(.horizontal, 18)
                    .padding(.top, 14)

                WallLine(known: known)
                    .padding(.top, 18)

                VStack(spacing: 7) {
                    Text(headline)
                        .brandFont(.title)
                        .foregroundStyle(brand.palette.ink)
                    Text(subline)
                        .font(.body)
                        .foregroundStyle(brand.palette.inkSoft)
                    Text(Voice.standing(panels: library.panelsStanding, of: Deck.themes.count))
                        .font(.footnote)
                        .foregroundStyle(brand.palette.inkSoft.opacity(0.85))
                }
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 26)
                .padding(.top, 22)

                actions
                    .padding(.top, 24)
                    .padding(.bottom, 28)
            }
            .frame(maxWidth: .infinity)
        }
        .workshopBackground()
        // The win is a moment, not a screen: the bars go away and the wall has the phone.
        .toolbar(.hidden, for: .tabBar)
        .toolbar(.hidden, for: .navigationBar)
        .confetti(trigger: burst,
                  colors: glazeChips,
                  count: 90,
                  power: confettiPower)
        .onAppear(perform: play)
    }

    // MARK: - The count

    private var hero: some View {
        VStack(spacing: 2) {
            CountUp(to: known, from: startedKnown, duration: 0.6) { _ in
                Haptics.impact(0.35)
            }
            .brandDisplay(size: 100)
            .foregroundStyle(isHundred ? brand.palette.highlight : brand.palette.ink)

            Mark(Deck.totalMark)
                .foregroundStyle(brand.palette.inkSoft)

            Mark("+\(freshRanks.count) SET TODAY")
                .foregroundStyle(brand.palette.highlight)
                .padding(.top, 5)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(known) of \(Deck.total) set. \(freshRanks.count) went in today.")
    }

    private var isHundred: Bool {
        if case .hundred = tier { return true }
        return false
    }

    // MARK: - The wall

    private var wall: some View {
        WallMosaic(firings: firings,
                   fresh: Set(freshRanks.prefix(landed)),
                   lustre: lustreT >= 0 ? lustreT : nil)
            .background {
                // The lamp swells behind the wall when the session simply finished: a normal
                // day is not a parade.
                RadialGradient(colors: [brand.palette.highlight.opacity(0.3 * glow), .clear],
                               center: .center, startRadius: 0, endRadius: 260)
                    .blur(radius: 30)
            }
            .scaleEffect(landed == 0 && !Motion.isStill ? 1.06 : 1)
    }

    private var firings: [Int: Firing] {
        var map: [Int: Firing] = [:]
        for (rank, state) in library.states {
            map[rank] = state.firing
        }
        // The day's tiles press in one at a time; until each lands it is still bare clay.
        for rank in pending { map[rank] = .bare }
        return map
    }

    private var glazeChips: [Color] {
        let used = setWords.map { AppBrand.glaze($0.theme) }
        return used.isEmpty ? brand.palette.extras : used
    }

    private var confettiPower: CGFloat {
        switch tier {
        case .set: return 0
        case .clean: return 1.1
        case .hundred: return 1.5
        }
    }

    // MARK: - After

    private var actions: some View {
        VStack(spacing: 14) {
            Button {
                Haptics.tap()
                onDone()
            } label: {
                Text("Back to the wall")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
            }
            .brandProminent()

            if let image = shareImage {
                ShareLink(item: image,
                          message: Text(shareLine),
                          preview: SharePreview("\(known) of a thousand", image: image)) {
                    Label("Share the wall", systemImage: "square.and.arrow.up")
                        .font(.headline)
                }
                .foregroundStyle(brand.palette.accent)
            }
        }
        .padding(.horizontal, 40)
    }

    private var shareLine: String {
        let newest = setWords.last?.word ?? ""
        return newest.isEmpty
            ? "\(known) of a thousand Spanish words."
            : "\(known) of a thousand Spanish words. \(newest) went in today."
    }

    @MainActor
    private var shareImage: Image? {
        ShareCard.image(known: known,
                        today: freshRanks.count,
                        newest: setWords.last,
                        firings: library.states.mapValues(\.firing))
    }

    // MARK: - The 1500 ms

    private func play() {
        guard !played else { return }
        played = true
        headline = Voice.headline(tier)
        subline = wentBack == 0
            ? Voice.line(from: Voice.praise, memory: "thousand.praise")
            : Voice.line(from: Voice.nearMiss, memory: "thousand.nearMiss")

        guard !Motion.isStill else {
            // A still capture shows a finished wall, not a wall in the middle of being laid.
            landed = freshRanks.count
            glow = 1
            burst = confettiPower > 0 ? 1 : 0
            return
        }

        Task { @MainActor in
            // 0–260: the pull-back, then the tiles press in, in order, climbing the scale.
            try? await Task.sleep(nanoseconds: 180_000_000)
            withMotion(Motion.gentle) { landed = 0 }
            for i in 0..<freshRanks.count {
                try? await Task.sleep(nanoseconds: 50_000_000)
                withMotion(Motion.snappy) { landed = i + 1 }
                Haptics.impact(0.3)
                Tones.shared.play(.step(i))
            }
        }

        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 900_000_000)
            switch tier {
            case .set:
                withMotion(Motion.gentle) { glow = 1 }
                Haptics.success()
                Tones.shared.play(.success)
            case .clean:
                glow = 1
                burst += 1
                Haptics.celebrate()
                Tones.shared.play(.fanfare)
            case .hundred:
                glow = 1
                burst += 1
                Haptics.celebrate()
                Tones.shared.play(.fanfare)
                lustreT = 0
                withAnimation(.easeInOut(duration: 0.7)) { lustreT = 1 }
                try? await Task.sleep(nanoseconds: 750_000_000)
                lustreT = -1
            }
        }
    }
}
