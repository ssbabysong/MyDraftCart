// 生成 App Store 的 Header（3840×1646）和搜索结果图（1920×1280），中英文各一版。
// 用法：node appstore/promo/make.mjs   （需要本机装有 Google Chrome，会联网加载 Google Fonts）
import { writeFileSync, mkdirSync } from "node:fs";
import { execFileSync } from "node:child_process";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const here = dirname(fileURLToPath(import.meta.url));
const shots = join(here, "../screenshots");
const out = join(here, "out");
const tmp = join(here, ".html");
mkdirSync(out, { recursive: true });
mkdirSync(tmp, { recursive: true });
const CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome";

const TEXT = {
  zh: {
    eyebrow: "Overtime Night Log", title: "加班<span class='hl'>夜记</span>",
    q1: "今晚加班，", q2: "花了<span class='mark'>多少</span>？",
    sub: "外卖、咖啡、打车回家……<br>10 秒记一笔，月底看清自己。",
    tag: "记下每晚加班花了多少、累不累",
  },
  en: {
    eyebrow: "late-night spending log", title: "Overtime <span class='hl'>Night Log</span>",
    q1: "What did tonight's", q2: "overtime <span class='mark'>cost</span> you?",
    sub: "Takeout, coffee, the ride home. Log it in 10 seconds and see your month.",
    tag: "Log the cost of late nights, in money and in burnouts",
  },
};

const css = (unit) => `
@import url("https://fonts.googleapis.com/css2?family=Ma+Shan+Zheng&family=ZCOOL+KuaiLe&family=Patrick+Hand&display=swap");
*{box-sizing:border-box;margin:0}
html,body{width:100%;height:100%;overflow:hidden}
body{background:#FAFAF4;background-image:linear-gradient(#DCE6EF ${unit * .05}px,transparent ${unit * .05}px),linear-gradient(90deg,#DCE6EF ${unit * .05}px,transparent ${unit * .05}px);background-size:${unit}px ${unit}px;color:#26354D;font-family:"ZCOOL KuaiLe","Patrick Hand",sans-serif;position:relative}
.en{font-family:"Patrick Hand","ZCOOL KuaiLe",sans-serif}
.title{font-family:"Ma Shan Zheng",cursive;font-weight:400;line-height:1;transform:rotate(-2deg);transform-origin:left bottom;white-space:nowrap}
.hl{background:linear-gradient(transparent 60%,#F6C9C3 60%,#F6C9C3 90%,transparent 90%);padding:0 .08em}
.mark{background:linear-gradient(transparent 52%,#F5C21B 52%,#F5C21B 90%,transparent 90%);padding:0 .06em}
.eyebrow{color:#6E7889;letter-spacing:.06em}
.phone{position:absolute;background:#26354D;border-radius:${unit * 1.5}px;padding:${unit * .22}px;box-shadow:${unit * .3}px ${unit * .36}px 0 #26354D22}
.phone img{display:block;width:100%;border-radius:${unit * 1.3}px}
.tape{position:absolute;background:#F5C21Bcc;height:${unit * .9}px;width:${unit * 4}px;opacity:.75}
`;

function search(lang) {
  const t = TEXT[lang], u = 48;
  return `<!doctype html><meta charset="utf-8"><style>${css(u)}
.copy{position:absolute;left:120px;top:150px;width:980px}
.eyebrow{font-size:40px}
.q{font-size:${lang === "zh" ? 128 : 110}px;line-height:1.18;margin-top:36px;font-weight:700}
.sub{font-size:44px;line-height:1.5;color:#4b5568;margin-top:44px;width:900px}
.brand{position:absolute;left:120px;bottom:110px;font-size:${lang === "zh" ? 92 : 78}px}
</style><body class="${lang}">
<div class="copy"><div class="eyebrow">${t.eyebrow}</div><div class="q">${t.q1}<br>${t.q2}</div><div class="sub">${t.sub}</div></div>
<div class="brand title">${t.title}</div>
<div class="phone" style="left:1240px;top:150px;width:560px;transform:rotate(4deg)"><img src="file://${shots}/${lang}-1-tonight.png"></div>
<div class="tape" style="left:1400px;top:118px;transform:rotate(-3deg)"></div>
</body>`;
}

function header(lang) {
  const t = TEXT[lang], u = 96;
  return `<!doctype html><meta charset="utf-8"><style>${css(u)}
.left{position:absolute;left:300px;top:430px}
.eyebrow{font-size:72px}
.big{font-size:${lang === "zh" ? 330 : 250}px;margin-top:40px}
.tag{font-size:${lang === "zh" ? 96 : 84}px;margin-top:90px;color:#4b5568}
</style><body class="${lang}">
<div class="left"><div class="eyebrow">${t.eyebrow}</div><div class="title big">${t.title}</div><div class="tag">${t.tag}</div></div>
<div class="phone" style="left:2140px;top:260px;width:620px;transform:rotate(-7deg)"><img src="file://${shots}/${lang}-2-calendar.png"></div>
<div class="phone" style="left:3020px;top:300px;width:620px;transform:rotate(7deg)"><img src="file://${shots}/${lang}-4-bill.png"></div>
<div class="phone" style="left:2560px;top:170px;width:680px;transform:rotate(0deg)"><img src="file://${shots}/${lang}-1-tonight.png"></div>
<div class="tape" style="left:2740px;top:120px;transform:rotate(-4deg);width:400px;height:86px"></div>
</body>`;
}

for (const lang of ["zh", "en"]) {
  for (const [name, w, h, html] of [["search", 1920, 1280, search(lang)], ["header", 3840, 1646, header(lang)]]) {
    const file = join(tmp, `${name}-${lang}.html`), png = join(out, `${name}-${lang}-${w}x${h}.png`);
    writeFileSync(file, html);
    execFileSync(CHROME, ["--headless=new", "--disable-gpu", "--hide-scrollbars", "--force-device-scale-factor=1", "--virtual-time-budget=8000", `--window-size=${w},${h}`, `--screenshot=${png}`, `file://${file}`], { stdio: "ignore" });
    console.log("ok", png);
  }
}
