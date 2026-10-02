import WidgetKit
import SwiftUI

// 桌面小组件：显示本月加班几晚、花了多少、几晚 burnout、几晚身体不行。
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
    var colors = Palette()

    static let sample = Summary(monthTitle: "9 月", nights: 15, spent: "$390", burnout: 6, body: 4, tonight: "$47.75")
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
        // App 每次有改动都会主动刷新；这里再每 3 小时兜底刷新一次
        let entry = Entry(date: Date(), summary: load())
        completion(Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(3 * 3600))))
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
                HStack(spacing: 8) {
                    Label("\(s.burnout)", systemImage: "flame.fill").foregroundColor(Color(hex: c.burn))
                    Label("\(s.body)", systemImage: "heart.fill").foregroundColor(Color(hex: c.body))
                }
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .labelStyle(.titleAndIcon)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func medium(_ s: Summary, _ c: Palette) -> some View {
        HStack(spacing: 14) {
            small(s, c)
            if entry.summary != nil {
                VStack(alignment: .leading, spacing: 8) {
                    stat(s.burnoutLabel, "\(s.burnout)", Color(hex: c.burn), c)
                    stat(s.bodyLabel, "\(s.body)", Color(hex: c.body), c)
                    stat(s.tonightLabel, s.tonight.isEmpty ? "—" : s.tonight, Color(hex: c.ink), c)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private func stat(_ label: String, _ value: String, _ color: Color, _ c: Palette) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(label).font(.system(size: 11, weight: .medium, design: .rounded)).foregroundColor(Color(hex: c.pencil))
            Text(value).font(.system(size: 20, weight: .bold, design: .rounded)).foregroundColor(color).lineLimit(1).minimumScaleFactor(0.6)
        }
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

@main
struct OvertimeWidget: Widget {
    let kind = "OvertimeWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            WidgetView(entry: entry)
        }
        .configurationDisplayName("加班夜记")
        .description("本月加班几晚、花了多少 · This month's overtime at a glance")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
