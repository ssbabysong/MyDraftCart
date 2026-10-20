import UIKit
import Capacitor
import UserNotifications

/// 在这里注册 App 自带的原生插件（iCloud 同步、桌面小组件、专注守护）。
class MainViewController: CAPBridgeViewController {
    /// 专注时为 true：从底部上滑回桌面、从顶部下拉都要滑两次（第一次只会露出小横条），防止手滑离开
    var guardEdges = false {
        didSet { setNeedsUpdateOfScreenEdgesDeferringSystemGestures() }
    }
    override var preferredScreenEdgesDeferringSystemGestures: UIRectEdge {
        guardEdges ? [.bottom, .top] : []
    }

    override open func capacitorDidLoad() {
        bridge?.registerPluginInstance(ICloudSyncPlugin())
        bridge?.registerPluginInstance(WidgetBridgePlugin())
        bridge?.registerPluginInstance(KeepAwakePlugin())
    }
}

/// 番茄专注守护：
/// - awake：不让屏幕自动锁定（锁屏也算离开，会让番茄坏掉）
/// - guard：专注中。拦一下系统手势；App 一进后台就由原生端立刻发「番茄要坏掉了」的通知，
///   不靠网页里的 JS（进后台后网页很快就被挂起，来不及排通知）；回到 App 时撤掉这条通知
@objc(KeepAwakePlugin)
public class KeepAwakePlugin: CAPPlugin, CAPBridgedPlugin {
    public let identifier = "KeepAwakePlugin"
    public let jsName = "KeepAwake"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "set", returnType: CAPPluginReturnPromise)
    ]

    static let leaveId = "overtime-focus-leave"
    private var leaveTitle: String?
    private var leaveBody = ""

    public override func load() {
        NotificationCenter.default.addObserver(self, selector: #selector(didLeave), name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didReturn), name: UIApplication.willEnterForegroundNotification, object: nil)
    }

    @objc func set(_ call: CAPPluginCall) {
        let awake = call.getBool("awake") ?? call.getBool("on") ?? false
        let guarding = call.getBool("guard") ?? false
        leaveTitle = guarding ? (call.getString("title") ?? "") : nil
        leaveBody = call.getString("body") ?? ""
        DispatchQueue.main.async {
            UIApplication.shared.isIdleTimerDisabled = awake
            (self.bridge?.viewController as? MainViewController)?.guardEdges = guarding
            call.resolve()
        }
    }

    @objc private func didLeave() {
        guard let title = leaveTitle else { return }
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = leaveBody
        content.sound = .default
        content.interruptionLevel = .timeSensitive
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: KeepAwakePlugin.leaveId, content: content, trigger: trigger))
    }

    @objc private func didReturn() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [KeepAwakePlugin.leaveId])
        center.removeDeliveredNotifications(withIdentifiers: [KeepAwakePlugin.leaveId])
    }
}
