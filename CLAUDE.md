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
| `ios/App/OvertimeWidget/` | WidgetKit 小组件扩展，iOS 17+：「加班夜记」概览（小号；中号加 14 晚花费趋势）和「加班日历」（小号、中号，GitHub 式一列一周的黄色小方块，越深那晚花得越多） |
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
- iOS 工程已在 Mac（Xcode 27）上编译通过（模拟器，free 模式），记一笔、日历、统计、愿望清单、主题、iCloud 测试模式提示、小组件桥接都在模拟器里测过。每晚提醒已在真机（iPhone 17 Pro Max，iOS 27，免费 Personal Team）上确认能收到通知。
- 真机连不上（Xcode 报 CoreDeviceError 4000 / `enablePersonalizedDDI`，`devicectl list devices` 显示 `connected (no DDI)`）时：iPhone「设置 → 通用 → 传输或还原 iPhone → 还原 → 还原位置与隐私」后重新插线信任即可。
- 最低系统版本统一为 iOS 17（小组件需要 17；Capacitor 按工程里第一个 `IPHONEOS_DEPLOYMENT_TARGET` 生成 `CapApp-SPM`，各 target 不一致会有链接警告）。
- Capacitor 8 的窗口是 `SceneDelegate.swift` 用代码建的，不走 storyboard：根控制器必须是 `MainViewController()`，否则自定义插件不会注册。
- 开发者会员已开通（个人账号），工程已切回 `npm run ios:paid` 正式模式，App 和 OvertimeWidget 两个 target 都选付费 Team。命令行 `xcodebuild -allowProvisioningUpdates` 真机构建已通过，签名里带 iCloud 键值存储和 App Group。`ios:free` 只在需要用免费账号时才用。
- App Store 截图（`appstore/screenshots/`）是 iPhone 17 Pro Max 模拟器截的，1320×2868，中英文各 6 张：今晚、日历、统计、月度账单、愿望清单、主题。功能界面有明显变化时要重拍。
- 「今晚」凌晨 4 点才换天（`index.html` 的 `DAY_START_HOUR`），加班到第二天凌晨还记在前一晚；小组件用 App 传过去的 `dayStartHour` 判断今天（日历方块的「今天」描边），凌晨 4 点也会自动刷新。
- Bundle ID：`com.ssbabysong.overtimenightlog`，小组件 `….widget`，App Group `group.com.ssbabysong.overtimenightlog`。
- 2026-10-08 已用 `xcodebuild -exportArchive`（method app-store-connect，destination upload）把 1.0（build 1）上传到 App Store Connect。再上传必须把两个 target 的 `CURRENT_PROJECT_VERSION` 加 1（同一版本号下 build 不能重复）。之后加了 App 和小组件的 `PrivacyInfo.xcprivacy`（UserDefaults：CA92.1、1C8F.1，防 ITMS-91053），build 号升到 2。
- 2026-10-08 已在 App Store Connect 提交审核（1.0）。截图要传到「iPhone with Dynamic Island (medium display)」槽位（`appstore/screenshots/6.3-inch/`，1206×2622）；描述里不能有 emoji，App Store Connect 会报 invalid characters。Header / 搜索结果宣传图在 `appstore/promo/out/`，用 `node appstore/promo/make.mjs` 生成。
- 上架地区：除中国大陆外全部，主要市场是美国。App Store Connect 主要语言是英文（美国），另加简体中文。
- 桌面图标名跟着系统语言（`ios/App/App/*.lproj/InfoPlist.strings`）：英文 Overtime Log，简体 加班夜记，繁体 加班夜記；基础值 `CFBundleDisplayName` 是英文。小组件的名称和没数据时的文字在 `OvertimeWidget.swift` 里按 `Locale.preferredLanguages` 选中英文。

## 约定

- 在分支 `claude/app-development-b8g0mq` 上开发，提交后推送到这个分支。
- 只有用户能做的事（登录 Apple ID、在 Xcode 里选 Team、信任开发者、App Store Connect 里点提交）要写清楚步骤让用户操作。
- 不要把任何密钥、Token、Apple 账号信息写进仓库。
- 改了 `index.html` 后：`sw.js` 的 `VERSION` 加一，并运行 `npm run build && npx cap sync ios`。
- 底部菜单 4 个：今晚 / 专注 / 愿望 / 日历（日历页标题处切换日历、统计；月历格子里有几个番茄画几个）。设置和历史记录、备份（tab `records`）不占菜单，从右上角齿轮 `.gear` 进去。分组在 `GROUPS`，再点底部按钮回到上次看的子页（`overtime-sub-<组>`）。
- 番茄专注：专注记录存 `overtime-focus-v1`（`{id, start, end, min, wishId?}`），和每晚记录、愿望一样进备份和 iCloud 三方合并；进行中的番茄 `overtime-focus-run` 只存在本机，按时间戳算剩余时间。愿望可设 `focusGoal`（分钟），绑定它的专注攒够了才解锁。专注时不能离开：不能收起，切出 App / 锁屏 / 关掉 App 超过 10 秒（`GRACE`）番茄就坏掉（phase `broken`，不计入）；休息结束用本地通知 id 900。App 里专注时用 `MainViewController.swift` 里的 KeepAwake 插件：关掉自动锁屏、回桌面和下拉要滑两次（`preferredScreenEdgesDeferringSystemGestures`）、进后台那一刻由原生端发「番茄要坏掉了」通知（回来自动撤掉）。网页版离开时用 beforeunload 确认，装到桌面且允许通知时用 Service Worker 弹通知。还没在真机上测过。
- 「身体不行」已并进 burnout：旧数据里有 `body` 的晚上读进来时算 burnout（`normFlags`），统计里那一格换成「专注番茄」，分享图第二行是 Burnout + 专注，小组件只显示 burnout。今晚的「从愿望清单里买」点一下记一笔（item 带 `wishId`）并把愿望勾成买到了，删掉这一笔愿望会回到清单。
