import UIKit
import Capacitor

/// 在这里注册 App 自带的原生插件（iCloud 同步、桌面小组件）。
class MainViewController: CAPBridgeViewController {
    override open func capacitorDidLoad() {
        bridge?.registerPluginInstance(ICloudSyncPlugin())
        bridge?.registerPluginInstance(WidgetBridgePlugin())
    }
}
