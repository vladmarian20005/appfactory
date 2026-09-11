import FactoryKit
import SwiftData
import SwiftUI

struct RootView: View {
    @EnvironmentObject private var store: Store
    @State private var showPaywall = false
    @State private var tab: Tab = .today

    enum Tab: String { case today, scorecard, practice, settings }

    var body: some View {
        Group {
            if LaunchOptions.screen == "share" {
                ShareCardPreview(flags: (0..<10).map { $0 != 3 },
                                 roundNumber: DailyPack.roundNumber(for: .now),
                                 streak: 12)
            } else {
                tabs
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView(store: store,
                        config: AppInfo.config,
                        headline: AppInfo.paywallHeadline,
                        bullets: AppInfo.paywallBullets,
                        promise: AppInfo.paywallPromise,
                        hero: {
                            Image("Desk")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 280)
                                .accessibilityLabel("A cup, a folded sheet and a pencil on a desk")
                        }) {
                showPaywall = false
            }
        }
        .onAppear(perform: applyLaunchOptions)
    }

    private var tabs: some View {
        TabView(selection: $tab) {
            NavigationStack {
                TodayView()
            }
            .tabItem { Label("Today", systemImage: "newspaper.fill") }
            .tag(Tab.today)

            NavigationStack {
                ScorecardView()
            }
            .tabItem { Label("Scorecard", systemImage: "calendar") }
            .tag(Tab.scorecard)

            NavigationStack {
                PracticeView(showPaywall: $showPaywall)
            }
            .tabItem { Label("Practice", systemImage: "tray.full.fill") }
            .tag(Tab.practice)

            NavigationStack {
                SettingsView(store: store, config: AppInfo.config, onUpgrade: { showPaywall = true }) {
                    QuizdaySettings()
                }
                // The Form's grey would cover the paper otherwise.
                .paper()
            }
            .tabItem { Label("Settings", systemImage: "gearshape.fill") }
            .tag(Tab.settings)
        }
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
            SoundsToggle()
            LabeledContent("Editions filed", value: "\(results.count)")
            LabeledContent("Questions in the pack", value: "\(DailyPack.shared.rounds.count * 10)")
            if !reports.isEmpty {
                NavigationLink {
                    ReportsView()
                } label: {
                    LabeledContent("Passed to the desk", value: "\(reports.count)")
                }
            }
        } header: {
            Text("The desk")
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

/// Screen 11. The questions a player flagged, set as a correction column: each one a ruled
/// block with its code and date in mono beneath, and the desk at the foot of the page.
struct ReportsView: View {
    @Environment(\.brand) private var brand
    @Environment(\.modelContext) private var context
    @Query(sort: \QuestionReport.reportedAt, order: .reverse) private var reports: [QuestionReport]

    var body: some View {
        List {
            Section {
                ForEach(reports) { report in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(report.questionText)
                            .scaledFont(size: 16, design: .serif, relativeTo: .body)
                            .foregroundStyle(brand.palette.ink)
                            .fixedSize(horizontal: false, vertical: true)
                        Text("\(report.questionID) · \(report.reportedAt.formatted(date: .abbreviated, time: .shortened))")
                            .dateline(9, tracking: 1.2)
                    }
                    .padding(.vertical, 4)
                    .listRowBackground(Color.clear)
                }
                .onDelete { offsets in
                    for index in offsets { context.delete(reports[index]) }
                    try? context.save()
                }
            } header: {
                Text("Corrections").dateline(10, tracking: 2)
            } footer: {
                Text("These stay on your device. Send the code to the desk and it is set right in the next pack.")
                    .scaledFont(size: 13, design: .serif, relativeTo: .caption)
            }

            Section {
                Link(destination: AppInfo.config.supportURL) {
                    Label("Write to the desk", systemImage: "questionmark.circle")
                }
                .listRowBackground(Color.clear)
            }
        }
        .paper()
        .navigationTitle("Corrections")
        .navigationBarTitleDisplayMode(.inline)
    }
}
