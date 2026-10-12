import FactoryKit
import SwiftUI

/// The Drawer tab: the things in the desk, and the whole count. A walnut panel with a brass
/// handle, pulled open; shut, with the handle catching the lamp, until it is bought.
struct DrawerView: View {
    @EnvironmentObject private var desk: Desk
    @Environment(\.brand) private var brand

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                if desk.isPro { open } else { shut }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 16)
        }
        .baize()
        .navigationTitle("Drawer")
    }

    // MARK: - Shut

    private var shut: some View {
        VStack(spacing: 18) {
            Image("Drawer")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 340)
                .ambientFloat(distance: 3, period: 6)
                .accessibilityHidden(true)
            VStack(spacing: 14) {
                Handle()
                Caps("The drawer", color: brand.palette.ink, style: .footnote)
                Text("Backs, cloths, the left-handed table, every past day's deal to lay again, and the whole count. $4.99, once.")
                    .foregroundStyle(brand.palette.inkSoft)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                Button { desk.showPaywall = true } label: {
                    Text("Open the drawer").font(.headline).frame(maxWidth: .infinity).padding(.vertical, 4)
                }
                .brandProminent()
            }
            .padding(22)
            .background(panel)
        }
        .padding(.horizontal, 8)
    }

    // MARK: - Open

    private var open: some View {
        VStack(alignment: .leading, spacing: 22) {
            Handle().frame(maxWidth: .infinity)
            section("Backs") {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .bottom, spacing: 12) {
                        ForEach(Back.allCases, id: \.self) { b in backTile(b) }
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 2)
                }
            }
            section("Cloths") {
                HStack(spacing: 14) {
                    ForEach(Cloth.allCases, id: \.self) { c in clothTile(c) }
                }
            }
            Toggle("Left-handed table", isOn: Binding(get: { desk.record.leftHanded },
                                                      set: { v in desk.update { $0.leftHanded = v } }))
                .foregroundStyle(brand.palette.ink)
            section("Past deals") { pastDeals }
            section("The count") { CountTable(record: desk.record) }
        }
        .padding(20)
        .background(panel)
    }

    private var panel: some View {
        RoundedRectangle(cornerRadius: brand.corner, style: .continuous)
            .fill(brand.palette.surface)
            .overlay(RoundedRectangle(cornerRadius: brand.corner, style: .continuous).strokeBorder(.white.opacity(0.08)))
            .shadow(color: .black.opacity(0.3), radius: 14, y: 8)
    }

    private func section<C: View>(_ title: String, @ViewBuilder _ content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Caps(title)
            content()
        }
    }

    private func backTile(_ b: Back) -> some View {
        let chosen = desk.back == b
        let earnedOnly = b == .brassLattice && !desk.record.hasEarned("lattice") && !desk.isPro
        return Button {
            Haptics.selection()
            withMotion(Motion.snappy) { desk.update { $0.back = b } }
        } label: {
            VStack(spacing: 6) {
                CardFace(card: Card(code: 0), faceUp: false, width: 44)
                    .environment(\.cardStyle.back, b)
                    .offset(y: chosen ? -6 : 0)
                    .shadow(color: .black.opacity(chosen ? 0.35 : 0.15), radius: chosen ? 8 : 2, y: chosen ? 6 : 1)
                Caps(b == .brassLattice && !desk.record.hasEarned("lattice") ? "Earned at 25" : b.title,
                     color: chosen ? brand.palette.accent : brand.palette.inkSoft)
                    .lineLimit(1)
                    .fixedSize()
            }
        }
        .buttonStyle(.pressable)
        .disabled(earnedOnly)
        .accessibilityLabel("\(b.title) back")
        .accessibilityAddTraits(chosen ? .isSelected : [])
    }

    private func clothTile(_ c: Cloth) -> some View {
        let chosen = desk.cloth == c
        return Button {
            Haptics.selection()
            withMotion(Motion.gentle) { desk.update { $0.cloth = c } }
        } label: {
            VStack(spacing: 6) {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(c.canvas)
                    .overlay(Nap().clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous)))
                    .frame(width: 52, height: 52)
                    .overlay(RoundedRectangle(cornerRadius: 9, style: .continuous).inset(by: -3)
                        .strokeBorder(chosen ? brand.palette.accent : .clear, lineWidth: 2))
                Caps(c == .claret && !desk.record.hasEarned("claret") ? "Earned at 10" : c.rawValue,
                     color: chosen ? brand.palette.accent : brand.palette.inkSoft)
                    .fixedSize()
            }
        }
        .buttonStyle(.pressable)
        .accessibilityLabel("\(c.rawValue) cloth")
        .accessibilityAddTraits(chosen ? .isSelected : [])
    }

    /// One row per past day, newest first, with its buried card and "Lay it again".
    private var pastDeals: some View {
        let days = desk.record.entries.filter { $0.kind == .today && $0.day < desk.today }.suffix(30).reversed()
        return VStack(spacing: 0) {
            if days.isEmpty {
                Text("A day that comes out is kept here, to lay again.")
                    .font(.callout)
                    .foregroundStyle(brand.palette.inkSoft)
            }
            ForEach(Array(days), id: \.id) { e in
                HStack(spacing: 12) {
                    CardFace(card: e.buried, width: 30)
                    VStack(alignment: .leading, spacing: 3) {
                        Caps("\(Voice.shortDate(e.date)) · draw \(Words.draw(e.draw)) · grade \(e.grade)", color: brand.palette.ink)
                        Caps(e.isClean ? "Out clean · \(e.moves) moves" : "Out · \(e.moves) moves",
                             color: e.isClean ? brand.palette.success : brand.palette.inkSoft)
                    }
                    Spacer(minLength: 6)
                    Button("Lay it again") {
                        desk.lay(.again(day: e.day))
                        desk.tab = .table
                    }
                    .font(.subheadline.weight(.semibold))
                    .buttonStyle(.bordered)
                    .buttonBorderShape(.capsule)
                }
                .padding(.vertical, 10)
                Rectangle().fill(brand.palette.ink.opacity(0.12)).frame(height: 0.5)
            }
        }
    }
}

