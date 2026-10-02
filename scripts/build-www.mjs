// 把网页版 App 复制到 www/，给 Capacitor 打包进 iOS App。网页版（GitHub Pages）直接用仓库根目录的文件，不受影响。
import { cpSync, rmSync, mkdirSync } from "node:fs";
rmSync("www", { recursive: true, force: true });
mkdirSync("www");
for (const f of ["index.html", "manifest.webmanifest", "icons"]) cpSync(f, `www/${f}`, { recursive: true });
console.log("www/ ready");
