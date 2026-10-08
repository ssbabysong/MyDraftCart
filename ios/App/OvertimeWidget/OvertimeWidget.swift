import WidgetKit
import SwiftUI

// 桌面小组件，两种：
//   「本月概览」小号：加班几晚、花了多少；中号再加最近 14 晚花费趋势；大号再加加班日历
//   「加班日历」小号 / 中号：本月每天下班多晚，颜色越深越晚
// 数据由 App 写进 App Group 共享存储（见 WidgetBridgePlugin.swift），颜色跟着 App 当前主题。

private let appGroup = "group.com.ssbabysong.overtimenightlog"

struct Palette: Codable {
    var paper = "#FAFAF4", ink = "#26354D", pencil = "#6E7889", card = "#FFFFFF"
    var money = "#F5C21B", moneyHi = "#FFEB7A", burn = "#D9483B", body = "#7550C8"
}

struct Summary: Codable {
    var appName = "加班夜记"
    var monthTitle = "9 月"
    var nights = 0
    var nightsLabel = "晚"
    var spent = "$0"
    var spentLabel = "花了"
    var burnout = 0
    var body = 0
    var burnoutLabel = "Burnout"
    var bodyLabel = "身体不行"
    var tonight = ""
    var tonightLabel = "今晚"
    var emptyText = "打开 App 记第一晚"
    var dayStartHour = 4
    var trendTitle = "最近 14 晚花费"
    var trendMax = "$50"
    var trend: [TrendPoint] = []
    var calTitle = "加班日历"
    var month = ""
    var lead = 0
    var levels: [Int] = []
    var weekdays = ["一", "二", "三", "四", "五", "六", "日"]
    var legend = "越深下班越晚"
    var lateLabel = "最晚下班"
    var late = "—"
    var colors = Palette()

    static let sample: Summary = {
        var s = Summary(monthTitle: "10 月", nights: 14, spent: "$356.25", burnout: 6, body: 4, tonight: "$47.75")
        let h: [Double] = [0, 0.84, 0.12, 0.2, 0, 0, 0.54, 0.84, 0.47, 0.8, 0, 0, 0, 0.37]
        s.trend = h.enumerated().map { TrendPoint(d: 9 + $0.offset, h: $0.element, t: $0.offset == 13, b: $0.element > 0.7) }
        s.trendMax = "$50"; s.late = "01:10"; s.month = "2026-10"; s.lead = 3
        s.levels = [2, 1, 0, 0, 4, 2, 4, 0, 1, 0, 0, 2, 3, 2, 3, 0, 0, 0, 2, 1, 4, 3, 0, 0, 0, 0, 0, 0, 0, 0, 0]
        return s
    }()
}

struct TrendPoint: Codable {
    var d = 1
    var h = 0.0
    var t: Bool? = false
    var b: Bool? = false
}

// 宽松解析：缺了哪个字段就用默认值，以后加字段也不会让小组件出错
extension Palette {
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.init()
        paper = try c.decodeIfPresent(String.self, forKey: .paper) ?? paper
        ink = try c.decodeIfPresent(String.self, forKey: .ink) ?? ink
        pencil = try c.decodeIfPresent(String.self, forKey: .pencil) ?? pencil
        card = try c.decodeIfPresent(String.self, forKey: .card) ?? card
        money = try c.decodeIfPresent(String.self, forKey: .money) ?? money
        moneyHi = try c.decodeIfPresent(String.self, forKey: .moneyHi) ?? moneyHi
        burn = try c.decodeIfPresent(String.self, forKey: .burn) ?? burn
        body = try c.decodeIfPresent(String.self, forKey: .body) ?? body
    }
}

