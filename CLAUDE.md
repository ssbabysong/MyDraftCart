# 加班夜记 · Overtime Night Log

记录每晚加班花销、burnout 和身体状态的手绘风 App。同一份网页代码同时用于：
- **网页版**：仓库根目录的 `index.html`（加 `manifest.webmanifest`、`sw.js`、`icons/`），发布在 GitHub Pages。
- **iOS App**：Capacitor 8（Swift Package Manager）把网页打包进 `ios/`，再加原生功能。

用户只会说中文，回复请用中文，说清楚每一步要点哪里。

## 结构

| 位置 | 内容 |
| --- | --- |
| `index.html` | 整个 App：HTML、CSS、JS 都在这一个文件里，没有构建步骤 |
| `sw.js` | 网页版离线缓存。**改了 index.html 就把 `VERSION` 加一**（App 里不用 service worker） |
| `scripts/build-www.mjs` | 把网页复制到 `www/`，给 Capacitor 打包 |
| `scripts/ios-mode.mjs` | `free` / `paid` 两种签名模式切换（见下） |
| `ios/App/App/Plugins/ICloudSyncPlugin.swift` | iCloud 键值存储插件（JS 名 `ICloudSync`） |
| `ios/App/App/Plugins/WidgetBridgePlugin.swift` | 把本月汇总写进 App Group，刷新小组件（JS 名 `WidgetBridge`） |
| `ios/App/App/MainViewController.swift` | 注册上面两个插件；`Main.storyboard` 指向它 |
| `ios/App/OvertimeWidget/` | WidgetKit 小组件扩展（小号、中号），iOS 17+ |
| `appstore/` | 上架步骤 `RELEASE.md`、文案 `metadata.md`、截图 |
| `privacy.html`、`support.html` | 隐私政策和技术支持页（App Store 要求） |

`index.html` 里通过 `NATIVE`（`window.Capacitor.isNativePlatform()`）区分网页和 App；原生插件用 `plug("名字")` 取。

## 常用命令

```bash
npm install
npm run ios          # build-www → cap sync ios → 打开 Xcode
npm run ios:free     # 免费 Personal Team 测试模式：Bundle ID 加 .dev，去掉 iCloud / App Group 权限
npm run ios:paid     # 正式模式（付费开发者账号，上架用）
xcodebuild -project ios/App/App.xcodeproj -scheme App -destination 'generic/platform=iOS Simulator' build
```

## 现状（交接时）

- 网页版和 App 的 JS 逻辑都在模拟环境里测过。
- **iOS 工程从没在 Mac 上编译过**（是在 Linux 上用 xcodeproj gem 生成和修改的）。第一次编译可能有 Swift / 工程配置错误，需要修。
- 开发者会员还在 Pending（付款 / 开通中），所以 Xcode 只有免费的 Personal Team，先用 `npm run ios:free` 测试。
- Bundle ID：`com.ssbabysong.overtimenightlog`，小组件 `….widget`，App Group `group.com.ssbabysong.overtimenightlog`。
- 上架地区：除中国大陆外全部。

## 约定

- 在分支 `claude/app-development-b8g0mq` 上开发，提交后推送到这个分支。
- 只有用户能做的事（登录 Apple ID、在 Xcode 里选 Team、信任开发者、App Store Connect 里点提交）要写清楚步骤让用户操作。
- 不要把任何密钥、Token、Apple 账号信息写进仓库。
- 改了 `index.html` 后：`sw.js` 的 `VERSION` 加一，并运行 `npm run build && npx cap sync ios`。
