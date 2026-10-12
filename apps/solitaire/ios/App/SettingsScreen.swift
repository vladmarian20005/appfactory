import FactoryKit
import SwiftUI

/// The kit's Settings, under the brand, with what is on the desk and the desk's own switches.
struct SettingsScreen: View {
    @EnvironmentObject private var store: Store
    @EnvironmentObject private var desk: Desk
    @Environment(\.brand) private var brand
    @State private var confirmClear = false

    var body: some View {
        SettingsView(store: store, config: AppInfo.config, onUpgrade: { desk.showPaywall = true },
                     upgradeTitle: "Open the drawer", activeTitle: "The drawer is open") {
            Section("On the desk") {
                LabeledContent("Entries", value: "\(desk.record.entries.count)")
                LabeledContent("Days running", value: "\(desk.record.daysRunning())")
                LabeledContent("Clean", value: "\(desk.record.clean)")
            }
            .foregroundStyle(brand.palette.ink)

            Section {
                SoundsToggle()
                ReminderRow(plain: true)
                toggle("Show the clock", \.showClock)
                toggle("Four-colour suits", \.fourColour)
                toggle("Large pips", \.largePips)
                if desk.record.hasEarned("claret") || desk.isPro {
                    Picker("Cloth", selection: Binding(get: { desk.cloth }, set: { c in desk.update { $0.cloth = c } })) {
                        ForEach(Cloth.allCases.filter { $0 == .blue || ($0 == .claret && desk.record.hasEarned("claret")) || desk.isPro }, id: \.self) {
                            Text($0.rawValue.capitalized).tag($0)
                        }
                    }
                }
                if desk.record.hasEarned("lattice") || desk.isPro {
                    Picker("Back", selection: Binding(get: { desk.back }, set: { b in desk.update { $0.back = b } })) {
                        ForEach(Back.allCases.filter { $0 == .lattice || ($0 == .brassLattice && desk.record.hasEarned("lattice")) || desk.isPro }, id: \.self) {
                            Text($0.title).tag($0)
                        }
                    }
                }
            } footer: {
                Text(desk.isPro ? "Everything you have played is on this phone and nowhere else."
                                : "Today's deal and the whole ledger. Every entry you have written stays in the diary.")
            }
            .foregroundStyle(brand.palette.ink)

            Section {
                Button("Clear the desk", role: .destructive) { confirmClear = true }
            }
        }
        .alert("Clear the desk — every entry and every deal on this phone?", isPresented: $confirmClear) {
            Button("Clear it", role: .destructive) { desk.clearDesk() }
            Button("Keep it", role: .cancel) {}
        }
    }

    private func toggle(_ title: String, _ key: WritableKeyPath<Record, Bool>) -> some View {
        Toggle(title, isOn: Binding(get: { desk.record[keyPath: key] }, set: { v in desk.update { $0[keyPath: key] = v } }))
    }
}
