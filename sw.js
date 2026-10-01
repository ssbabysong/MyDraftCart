// 加班夜记 service worker：离线可用 + 安全更新。
// 发布新版本时只需把 VERSION 加一：打开中的 App 会弹出「有新版本」提示，点一下就换上新界面。
// 这里只缓存 App 本身的文件；你的记录存在 localStorage 里，更新和清理缓存都不会碰到它。
const VERSION = "v13";
const SHELL = `shell-${VERSION}`;
const FONTS = "fonts";
const ASSETS = ["./", "manifest.webmanifest", "icons/icon.svg", "icons/icon-180.png", "icons/icon-192.png", "icons/icon-512.png"];

self.addEventListener("install", (e) => {
  // cache: "reload" 跳过浏览器自己的 HTTP 缓存，保证装进来的是服务器上的最新文件
  e.waitUntil(caches.open(SHELL).then((c) => c.addAll(ASSETS.map((u) => new Request(u, { cache: "reload" })))));
  // 不自动 skipWaiting：等页面上点了「更新」再切换，避免用到一半界面突然变了
});

self.addEventListener("message", (e) => {
  if (e.data === "skipWaiting") self.skipWaiting();
  if (e.data === "version" && e.ports[0]) e.ports[0].postMessage(VERSION);
});

self.addEventListener("activate", (e) => {
  e.waitUntil(
    caches.keys()
      .then((keys) => Promise.all(keys.filter((k) => k.startsWith("shell-") && k !== SHELL).map((k) => caches.delete(k))))
      .then(() => self.clients.claim())
  );
});

self.addEventListener("fetch", (e) => {
  const req = e.request;
  if (req.method !== "GET") return;
  const url = new URL(req.url);

  // 手写字体：先用缓存，后台更新
  if (url.hostname === "fonts.googleapis.com" || url.hostname === "fonts.gstatic.com") {
    e.respondWith(caches.open(FONTS).then(async (c) => {
      const hit = await c.match(req);
      const net = fetch(req).then((r) => { if (r.ok || r.type === "opaque") c.put(req, r.clone()); return r; }).catch(() => hit);
      return hit || net;
    }));
    return;
  }
  if (url.origin !== location.origin) return;

  // 页面：有网就向服务器确认最新版（no-cache 会绕过 10 分钟的浏览器缓存），断网才用缓存
  if (req.mode === "navigate") {
    e.respondWith(
      fetch(req.url, { cache: "no-cache" })
        .then((r) => {
          if (r.ok) { const copy = r.clone(); caches.open(SHELL).then((c) => c.put("./", copy)); }
          return r;
        })
        .catch(() => caches.match("./", { ignoreSearch: true }))
    );
    return;
  }
  e.respondWith(caches.match(req).then((hit) => hit || fetch(req)));
});
