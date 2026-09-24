import FactoryKit
import SwiftUI

/// The pillow: a rounded bolster in the linen darkened a shade, with a highlight along its
/// top edge and a soft shadow beneath — the thing the card is pinned to.
struct PillowBolster<Content: View>: View {
    var dim: Double = 0
    @ViewBuilder var content: Content
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 28, style: .continuous)
        content
            .padding(.vertical, 22)
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity)
            .background {
                shape
                    .fill(AppBrand.Pillow.cloth)
                    .overlay(alignment: .top) {
                        shape
                            .strokeBorder(
                                LinearGradient(colors: [AppBrand.Pillow.highlight, .clear],
                                               startPoint: .top, endPoint: .center),
                                lineWidth: 1)
                    }
                    .shadow(color: .black.opacity(scheme == .dark ? 0.4 : 0.14), radius: 24, x: 0, y: 12)
                    .overlay { shape.fill(Color.black.opacity(dim)) }
                    .animation(Motion.resolved(Motion.gentle), value: dim)
            }
    }
}

/// The pricking card: parchment, held at −1.2° by four brass pins at its corners.
struct PrickingCard<Content: View>: View {
    let size: CGFloat
    @ViewBuilder var content: Content
    @Environment(\.brand) private var brand
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        content
            .frame(width: size, height: size)
            .background {
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(brand.palette.surface)
                    .shadow(color: .black.opacity(scheme == .dark ? 0.45 : 0.16), radius: 3, x: 1.5, y: 2.5)
            }
            .overlay {
                // The four brass pins that hold the card, each with its own shadow.
                GeometryReader { g in
                    ForEach(0..<4, id: \.self) { i in
                        PinHead(color: AppBrand.Workbox.brass, size: 9)
                            .position(x: i % 2 == 0 ? 7 : g.size.width - 7,
                                      y: i < 2 ? 7 : g.size.height - 7)
                    }
                }
                .allowsHitTesting(false)
            }
            .rotationEffect(.degrees(-1.2))
    }
}

/// The card while winding: one Canvas for pricks, pins, gimp and thread, the newest segment
/// reaching on its own spring, and a drag over all of it.
struct CardView: View {
    @EnvironmentObject private var bench: Bench
    let pillow: SavedPillow
    let size: CGFloat

    @Environment(\.brand) private var brand
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var reach: CGFloat = 1
    @State private var ringPop: CGFloat = 1
    @State private var finger: CGPoint?
    @State private var arrived: CGFloat = Motion.isStill ? 1 : 0
    @State private var holdTask: Task<Void, Never>?
    @State private var began = false

    private var pr: Pricking { pillow.pricking }
    private var layout: CardLayout { CardLayout(side: pr.side, size: size) }
    private var path: [Int] { pillow.path.map(Int.init) }
    private var thread: ThreadColour { bench.record.threadInHand }

    var body: some View {
        PrickingCard(size: size) {
            ZStack {
                PinsLayer(pillow: pillow, layout: layout, arrived: arrived, thread: thread,
                          ink: brand.palette.ink, canvas: AppBrand.Pillow.cloth)
                newestSegment
                plaitFlash
                deadEndRing
                sprungPin
                if pillow.isEmpty { teaching }
                markers
                bobbin
            }
            .frame(width: size, height: size)
            .contentShape(Rectangle())
            .gesture(drag)
            .overlay { accessibilityGrid }
        }
        .onAppear { arrive() }
        .onChange(of: pr.seed) { _, _ in arrived = 0; arrive() }
        .onChange(of: pillow.path.count) { old, new in
            guard new > old else { reach = 1; return }
            reach = 0
            ringPop = 1.5
            withAnimation(Motion.resolved(Lace.wind)) { reach = 1 }
            withAnimation(Motion.resolved(Motion.pop)?.delay(0.04)) { ringPop = 1 }
        }
    }

    private func arrive() {
        guard arrived < 1 else { return }
        if Motion.isStill || reduceMotion { arrived = 1; return }
        withAnimation(.easeOut(duration: 0.5)) { arrived = 1 }
    }

    // MARK: - The newest pin's three beats

