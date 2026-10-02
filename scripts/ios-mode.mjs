// 切换 iOS 工程的签名模式：
//   node scripts/ios-mode.mjs free   免费 Apple ID（Personal Team）也能装到自己手机上测试：
//                                    关掉 iCloud / App Group 权限，Bundle ID 加 .dev，避免占用正式 ID
//   node scripts/ios-mode.mjs paid   正式模式（付费开发者账号，上架用）
import { readFileSync, writeFileSync } from "node:fs";

const mode = process.argv[2];
if (mode !== "free" && mode !== "paid") { console.error("用法：node scripts/ios-mode.mjs free|paid"); process.exit(1); }

const ID = "com.ssbabysong.overtimenightlog";
const PBX = "ios/App/App.xcodeproj/project.pbxproj";
const PLIST = "ios/App/App/Info.plist";
const MAP = [
  // [正式模式, 测试模式]
  [`PRODUCT_BUNDLE_IDENTIFIER = ${ID}.widget;`, `PRODUCT_BUNDLE_IDENTIFIER = ${ID}.dev.widget;`],
  [`PRODUCT_BUNDLE_IDENTIFIER = ${ID};`, `PRODUCT_BUNDLE_IDENTIFIER = ${ID}.dev;`],
  ["CODE_SIGN_ENTITLEMENTS = App/App.entitlements;", "CODE_SIGN_ENTITLEMENTS = \"\"; /* free:App */"],
  ["CODE_SIGN_ENTITLEMENTS = OvertimeWidget/OvertimeWidget.entitlements;", "CODE_SIGN_ENTITLEMENTS = \"\"; /* free:Widget */"],
];

let pbx = readFileSync(PBX, "utf8");
for (const [paid, free] of MAP) pbx = mode === "free" ? pbx.split(paid).join(free) : pbx.split(free).join(paid);
writeFileSync(PBX, pbx);

// Info.plist 里的标记让 App 知道自己处于测试模式（iCloud 同步显示为已关闭）
let plist = readFileSync(PLIST, "utf8").replace(/\s*<key>OvertimeFreeMode<\/key>\s*<true\/>/, "");
if (mode === "free") plist = plist.replace(/<dict>/, "<dict>\n\t<key>OvertimeFreeMode</key>\n\t<true/>");
writeFileSync(PLIST, plist);

console.log(mode === "free"
  ? `已切到测试模式：Bundle ID ${ID}.dev，iCloud 和小组件数据共享已关闭。在 Xcode 里 Team 选 Personal Team。`
  : `已切到正式模式：Bundle ID ${ID}，iCloud 和 App Group 已打开。在 Xcode 里 Team 选付费开发者账号。`);
