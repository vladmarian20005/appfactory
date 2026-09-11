import FactoryKit
import SwiftData
import SwiftUI

/// The shore: the whole ladder as a shelf of vials, and the three things the one-time unlock
/// opens.
struct PacksView: View {
    @EnvironmentObject private var store: Store
    @Query private var results: [LevelResult]

    @Environment(\.brand) private var brand

    @Binding var showPaywall: Bool
    let onOpenLevel: (Int) -> Void

    @AppStorage("tidepour.calmMode") private var calmMode = false
    @AppStorage("tidepour.accessiblePalette") private var accessiblePalette = false
    @AppStorage("tidepour.shapeMarkers") private var shapeMarkers = false
    @AppStorage("tidepour.currentLevel") private var currentLevel = 1

    /// How far the shelf is drawn. Racks are dealt on the way in, so this is only how many
    /// vials to show, never how many boards exist.
    private var visibleLevels: Int {
        store.isUnlocked ? max(240, currentLevel + 60) : AppInfo.freeLevelCount
    }

    private var cleared: Set<Int> { Set(results.compactMap(\.number)) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 26) {
                if !store.isUnlocked { unlockCard }
                options
                ladder
            }
            .padding(.horizontal, FactoryTheme.padding)
            .padding(.top, 8)
            // Clear of the tab bar: the last row was sitting half under it.
            .padding(.bottom, 96)
        }
        .brandBackground(drift: true)
        .navigationTitle("Shore")
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    private var unlockCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image("OpenWater")
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 130)
                .frame(maxWidth: .infinity)
                .ambientFloat(distance: 4, period: 5)
            Text("The tide goes further out")
                .brandFont(.title2)
                .foregroundStyle(brand.palette.ink)
            Text("The first \(AppInfo.freeLevelCount) racks and today's pool are yours for good. One payment opens the rest of the shelf, calm mode and the colour-blind palette.")
                .font(.footnote)
                .foregroundStyle(brand.palette.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
            Button("See what opens") { showPaywall = true }
                .brandProminent()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .brandSurface()
    }

    private var ladder: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                ChartMark(text: "The shelf", color: brand.palette.highlight)
                Spacer()
                ChartMark(text: "\(cleared.count) lit")
            }
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 5), spacing: 14) {
                ForEach(1...visibleLevels, id: \.self) { level in
                    Button { onOpenLevel(level) } label: {
                        LevelVial(level: level,
                                  isCleared: cleared.contains(level),
                                  isCurrent: level == currentLevel)
                    }
                    .buttonStyle(.pressable)
                }
            }
            if !store.isUnlocked {
                Button {
                    showPaywall = true
                } label: {
                    Label("The shelf runs on past \(AppInfo.freeLevelCount)", systemImage: "lock.fill")
                        .font(.footnote)
                }
                .tint(brand.palette.accent)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var options: some View {
        VStack(alignment: .leading, spacing: 16) {
            ChartMark(text: "How you pour", color: brand.palette.highlight)
            GatedToggle(title: "Calm mode",
                        detail: "No counter, muted light, a slower pour.",
                        symbol: "leaf.fill",
                        isOn: $calmMode,
                        unlocked: store.isUnlocked) { showPaywall = true }
            GatedToggle(title: "Colour-blind palette",
                        detail: "Okabe–Ito colours, chosen to stay apart for every common kind of colour blindness.",
                        symbol: "eye.fill",
                        isOn: $accessiblePalette,
                        unlocked: store.isUnlocked) { showPaywall = true }
            GatedToggle(title: "Shape markers",
                        detail: "A different shape stamped on every colour, so the rack reads without colour at all.",
                        symbol: "square.on.circle",
                        isOn: $shapeMarkers,
                        unlocked: store.isUnlocked) { showPaywall = true }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .brandSurface()
    }
}

/// One place on the shelf: a vial, full of light when the rack has been cleared and empty
/// glass when it has not — so the ladder reads as a shelf at a glance, not as a grid of
/// numbered squares.
struct LevelVial: View {
    let level: Int
    let isCleared: Bool
    let isCurrent: Bool

    @Environment(\.brand) private var brand

    /// The vial grows with the text size, but only so far, and a three-digit number shrinks
    /// to fit rather than clipping.
    @ScaledMetric(relativeTo: .subheadline) private var height: CGFloat = 54

    private var liquid: LiquidColor { Palette.standard[level % Palette.standard.count] }

    private var shape: UnevenRoundedRectangle {
        UnevenRoundedRectangle(topLeadingRadius: 6,
                               bottomLeadingRadius: 17,
                               bottomTrailingRadius: 17,
                               topTrailingRadius: 6,
                               style: .continuous)
    }

    var body: some View {
        Text("\(level)")
            .font(.subheadline)
            .monospacedDigit()
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .dynamicTypeSize(...DynamicTypeSize.accessibility1)
            .foregroundStyle(isCleared ? liquid.markerColor : brand.palette.inkSoft)
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .background {
                ZStack {
                    shape.fill(brand.palette.surface.opacity(0.75))
                    if isCleared {
                        shape.fill(LinearGradient(colors: [liquid.top, liquid.color, liquid.bottom],
                                                  startPoint: .top, endPoint: .bottom))
                            .shadow(color: liquid.glow.opacity(0.55), radius: 7)
                    }
                    // The light of the sky on a wet curve, on every vial, full or not.
                    Capsule()
                        .fill(.white.opacity(0.3))
                        .frame(width: 2.5, height: height * 0.4)
                        .offset(x: -height * 0.17, y: -height * 0.12)
                }
            }
            .clipShape(shape)
            .overlay {
                shape.strokeBorder(isCurrent ? brand.palette.accent : brand.palette.ink.opacity(0.14),
                                   lineWidth: isCurrent ? 2.4 : 1)
            }
            .accessibilityLabel("Rack \(level)\(isCleared ? ", lit" : "")")
    }
}

/// A toggle that only moves once the unlock is bought; tapping it locked opens the paywall
/// rather than doing nothing.
struct GatedToggle: View {
    let title: String
    let detail: String
    let symbol: String
    @Binding var isOn: Bool
    let unlocked: Bool
    let onLocked: () -> Void

    @Environment(\.brand) private var brand

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if unlocked {
                Toggle(isOn: $isOn) {
                    Label(title, systemImage: symbol)
                        .foregroundStyle(brand.palette.ink)
                }
            } else {
                Button(action: onLocked) {
                    HStack {
                        Label(title, systemImage: symbol)
                            .foregroundStyle(brand.palette.ink)
                        Spacer()
                        Image(systemName: "lock.fill")
                            .foregroundStyle(brand.palette.inkSoft)
                    }
                }
                .buttonStyle(.plain)
            }
            Text(detail)
                .font(.caption)
                .foregroundStyle(brand.palette.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
