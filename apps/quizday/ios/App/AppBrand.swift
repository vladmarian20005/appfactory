import FactoryKit
import SwiftUI

enum AppBrand {
    static let brand = Brand(
        palette: BrandPalette(
            canvas:    Color(light: 0xF5EFE2, dark: 0x151821),
            surface:   Color(light: 0xFBF7EC, dark: 0x1E2230),
            ink:       Color(light: 0x1B2027, dark: 0xF2EDE1),
            inkSoft:   Color(light: 0x5E6470, dark: 0x9AA1B2),
            accent:    Color(light: 0xC1362C, dark: 0xE2695C),
            onAccent:  Color(light: 0xFFF8EC, dark: 0x1A1210),
            highlight: Color(light: 0x8E6214, dark: 0xE3AE4E),
            success:   Color(light: 0x2F6B4F, dark: 0x6FBF95),
            miss:      Color(light: 0x6F6A60, dark: 0x9C968A),
            extras: [
                Color(light: 0x2D4F7C, dark: 0x8FB4E6),   // ink blue
                Color(light: 0x6B3A63, dark: 0xC99BC0),   // plum
                Color(light: 0x1F6B70, dark: 0x6FC9CE),   // teal
                Color(light: 0xA8552A, dark: 0xE39A6E),   // rust
                Color(light: 0x4A6327, dark: 0xA8C877),   // olive
                Color(light: 0x44505E, dark: 0xA6B4C4),   // slate
            ]
        ),
        type: BrandType(display: .serif,
                        displayWidth: .standard,
                        displayWeight: .bold,
                        body: .serif),
        corner: 6,
        canvas: .glow(Color(light: 0xFFFDF6, dark: 0x232838),
                      at: UnitPoint(x: 0.5, y: 0.10))
    )

    /// The section inks, by the pack's category names. Six inks, thirteen sections.
    static func ink(for category: String) -> Color {
        let extras = brand.palette.extras
        switch category {
        case "Geography", "Space":                        return extras[0]
        case "Art & Literature", "Music":                 return extras[1]
        case "Science", "Technology":                     return extras[2]
        case "History", "Food & Drink":                   return extras[3]
        case "Nature", "Sport":                           return extras[4]
        default:                                          return extras[5]
        }
    }

    /// The dateline / section-mark / legend face: SF Mono, uppercase, tracked.
    ///
    /// Frozen on purpose, and only for `ShareImage`: the share card is rendered at a fixed
    /// 1080 × 1350 outside the view hierarchy, where Dynamic Type has nothing to scale
    /// against. On screen the same face comes from `.dateline(_:)`, which scales.
    static func dateline(_ size: CGFloat = 11) -> Font {
        .system(size: size, weight: .medium, design: .monospaced)
    }
}
