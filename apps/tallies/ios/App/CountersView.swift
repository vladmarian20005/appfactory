import FactoryKit
import SwiftData
import SwiftUI

/// Screen 1: the counters, each a card you can tap to add to without leaving the list.
struct CountersView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var store: Store
    @Binding var showPaywall: Bool

    @Query(sort: \Counter.createdAt, order: .forward) private var counters: [Counter]
    @State private var path: [Counter] = []
    @State private var showAdd = false

    var body: some View {
        NavigationStack(path: $path) {
            Group {
                if counters.isEmpty {
                    ContentUnavailableView {
                        Label("Nothing counted yet", systemImage: "list.bullet")
                    } description: {
                        Text("Make a counter for anything you want to keep a number on.")
                    } actions: {
                        Button("Create the first one") { showAdd = true }
                            .buttonStyle(.borderedProminent)
                    }
                } else {
                    List {
                        ForEach(counters) { counter in
                            CounterRow(counter: counter, onIncrement: { increment(counter) })
                                .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                        }
                        .onDelete(perform: delete)

                        if !store.isProUnlocked {
                            freeTierFooter
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                        }
                    }
                    .listStyle(.plain)
                    // The cards are `secondarySystemGroupedBackground`; on a plain list's
                    // default background they are white on white and stop reading as cards.
                    .scrollContentBackground(.hidden)
                    .background(Color(.systemGroupedBackground))
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Tallies")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { addTapped() } label: { Image(systemName: "plus") }
                        .accessibilityLabel("Add a counter")
                }
            }
            .navigationDestination(for: Counter.self) { CounterDetailView(counter: $0, showPaywall: $showPaywall) }
            .sheet(isPresented: $showAdd) {
                AddCounterView { name, colorID, goal in
                    let counter = Counter(name: name, colorID: colorID, dailyGoal: goal)
                    context.insert(counter)
                    try? context.save()
                }
            }
            .onAppear(perform: applyLaunchOptions)
        }
    }

    private var freeTierFooter: some View {
        Button { showPaywall = true } label: {
            HStack(spacing: 12) {
                Image(systemName: "lock.fill").foregroundStyle(.secondary)
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(counters.count) of \(AppInfo.freeCounterLimit) free counters")
                        .font(.subheadline.weight(.medium))
                    Text("Pro removes the limit and unlocks History.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right").font(.footnote).foregroundStyle(.tertiary)
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }

    private func addTapped() {
        if store.isProUnlocked || counters.count < AppInfo.freeCounterLimit {
            showAdd = true
        } else {
            showPaywall = true
        }
    }

    private func increment(_ counter: Counter) {
        Haptics.tap()
        context.insert(Tap(delta: 1, counter: counter))
        try? context.save()
    }

    private func delete(_ offsets: IndexSet) {
        for index in offsets { context.delete(counters[index]) }
        try? context.save()
    }

    private func applyLaunchOptions() {
        guard let screen = LaunchOptions.screen else { return }
        switch screen {
        case "detail":
            if let first = counters.first, path.isEmpty { path = [first] }
        case "add":
            showAdd = true
        default:
            break
        }
    }
}

/// One card: the name, the running total, and a `+` big enough to hit without looking.
///
/// The link and the `+` are siblings, not one nested in the other. A `Button` inside a
/// `NavigationLink` label is ambiguous about which one a tap belongs to, and the whole point
/// of this screen is that adding one does not navigate anywhere.
struct CounterRow: View {
    let counter: Counter
    let onIncrement: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            NavigationLink(value: counter) {
                HStack(spacing: 14) {
                    Capsule()
                        .fill(counter.swatch.color)
                        .frame(width: 6, height: 40)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(counter.name)
                            .font(.headline)
                            .lineLimit(2)
                        Text(counter.dailyGoal > 0
                             ? "\(counter.todayTotal) of \(counter.dailyGoal) today"
                             : "\(counter.todayTotal) today")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    Spacer(minLength: 8)

                    Text("\(counter.total)")
                        .scaledFont(size: 32, weight: .semibold, design: .rounded, relativeTo: .title)
                        .monospacedDigit()
                        .contentTransition(.numericText())
                        .foregroundStyle(.primary)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityHint("Opens the counter")

            Button(action: onIncrement) {
                Image(systemName: "plus")
                    .font(.title3.weight(.semibold))
                    .frame(width: 44, height: 44)
                    .background(counter.swatch.color.opacity(0.16), in: Circle())
                    .foregroundStyle(counter.swatch.color)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Add one to \(counter.name)")
        }
        .padding(16)
        .frame(minHeight: 76)
        .background(Color(.secondarySystemGroupedBackground),
                    in: RoundedRectangle(cornerRadius: FactoryTheme.cornerRadius, style: .continuous))
    }
}