extension Summary {
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.init()
        appName = try c.decodeIfPresent(String.self, forKey: .appName) ?? appName
        monthTitle = try c.decodeIfPresent(String.self, forKey: .monthTitle) ?? monthTitle
        nights = try c.decodeIfPresent(Int.self, forKey: .nights) ?? nights
        nightsLabel = try c.decodeIfPresent(String.self, forKey: .nightsLabel) ?? nightsLabel
        spent = try c.decodeIfPresent(String.self, forKey: .spent) ?? spent
        spentLabel = try c.decodeIfPresent(String.self, forKey: .spentLabel) ?? spentLabel
        burnout = try c.decodeIfPresent(Int.self, forKey: .burnout) ?? burnout
        body = try c.decodeIfPresent(Int.self, forKey: .body) ?? body
        burnoutLabel = try c.decodeIfPresent(String.self, forKey: .burnoutLabel) ?? burnoutLabel
        bodyLabel = try c.decodeIfPresent(String.self, forKey: .bodyLabel) ?? bodyLabel
        tonight = try c.decodeIfPresent(String.self, forKey: .tonight) ?? tonight
        tonightLabel = try c.decodeIfPresent(String.self, forKey: .tonightLabel) ?? tonightLabel
        emptyText = try c.decodeIfPresent(String.self, forKey: .emptyText) ?? emptyText
        dayStartHour = try c.decodeIfPresent(Int.self, forKey: .dayStartHour) ?? dayStartHour
        trendTitle = try c.decodeIfPresent(String.self, forKey: .trendTitle) ?? trendTitle
        trendMax = try c.decodeIfPresent(String.self, forKey: .trendMax) ?? trendMax
        trend = (try? c.decodeIfPresent([TrendPoint].self, forKey: .trend)) ?? trend
        calTitle = try c.decodeIfPresent(String.self, forKey: .calTitle) ?? calTitle
        month = try c.decodeIfPresent(String.self, forKey: .month) ?? month
        lead = try c.decodeIfPresent(Int.self, forKey: .lead) ?? lead
        levels = (try? c.decodeIfPresent([Int].self, forKey: .levels)) ?? levels
        weekdays = (try? c.decodeIfPresent([String].self, forKey: .weekdays)) ?? weekdays
        legend = try c.decodeIfPresent(String.self, forKey: .legend) ?? legend
        lateLabel = try c.decodeIfPresent(String.self, forKey: .lateLabel) ?? lateLabel
        late = try c.decodeIfPresent(String.self, forKey: .late) ?? late
        colors = try c.decodeIfPresent(Palette.self, forKey: .colors) ?? colors
    }
}

struct Entry: TimelineEntry {
    let date: Date
    let summary: Summary?
}

struct Provider: TimelineProvider {
    func load() -> Summary? {
        guard let json = UserDefaults(suiteName: appGroup)?.string(forKey: "summary"),
              let data = json.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(Summary.self, from: data)
    }
    func placeholder(in context: Context) -> Entry { Entry(date: Date(), summary: .sample) }
    func getSnapshot(in context: Context, completion: @escaping (Entry) -> Void) {
        completion(Entry(date: Date(), summary: context.isPreview ? (load() ?? .sample) : load()))
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
        // App 每次有改动都会主动刷新；这里再每 3 小时兜底刷新一次，凌晨换天（默认 4 点）时也刷新，让日历的「今天」跟着走
        let s = load(), now = Date()
        var next = now.addingTimeInterval(3 * 3600)
        if let dayStart = Calendar.current.nextDate(after: now, matching: DateComponents(hour: s?.dayStartHour ?? 4, minute: 1), matchingPolicy: .nextTime), dayStart < next { next = dayStart }
        completion(Timeline(entries: [Entry(date: now, summary: s)], policy: .after(next)))
    }
}

extension Color {
    init(hex: String) {
        var s = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.hasPrefix("#") { s.removeFirst() }
        if s.count == 3 { s = s.map { "\($0)\($0)" }.joined() }
        var v: UInt64 = 0
        Scanner(string: s).scanHexInt64(&v)
        self.init(red: Double((v >> 16) & 0xFF) / 255, green: Double((v >> 8) & 0xFF) / 255, blue: Double(v & 0xFF) / 255)
    }
}

