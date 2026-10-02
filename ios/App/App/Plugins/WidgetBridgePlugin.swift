import Foundation
import Capacitor
import WidgetKit

/// 把本月汇总写到 App Group 共享存储，让桌面小组件读取，然后刷新小组件。
@objc(WidgetBridgePlugin)
public class WidgetBridgePlugin: CAPPlugin, CAPBridgedPlugin {
    public let identifier = "WidgetBridgePlugin"
    public let jsName = "WidgetBridge"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "update", returnType: CAPPluginReturnPromise)
    ]

    static let appGroup = "group.com.ssbabysong.overtimenightlog"

    @objc func update(_ call: CAPPluginCall) {
        guard let json = call.getString("json") else { return call.reject("missing json") }
        guard let defaults = UserDefaults(suiteName: WidgetBridgePlugin.appGroup) else {
            return call.reject("App Group not configured")
        }
        defaults.set(json, forKey: "summary")
        WidgetCenter.shared.reloadAllTimelines()
        call.resolve()
    }
}
