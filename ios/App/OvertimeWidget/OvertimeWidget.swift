import WidgetKit
import SwiftUI

// 桌面小组件，两种：
//   「加班夜记」小号：本月加班几晚、花了多少；中号再加最近 14 晚花费趋势
//   「加班日历」小号 / 中号：GitHub 那种小方块，一列一周，黄色越深那晚花得越多
// 数据由 App 写进 App Group 共享存储（见 WidgetBridgePlugin.swift），颜色跟着 App 当前主题。

private let appGroup = "group.com.ssbabysong.overtimenightlog"

struct Palette: Codable {
    var paper = "#FAFAF4", ink = "#26354D", pencil = "#6E7889", card = "#FFFFFF"
    var money = "#F5C21B", moneyHi = "#FFEB7A", burn = "#D9483B", body = "#7550C8"
}

struct Summary: Codable {
    var appName = T("加班夜记", "Overtime")
    var monthTitle = T("10 月", "October")
    var nights = 0
    var nightsLabel = T("晚", "nights")
    var spent = "$0"
    var spentLabel = T("花了", "spent")
    var burnout = 0
    var body = 0
    var burnoutLabel = "Burnout"
    var bodyLabel = T("身体不行", "Unwell")
    var tonight = ""
    var tonightLabel = T("今晚", "Tonight")
    var emptyText = T("打开 App 记第一晚", "Open the app to log tonight")
    var dayStartHour = 4
    var trendTitle = T("近 14 晚", "Last 14 nights")
    var trend: [TrendPoint] = []
    var heatStart = ""          // heat[0] 对应的日期（周一），yyyy-MM-dd
    var heat: [Int] = []        // 每天一个等级：0 没花钱，1–4 越大花得越多
    var monthShort = zh ? (1...12).map { "\($0)月" } : ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
    var colors = Palette()

