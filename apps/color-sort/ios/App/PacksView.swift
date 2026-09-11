import FactoryKit
import SwiftData
import SwiftUI

/// The level ladder and the three things the one-time unlock buys.
struct PacksView: View {
    @EnvironmentObject private var store: Store
    @Query private var results: [LevelResult]

    @Binding var showPaywall: Bool
    let onOpenLevel: (Int) -> Void

    @AppStorage("tidepour.calmMode") private var calmMode = false
    @AppStorage("tidepour.accessiblePalette") private var accessiblePalette = false
    @AppStorage("tidepour.shapeMarkers") private var shapeMarkers = false
    @AppStorage("tidepour.currentLevel") private var currentLevel = 1

    /// How far the ladder is drawn. Levels are generated on the way in, so this is only how
    /// many squares to show, never how many boards exist.
    private var visibleLevels: Int {
        store.isUnlocked ? max(240, currentLevel + 60) : AppInfo.freeLevelCount
    }

    private var cleared: Set<Int> { Set(results.compactMap(\.number)) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if !store.isUnlocked { unlockCard }
                ladder
                options
            }
            .padding(FactoryTheme.padding)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Packs")
    }

    private var unlockCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Unlock Tidepour")
                .font(.headline)
            Text("The first \(AppInfo.freeLevelCount) levels and the daily puzzle are free forever. "
                 + "One payment opens the rest of the ladder, calm mode and the color-blind palettes. "
                 + "There is no subscription, no currency and no advertising in this app.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Button("See what it unlocks") { showPaywall = true }
                .buttonStyle(.factoryPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .factoryCard()
    }

    private var ladder: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Levels")
                    .font(.headline)
                Spacer()
                Text("\(cleared.count) cleared")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            Text("Every board on this ladder is dealt at random and then solved. The ones the solver cannot finish are thrown away, so none of them reaches you.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 5), spacing: 8) {
                ForEach(1...visibleLevels, id: \.self) { level in
                    Button { onOpenLevel(level) } label: {
                        LevelChip(level: level,
                                  isCleared: cleared.contains(level),
                                  isCurrent: level == currentLevel)
                    }
                    .buttonStyle(.plain)
                }
            }
            if !store.isUnlocked {
                Button {
                    showPaywall = true
                } label: {
                    Label("Levels past \(AppInfo.freeLevelCount) are in the unlock", systemImage: "lock.fill")
                        .font(.footnote)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .factoryCard()
    }

    private var options: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Playing style")
                .font(.headline)
            GatedToggle(title: "Calm mode",
                        detail: "No move counter, muted colors, a slower pour.",
                        symbol: "leaf.fill",
                        isOn: $calmMode,
                        unlocked: store.isUnlocked) { showPaywall = true }
            GatedToggle(title: "Color-blind palette",
                        detail: "Okabe–Ito colors, chosen to stay apart for every common kind of color blindness.",
                        symbol: "eye.fill",
                        isOn: $accessiblePalette,
                        unlocked: store.isUnlocked) { showPaywall = true }
            GatedToggle(title: "Shape markers",
                        detail: "A different shape stamped on every color, so the board reads without color at all.",
                        symbol: "square.on.circle",
                        isOn: $shapeMarkers,
                        unlocked: store.isUnlocked) { showPaywall = true }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .factoryCard()
    }
}

/// One square on the ladder.
struct LevelChip: View {
    let level: Int
    let isCleared: Bool
    let isCurrent: Bool

    private var background: Color {
        isCleared ? .accentColor : Color(.tertiarySystemGroupedBackground)
    }

    var body: some View {
        Text("\(level)")
            .font(.subheadline)
            .monospacedDigit()
            .foregroundStyle(isCleared ? Color.white : Color.primary)
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(background, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay {
                if isCurrent {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(Color.accentColor, lineWidth: 2)
                }
            }
            .accessibilityLabel("Level \(level)\(isCleared ? ", cleared" : "")")
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

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if unlocked {
                Toggle(isOn: $isOn) {
                    Label(title, systemImage: symbol)
                }
            } else {
                Button(action: onLocked) {
                    HStack {
                        Label(title, systemImage: symbol)
                        Spacer()
                        Image(systemName: "lock.fill")
                            .foregroundStyle(.secondary)
                    }
                }
                .buttonStyle(.plain)
            }
            Text(detail)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
