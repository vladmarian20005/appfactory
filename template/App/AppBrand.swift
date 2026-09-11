import FactoryKit
import SwiftUI

/// The app's look: palette, type, shape and canvas, from DESIGN.md's Tokens section.
///
/// Until that section is pasted in, the app wears the kit's gray default, and
/// `tools/design/tells.mjs` fails it for exactly that.
enum AppBrand {
    static let brand = Brand.factoryDefault
}
