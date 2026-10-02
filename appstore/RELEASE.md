# 上架 App Store 步骤 · 加班夜记

全程在你的 Mac 上操作。第一次大约需要 1–2 小时，之后每次更新 10 分钟左右。

## 0. 准备

- 最新版 **Xcode**（App Store 里免费下载）
- **Node.js** 20 以上：https://nodejs.org 下载 LTS 版安装
- 已经付费的 Apple 开发者账号（你已经有了）

## 1. 拿到代码，打开 Xcode 工程

打开「终端」，依次运行：

```bash
git clone https://github.com/ssbabysong/MyDraftCart.git
cd MyDraftCart
git checkout claude/app-development-b8g0mq   # 如果已经合并到 main，就跳过这一行
npm install
npm run ios
```

最后一条命令会把网页打包进 App，并自动打开 Xcode。第一次打开时，Xcode 会下载 Capacitor 的依赖包，左下角会转一会儿圈，等它结束。

## 2. 配置签名（只做一次）

在 Xcode 左侧点最上面蓝色的 **App** 工程，然后：

**App 这个 target**
1. 选中 TARGETS 里的 **App** → 顶部 **Signing & Capabilities**
2. 勾选 **Automatically manage signing**，**Team** 选你的开发者账号
3. Bundle Identifier 应该是 `com.ssbabysong.overtimenightlog`（如果提示已被占用，改成别的，比如 `com.你的名字.overtimenightlog`，下面所有地方都跟着改）
4. 下面应该能看到 **iCloud** 和 **App Groups** 两项能力：
   - iCloud：勾选 **Key-value storage**
   - App Groups：勾选 `group.com.ssbabysong.overtimenightlog`
   - 如果没有显示，点左上角 **+ Capability** 分别加上，再勾选

**OvertimeWidget 这个 target**（桌面小组件）
1. 选中 TARGETS 里的 **OvertimeWidget** → **Signing & Capabilities**
2. 同样勾选自动签名，选同一个 Team
3. Bundle Identifier 是 `com.ssbabysong.overtimenightlog.widget`
4. **App Groups** 勾选同一个 `group.com.ssbabysong.overtimenightlog`

## 3. 先在手机上试一试

1. 用数据线连上 iPhone（第一次需要在 iPhone「设置 → 隐私与安全性 → 开发者模式」打开）
2. Xcode 顶部选择你的 iPhone，点 ▶ 运行
3. 检查这几样：
   - 记几笔，看日历、统计、愿望清单是否正常
   - 「记录 → 设置 → 每晚提醒」打开，系统会询问通知权限
   - 「记录 → 备份」里能看到「已同步到 iCloud」
   - 回到桌面，长按空白处 →「+」→ 搜「加班夜记」，添加小组件
   - 换一个主题，状态栏文字颜色是否跟着变

**编译报错怎么办**：把 Xcode 左侧红色错误的截图发给我，我来改。

## 会员还没开通？先用免费账号在手机上测试

开发者会员开通前（developer.apple.com 显示 Pending），Xcode 里只有免费的「Personal Team」，它不支持 iCloud。可以先切到测试模式：

```bash
npm run ios:free
```

- Bundle ID 会变成 `com.ssbabysong.overtimenightlog.dev`，不占用正式 ID
- iCloud 同步和小组件数据共享暂时关闭；提醒、震动、分享、主题等都能测
- 两个 target 的 Team 都选 **Personal Team**
- 免费账号装的 App 7 天后会失效，到时重新运行一次就行
- 测试模式里记的数据不会带到正式版

会员开通后切回正式模式，Team 改选付费账号：

```bash
npm run ios:paid
```

## 4. 在 App Store Connect 创建 App

1. 打开 https://appstoreconnect.apple.com →「App」→ 左上角「+」→「新建 App」
2. 平台：iOS；名称：**加班夜记**（如果被占用，可以用「加班夜记 Overtime」）；主要语言：简体中文；套装 ID：选 `com.ssbabysong.overtimenightlog`；SKU：`overtime-night-log`
3. 按 `appstore/metadata.md` 填写：副标题、描述、关键词、类别、隐私政策网址、技术支持网址
4. 再点右上角语言菜单，添加「英文（美国）」，填英文那一份
5. **App 隐私**：选择「不收集数据」
6. **价格与销售范围**：免费；地区全选，然后取消「中国大陆」
7. 截图：上传 `appstore/screenshots/` 里对应语言的 6 张图到「6.9 英寸显示屏」

> 隐私政策和技术支持网址需要 GitHub Pages 已经开启。请确认在浏览器里能打开这两个网址。

## 5. 打包上传

1. Xcode 顶部的设备选择 **Any iOS Device (arm64)**
2. 菜单 **Product → Archive**，等几分钟
3. 弹出的 Organizer 窗口里选刚才的包 → **Distribute App** → **App Store Connect** → 一路「Next / Upload」
4. 上传后等 10–30 分钟，App Store Connect 里的「构建版本」会出现这个版本（会收到邮件）

## 6. 提交审核

1. 在 App Store Connect 的版本页面，「构建版本」选刚上传的那个
2. 「App 审核信息」的备注里，粘贴 `metadata.md` 最后那段英文说明
3. 点右上角 **提交以供审核**

审核一般 1–3 天。被拒的话，把苹果的拒绝理由发给我，我来改。

---

## 以后更新 App

1. 让我改代码，或者自己改 `index.html`
2. Xcode 里把 App 和 OvertimeWidget 两个 target 的 **Version** 改成新的版本号（比如 1.1），**Build** 加 1
3. 终端运行 `npm run ios`
4. 重复第 5、6 步

网页版（GitHub Pages）和 App 用的是同一份 `index.html`，改一次两边都有。