/// 加班的「今晚」：凌晨 dayStartHour 点前还算前一天，和 App 里的 nightOf 一致
func nightDay(_ date: Date, dayStartHour: Int) -> DateComponents {
    let cal = Calendar.current
    let d = cal.component(.hour, from: date) < dayStartHour ? cal.date(byAdding: .day, value: -1, to: date)! : date
    return cal.dateComponents([.year, .month, .day], from: d)
}

struct WidgetView: View {
    @Environment(\.widgetFamily) var family
    let entry: Entry

    var body: some View {
        let s = entry.summary ?? Summary()
        let c = s.colors
        Group {
            switch family {
            case .systemLarge: large(s, c)
            case .systemMedium: medium(s, c)
            default: small(s, c)
            }
        }
        .foregroundColor(Color(hex: c.ink))
        .widgetBackground(Color(hex: c.paper))
    }

    private func small(_ s: Summary, _ c: Palette) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(s.monthTitle).font(.system(size: 13, weight: .semibold, design: .rounded)).foregroundColor(Color(hex: c.pencil))
            if entry.summary == nil {
                Spacer()
                Text(s.emptyText).font(.system(size: 14, weight: .medium, design: .rounded))
                Spacer()
            } else {
                HStack(alignment: .firstTextBaseline, spacing: 3) {
                    Text("\(s.nights)").font(.system(size: 40, weight: .bold, design: .rounded))
                    Text(s.nightsLabel).font(.system(size: 14, weight: .medium, design: .rounded)).foregroundColor(Color(hex: c.pencil))
                }
                Text(s.spent)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .minimumScaleFactor(0.6).lineLimit(1)
                    .padding(.horizontal, 4)
                    .background(Color(hex: c.moneyHi).cornerRadius(4))
                Spacer(minLength: 0)
                flags(s, c)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func flags(_ s: Summary, _ c: Palette) -> some View {
        HStack(spacing: 8) {
            Label("\(s.burnout)", systemImage: "flame.fill").foregroundColor(Color(hex: c.burn))
            Label("\(s.body)", systemImage: "heart.fill").foregroundColor(Color(hex: c.body))
        }
        .font(.system(size: 13, weight: .semibold, design: .rounded))
        .labelStyle(.titleAndIcon)
    }

    private func medium(_ s: Summary, _ c: Palette) -> some View {
        HStack(spacing: 14) {
            small(s, c).frame(width: 110)
            if entry.summary != nil { TrendView(s: s, c: c) }
        }
    }

    private func large(_ s: Summary, _ c: Palette) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            if entry.summary == nil {
                small(s, c)
            } else {
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Text(s.monthTitle).font(.system(size: 15, weight: .semibold, design: .rounded)).foregroundColor(Color(hex: c.pencil)).lineLimit(1)
                    Text("\(s.nights) \(s.nightsLabel)").font(.system(size: 20, weight: .bold, design: .rounded)).lineLimit(1).fixedSize()
                    Text(s.spent).font(.system(size: 20, weight: .bold, design: .rounded)).lineLimit(1).minimumScaleFactor(0.6)
                        .padding(.horizontal, 4).background(Color(hex: c.moneyHi).cornerRadius(4))
                    Spacer(minLength: 0)
                    flags(s, c).fixedSize().layoutPriority(1)
                }
                TrendView(s: s, c: c).frame(height: 120)
                CalendarView(s: s, c: c, now: entry.date, showHeader: true)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

/// 最近 14 晚的花费柱状图，今晚的柱子用实色
struct TrendView: View {
    let s: Summary
    let c: Palette

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline) {
                Text(s.trendTitle).font(.system(size: 12, weight: .semibold, design: .rounded)).foregroundColor(Color(hex: c.pencil))
                Spacer(minLength: 4)
                if !s.tonight.isEmpty {
                    Text("\(s.tonightLabel) \(s.tonight)").font(.system(size: 12, weight: .bold, design: .rounded)).lineLimit(1).minimumScaleFactor(0.7)
                }
            }
            ZStack(alignment: .topTrailing) {
                GeometryReader { g in
                    let n = max(s.trend.count, 1)
                    let gap: CGFloat = 3
                    let w = max((g.size.width - gap * CGFloat(n - 1)) / CGFloat(n), 2)
                    HStack(alignment: .bottom, spacing: gap) {
                        ForEach(Array(s.trend.enumerated()), id: \.offset) { _, p in
                            VStack(spacing: 2) {
                                Spacer(minLength: 0)
                                if p.b == true { Circle().fill(Color(hex: c.burn)).frame(width: 4, height: 4) }
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color(hex: c.money).opacity(p.t == true ? 1 : 0.55))
                                    .overlay(RoundedRectangle(cornerRadius: 2).stroke(Color(hex: c.ink), lineWidth: p.t == true ? 1.2 : 0))
                                    .frame(width: w, height: max(CGFloat(min(p.h, 1)) * (g.size.height - 8), p.h > 0 ? 3 : 1))
                            }
                        }
                    }
                    .frame(maxHeight: .infinity, alignment: .bottom)
                }
                .overlay(Rectangle().fill(Color(hex: c.pencil).opacity(0.5)).frame(height: 1), alignment: .bottom)
                Text(s.trendMax).font(.system(size: 9, weight: .medium, design: .rounded)).foregroundColor(Color(hex: c.pencil))
            }
            HStack {
                Text(s.trend.first.map { "\($0.d)" } ?? "")
                Spacer()
                Text(s.trend.last.map { "\($0.d)" } ?? "")
            }
            .font(.system(size: 9, weight: .medium, design: .rounded)).foregroundColor(Color(hex: c.pencil))
        }
    }
}