    static let sample: Summary = {
        var s = Summary(nights: 14, spent: "$356.25", burnout: 6, body: 4, tonight: "$47.75")
        let h: [Double] = [0, 0.84, 0.12, 0.2, 0, 0, 0.54, 0.84, 0.47, 0.8, 0, 0, 0, 0.37]
        s.trend = h.enumerated().map { TrendPoint(d: 9 + $0.offset, h: $0.element, t: $0.offset == 13, b: $0.element > 0.7) }
        s.heatStart = "2026-05-25"
        s.heat = (0..<151).map { i in i % 7 >= 5 ? 0 : [0, 1, 2, 0, 3, 4, 1, 2, 0, 3][(i * 7 + i / 5) % 10] }
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
        trend = (try? c.decodeIfPresent([TrendPoint].self, forKey: .trend)) ?? trend
        heatStart = try c.decodeIfPresent(String.self, forKey: .heatStart) ?? heatStart
        heat = (try? c.decodeIfPresent([Int].self, forKey: .heat)) ?? heat
        monthShort = (try? c.decodeIfPresent([String].self, forKey: .monthShort)) ?? monthShort
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
func nightDay(_ date: Date, dayStartHour: Int) -> Date {
    let cal = Calendar.current
    let d = cal.component(.hour, from: date) < dayStartHour ? cal.date(byAdding: .day, value: -1, to: date)! : date
    return cal.startOfDay(for: d)
}

struct WidgetView: View {
    @Environment(\.widgetFamily) var family
    let entry: Entry

    var body: some View {
        let s = entry.summary ?? Summary()
        let c = s.colors
        Group {
            if family == .systemMedium { medium(s, c) } else { small(s, c) }
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
        }
    }
}

/// GitHub 那种小方块：一列一周（周一在上），黄色越深那晚花得越多，今天描边。放得下几周就显示几周，最右一列是本周
struct HeatmapView: View {
    let s: Summary
    let c: Palette
    let now: Date
    var monthLabels = true

    func shade(_ level: Int) -> Color {
        let o: [Double] = [0, 0.3, 0.55, 0.8, 1]
        return level <= 0 ? Color(hex: c.pencil).opacity(0.12) : Color(hex: c.money).opacity(o[min(level, 4)])
    }

    /// heat[0] 那天（周一）
    var start: Date? {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.date(from: s.heatStart).map { Calendar.current.startOfDay(for: $0) }
    }

    var body: some View {
        let cal = Calendar.current
        let today = nightDay(now, dayStartHour: s.dayStartHour)
        GeometryReader { g in
            let gap: CGFloat = 3, head: CGFloat = monthLabels ? 12 : 0
            let side = max((g.size.height - head - gap * 6) / 7, 4)
            let fit = max(Int((g.size.width + gap) / (side + gap)), 1)
            if let start, let todayIdx = cal.dateComponents([.day], from: start, to: today).day, todayIdx >= 0 {
                let weeks = min(fit, todayIdx / 7 + 1)
                let first = todayIdx / 7 - weeks + 1
                HStack(alignment: .top, spacing: gap) {
                    ForEach(0..<weeks, id: \.self) { k in
                        let w = first + k
                        VStack(spacing: gap) {
                            if monthLabels {
                                // 这一周里有某月 1 号（或者是第一列）就标上月份
                                let label: String = {
                                    for d in 0..<7 {
                                        guard let day = cal.date(byAdding: .day, value: w * 7 + d, to: start) else { continue }
                                        if cal.component(.day, from: day) == 1 || (k == 0 && d == 0 && cal.component(.day, from: day) < 22) {
                                            let m = cal.component(.month, from: day)
                                            return s.monthShort.indices.contains(m - 1) ? s.monthShort[m - 1] : "\(m)"
                                        }
                                    }
                                    return ""
                                }()
                                Text(label).font(.system(size: 9, weight: .medium, design: .rounded)).foregroundColor(Color(hex: c.pencil))
                                    .fixedSize().frame(width: side, height: head, alignment: .leading)
                            }
                            ForEach(0..<7, id: \.self) { d in
                                let i = w * 7 + d
                                RoundedRectangle(cornerRadius: max(side * 0.25, 1.5))
                                    .fill(i > todayIdx ? Color.clear : shade(i < s.heat.count ? s.heat[i] : 0))
                                    .overlay(RoundedRectangle(cornerRadius: max(side * 0.25, 1.5)).stroke(Color(hex: c.ink), lineWidth: i == todayIdx ? 1.2 : 0))
                                    .frame(width: side, height: side)
                            }
                        }
                    }
                }
                .frame(width: g.size.width, height: g.size.height, alignment: .trailing)
            }
        }
    }

    /// 「少 ▢▢▢▢ 多」图例，不带文字
    var legend: some View {
        HStack(spacing: 2) {
            ForEach(0...4, id: \.self) { l in RoundedRectangle(cornerRadius: 2).fill(shade(l)).frame(width: 8, height: 8) }
        }
    }
}

/// 「加班日历」小组件：小号只有方块；中号上面一行本月花费 + 图例
struct CalendarWidgetView: View {
    @Environment(\.widgetFamily) var family
    let entry: Entry

    var body: some View {
        let s = entry.summary ?? Summary()
        let c = s.colors
        let map = HeatmapView(s: s, c: c, now: entry.date)
        Group {
            if entry.summary == nil {
                Text(s.emptyText).font(.system(size: 14, weight: .medium, design: .rounded))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            } else if family == .systemMedium {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text(s.monthTitle).font(.system(size: 12, weight: .semibold, design: .rounded)).foregroundColor(Color(hex: c.pencil))
                        Text(s.spent).font(.system(size: 15, weight: .bold, design: .rounded)).lineLimit(1)
                        Spacer(minLength: 0)
                        map.legend
                    }
                    map
                }
            } else {
                map
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

/// 添加小组件时显示的名字跟着手机语言：中文手机用中文，其他都用英文
private let zh = Locale.preferredLanguages.first?.hasPrefix("zh") == true
private func T(_ zhText: String, _ en: String) -> String { zh ? zhText : en }

struct OvertimeWidget: Widget {
    let kind = "OvertimeWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            WidgetView(entry: entry)
        }
        .configurationDisplayName(T("加班夜记", "Overtime"))
        .description(T("本月加班几晚、花了多少、最近 14 晚花费趋势", "This month's overtime nights, spending and a 14-night trend"))
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct OvertimeCalendarWidget: Widget {
    let kind = "OvertimeCalendar"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            CalendarWidgetView(entry: entry)
        }
        .configurationDisplayName(T("加班日历", "Overtime Calendar"))
        .description(T("每晚花了多少，黄色越深花得越多", "Each night's spending. Darker squares mean you spent more."))
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