/// The brass handle on the drawer's front, catching the lamp.
struct Handle: View {
    var body: some View {
        ZStack {
            Capsule().fill(AppBrand.CardBox.brassDeep).frame(width: 96, height: 14)
            Capsule().fill(AppBrand.CardBox.lamp.opacity(0.85)).frame(width: 80, height: 4).offset(y: -3)
        }
        .shadow(color: .black.opacity(0.3), radius: 3, y: 2)
        .accessibilityHidden(true)
    }
}

/// The whole count: a ruled table on card stock — out, clean, under the mark — by draw, by
/// grade and by shape. The same entries `Mastery` reads.
struct CountTable: View {
    let record: Record
    private let ink = AppBrand.CardBox.ink

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header("By draw")
            ForEach([1, 3], id: \.self) { d in row("Draw \(Words.draw(d))", record.entries.filter { $0.draw == d }) }
            header("By grade")
            ForEach(1...9, id: \.self) { g in
                let es = record.entries.filter { $0.grade == g }
                if !es.isEmpty { row("Grade \(g)", es) }
            }
            header("By what it asked")
            ForEach(Shape.allCases, id: \.self) { s in
                row(s.title, record.entries.filter { $0.shape == s }, strength: record.mastery.strength(of: s))
            }
        }
        .padding(14)
        .background(AppBrand.CardBox.stock, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .environment(\.dynamicTypeSize, .large)
    }

    private func header(_ t: String) -> some View {
        HStack {
            Text(t).font(.caption2.weight(.semibold)).textCase(.uppercase).tracking(1.5).foregroundStyle(ink.opacity(0.7))
            Spacer()
            Group {
                Text("Out").frame(width: 40, alignment: .trailing)
                Text("Clean").frame(width: 44, alignment: .trailing)
                Text("Under").frame(width: 44, alignment: .trailing)
            }
            .font(.caption2.weight(.medium)).textCase(.uppercase).foregroundStyle(ink.opacity(0.5))
        }
        .padding(.top, 12)
        .padding(.bottom, 6)
    }

    private func row(_ name: String, _ es: [Entry], strength: Double? = nil) -> some View {
        VStack(spacing: 0) {
            HStack {
                Text(name).font(.subheadline).foregroundStyle(ink)
                if let strength {
                    Capsule().fill(ink.opacity(0.1)).frame(width: 40, height: 4)
                        .overlay(alignment: .leading) {
                            Capsule().fill(AppBrand.CardBox.green).frame(width: 40 * strength, height: 4)
                        }
                        .accessibilityLabel("Held at \(Int(strength * 100)) percent")
                }
                Spacer()
                Group {
                    Text("\(es.count)").frame(width: 40, alignment: .trailing)
                    Text("\(es.filter(\.isClean).count)").frame(width: 44, alignment: .trailing)
                    Text("\(es.filter(\.underMark).count)").frame(width: 44, alignment: .trailing)
                }
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(ink)
            }
            .padding(.vertical, 7)
            Rectangle().fill(ink.opacity(0.12)).frame(height: 0.5)
        }
    }
}
