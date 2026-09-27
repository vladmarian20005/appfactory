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

/// The card while winding: one Canvas for pricks, pins, gimp and thread, the thread's end and
/// its slack to the finger, and a drag over all of it.
struct CardView: View {
    @EnvironmentObject private var bench: Bench
    let pillow: SavedPillow
    let size: CGFloat

    @Environment(\.brand) private var brand
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var finger: CGPoint?
    /// Where the finger was last read, in card space: the next move is walked from here, so a
    /// fast stroke takes exactly the pins it passed over, and never ones it did not.
    @State private var lastPoint: CGPoint?
    /// The pin the finger is pressing into that the thread cannot take — gimp or already
    /// wound. The slack goes madder while it is there, and the detent fires once.
    @State private var blocked: Int?
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
                slack
                newestSegment
                headMark
                plaitFlash
                deadEndRing
                sprungPin
                if let hand = bench.lesson?.hand {
                    GhostHand(points: hand.cells.map(layout.centre), backward: hand.backward,
                              trail: hand.backward ? brand.palette.miss : thread.color,
                              ink: brand.palette.ink, width: layout.threadWidth)
                        .id(hand.cells)
                } else if pillow.isEmpty && bench.lesson == nil {
                    teaching
                }
                if !pillow.isEmpty { nudgeRing }
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
    }

    private func arrive() {
        guard arrived < 1 else { return }
        if Motion.isStill || reduceMotion { arrived = 1; return }
        withAnimation(.easeOut(duration: 0.5)) { arrived = 1 }
    }

    // MARK: - The thread's end

    /// The thread is drawn to the pin the moment it is taken — under the finger, not after
    /// it. What connects the last pin to the finger is the slack: a lighter strand from the
    /// thread's end towards the fingertip, a pitch long at most, so the thread always looks
    /// held. Madder while the finger presses into a pin the thread cannot take.
    @ViewBuilder
    private var slack: some View {
        if bench.winding, let f = finger, let head = pillow.head, bench.lift == nil {
            let c = layout.centre(head)
            let dx = f.x - c.x, dy = f.y - c.y
            let d = max(hypot(dx, dy), 0.001)
            let reach = min(d, layout.pitch * 0.9)
            let end = CGPoint(x: c.x + dx / d * reach, y: c.y + dy / d * reach)
            Path { p in p.move(to: c); p.addLine(to: end) }
                .stroke((blocked == nil ? thread.color : brand.palette.miss).opacity(0.5),
                        style: StrokeStyle(lineWidth: layout.threadWidth * 0.8, lineCap: .round))
                .allowsHitTesting(false)
        }
    }

    /// Where the thread is: a bead of thread on the last pin, with a soft halo while a finger
    /// holds it, and a small press as each pin sinks.
    @ViewBuilder
    private var headMark: some View {
        if let head = pillow.head {
            let c = layout.centre(head)
            let r = max(layout.threadWidth * 1.15, 3)
            ZStack {
                Circle()
                    .fill(thread.color.opacity(0.16))
                    .frame(width: layout.pitch * 0.78, height: layout.pitch * 0.78)
                    .opacity(bench.winding ? 1 : 0)
                    .animation(Motion.resolved(.easeOut(duration: 0.15)), value: bench.winding)
                Circle()
                    .fill(thread.color)
                    .frame(width: 2 * r, height: 2 * r)
            }
            .keyframeAnimator(initialValue: CGFloat(1), trigger: bench.reachTick) { v, s in
                v.scaleEffect(s)
            } keyframes: { _ in
                KeyframeTrack {
                    CubicKeyframe(1.25, duration: 0.05)
                    SpringKeyframe(1, duration: 0.16, spring: .snappy)
                }
            }
            .position(c)
            .allowsHitTesting(false)
        }
    }

    /// The last segment, drawn apart from the rest only so a dead end can tug it.
    @ViewBuilder
    private var newestSegment: some View {
        if path.count >= 2 {
            let a = layout.centre(path[path.count - 2]), b = layout.centre(path[path.count - 1])
            let dir = CGVector(dx: (b.x - a.x) / layout.pitch, dy: (b.y - a.y) / layout.pitch)
            ZStack {
                Path { p in p.move(to: a); p.addLine(to: b) }
                    .stroke(thread.color, style: StrokeStyle(lineWidth: layout.threadWidth, lineCap: .round))
                // The wrap round the pin before, if the thread turned there.
                if path.count >= 3, (path[path.count - 1] - path[path.count - 2]) != (path[path.count - 2] - path[path.count - 3]) {
                    let r = layout.ringRadius
                    Circle()
                        .stroke(thread.color, lineWidth: layout.ringWidth)
                        .frame(width: 2 * r, height: 2 * r)
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

    // MARK: - Teaching a fresh pattern

    /// The start pin breathes, and a ghost thread runs from it into the first forced pin.
    /// The first card's ghost hand takes this over while it is out.
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
        nudgeRing
    }

    /// A touch that could not start the thread rings the pin it has to start from.
    @ViewBuilder
    private var nudgeRing: some View {
        let at: Int? = pillow.head ?? pr.start.map(Int.init)
        if let at {
            // At rest the ring is spent (t = 1, invisible); a nudge runs it from 0 again.
            Circle()
                .stroke(AppBrand.Workbox.brass, lineWidth: 2)
                .frame(width: layout.pitch * 0.8, height: layout.pitch * 0.8)
                .keyframeAnimator(initialValue: CGFloat(1), trigger: bench.nudges) { v, t in
                    v.scaleEffect(0.6 + t * 0.9).opacity(Double(1 - t))
                } keyframes: { _ in
                    KeyframeTrack {
                        CubicKeyframe(0, duration: 0.01)
                        CubicKeyframe(1, duration: 0.55)
                    }
                }
                .position(layout.centre(at))
                .allowsHitTesting(false)
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

    /// A small walnut bobbin lying beside the last pin while the thread is set down: where to
    /// pick it up again. In the hand it is gone — the finger is the bobbin, and nothing trails
    /// behind it.
    @ViewBuilder
    private var bobbin: some View {
        if let head = pillow.head {
            let c = layout.centre(head)
            Bobbin()
                .rotationEffect(.degrees(20))
                .scaleEffect(min(1, layout.pitch / 30))
                .position(x: c.x + layout.pitch * 0.42, y: c.y + layout.pitch * 0.55)
                .opacity(bench.winding ? 0 : 1)
                .animation(Motion.resolved(.easeOut(duration: 0.18)), value: bench.winding)
                .animation(Motion.resolved(Motion.gentle), value: head)
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
                lastPoint = nil
                blocked = nil
                bench.endGesture()
            }
    }

    private func distance(_ a: CGPoint, _ b: CGPoint) -> CGFloat { hypot(a.x - b.x, a.y - b.y) }

    /// A fingertip is wider than a pin, so a touch anywhere near the thread's end picks it
    /// up, and a touch near the brass pin on a fresh card starts there.
    private func touchDown(at p: CGPoint) {
        let grab = layout.pitch * 0.95
        if let head = pillow.head, distance(p, layout.centre(head)) <= grab {
            Haptics.soft()
            bench.winding = true
            lastPoint = layout.centre(head)
            return
        }
        if pillow.isEmpty, let s = pr.start.map(Int.init), distance(p, layout.centre(s)) <= grab {
            bench.winding = true
            bench.take(s)
            lastPoint = layout.centre(s)
            return
        }
        guard let cell = layout.cell(at: p), pr.open[cell] else { return }
        if let i = path.firstIndex(of: cell) {
            // A touch on an earlier pin of the thread cuts it back there, and winds on from it.
            bench.unpick(to: i)
            bench.winding = true
            lastPoint = layout.centre(cell)
        } else if bench.canTake(cell) {
            bench.winding = true
            bench.take(cell)
            lastPoint = layout.centre(cell)
        } else if bench.record.hasEarned("pin") {
            // Press and hold a bare pin for a marking pin.
            holdTask?.cancel()
            holdTask = Task { @MainActor in
                try? await Task.sleep(nanoseconds: 450_000_000)
                guard !Task.isCancelled, began, let f = finger, layout.cell(at: f) == cell else {
                    return
                }
                withMotion(Motion.pop) { bench.toggleMarker(cell) }
            }
            nudgeLater(for: cell)
        } else {
            bench.nudge()
        }
    }

    /// A bare pin pressed without holding: when the hold does not become a marking pin, the
    /// thread's end rings, to say where to pick it up.
    private func nudgeLater(for cell: Int) {
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 200_000_000)
            if !began { bench.nudge() }
        }
    }

    /// Follow the finger along the way it actually went. The stroke since the last reading is
    /// walked in fifth-of-a-pitch steps; each pin the finger passes well inside of is taken if
    /// the thread can take it, the pin behind the end is picked out, and a pin the thread
    /// cannot take stops the walk there — the thread never jumps ahead of the finger, and never
    /// turns a corner the finger did not.
    private func follow(to p: CGPoint) {
        guard bench.winding, let from = lastPoint else { return }
        let length = distance(from, p)
        let steps = max(1, Int((length / (layout.pitch * 0.2)).rounded(.up)))
        for k in 1...steps {
            let t = CGFloat(k) / CGFloat(steps)
            let q = CGPoint(x: from.x + (p.x - from.x) * t, y: from.y + (p.y - from.y) * t)
            guard step(at: q) else { break }
            if bench.lift != nil { break }
        }
        lastPoint = p
    }

    /// One reading of the finger. False when the thread is stopped against something.
    private func step(at q: CGPoint) -> Bool {
        guard let cur = bench.current, let head = cur.head else { return true }
        guard let cell = layout.cell(at: q), pr.open[cell], cell != head else {
            blocked = nil
            return true
        }
        // Well inside the pin's square before it counts: a finger on a border does not
        // flicker between two pins.
        let c = layout.centre(cell)
        guard abs(q.x - c.x) <= layout.pitch * 0.4, abs(q.y - c.y) <= layout.pitch * 0.4 else { return true }
        let path = cur.path.map(Int.init)
        if path.count >= 2, cell == path[path.count - 2] {
            blocked = nil
            bench.unpickLast()
            return true
        }
        let dr = cell / pr.side - head / pr.side, dc = cell % pr.side - head % pr.side
        if abs(dr) + abs(dc) == 1 {
            if bench.canTake(cell) {
                blocked = nil
                bench.take(cell)
                return true
            }
            refuse(cell)
            return false
        }
        if abs(dr) == 1 && abs(dc) == 1 {
            // The finger cut a corner: go by whichever of the two pins between leads on to
            // where it went.
            let via = [head + dr * pr.side, head + dc].filter { v in
                bench.canTake(v) && pr.canStep(from: v, to: cell) && !path.contains(cell)
            }
            if via.count == 1, let v = via.first {
                bench.take(v)
                if bench.canTake(cell) { bench.take(cell) }
                blocked = nil
                return true
            }
            // Both ways lead there, or neither: wait for the finger to say which.
            return true
        }
        return true
    }

    private func refuse(_ cell: Int) {
        guard blocked != cell else { return }
        blocked = cell
        Haptics.rigid()
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
