import FactoryKit
import SwiftData
import SwiftUI

struct RootView: View {
    @EnvironmentObject private var store: Store
    @State private var showPaywall = false
    @State private var tab: Tab = .today

    enum Tab: String { case today, scorecard, practice, settings }

    var body: some View {
        TabView(selection: $tab) {
            NavigationStack {
                TodayView()
            }
            .tabItem { Label("Today", systemImage: "checklist") }
            .tag(Tab.today)

            NavigationStack {
                ScorecardView()
            }
            .tabItem { Label("Scorecard", systemImage: "calendar") }
            .tag(Tab.scorecard)

            NavigationStack {
                PracticeView(showPaywall: $showPaywall)
            }
            .tabItem { Label("Practice", systemImage: "infinity") }
            .tag(Tab.practice)

            NavigationStack {
                SettingsView(store: store, config: AppInfo.config, onUpgrade: { showPaywall = true }) {
                    QuizdaySettings()
                }
            }
            .tabItem { Label("Settings", systemImage: "gearshape.fill") }
            .tag(Tab.settings)
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView(store: store,
                        config: AppInfo.config,
                        headline: AppInfo.paywallHeadline,
                        bullets: AppInfo.paywallBullets,
                        promise: AppInfo.paywallPromise) {
                showPaywall = false
            }
        }
        .onAppear(perform: applyLaunchOptions)
    }

    private func applyLaunchOptions() {
        switch LaunchOptions.screen {
        case "today": tab = .today
        case "scorecard": tab = .scorecard
        case "practice": tab = .practice
        case "settings": tab = .settings
        case "paywall": showPaywall = true
        default: break
        }
        if LaunchOptions.fakeProducts {
            store.debugOffers = [
                PaywallOffer(id: AppInfo.config.productIDs[0], title: "Weekly",
                             priceText: "$2.99", periodText: "per week", trialText: "3-day free trial"),
                PaywallOffer(id: AppInfo.config.productIDs[1], title: "Yearly",
                             priceText: "$19.99", periodText: "per year", trialText: "3-day free trial"),
            ]
        }
    }
}

/// The Quizday rows that sit inside the kit's Settings screen.
struct QuizdaySettings: View {
    @Environment(\.modelContext) private var context
    @Query private var reports: [QuestionReport]
    @Query private var results: [DayResult]
    @State private var confirmingReset = false

    var body: some View {
        Section {
            LabeledContent("Days played", value: "\(results.count)")
            LabeledContent("Questions in the pack", value: "\(DailyPack.shared.rounds.count * 10)")
            if !reports.isEmpty {
                NavigationLink {
                    ReportsView()
                } label: {
                    LabeledContent("Questions you reported", value: "\(reports.count)")
                }
            }
        } header: {
            Text("Your play")
        } footer: {
            Text("Quizday has no ads and no in-app currency. Everything you play stays on this device.")
        }

        Section {
            Button(role: .destructive) { confirmingReset = true } label: {
                Label("Erase my history", systemImage: "trash")
            }
            .confirmationDialog("Erase every score, streak and report on this device?",
                                isPresented: $confirmingReset, titleVisibility: .visible) {
                Button("Erase everything", role: .destructive, action: erase)
                Button("Cancel", role: .cancel) {}
            }
        } footer: {
            Text(OpenTDB.attribution)
        }
    }

    private func erase() {
        for result in results { context.delete(result) }
        for report in reports { context.delete(report) }
        let stats = (try? context.fetch(FetchDescriptor<CategoryStat>())) ?? []
        for stat in stats { context.delete(stat) }
        try? context.save()
    }
}

/// The questions a player flagged, so they can pass them on from the support page.
struct ReportsView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \QuestionReport.reportedAt, order: .reverse) private var reports: [QuestionReport]

    var body: some View {
        List {
            Section {
                ForEach(reports) { report in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(report.questionText)
                            .font(.subheadline)
                            .fixedSize(horizontal: false, vertical: true)
                        Text("\(report.questionID) · \(report.reportedAt.formatted(date: .abbreviated, time: .shortened))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .onDelete { offsets in
                    for index in offsets { context.delete(reports[index]) }
                    try? context.save()
                }
            } footer: {
                Text("These stay on your device. Send the question code to support and it gets fixed in the next pack.")
            }

            Section {
                Link(destination: AppInfo.config.supportURL) {
                    Label("Open support", systemImage: "questionmark.circle")
                }
            }
        }
        .navigationTitle("Reported")
        .navigationBarTitleDisplayMode(.inline)
    }
}
