# 给 App Review 的说明（Guideline 2.1 补充资料）

把下面「回复内容」整段复制两处：
1. App Store Connect → 这次提交下方的 Messages 里点回复，粘贴，并附上真机录屏；
2. App 版本页面 →「App 审核信息」→「备注」（Notes），以后每次提交都会带上。

---

## 回复内容（English）

Hello, thank you for reviewing Overtime Night Log. Please find the requested information below. A screen recording captured on a physical iPhone running the latest iOS is attached.

**1. Screen recording**
Attached. It starts by launching the app from the Home Screen and shows the typical flow: logging tonight's purchases and finish time, marking a burnout / unwell night, the Calendar (month view, day details, Items view), Stats and the shareable monthly bill, the Wishlist, Settings (language, currency, theme, nightly reminder) and the Home Screen widget.
The app has no account registration or login, no user-generated content shared with other users, and no paid content or in-app purchases.

**2. Purpose and target audience**
Overtime Night Log is a personal journal for people who often work late, such as office workers, engineers and students. On late nights people tend to spend small amounts on coffee, takeout and rides home, and they rarely notice how much it adds up to or how often they feel burned out. The app lets them log each overtime night in a few seconds (what they bought, how much it cost, when they left work, and whether they felt burned out or physically unwell) and then shows the month in a calendar, statistics and a shareable monthly summary. The value is awareness: seeing the real cost of overtime in money and wellbeing, so users can take better care of themselves.

**3. How to access the main features**
No login, credentials or sample files are needed. The app works immediately after launch.
- To see the app with data quickly: open the **Log** tab (bottom right), scroll to History and tap **Load sample data**. This fills in two weeks of example nights.
- **Tonight** tab: add an item and amount, tap Add; set "Left work at"; tap the Burnout / Unwell cards to mark the night.
- **Calendar** tab: darker days mean more spending; tap a day to see its details; switch to **Items** to see everything bought this month.
- **Stats** tab: monthly totals; tap **Make my monthly overtime bill** to generate and share an image.
- **Wishes** tab: add things you want with a price and tick them off.
- **Log** tab → **Settings**: language (English / 中文), currency and exchange rate, six visual themes, and the nightly reminder (asks for notification permission).
- **Widget**: touch and hold the Home Screen → + → search "Overtime Night Log" (small and medium sizes).

**4. External services**
The app does not use any third-party service, server, SDK, analytics, advertising, AI service or payment processor. It only uses Apple frameworks:
- iCloud key-value storage (NSUbiquitousKeyValueStore) to sync the user's own records across their devices;
- local notifications (UserNotifications) for the optional nightly reminder;
- WidgetKit and an App Group for the Home Screen widget.
Handwriting font files are downloaded from Google Fonts; these requests contain no user data. All records are stored on the device and in the user's own iCloud; the developer has no access to them.

**5. Regional differences**
The app functions identically in all regions where it is available. The interface is available in English and Simplified Chinese, and users can choose the currency used to display amounts. The app is not offered in mainland China.

**6. Regulated industries / third-party material**
Not applicable. The app is a personal journal; it does not provide financial, medical or other regulated services, and it does not include protected third-party material. Amounts are only the user's own notes, not transactions.

Thank you!

---

## 录屏要录什么（约 1–2 分钟）

用 iPhone 自带的录屏：「设置 → 控制中心」里加上「屏幕录制」，从屏幕右上角下拉打开控制中心，点录制按钮，3 秒后开始。

1. **从桌面点开「加班夜记」**（苹果要求必须从启动 App 开始）
2. 今晚：记一笔（比如「拿铁 6」）、设下班时间、点一下 Burnout 和身体不适
3. 日历：点某一天看详情，切到「商品」
4. 统计：点「生成我的月度加班账单」，点分享（可以直接取消）
5. 愿望：添加一个愿望，勾掉
6. 记录 → 设置：切换一下英文 / 中文、换一个主题、打开每晚提醒（允许通知）
7. 回到桌面，长按空白处 → 左上角「+」→ 搜索「加班夜记」，展示小组件
8. 停止录制（视频会存到「照片」）

提示：如果手机里没什么数据，先在「记录」页点「载入示例数据」，录出来更好看，但第 2 步记一笔的操作要录进去。录完在照片里剪掉开头和结尾多余的部分。
