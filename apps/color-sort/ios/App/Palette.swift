import SwiftUI

/// One liquid color: what it looks like, what it is called, and the shape stamped on it when
/// markers are on.
struct LiquidColor: Sendable {
    let name: String
    let symbol: String
    let red: Double
    let green: Double
    let blue: Double

    var color: Color { Color(.sRGB, red: red, green: green, blue: blue, opacity: 1) }

    /// Calm mode pulls every color a third of the way to a soft grey. The board stays
    /// readable, the screen stops shouting.
    var muted: Color {
        let t = 0.34
        return Color(.sRGB,
                     red: red + (0.62 - red) * t,
                     green: green + (0.62 - green) * t,
                     blue: blue + (0.64 - blue) * t,
                     opacity: 1)
    }
}

/// The two palettes. Index 0 is used by every level, so the most distinguishable colors come
/// first and the ladder adds the harder-to-separate ones later.
enum Palette {
    /// Eight, though the ladder tops out at seven — the eighth is headroom, not a level.
    static let standard: [LiquidColor] = [
        LiquidColor(name: "amber", symbol: "circle.fill", red: 0.961, green: 0.647, blue: 0.141),
        LiquidColor(name: "blue", symbol: "square.fill", red: 0.243, green: 0.561, blue: 0.941),
        LiquidColor(name: "red", symbol: "triangle.fill", red: 0.898, green: 0.282, blue: 0.302),
        LiquidColor(name: "teal", symbol: "diamond.fill", red: 0.071, green: 0.647, blue: 0.580),
        LiquidColor(name: "purple", symbol: "hexagon.fill", red: 0.557, green: 0.306, blue: 0.776),
        LiquidColor(name: "pink", symbol: "star.fill", red: 0.914, green: 0.239, blue: 0.510),
        LiquidColor(name: "green", symbol: "seal.fill", red: 0.275, green: 0.655, blue: 0.345),
        LiquidColor(name: "brown", symbol: "shield.fill", red: 0.659, green: 0.486, blue: 0.373),
    ]

    /// Okabe–Ito, the palette that stays separable for every common kind of color blindness.
    /// Water Sort shipped a brighter update and its reviewers answered "it's hard to see
    /// colors"; this is the answer to that, with the shape markers as the belt and braces.
    static let accessible: [LiquidColor] = [
        LiquidColor(name: "orange", symbol: "circle.fill", red: 0.902, green: 0.624, blue: 0.000),
        LiquidColor(name: "sky", symbol: "square.fill", red: 0.337, green: 0.706, blue: 0.914),
        LiquidColor(name: "green", symbol: "triangle.fill", red: 0.000, green: 0.620, blue: 0.451),
        LiquidColor(name: "yellow", symbol: "diamond.fill", red: 0.941, green: 0.894, blue: 0.259),
        LiquidColor(name: "blue", symbol: "hexagon.fill", red: 0.000, green: 0.447, blue: 0.698),
        LiquidColor(name: "vermilion", symbol: "star.fill", red: 0.835, green: 0.369, blue: 0.000),
        LiquidColor(name: "mauve", symbol: "seal.fill", red: 0.800, green: 0.475, blue: 0.655),
        LiquidColor(name: "slate", symbol: "shield.fill", red: 0.549, green: 0.549, blue: 0.576),
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

    func color(_ index: Int) -> Color {
        let c = set[index % set.count]
        return calm ? c.muted : c.color
    }

    func name(_ index: Int) -> String {
        set[index % set.count].name
    }

    func symbol(_ index: Int) -> String? {
        markers ? set[index % set.count].symbol : nil
    }

    /// Calm mode slows the pour and drops the move counter; both are settings, not levels.
    var pourDuration: Double { calm ? 0.45 : 0.24 }

    static func == (a: BoardStyle, b: BoardStyle) -> Bool {
        a.accessiblePalette == b.accessiblePalette && a.calm == b.calm && a.markers == b.markers
    }
}
