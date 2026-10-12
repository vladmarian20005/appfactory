import FactoryKit
import SwiftUI

/// The desk: a Prussian-blue baize by day, midnight under the lamp, cream card stock with
/// serif indexes, walnut round the edge and brass fittings. DESIGN.md's Tokens, verbatim.
enum AppBrand {
    static let brand = Brand(
        palette: BrandPalette(
            canvas: Color(light: 0x34547A, dark: 0x14243A),
            surface: Color(light: 0x5E4432, dark: 0x3A2A1F),
            ink: Color(light: 0xF4ECDC, dark: 0xEDE3CF),
            inkSoft: Color(light: 0xD2C8B2, dark: 0xA89F8B),
            accent: Color(light: 0xD9B35C, dark: 0xE2BD66),
            onAccent: Color(light: 0x241A10, dark: 0x1E150B),
            highlight: Color(light: 0xFBB9A9, dark: 0xF7A896),
            success: Color(light: 0xA6D6AD, dark: 0x95C9A0),
            miss: Color(light: 0xB7CADD, dark: 0x9DB1C7),
            extras: [
                Color(light: 0xF6EFE0, dark: 0xEFE7D6),   // card stock — every card's face, the page
                Color(hex: 0x1E2532),                     // card ink — indexes, spades, clubs, type on the page
                Color(hex: 0xB8372A),                     // pip red — hearts, diamonds
                Color(hex: 0x2F6B45),                     // pip green — clubs, four-colour suits
                Color(hex: 0x2B5C9B),                     // pip blue — diamonds, four-colour suits
                Color(light: 0xF3C37A, dark: 0xF0B964),   // lamp — the glow's centre, the seal
                Color(light: 0xA47E35, dark: 0x8F6D2C),   // brass deep — the shadow side of brass
            ]
        ),
        type: BrandType(display: .serif,
                        displayWidth: .standard,
                        displayWeight: .semibold,
                        body: .default),
        corner: 8,
        canvas: .glow(Color(light: 0x4B6E96, dark: 0x4A3F2E),
                      at: UnitPoint(x: 0.12, y: 0.02))
    )

    /// The card box by name, so no view indexes `extras` by number.
    enum CardBox {
        static let stock     = brand.palette.extras[0]
        static let ink       = brand.palette.extras[1]
        static let red       = brand.palette.extras[2]
        static let green     = brand.palette.extras[3]
        static let blue      = brand.palette.extras[4]
        static let lamp      = brand.palette.extras[5]
        static let brassDeep = brand.palette.extras[6]
    }

    /// The cloths. `brand` is blue; a chosen cloth swaps the canvas and the glow and nothing
    /// else. Each pair was checked against ink and inkSoft in both modes.
    enum Cloth: String, CaseIterable, Codable {
        case blue, claret, moss, slate

        var canvas: Color {
            switch self {
            case .blue:   return Color(light: 0x34547A, dark: 0x14243A)
            case .claret: return Color(light: 0x7A2E35, dark: 0x3C181D)
            case .moss:   return Color(light: 0x2F5A42, dark: 0x14291D)
            case .slate:  return Color(light: 0x4A5563, dark: 0x232A33)
            }
        }
        var glow: Color {
            switch self {
            case .blue:   return Color(light: 0x4B6E96, dark: 0x4A3F2E)
            case .claret: return Color(light: 0x95464D, dark: 0x5A3230)
            case .moss:   return Color(light: 0x45745A, dark: 0x3A4A30)
            case .slate:  return Color(light: 0x62707F, dark: 0x3E3E3E)
            }
        }
        var brand: Brand {
            var b = AppBrand.brand
            b.palette.canvas = canvas
            b.canvas = .glow(glow, at: UnitPoint(x: 0.12, y: 0.02))
            return b
        }
    }

    /// The lattice on the default back is the blue cloth's colour in both modes, so a back is
    /// a blue lattice under the lamp too.
    static let lattice = Color(hex: 0x34547A)
}

typealias Cloth = AppBrand.Cloth