    @ViewBuilder
    private var newestSegment: some View {
        if path.count >= 2 {
            let a = layout.centre(path[path.count - 2]), b = layout.centre(path[path.count - 1])
            let dir = CGVector(dx: (b.x - a.x) / layout.pitch, dy: (b.y - a.y) / layout.pitch)
            ZStack {
                Path { p in p.move(to: a); p.addLine(to: b) }
                    .trim(from: 0, to: reach)
                    .stroke(thread.color, style: StrokeStyle(lineWidth: layout.threadWidth, lineCap: .round))
                // The wrap round the pin before, if the thread turned there.
                if path.count >= 3, (path[path.count - 1] - path[path.count - 2]) != (path[path.count - 2] - path[path.count - 3]) {
                    let r = layout.ringRadius
                    Circle()
                        .stroke(thread.color, lineWidth: layout.ringWidth)
                        .frame(width: 2 * r, height: 2 * r)
                        .scaleEffect(ringPop)
                        .position(a)
                }
            }
            // The dead end: the thread's end tugs twice along its last direction.
            .keyframeAnimator(initialValue: CGFloat.zero, trigger: bench.tugs) { view, t in
                view.offset(x: dir.dx * t, y: dir.dy * t)
            } keyframes: { _ in
                KeyframeTrack {
                    CubicKeyframe(2, duration: 0.045)
                    CubicKeyframe(0, duration: 0.045)
                    CubicKeyframe(2, duration: 0.045)
                    CubicKeyframe(0, duration: 0.06)
                }
            }
            .allowsHitTesting(false)
        }
    }

    /// A run tightening into a plait: its stroke goes 3.4 → 3.8 and back.
    @ViewBuilder
    private var plaitFlash: some View {
        if let run = bench.plaitFlash, run.upperBound <= path.count {
            Path { p in
                p.move(to: layout.centre(path[run.lowerBound]))
                p.addLine(to: layout.centre(path[run.upperBound - 1]))
            }
            .keyframeAnimator(initialValue: CGFloat(0), trigger: bench.plaitTick) { _, extra in
                Path { p in
                    p.move(to: layout.centre(path[run.lowerBound]))
                    p.addLine(to: layout.centre(path[run.upperBound - 1]))
                }
                .stroke(thread.color, style: StrokeStyle(lineWidth: layout.threadWidth + extra, lineCap: .round))
                .opacity(extra > 0.01 ? 1 : 0)
            } keyframes: { _ in
                KeyframeTrack {
                    CubicKeyframe(0.4, duration: 0.08)
                    SpringKeyframe(0, duration: 0.2, spring: .bouncy)
                }
            }
            .allowsHitTesting(false)
        }
    }

    @ViewBuilder
    private var deadEndRing: some View {
        if let cell = bench.deadEnd {
            let r = layout.ringRadius * 1.6
            Circle()
                .stroke(brand.palette.miss, lineWidth: 1.6)
                .frame(width: 2 * r, height: 2 * r)
                .position(layout.centre(cell))
                .transition(.opacity)
                .allowsHitTesting(false)
        }
    }

    /// A pin picked out springs back up: 0.86 → 1.04 → 1.
    @ViewBuilder
    private var sprungPin: some View {
        if let cell = bench.sprung, !path.contains(cell) {
            PinHead(size: 5.5)
                .keyframeAnimator(initialValue: CGFloat(1), trigger: bench.springs) { v, s in
                    v.scaleEffect(s)
                } keyframes: { _ in
                    KeyframeTrack {
                        CubicKeyframe(0.86, duration: 0.01)
                        SpringKeyframe(1.04, duration: 0.12, spring: .snappy)
                        SpringKeyframe(1, duration: 0.16)
                    }
                }
                .position(layout.centre(cell))
                .allowsHitTesting(false)
        }
    }

    // MARK: - Teaching the first one, with no text