/// 本月加班日历：每天一个格子，下班越晚颜色越深；今天描边
struct CalendarView: View {
    let s: Summary
    let c: Palette
    let now: Date
    var showHeader = false

    private func shade(_ level: Int) -> Color {
        let o: [Double] = [0, 0.18, 0.4, 0.65, 0.92]
        return level <= 0 ? Color(hex: c.pencil).opacity(0.08) : Color(hex: c.ink).opacity(o[min(level, 4)])
    }

    var body: some View {
        let today = nightDay(now, dayStartHour: s.dayStartHour)
        let todayIndex = String(format: "%04d-%02d", today.year ?? 0, today.month ?? 0) == s.month ? (today.day ?? 0) : 0
        let cells = Array(repeating: -1, count: s.lead) + s.levels
        let rows = Int((Double(cells.count) / 7).rounded(.up))
        VStack(alignment: .leading, spacing: 4) {
            if showHeader {
                HStack(alignment: .firstTextBaseline) {
                    Text(s.calTitle).font(.system(size: 12, weight: .semibold, design: .rounded)).foregroundColor(Color(hex: c.pencil))
                    Spacer()
                    legendView
                }
            }
            // 表头和格子用同一个边长，保证星期和日期对齐
            GeometryReader { g in
                let gap: CGFloat = 3, head: CGFloat = 13
                let side = max(min((g.size.width - gap * 6) / 7, (g.size.height - head - gap * CGFloat(rows)) / CGFloat(max(rows, 1))), 4)
                VStack(alignment: .leading, spacing: gap) {
                    HStack(spacing: gap) {
                        ForEach(Array(s.weekdays.enumerated()), id: \.offset) { _, w in
                            Text(w).font(.system(size: 9, weight: .medium, design: .rounded)).foregroundColor(Color(hex: c.pencil)).frame(width: side, height: head)
                        }
                    }
                    ForEach(0..<rows, id: \.self) { r in
                        HStack(spacing: gap) {
                            ForEach(0..<7, id: \.self) { k in
                                let i = r * 7 + k
                                let level = i < cells.count ? cells[i] : -1
                                let day = i - s.lead + 1
                                RoundedRectangle(cornerRadius: max(side * 0.22, 2))
                                    .fill(level < 0 ? Color.clear : shade(level))
                                    .overlay(RoundedRectangle(cornerRadius: max(side * 0.22, 2)).stroke(Color(hex: c.burn), lineWidth: day == todayIndex && level >= 0 ? 1.5 : 0))
                                    .overlay {
                                        if level >= 0 && side >= 24 {
                                            Text("\(day)").font(.system(size: side * 0.32, weight: .semibold, design: .rounded))
                                                .foregroundColor(level >= 3 ? Color(hex: c.paper) : Color(hex: c.pencil))
                                        }
                                    }
                                    .frame(width: side, height: side)
                            }
                        }
                    }
                }
                .frame(width: g.size.width, height: g.size.height, alignment: .top)
            }
        }
    }

