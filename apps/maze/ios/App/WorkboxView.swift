import FactoryKit
import SwiftUI

/// Screen 4 · Settings: the kit's, with the pillow's own rows.
struct WorkboxView: View {
    @Binding var showPaywall: Bool
    @EnvironmentObject private var store: Store
    @EnvironmentObject private var bench: Bench

    var body: some View {
        NavigationStack {
            SettingsView(store: store,
                         config: AppInfo.config,
                         onUpgrade: { showPaywall = true },
                         upgradeTitle: "Open the pattern book",
                         activeTitle: "The pattern book is open") {
                WorkboxRows()
            }
            .serifTitle("The workbox")
            .background { Linen(ticking: bench.record.ticking) }
        }
    }
}

private struct WorkboxRows: View {
    @EnvironmentObject private var bench: Bench
    @EnvironmentObject private var store: Store
    @Environment(\.brand) private var brand
    @State private var confirmEmpty = false
    @State private var reminderOn = false
    @State private var hour = Calendar.current.date(bySettingHour: 20, minute: 0, second: 0, of: .now) ?? .now
    @State private var initials = ""

    private var record: Record { bench.record }

    var body: some View {
        Group {
            Section("On the pillow") {
                row("Pieces worked", "\(record.pieces.count)")
                row("Longest thread", "\(record.bestThread)")
                row("Days running", "\(record.daysRunning())")
            }
            Section {
                SoundsToggle()
                Toggle("Pin a reminder", isOn: $reminderOn)
                    .onChange(of: reminderOn) { _, on in setReminder(on) }
                if reminderOn {
                    DatePicker("At", selection: $hour, displayedComponents: .hourAndMinute)
                        .onChange(of: hour) { _, _ in setReminder(true) }
                }
                if record.hasEarned("silk") {
                    Picker("Thread", selection: Binding(get: { record.threadInHand }, set: bench.setThread)) {
                        ForEach(threads, id: \.self) { t in Text(t.name).tag(t) }
                    }
                }
                if record.hasEarned("ticking") {
                    Picker("Cover", selection: Binding(get: { record.cover }, set: bench.setCover)) {
                        Text("Linen").tag(Cover.linen)
                        Text("Indigo ticking").tag(Cover.ticking)
                    }
                }
                if record.hasEarned("initials") {
                    TextField("Initials", text: $initials)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .onChange(of: initials) { _, s in bench.setInitials(s) }
                }
            } footer: {
                Text(store.isPro || LaunchOptions.forcePro
                     ? "Everything you have worked is on this phone and nowhere else."
                     : "Today's pattern and the first sixty in the book. Every piece you have worked stays in the sampler.")
            }
            Section {
                Button("Empty the workbox", role: .destructive) { confirmEmpty = true }
            }
            .alert("Empty the workbox — every piece and every pin on this phone?", isPresented: $confirmEmpty) {
                Button("Empty it", role: .destructive) { bench.emptyWorkbox() }
                Button("Keep it", role: .cancel) {}
            }
        }
        .onAppear {
            reminderOn = record.reminderHour != nil
            if let h = record.reminderHour {
                hour = Calendar.current.date(bySettingHour: h, minute: 0, second: 0, of: .now) ?? hour
            }
            initials = record.initials
        }
    }

    private var threads: [ThreadColour] {
        [.indigo, .rose] + (record.hasEarned("gold") ? [.gold] : [])
    }

    private func row(_ name: String, _ value: String) -> some View {
        HStack {
            Text(name).foregroundStyle(brand.palette.ink)
            Spacer()
            Text(value)
                .font(.body.monospacedDigit())
                .fontDesign(.serif)
                .foregroundStyle(brand.palette.highlight)
        }
        .accessibilityElement(children: .combine)
    }

    private func setReminder(_ on: Bool) {
        if on {
            let h = Calendar.current.component(.hour, from: hour)
            Task {
                let ok = await Reminder.pin(hour: h)
                bench.setReminder(ok ? h : nil)
                if !ok { reminderOn = false }
            }
        } else {
            Reminder.cancel()
            bench.setReminder(nil)
        }
    }
}
