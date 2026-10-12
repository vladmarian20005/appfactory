import FactoryKit
import SwiftUI

/// The Diary tab: the days, and what each one asked for. Entries at 112 pt behind the top of
/// the page; the month on card stock; today's line; the reminder; the page to send.
struct DiaryView: View {
    @EnvironmentObject private var desk: Desk
    @Environment(\.brand) private var brand
    @Binding var showSettings: Bool
    @State private var month = 0            // 0 = this month, -1 = last …
    @State private var selected: Int?

    var body: some View {
        GeometryReader { geo in
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    if desk.record.entries.isEmpty {
                        empty
                    } else {
                        if desk.record.hasEarned("volume") { shelf.padding(.bottom, 14) }
                        hero
                        pages(width: geo.size.width - 32)
                            .padding(.top, -44)
                        selectedLine
                        todayBlock
                            .padding(.top, 20)
                    }
                    ReminderRow()
                        .padding(.top, 18)
                    if !desk.record.entries.isEmpty { send.padding(.top, 12) }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 28)
            }
        }
        .baize()
        .navigationTitle("Diary")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showSettings = true } label: { Image(systemName: "gearshape") }
                    .accessibilityLabel("Settings")
            }
        }
    }

    // MARK: - Hero

    private var hero: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(desk.record.entries.count)")
                .brandDisplay(size: 112)
                .foregroundStyle(brand.palette.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            Caps("Entries")
                .padding(.top, 22)
            Spacer()
        }
        .padding(.leading, 6)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(desk.record.entries.count) entries")
    }

    // MARK: - The pages

    private var months: [Int] {
        let cal = Calendar.current
        guard let first = desk.record.entries.first?.date else { return [0] }
        let span = cal.dateComponents([.month], from: cal.startOfMonth(first), to: cal.startOfMonth(.now)).month ?? 0
        return Array((-max(0, span))...0)
    }

    private func date(_ offset: Int) -> Date {
        Calendar.current.date(byAdding: .month, value: offset, to: .now) ?? .now
    }

    private func pages(width: CGFloat) -> some View {
        let rows: CGFloat = 6
        let slot = (width - 40 - 36) / 7
        let height = 40 + 46 + 10 + 20 + rows * (slot * 1.4 + 6) + 60 + 50
        return TabView(selection: $month) {
            ForEach(months, id: \.self) { m in
                MonthPage(month: date(m), record: desk.record, today: desk.today,
                          selected: selected, onSelect: { d in
                              Haptics.selection()
                              withMotion(Motion.snappy) { selected = selected == d ? nil : d }
                          }, pageWidth: width)
                    .shadow(color: .black.opacity(0.25), radius: 12, y: 6)
                    .padding(.bottom, 16)
                    .frame(maxHeight: .infinity, alignment: .top)
                    .tag(m)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .frame(height: height)
        .animation(Motion.resolved(Motion.gentle), value: month)
    }

    /// A tapped slot: the day's line, and in the drawer, "Lay it again".
    @ViewBuilder
    private var selectedLine: some View {
        if let d = selected {
            VStack(alignment: .leading, spacing: 10) {
                if let e = desk.record.entry(forDay: d) {
                    Caps(dayLine(e), color: e.isClean ? brand.palette.success : brand.palette.inkSoft)
                } else {
                    Caps("\(Voice.shortDate(Play.date(ofDay: d))) · nothing written")
                }
                if d < desk.today, d >= 0 || desk.record.entry(forDay: d)?.kind == .today {
                    Button {
                        if desk.isPro { desk.lay(.again(day: d)); desk.tab = .table } else { desk.showPaywall = true }
                    } label: {
                        Text("Lay it again").font(.headline)
                    }
                    .buttonStyle(.bordered)
                    .buttonBorderShape(.capsule)
                }
            }
            .padding(.top, 4)
            .transition(.opacity)
        }
    }

    private func dayLine(_ e: Entry) -> String {
        var parts = [Voice.shortDate(e.date)]
        parts.append(e.isClean ? "Out clean" : "Out")
        parts.append("\(e.moves) moves")
        if e.underMark && e.mark > e.moves { parts.append("Under the mark by \(e.mark - e.moves)") }
        parts.append(e.buried.name)
        return parts.joined(separator: " · ")
    }

    // MARK: - Today

    @ViewBuilder
    private var todayBlock: some View {
        let d = desk.todayDials
        let weekday = Voice.dateCaps(.now).split(separator: " ").first.map(String.init) ?? ""
        switch desk.todayState {
        case .out(let e):
            Caps("Today · " + dayLine(e).split(separator: "·").dropFirst().joined(separator: "·").trimmingCharacters(in: .whitespaces),
                 color: brand.palette.success)
        default:
            VStack(alignment: .leading, spacing: 12) {
                Caps("Today · \(weekday) · draw \(Words.draw(d.draw)) · grade \(d.grade)")
                Button {
                    desk.lay(.today)
                    desk.tab = .table
                } label: {
                    Text(desk.todayState == .laid(started: true) ? "Back to the table" : "Lay today's deal")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                }
                .brandProminent()
            }
        }
    }

    @ViewBuilder
    private var send: some View {
        if let image = ShareCard.renderPage(month: date(month), desk: desk) {
            ShareLink(item: image, preview: SharePreview("Baize · the diary", image: image)) {
                Text("Send the page").font(.headline).frame(maxWidth: .infinity).padding(.vertical, 4)
            }
            .buttonStyle(.bordered)
            .buttonBorderShape(.capsule)
            .controlSize(.large)
        }
    }

    // MARK: - Empty, and the shelf

    private var empty: some View {
        VStack(spacing: 14) {
            Image("Desk")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 320)
                .ambientFloat(distance: 4, period: 5)
                .accessibilityHidden(true)
            Text("Nothing written yet")
                .brandFont(.title)
                .foregroundStyle(brand.palette.ink)
            Text("Today's deal is laid. The first day that comes out goes here.")
                .foregroundStyle(brand.palette.inkSoft)
                .multilineTextAlignment(.center)
            Button {
                desk.lay(.today)
                desk.tab = .table
            } label: {
                Text("Lay today's deal").font(.headline).frame(maxWidth: .infinity).padding(.vertical, 4)
            }
            .brandProminent()
            .padding(.top, 6)
        }
        .padding(.top, 12)
        .padding(.horizontal, 12)
    }

    /// Volume one, hemmed at the top: twelve small pages of the first year.
    private var shelf: some View {
        VStack(alignment: .leading, spacing: 8) {
            Caps("Volume one")
            HStack(spacing: 4) {
                ForEach(0..<12, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .fill(AppBrand.CardBox.stock)
                        .overlay(alignment: .top) {
                            Rectangle().fill(AppBrand.CardBox.ink.opacity(0.25)).frame(height: 1).padding(.top, 5).padding(.horizontal, 3)
                        }
                        .frame(height: 34)
                        .shadow(color: .black.opacity(0.2), radius: 2, y: 1)
                        .rotationEffect(.degrees(Double(i % 3 - 1) * 1.2))
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Volume one, twelve months, shelved")
        }
    }
}

/// "Lay a reminder", with its hour once laid. On the Diary and in Settings.
struct ReminderRow: View {
    @EnvironmentObject private var desk: Desk
    @Environment(\.brand) private var brand
    var plain = false

    var body: some View {
        let on = Binding<Bool>(
            get: { desk.record.reminderHour != nil },
            set: { value in
                if value {
                    Task {
                        let hour = 20
                        if await Reminder.lay(hour: hour) { desk.update { $0.reminderHour = hour } }
                    }
                } else {
                    Reminder.lift()
                    desk.update { $0.reminderHour = nil }
                }
            })
        let hour = Binding<Date>(
            get: { Calendar.current.date(bySettingHour: desk.record.reminderHour ?? 20, minute: 0, second: 0, of: .now) ?? .now },
            set: { d in
                let h = Calendar.current.component(.hour, from: d)
                desk.update { $0.reminderHour = h }
                Task { _ = await Reminder.lay(hour: h) }
            })
        let rows = VStack(spacing: 10) {
            Toggle("Lay a reminder", isOn: on)
                .foregroundStyle(brand.palette.ink)
            if desk.record.reminderHour != nil {
                DatePicker("At", selection: hour, displayedComponents: .hourAndMinute)
                    .foregroundStyle(brand.palette.inkSoft)
            }
        }
        if plain {
            rows
        } else {
            rows
                .padding(.horizontal, 18)
                .padding(.vertical, 14)
                .background(brand.palette.surface, in: RoundedRectangle(cornerRadius: brand.corner, style: .continuous))
        }
    }
}

extension Calendar {
    func startOfMonth(_ d: Date) -> Date {
        date(from: dateComponents([.year, .month], from: d)) ?? d
    }
}