    /// The start pin breathes, and a ghost thread runs from it into the first forced pin.
    @ViewBuilder
    private var teaching: some View {
        let answer = bench.orientedAnswer(pr).map(Int.init)
        if answer.count >= 2 {
            let a = layout.centre(answer[0]), b = layout.centre(answer[1])
            TimelineView(.animation(minimumInterval: 1.0 / 30, paused: Motion.isStill || reduceMotion)) { ctx in
                let t = Motion.isStill || reduceMotion ? 1.0 : ctx.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 2.0)
                let trim = min(1, t / 1.2)
                Path { p in p.move(to: a); p.addLine(to: b) }
                    .trim(from: 0, to: trim)
                    .stroke(thread.color.opacity(t > 1.6 && !Motion.isStill ? 0 : 0.22),
                            style: StrokeStyle(lineWidth: layout.threadWidth, lineCap: .round))
            }
            .allowsHitTesting(false)
            if pr.start != nil {
                PinHead(color: AppBrand.Workbox.brass, size: 8)
                    .breathing(amount: 0.08, period: 2.4)
                    .position(a)
                    .allowsHitTesting(false)
            }
        }
    }

    @ViewBuilder
    private var markers: some View {
        ForEach(pillow.markers.map(Int.init), id: \.self) { cell in
            let c = layout.centre(cell)
            PinHead(color: brand.palette.success, size: 5)
                .position(x: c.x + layout.pitch * 0.26, y: c.y - layout.pitch * 0.26)
                .transition(.scale.combined(with: .opacity))
                .allowsHitTesting(false)
        }
    }

    // MARK: - The bobbin

    /// A small walnut bobbin, hanging below and to the right of the finger while winding; lying
    /// beside the last pin when the finger lifts.
    @ViewBuilder
    private var bobbin: some View {
        if let head = pillow.head {
            let c = layout.centre(head)
            let held = bench.winding && finger != nil
            let at = held ? CGPoint(x: finger!.x + 22, y: finger!.y + 22) : CGPoint(x: c.x + 11, y: c.y + 16)
            Bobbin()
                .rotationEffect(.degrees(held ? 8 : 20))
                .position(at)
                .animation(Motion.resolved(held ? Motion.gentle : Motion.bouncy), value: at)
                .allowsHitTesting(false)
        }
    }

    // MARK: - The drag

    private var drag: some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .local)
            .onChanged { v in
                if !began {
                    began = true
                    touchDown(at: v.startLocation)
                }
                finger = v.location
                follow(to: v.location)
            }
            .onEnded { _ in
                began = false
                holdTask?.cancel()
                finger = nil
                bench.endGesture()
            }
    }

    private func touchDown(at p: CGPoint) {
        guard let cell = layout.cell(at: p), pr.open[cell] else { return }
        if let i = path.firstIndex(of: cell) {
            if i == path.count - 1 {
                Haptics.soft()
            } else {
                // A touch on an earlier pin of the thread cuts it back there — one miss.
                bench.unpick(to: i)
            }
            bench.winding = true
        } else if bench.canTake(cell) {
            Haptics.soft()
            bench.winding = true
            bench.take(cell)
        } else if bench.record.hasEarned("pin") {
            // Press and hold a bare pin for a marking pin.
            holdTask?.cancel()
            holdTask = Task { @MainActor in
                try? await Task.sleep(nanoseconds: 450_000_000)
                guard !Task.isCancelled, began, let f = finger, layout.cell(at: f) == cell else { return }
                withMotion(Motion.pop) { bench.toggleMarker(cell) }
            }
        }
    }

    /// Follow the finger: back onto the previous pin unwinds it; into a bare neighbour takes
    /// it; a fast finger that skipped cells is walked there one legal step at a time.
    private func follow(to p: CGPoint) {
        guard bench.winding, let target = layout.innerCell(at: p) else { return }
        guard let cur = bench.current, let head = cur.head, target != head else { return }
        let path = cur.path.map(Int.init)
        if path.count >= 2, target == path[path.count - 2] {
            bench.unpickLast()
            return
        }
        var steps = 0
        while steps < 28, let now = bench.current?.head, now != target {
            steps += 1
            let dr = target / pr.side - now / pr.side, dc = target % pr.side - now % pr.side
            let vertical = now + (dr > 0 ? pr.side : -pr.side)
            let horizontal = now + (dc > 0 ? 1 : -1)
            let first = abs(dr) >= abs(dc) ? (dr != 0 ? vertical : nil) : (dc != 0 ? horizontal : nil)
            let second = abs(dr) >= abs(dc) ? (dc != 0 ? horizontal : nil) : (dr != 0 ? vertical : nil)
            if let first, bench.canTake(first) {
                bench.take(first)
            } else if let second, bench.canTake(second) {
                bench.take(second)
            } else {
                break
            }
            if bench.lift != nil { break }
        }
    }

    // MARK: - VoiceOver

    /// Every pin is an element with a label and the tap-to-take fallback.
    private var accessibilityGrid: some View {
        ZStack {
            ForEach(0..<(pr.side * pr.side), id: \.self) { cell in
                if pr.open[cell] {
                    let c = layout.centre(cell)
                    Color.clear
                        .frame(width: layout.pitch, height: layout.pitch)
                        .position(c)
                        .accessibilityElement()
                        .accessibilityLabel(label(cell))
                        .accessibilityHint(cell == pillow.head || (pillow.isEmpty && bench.canTake(cell))
                                           ? "Drag or double tap a neighbouring pin to wind the thread onto it. Every pin, once." : "")
                        .accessibilityAddTraits(bench.canTake(cell) ? .isButton : [])
                        .accessibilityAction {
                            if bench.canTake(cell) {
                                bench.take(cell)
                            } else if let i = path.firstIndex(of: cell), i < path.count - 1 {
                                bench.unpick(to: i)
                                bench.endGesture()
                            }
                        }
                        .accessibilityAction(named: "Set a marking pin") { bench.toggleMarker(cell) }
                }
            }
        }
        .allowsHitTesting(false)
    }

    private func label(_ cell: Int) -> String {
        let where_ = "row \(cell / pr.side + 1) column \(cell % pr.side + 1)"
        var state = path.contains(cell) ? "on the thread" : "bare"
        if cell == pillow.head { state = "the thread's end" }
        if let s = pr.start, Int(s) == cell, !path.contains(cell) { state = "start" }
        if let f = pr.finish, Int(f) == cell, !path.contains(cell) { state = "finish" }
        return "Pin, \(where_), \(state)"
    }
}

