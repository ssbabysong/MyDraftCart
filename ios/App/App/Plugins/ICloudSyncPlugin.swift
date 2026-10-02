import Foundation
import Capacitor

/// iCloud 键值存储（NSUbiquitousKeyValueStore）。
/// 数据存在用户自己的 iCloud 里，同一个 Apple ID 的设备之间由系统自动同步，不经过任何服务器。
/// 限制：总共 1 MB，足够存好几年的加班记录。
@objc(ICloudSyncPlugin)
public class ICloudSyncPlugin: CAPPlugin, CAPBridgedPlugin {
    public let identifier = "ICloudSyncPlugin"
    public let jsName = "ICloudSync"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "status", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "get", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "set", returnType: CAPPluginReturnPromise)
    ]

    private let store = NSUbiquitousKeyValueStore.default
    private let maxBytes = 1_000_000

    override public func load() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(changedExternally(_:)),
            name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: store
        )
        store.synchronize()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    /// 别的设备改了数据，或者 iCloud 账号变了：通知网页重新合并
    @objc private func changedExternally(_ note: Notification) {
        let reason = (note.userInfo?[NSUbiquitousKeyValueStoreChangeReasonKey] as? Int) ?? -1
        notifyListeners("change", data: ["reason": reason])
    }

    /// 有没有登录 iCloud
    @objc func status(_ call: CAPPluginCall) {
        call.resolve(["available": FileManager.default.ubiquityIdentityToken != nil])
    }

    @objc func get(_ call: CAPPluginCall) {
        guard let key = call.getString("key") else { return call.reject("missing key") }
        store.synchronize()
        if let value = store.string(forKey: key) {
            call.resolve(["value": value])
        } else {
            call.resolve(["value": NSNull()])
        }
    }

    @objc func set(_ call: CAPPluginCall) {
        guard let key = call.getString("key"), let value = call.getString("value") else {
            return call.reject("missing key or value")
        }
        if value.utf8.count > maxBytes {
            return call.reject("too_large", "TOO_LARGE")
        }
        store.set(value, forKey: key)
        store.synchronize()
        call.resolve()
    }
}
