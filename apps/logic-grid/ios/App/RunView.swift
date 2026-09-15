import FactoryKit
import SwiftUI

/// The run: the ladder, plate by plate, and what is waiting. A shelf of copper standing on
/// edge — not a list of rows and not a grid of level buttons.
struct RunView: View {
    @ObservedObject var bench: Bench
    @Binding var showPaywall: Bool
    @Binding var tab: RootView.Tab
    @Environment(\.brand) private var brand

    private var rung: Int { bench.nextRung }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {
                    nextPlate
                    shelf
                    if bench.runIsLocked || !bench.isPro { locked }
                    earnedShelf
                    if bench.isPro { proToggles }
                }
                .padding(.horizontal, 14)
                .padding(.top, 6)
                .padding(.bottom, 30)
            }
            .shopBackground()
            .navigationTitle("The run")
        }
    }

    // MARK: The next plate, standing at the front

    private var nextPlate: some View {
        VStack(spacing: 14) {
            StandingPlate(number: rung, side: 190, state: .next)
                .ambientFloat(distance: 2.5, period: 4.6)
            Text(shapeCaps)
                .plateCaps(size: 9.5)
                .foregroundStyle(brand.palette.inkSoft)
                .multilineTextAlignment(.center)
            Button {
                if bench.runIsLocked {
                    showPaywall = true
                } else {
                    bench.rule(daily: false)
                    tab = .bed
                }
            } label: {
                Text("Rule the next plate")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
            }
            .brandProminent()
        }
    }

    private var shapeCaps: String {
        let shape = Play.shape(at: rung)
        var parts = ["plate \(rung)",
                     "\(Spelled.out(shape.categories)) categories, \(Spelled.out(shape.members)) to a side",
                     "depth \(shape.depth)"]
        if shape.sealed > 0 { parts.append("\(Spelled.out(shape.sealed)) sealed") }
        return parts.joined(separator: " · ")
    }

    /// The plates behind it: what has been pulled, what is ruled and unfinished, what is still
    /// bare copper.
    private var shelf: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .bottom, spacing: 10) {
                ForEach(Array(stride(from: max(1, rung - 4), to: rung + 8, by: 1)), id: \.self) { number in
                    VStack(spacing: 6) {
                        StandingPlate(number: number, side: 78, state: state(of: number))
                        Text("\(number)")
                            .plateCaps(size: 8)
                            .foregroundStyle(brand.palette.inkSoft)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .background {
            // The rack the plates stand in.
            VStack(spacing: 0) {
                Spacer(minLength: 0)
                Rectangle().fill(brand.palette.ink.opacity(0.16)).frame(height: 2)
                Rectangle().fill(brand.palette.highlight.opacity(0.22)).frame(height: 1)
            }
            .padding(.bottom, 6)
        }
    }

    private func state(of number: Int) -> StandingPlate.State {
        if number < rung { return .pulled }
        if number == rung { return .next }
        return number > Play.freeRungs && !bench.isPro ? .locked : .bare
    }

    /// Plate forty-one is a blank, unruled plate with the run's own words crosshatched across
    /// it. Not a lock row and not a price.
    private var locked: some View {
        Button {
            showPaywall = true
        } label: {
            VStack(spacing: 14) {
                Image("Rack")
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 150)
                ZStack {
                    StandingPlate(number: Play.freeRungs + 1, side: 150, state: .locked)
                    Text("The run goes on")
                        .plateCaps(size: 11)
                        .foregroundStyle(AppBrand.Plate.trough)
                        .rotationEffect(.degrees(-4))
                }
                Text("Past the fortieth the plates go to five categories and six a side, ruled and proved exactly the same way.")
                    .brandFont(.callout, weight: .regular)
                    .foregroundStyle(brand.palette.inkSoft)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                Text("See the whole run")
                    .font(.headline)
                    .foregroundStyle(brand.palette.accent)
            }
            .padding(16)
            .frame(maxWidth: .infinity)
            .background {
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(brand.palette.surface)
                    .shadow(color: .black.opacity(0.10), radius: 8, x: 0, y: 4)
            }
        }
        .buttonStyle(.pressable(scale: 0.985))
    }

    // MARK: What playing has opened

    private var earnedShelf: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text("On the bench")
                    .brandFont(.title2)
                    .foregroundStyle(brand.palette.ink)
                Spacer(minLength: 0)
                if let next = Play.earned.next(after: bench.record.platesPulled) {
                    Text("\(Spelled.out(next.at - bench.record.platesPulled)) to go")
                        .plateCaps(size: 9.5)
                        .foregroundStyle(brand.palette.highlight)
                }
            }
            ForEach(Play.earned.milestones) { milestone in
                let has = bench.record.platesPulled >= milestone.at
                HStack(alignment: .top, spacing: 11) {
                    EngravedMark(glyph: glyph(milestone.id), size: 26,
                                 color: has ? brand.palette.ink : brand.palette.inkSoft.opacity(0.4),
                                 lip: nil, weight: 2)
                        .padding(.top, 2)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(milestone.title)
                            .brandFont(.headline)
                            .foregroundStyle(has ? brand.palette.ink : brand.palette.inkSoft)
                        Text(has ? milestone.blurb : "At \(Spelled.out(milestone.at)) plates pulled.")
                            .brandFont(.footnote, weight: .regular)
                            .foregroundStyle(brand.palette.inkSoft)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 0)
                    if has {
                        Lozenge().fill(brand.palette.highlight).frame(width: 13, height: 8).padding(.top, 8)
                    }
                }
                .opacity(has ? 1 : 0.7)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(brand.palette.surface)
                .shadow(color: .black.opacity(0.10), radius: 8, x: 0, y: 4)
        }
    }

    private func glyph(_ id: String) -> Glyph {
        switch id {
        case "line": return .rope
        case "pencil": return .feather
        case "burnisher": return .hook
        case "aquatint": return .jar
        case "chine": return .leaf
        default: return .chest
        }
    }

    private var proToggles: some View {
        VStack(spacing: 0) {
            Toggle("Muted ink", isOn: Binding(get: { bench.record.calmInk }, set: bench.setCalm))
                .padding(.vertical, 6)
            Rectangle().fill(brand.palette.ink.opacity(0.12)).frame(height: 0.5)
            Toggle("Let the plate cross out for you", isOn: Binding(get: { bench.record.assist }, set: bench.setAssist))
                .padding(.vertical, 6)
        }
        .brandFont(.body, weight: .regular)
        .foregroundStyle(brand.palette.ink)
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(brand.palette.surface)
                .shadow(color: .black.opacity(0.10), radius: 8, x: 0, y: 4)
        }
    }
}