    var legendView: some View {
        HStack(spacing: 2) {
            Text(s.legend).font(.system(size: 9, weight: .medium, design: .rounded)).foregroundColor(Color(hex: c.pencil)).padding(.trailing, 2)
            ForEach(1...4, id: \.self) { l in RoundedRectangle(cornerRadius: 2).fill(shade(l)).frame(width: 8, height: 8) }
        }
    }
}

/// 「加班日历」小组件：小号只有日历，中号旁边加加班几晚和最晚下班
struct CalendarWidgetView: View {
    @Environment(\.widgetFamily) var family
    let entry: Entry

    var body: some View {
        let s = entry.summary ?? Summary()
        let c = s.colors
        Group {
            if entry.summary == nil {
                VStack(alignment: .leading) {
                    Text(s.calTitle).font(.system(size: 13, weight: .semibold, design: .rounded)).foregroundColor(Color(hex: c.pencil))
                    Spacer()
                    Text(s.emptyText).font(.system(size: 14, weight: .medium, design: .rounded))
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            } else if family == .systemMedium {
                HStack(spacing: 14) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(s.monthTitle).font(.system(size: 13, weight: .semibold, design: .rounded)).foregroundColor(Color(hex: c.pencil))
                        HStack(alignment: .firstTextBaseline, spacing: 3) {
                            Text("\(s.nights)").font(.system(size: 34, weight: .bold, design: .rounded))
                            Text(s.nightsLabel).font(.system(size: 13, weight: .medium, design: .rounded)).foregroundColor(Color(hex: c.pencil))
                        }
                        VStack(alignment: .leading, spacing: 0) {
                            Text(s.lateLabel).font(.system(size: 11, weight: .medium, design: .rounded)).foregroundColor(Color(hex: c.pencil))
                            Text(s.late).font(.system(size: 20, weight: .bold, design: .rounded))
                        }
                        Spacer(minLength: 0)
                        CalendarView(s: s, c: c, now: entry.date).legendView
                    }
                    .frame(width: 112, alignment: .leading)
                    CalendarView(s: s, c: c, now: entry.date)
                }
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    Text(s.monthTitle).font(.system(size: 12, weight: .semibold, design: .rounded)).foregroundColor(Color(hex: c.pencil))
                    CalendarView(s: s, c: c, now: entry.date)
                }
            }
        }
        .foregroundColor(Color(hex: c.ink))
        .widgetBackground(Color(hex: c.paper))
    }
}

extension View {
    /// iOS 17 起小组件要求用 containerBackground 设背景
    @ViewBuilder func widgetBackground(_ color: Color) -> some View {
        if #available(iOS 17.0, *) {
            self.containerBackground(for: .widget) { color }
        } else {
            self.padding().background(color)
        }
    }
}

struct OvertimeWidget: Widget {
    let kind = "OvertimeWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            WidgetView(entry: entry)
        }
        .configurationDisplayName("加班夜记")
        .description("本月加班几晚、花了多少、最近花费趋势 · This month's overtime and spending trend")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct OvertimeCalendarWidget: Widget {
    let kind = "OvertimeCalendar"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            CalendarWidgetView(entry: entry)
        }
        .configurationDisplayName("加班日历")
        .description("本月每天下班多晚，颜色越深越晚 · Darker days mean you left later")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

@main
struct OvertimeWidgets: WidgetBundle {
    var body: some Widget {
        OvertimeWidget()
        OvertimeCalendarWidget()
    }
}
