import FactoryKit
import SwiftUI

/// One liquid colour: what it is called, the shape stamped on it when markers are on, and the
/// light it throws.
///
/// Held as hex in light and dark rather than as three Doubles, because this is light inside
/// glass, not paint on paper — every unit is drawn as a top-lit gradient with a specular
/// stripe and a meniscus, and each of those wants its own value of the same colour.
struct LiquidColor: Sendable {
    let name: String
    let symbol: String
    let light: UInt32
    let dark: UInt32

    var color: Color { Color(light: light, dark: dark) }

    /// The surface of the liquid, where the light comes in.
    var top: Color { Color(light: Mix.tint(light, 0.20), dark: Mix.tint(dark, 0.16)) }
    /// The bottom of the glass, where it is thickest.
    var bottom: Color { Color(light: Mix.shade(light, 0.34), dark: Mix.shade(dark, 0.32)) }
    /// The ring it throws on the wet flat underneath the vial.
    var glow: Color { Color(light: Mix.tint(light, 0.12), dark: Mix.tint(dark, 0.10)) }

    /// White on a dark liquid, near-black on a pale one. A white shape on the color-blind
    /// palette's yellow is invisible, which defeats the point of stamping shapes at all.
    var markerColor: Color {
        let r = Double((light >> 16) & 0xFF) / 255
        let g = Double((light >> 8) & 0xFF) / 255
        let b = Double(light & 0xFF) / 255
        return 0.2126 * r + 0.7152 * g + 0.0722 * b > 0.62
            ? Color.black.opacity(0.62)
            : Color.white.opacity(0.92)
    }

    /// Calm mode pulls every colour a third of the way to a cold sea grey. The board stays
    /// readable, the shore stops shouting.
    var muted: LiquidColor {
        LiquidColor(name: name,
                    symbol: symbol,
                    light: Mix.blend(light, 0x7E9AA0, 0.36),
                    dark: Mix.blend(dark, 0x5B747C, 0.36))
    }
}

/// Hex arithmetic, so a liquid can be lit, deepened or calmed without a second table of values.
enum Mix {
    static func blend(_ a: UInt32, _ b: UInt32, _ t: Double) -> UInt32 {
        var out: UInt32 = 0
        for shift in [UInt32(16), 8, 0] {
            let ca = Double((a >> shift) & 0xFF)
            let cb = Double((b >> shift) & 0xFF)
            let c = UInt32(max(0, min(255, (ca + (cb - ca) * t).rounded())))
            out |= c << shift
        }
        return out
    }

    static func tint(_ hex: UInt32, _ t: Double) -> UInt32 { blend(hex, 0xFFFFFF, t) }
    static func shade(_ hex: UInt32, _ t: Double) -> UInt32 { blend(hex, 0x000000, t) }
}

/// The two palettes. Index 0 is used by every level, so the most distinguishable colours come
/// first and the ladder adds the harder-to-separate ones later.
enum Palette {
    /// The shore's eight lights, from DESIGN.md. Six of them are on the board at most; the
    /// last two are headroom for the deepest levels.
    static let standard: [LiquidColor] = [
        LiquidColor(name: "ember", symbol: "circle.fill", light: 0xFF8A57, dark: 0xF07C4C),
        LiquidColor(name: "tide", symbol: "square.fill", light: 0x5CB2F0, dark: 0x4C9EDC),
        LiquidColor(name: "lantern", symbol: "triangle.fill", light: 0xFFD265, dark: 0xEFC055),
        LiquidColor(name: "kelp", symbol: "diamond.fill", light: 0x5FD8A9, dark: 0x4FC79A),
        LiquidColor(name: "dusk", symbol: "hexagon.fill", light: 0xB69AF5, dark: 0xA286E6),
        LiquidColor(name: "coral", symbol: "star.fill", light: 0xFF93AC, dark: 0xEC819B),
        LiquidColor(name: "pearl", symbol: "seal.fill", light: 0xEADCC0, dark: 0xD6C7A9),
        LiquidColor(name: "abyss", symbol: "shield.fill", light: 0x6E82E4, dark: 0x6070D4),
    ]

    /// Okabe–Ito, the palette that stays separable for every common kind of colour blindness.
    /// Water Sort shipped a brighter update and its reviewers answered "it's hard to see
    /// colors"; this is the answer to that, with the shape markers as the belt and braces.
    /// Kept exactly as drawn — it is the one thing on this board a competitor does not have.
    static let accessible: [LiquidColor] = [
        LiquidColor(name: "orange", symbol: "circle.fill", light: 0xE69F00, dark: 0xE69F00),
        LiquidColor(name: "sky", symbol: "square.fill", light: 0x56B4E9, dark: 0x56B4E9),
        LiquidColor(name: "green", symbol: "triangle.fill", light: 0x009E73, dark: 0x009E73),
        LiquidColor(name: "yellow", symbol: "diamond.fill", light: 0xF0E442, dark: 0xF0E442),
        LiquidColor(name: "blue", symbol: "hexagon.fill", light: 0x0072B2, dark: 0x3C8DC4),
        LiquidColor(name: "vermilion", symbol: "star.fill", light: 0xD55E00, dark: 0xD55E00),
        LiquidColor(name: "mauve", symbol: "seal.fill", light: 0xCC79A7, dark: 0xCC79A7),
        LiquidColor(name: "slate", symbol: "shield.fill", light: 0x8C8C93, dark: 0x8C8C93),
    ]

    static func set(accessible useAccessible: Bool) -> [LiquidColor] {
        useAccessible ? accessible : standard
    }
}

/// How the board should be drawn right now: which palette, whether calm mode is on, and
/// whether each unit carries its shape. Passed down the view tree so one place decides.
struct BoardStyle: Equatable {
    var accessiblePalette = false
    var calm = false
    var markers = false

    private var set: [LiquidColor] { Palette.set(accessible: accessiblePalette) }

    func liquid(_ index: Int) -> LiquidColor {
        let c = set[index % set.count]
        return calm ? c.muted : c
    }

    func color(_ index: Int) -> Color { liquid(index).color }

    func name(_ index: Int) -> String { set[index % set.count].name }

    func symbol(_ index: Int) -> String? {
        markers ? set[index % set.count].symbol : nil
    }

    func markerColor(_ index: Int) -> Color { liquid(index).markerColor }

    /// Calm mode slows the pour and drops the move counter; both are settings, not levels.
    var pourDuration: Double { calm ? 0.45 : 0.24 }

    /// How long the vial takes to leave the rack and to swing back into it.
    var liftDuration: Double { calm ? 0.3 : 0.18 }
    /// How long the receiving level takes to overshoot and settle.
    var landDuration: Double { calm ? 0.34 : 0.22 }

    static func == (a: BoardStyle, b: BoardStyle) -> Bool {
        a.accessiblePalette == b.accessiblePalette && a.calm == b.calm && a.markers == b.markers
    }
}
