# 加班夜记

一个手绘风的小本子，记录每晚加班：

- 买了什么、花了多少钱
- Burnout 了几次、身体不行了几次（用「正」字计数）
- 几点下班、备注

带月历视图、本周 / 本月统计，还有最近 14 晚的花费走势。

**数据只存在你自己的设备上**，不会上传到任何服务器。可以在页面底部导出 / 导入备份。

## 安装到手机

打开 App 的网址后：

- **iPhone（Safari）**：点底部的「分享」按钮 → 「添加到主屏幕」
- **安卓（Chrome）**：点右上角 ⋮ → 「添加到主屏幕」或「安装应用」
- **电脑（Chrome / Edge）**：地址栏右侧的安装图标

装好以后，从桌面图标打开是全屏的，断网也能用。

## 文件

| 文件 | 作用 |
| --- | --- |
| `index.html` | 整个 App（页面、样式、逻辑都在这一个文件里） |
| `manifest.webmanifest` | App 名称、图标、全屏显示设置 |
| `sw.js` | 离线缓存。改了 `index.html` 后把里面的 `VERSION` 加一，用户下次打开就会更新 |
| `icons/` | 桌面图标 |

## 发布（GitHub Pages）

仓库 Settings → Pages → Build and deployment → Source 选 **Deploy from a branch**，
Branch 选 `main`、目录 `/ (root)`，保存。一两分钟后 App 就在
`https://<你的用户名>.github.io/<仓库名>/` 上线了。