/// Pricks, windows, pins, gimp and the wound thread — everything that does not move, in one
/// Canvas. `arrived` sweeps the pins in when a new pattern is pinned.
private struct PinsLayer: View, Animatable {
    let pillow: SavedPillow
    let layout: CardLayout
    var arrived: CGFloat
    let thread: ThreadColour
    let ink: Color
    let canvas: Color

    var animatableData: CGFloat {
        get { arrived }
        set { arrived = newValue }
    }

    var body: some View {
        Canvas { gc, _ in
            let pr = pillow.pricking
            let path = pillow.path.map(Int.init)
            let onThread = Set(path)
            let n = pr.side * pr.side
            // Windows: the card snipped away, the pillow showing through.
            for c in 0..<n where !pr.open[c] {
                let p = layout.centre(c)
                let h = layout.pitch / 2 + 0.5
                gc.fill(Path(CGRect(x: p.x - h, y: p.y - h, width: 2 * h, height: 2 * h)), with: .color(canvas))
            }
            gc.drawGimp(pr.gimp, layout: layout, color: AppBrand.Pillow.gimp.opacity(0.7))
            // The pins, arriving in a wave from the top left.
            let head: CGFloat = 5
            for c in 0..<n where pr.open[c] {
                let order = CGFloat(c / pr.side + c % pr.side) / CGFloat(2 * pr.side)
                guard order <= arrived + 0.001 else { continue }
                let p = layout.centre(c)
                gc.drawPrick(at: CGPoint(x: p.x + 0.8, y: p.y + 1), size: 3, ink: ink)
                let isStart = pr.start.map(Int.init) == c
                let isFinish = pr.finish.map(Int.init) == c
                if isFinish {
                    let r = layout.ringRadius * 1.4
                    gc.stroke(Path(ellipseIn: CGRect(x: p.x - r, y: p.y - r, width: 2 * r, height: 2 * r)),
                              with: .color(AppBrand.Workbox.brass), lineWidth: 1.4)
                }
                gc.drawPin(at: p, head: isStart || isFinish ? head + 2 : head,
                           color: isStart || isFinish ? AppBrand.Workbox.brass : AppBrand.Workbox.steel,
                           sunk: onThread.contains(c))
            }
            // The thread, but for its newest segment and ring, which reach on their own.
            if !path.isEmpty {
                let settled = Array(path.prefix(max(1, path.count - 1)))
                gc.drawThread(settled, plaits: pillow.plaits.filter { $0.upperBound < path.count },
                              layout: layout,
                              style: ThreadStyle(color: thread.color, twist: thread.twist),
                              ringsUpTo: path.count - 2)
            }
        }
        .accessibilityHidden(true)
    }
}

/// A small walnut bobbin, 14 × 34, with a madder band.
struct Bobbin: View {
    @Environment(\.brand) private var brand
    var body: some View {
        ZStack {
            Capsule()
                .fill(AppBrand.Workbox.walnut)
                .frame(width: 8, height: 30)
            Capsule()
                .fill(brand.palette.accent)
                .frame(width: 9, height: 9)
                .offset(y: -3)
            Rectangle()
                .fill(brand.palette.highlight)
                .frame(width: 8, height: 2.5)
                .offset(y: 6)
            Circle()
                .stroke(AppBrand.Workbox.walnut, lineWidth: 1.2)
                .frame(width: 6, height: 6)
                .offset(y: 18)
        }
        .frame(width: 14, height: 40)
        .shadow(color: .black.opacity(0.25), radius: 1.5, x: 1, y: 1.5)
        .accessibilityHidden(true)
    }
}