/// A copper plate standing on edge in the rack, its number engraved on the bevel. A pulled
/// plate has its print pegged behind it; the next one has the burin lying across it; an
/// untouched one is bare copper; one past the fortieth is crosshatched over.
struct StandingPlate: View {
    enum State { case pulled, next, bare, locked }

    let number: Int
    var side: CGFloat
    var state: State
    @Environment(\.brand) private var brand

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            if state == .pulled {
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(brand.palette.surface)
                    .frame(width: side * 0.86, height: side * 0.92)
                    .offset(x: -side * 0.1, y: -side * 0.12)
                    .shadow(color: .black.opacity(0.10), radius: 5, x: 1, y: 3)
            }
            ZStack {
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(AppBrand.Plate.bevel)
                    .offset(x: 3.5, y: 3.5)
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(LinearGradient(colors: [AppBrand.Plate.faceTop, AppBrand.Plate.faceBottom],
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
                if state == .locked {
                    CutShading(progress: 1, spacing: 4.2, weight: 1.1)
                        .clipShape(RoundedRectangle(cornerRadius: 3, style: .continuous))
                }
                if state == .next {
                    Text("\(number)")
                        .brandDisplay(size: side * 0.4)
                        .foregroundStyle(AppBrand.Plate.trough.opacity(0.82))
                        .shadow(color: AppBrand.Plate.lip.opacity(0.5), radius: 0, x: -0.7, y: -0.8)
                    Image("Burin")
                        .resizable()
                        .scaledToFit()
                        .frame(width: side * 0.92)
                        .rotationEffect(.degrees(-8))
                        .offset(y: side * 0.24)
                }
                if state == .pulled {
                    CutShading(progress: 1, spacing: 5.4, weight: 0.7, tone: 0.5)
                        .clipShape(RoundedRectangle(cornerRadius: 3, style: .continuous))
                }
            }
            .frame(width: side, height: side * 0.78)
        }
        .frame(width: side + 6, height: side * 0.94)
        .accessibilityLabel("Plate \(number)")
    }
}
