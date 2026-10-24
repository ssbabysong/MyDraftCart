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
- 底部菜单 4 个：今天（顶上是日历，默认只显示一周 `.cal.wk-mode`，「展开月历」看整月，`overtime-cal-open` 记住；点哪天下面的计划和花销就切到哪天；标题处切到「统计」，商品墙也在统计页）/ 目标（tab id `focus`，只有目标）/ 番茄（tab id `timer`，大番茄表盘 + 时长）/ 愿望。设置和历史记录、备份（tab `records`）从右上角时钟上方的小齿轮 `.gear` 进去。旧的 `#calendar` 链接落到今天。
- 番茄专注：专注记录存 `overtime-focus-v1`（`{id, start, end, min, wishId?}`），和每晚记录、愿望一样进备份和 iCloud 三方合并；进行中的番茄 `overtime-focus-run` 只存在本机，按时间戳算剩余时间。愿望可设 `focusGoal`（分钟），绑定它的专注攒够了才解锁。专注时不能离开：不能收起，切出 App / 锁屏 / 关掉 App 超过 10 秒（`GRACE`）番茄就坏掉（phase `broken`，不计入）；休息结束用本地通知 id 900。App 里专注时用 `MainViewController.swift` 里的 KeepAwake 插件：关掉自动锁屏、回桌面和下拉要滑两次（`preferredScreenEdgesDeferringSystemGestures`）、进后台那一刻由原生端发「番茄要坏掉了」通知（回来自动撤掉）。网页版离开时用 beforeunload 确认，装到桌面且允许通知时用 Service Worker 弹通知。还没在真机上测过。
- 「身体不行」已并进 burnout：旧数据里有 `body` 的晚上读进来时算 burnout（`normFlags`），统计里那一格换成「专注番茄」，分享图第二行是 Burnout + 专注，小组件只显示 burnout。今晚的「从愿望清单里买」点一下记一笔（item 带 `wishId`）并把愿望勾成买到了，删掉这一笔愿望会回到清单。
- 今天页的花销卡片：Burnout 是「备注」旁边的小标签（`.burn-chip`）。记账是一行「买了什么 / 金额 / +」，下面两行横向滑动的快捷项：「常买」（`quickList`：按自己记过的次数排前 8 个，金额取最近一次，不够用默认补）和「愿望」，点一下直接记一笔。
- 番茄页只留：表盘、时长、为了哪个愿望（没有带专注目标的愿望时隐藏）、开始按钮。统计和番茄记录不在这页（日历里能看到每天的番茄）。
- 2026-10-24 起定位改成面向「上班族自学」的学习 App（名字还没改，`APP_ZH` / `APP_EN` 一处改）。今天页 = 今日计划（`overtime-tasks-v1`：`{id, date, title, done, doneAt?, created}`，没做完的自动带到之后的今天；点「专注」小按钮开番茄，番茄记 `taskId`，完成页可以顺手把那件事勾掉）+ 今天专注了多少 + 花销卡片。计划同样进备份和 iCloud 合并。下班时间不再输入（旧数据保留）。统计：专注时长 / 番茄 / 做完的事 / 总花费 / 平均每天花 / Burnout 天数，外加「专注过的日子 vs 没专注的日子平均花多少」。分享图叫「学习账单」。小组件：本月番茄数、今天专注时长、学习日历（按专注分钟分档）、近 14 天花费。
- 目标（专注页下方，`overtime-goals-v1`：`{id, title, start, end?, closed, closedAt?, checks, created}`）：番茄和计划可以挂 `goalId`；打卡 = 那天为它专注过 / 做完了属于它的计划 / 手动点「打卡」；卡片里是 GitHub 那种打卡小点点（没打卡是小灰点，打卡的绿点按专注分钟分 4 档，最近半年，至少画 8 周，截止日前是空心小圈）、专注时长、打卡天数、这段时间（开始到今天或完成那天）的总花销。「完成目标」后收进「已完成的目标」，可以重新打开或删除。同样进备份和 iCloud。
- 主题「铅笔」（`data-skin="pencil"`）是新用户的默认主题：手绘但极简——米白纸、细浅线（`--bc`）、卡片保留手绘的不规则边，小控件用胶囊 / 圆形；没有阴影、胶带、倾斜和方格纸；主按钮深色实心，强调色只有番茄红；正文黑体，标题和数字手写。之前选过主题的用户保持原样，「方格本」等还在设置里。
- 2026-10-24 简化：番茄只归属目标（从计划或目标卡片的「专注」开；番茄钟本身没有下拉框）。愿望不再绑定番茄，`focusFor(w)` = 许愿之后所有专注分钟（旧数据里绑定过 `wishId` 的也算），完成页顺带显示解锁了哪个愿望或离最近的还差多少。今天页的花销卡片默认收起成一行（`overtime-spend-open` 记住展开状态），计划的目标下拉框只在输入时出现。
- 今日计划按目标分组（`renderPlan`）：每个进行中的目标一组，组头显示今天为它开的番茄数和是否已打卡，组里「+ 加一件事」直接加到这个目标；没目标的事在「其他」，底部输入框加的就是「其他」。目标页：目标卡片（打卡点点、专注、打卡天数、这段时间花销、最近做完的 3 件事）在上，番茄钟（只调时长 + 随便专注一下）在下。
- 开番茄（计划 / 目标 / 番茄页）前会弹「这个番茄攒给…」面板（`startWithWish`），列出还锁着的愿望和进度，上次选的排第一；选了的番茄记 `wishId`，愿望进度只算这些（`focusFor`）。再来一个 / 重新开始沿用上一个番茄的愿望（解锁了就不再沿用）。没有锁着的愿望就直接开始。
