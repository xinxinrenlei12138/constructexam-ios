import SwiftUI
import UIKit
import WebKit

// MARK: - 配置

/// 壳的常量。**这里只有三处与 Android 侧耦合**，改动前先看 `NativeBridge.kt` 的注释。
enum ShellConfig {
    /// 内容层所在位置。
    ///
    /// ⚠️ 必须是 **HTTPS**，且页面里的 `/api/`、`/page/`、`/page-img/`
    /// 与它**同源** —— 这一条直接决定了下面 nativeShim 里 HTTP 走 fetch 还是走原生。
    static let contentURL = URL(string: "https://constructexam.cadqto.com/app/")!

    /// App 版本号。页面「更多 → 关于」会显示它（app.js:443 的 `APP_VERSION` 取自这里）。
    ///
    /// ⚠️ **不再手写**（2026-09-26 改）。此前这里是 `= "1.5.0"`，与 Android 侧
    ///    `app/build.gradle.kts` 的 `versionName` 各写一份 —— 而它**已经静默漂了七轮**
    ///    （APK 走到 1.12.0 了，iOS 仍报 1.5.0），用户在两台设备上看到的版本号互相矛盾，
    ///    且**没有任何一处会报错**。这正是本项目反复强调的
    ///    「手工维护的第二真相来源必然漂移，而且不报错」。
    ///
    /// 改成**运行时读自己的 Info.plist**：`ios/project.yml` 的 `MARKETING_VERSION`
    /// 由 Xcode 写进生成的 `CFBundleShortVersionString`（`GENERATE_INFOPLIST_FILE: YES`
    /// 时 Xcode 会自动把 `$(MARKETING_VERSION)` 填进去）→ 版本号**只剩一个源**，
    /// 也就不会再出现"两个地方要一起改"这种约定。
    ///
    /// ⚠️ 读不到时**不编一个像样的版本号**，而是回一个显眼的 `unknown`：
    ///    版本号对不上比"明说读不到"难查得多（同 app.js 的 `APP_VERSION || "?"`）。
    ///    `?? "—"` 那种写法看起来"优雅"，实则把失败伪装成一个正常值。
    static let appVersion: String = {
        guard let v = (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String)?
            .trimmingCharacters(in: .whitespacesAndNewlines), !v.isEmpty else {
            return "unknown"
        }
        return v
    }()

    /// 原生消息通道名。JS 侧写作 `window.webkit.messageHandlers.cex`。
    /// ⚠️ 与 Android 的方法名不同名是**有意的**：Android 是「对象直调」，
    ///    iOS 只有「消息通道」，二者不是同一个机制，硬凑同名反而会让人误以为是同一套。
    static let messageHandler = "cex"
}

// MARK: - 注入页面的原生垫片

/// 在 `documentStart` 注入，把 `window.Native` 造出来。
///
/// ## 为什么必须是「注入 JS」，而不是「注入一个原生对象」
/// iOS **没有** Android 的 `addJavascriptInterface` —— 原生对象无法凭空出现在 JS 全局里。
/// 所以这里的做法是：用一段脚本把 `window.Native` 定义出来，
/// 能同步回答的（版本号）给常量，需要真原生的（剪贴板）走 `postMessage`。
///
/// ## 契约与 Android 侧逐字对齐（见 `web/NativeBridge.kt`）
/// ```
/// Native.httpGet(path, cbId)
/// Native.httpPost(path, bodyStr, cbId)
/// Native.copyText(text) -> Bool     // 同步返回
/// Native.appVersion()   -> String   // 同步返回
/// 回传：window.__nativeResult(cbId, ok, body)   // ok 只认 2xx
/// ```
/// ⚠️ `nativeGet / nativePost / pending / __nativeResult / seq` 这几个名字被
/// `tools/verify_cdp.py` 的探针断言依赖，**不许改名**。
///
/// ## 与 Android 的**一处有意不同**：HTTP 走页面自己的同源 `fetch`，不经原生
/// · Android 必须经原生 —— 它的页面在 `file://` / assetloader 源下，
///   `fetch` 会被同源策略拦，这是硬约束（`NativeBridge.kt` 开头就写了这件事）。
/// · iOS 这一版把页面放在 `constructexam.cadqto.com/app/` 上，
///   而 `/api/` 就在同一个域 → **fetch 直接可用，连 CORS 都不涉及**。
/// · 于是省掉了「大响应体 → JS 字符串转义 → evaluateJavaScript」这条
///   又慢又脆的路（教材页级原文单页可达数百 KB）。
/// · 代价写在 README「已知耦合」一节：**若将来改成把 www 打进包，这段要改回走原生**。
///
/// ## 一处必须保留的判据（照抄 Android 的教训）
/// **桥的每一层出口都必须能落到一个回调上。** 宁可回一个难看的错误字符串，
/// 也绝不能什么都不回 —— 什么都不回 = Promise 永远 pending = 页面停在「加载中」，
/// 而且日志里什么都没有。这是本项目最忌讳的失败形态。
private let nativeShim: String = {
    let version = ShellConfig.appVersion
    let channel = ShellConfig.messageHandler
    return """
(function () {
  if (window.Native) return;
  function post(payload) {
    try { window.webkit.messageHandlers.\(channel).postMessage(payload); return true; }
    catch (e) { return false; }
  }
  function send(path, options, cbId) {
    fetch(path, options).then(function (r) {
      return r.text().then(function (body) {
        window.__nativeResult(cbId, r.status >= 200 && r.status < 300, body);
      });
    }).catch(function (e) {
      window.__nativeResult(cbId, false, "无法连接服务器（" + ((e && e.message) || e) + "）");
    });
  }
  window.Native = {
    appVersion: function () { return "\(version)"; },
    copyText: function (text) {
      return post({ cmd: "copy", text: String(text == null ? "" : text) });
    },
    httpGet: function (path, cbId) {
      send(path, { method: "GET", headers: { "Accept": "application/json" } }, cbId);
    },
    httpPost: function (path, bodyStr, cbId) {
      send(path, {
        method: "POST",
        headers: { "Content-Type": "application/json", "Accept": "application/json" },
        body: bodyStr
      }, cbId);
    }
  };
})();
"""
}()

/// 首屏加载失败时的兜底页。
///
/// ⚠️ 不做这个兜底的话，断网启动就是**一片白**：没有报错、没有重试、用户只能杀进程。
/// 这正是本项目反复强调要避免的「静默失败」，所以在第一屏就把它堵掉。
private let loadFailureHTML: String = {
    let url = ShellConfig.contentURL.absoluteString
    return """
<!DOCTYPE html><html lang="zh-CN"><head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1,viewport-fit=cover">
<meta name="color-scheme" content="light dark">
<style>
  body{margin:0;height:100vh;display:flex;align-items:center;justify-content:center;
       font:15px/1.7 -apple-system,system-ui,sans-serif;
       background:#ffffff;color:#1f2328}
  @media (prefers-color-scheme:dark){body{background:#16181d;color:#e6e6e6}}
  .box{padding:0 32px;text-align:center;max-width:420px}
  h1{font-size:17px;font-weight:500;margin:0 0 12px}
  p{margin:0 0 20px;opacity:.7;font-size:14px}
  a{display:inline-block;padding:10px 22px;border-radius:8px;text-decoration:none;
    border:1px solid currentColor;color:inherit;font-size:14px}
</style></head><body>
<div class="box">
  <h1>没能连上服务器</h1>
  <p>题目与解析都在服务器上。请确认网络可用后重试。</p>
  <a href="\(url)">重试</a>
</div>
</body></html>
"""
}()

// MARK: - SwiftUI 包装

/// 整个 App 就是这一屏：一块把整屏让给网页的 WKWebView。
///
/// ⚠️ **不给它加导航栏、不加 TabBar** —— 导航全部由页面自己负责
///    （`index.html` 有自绘的 header / 底部 tab / 返回按钮）。
///    壳的职责只有三件：上屏、给原生能力、保证不会白屏。
struct ShellWebView: UIViewRepresentable {

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> WKWebView {
        let controller = WKUserContentController()
        controller.addUserScript(
            WKUserScript(source: nativeShim, injectionTime: .atDocumentStart, forMainFrameOnly: true)
        )
        controller.add(context.coordinator, name: ShellConfig.messageHandler)

        let config = WKWebViewConfiguration()
        config.userContentController = controller
        // 持久化存储：本 App 把学习进度放 localStorage、题库与教材页缓存放 IndexedDB
        // （实测 13 处 localStorage + 16 处 IndexedDB）。默认值就是持久的，
        // 这里显式写出来是**为了它不被后人顺手改成 .nonPersistent()**。
        config.websiteDataStore = .default()
        config.allowsInlineMediaPlayback = true

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator

        // 本 App **不用 URL 路由**（无 pushState / location.hash / onhashchange），
        // 所以 WKWebView 里根本没有「历史」可回 —— 侧滑手势会表现为「划了没反应」。
        // 返回由页面自绘的 `#backBtn` 负责（app.js 的 updNav()）。
        // ⚠️ 因此这里**故意关掉**，而不是开着一个注定无效的手势。
        webView.allowsBackForwardNavigationGestures = false

        // 页面自己处理安全区（app.css 里 `--safe-t/--safe-b` 取自
        // env(safe-area-inset-*)，且 index.html 的 viewport 带 viewport-fit=cover）
        // → 壳必须把**整屏**交给它，不能自己再让一次。
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear

        context.coordinator.webView = webView
        webView.load(URLRequest(url: ShellConfig.contentURL))
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    // MARK: Coordinator

    final class Coordinator: NSObject, WKScriptMessageHandler, WKNavigationDelegate {

        weak var webView: WKWebView?

        // MARK: 来自 JS 的原生调用

        func userContentController(_ controller: WKUserContentController,
                                  didReceive message: WKScriptMessage) {
            guard let body = message.body as? [String: Any],
                  let cmd = body["cmd"] as? String else { return }
            switch cmd {
            case "copy":
                // `UIPasteboard` 是系统 API，行为确定。
                // 不用网页侧 `navigator.clipboard.writeText()` 的理由与 Android 侧相同：
                // 它额外要求「在用户手势的调用栈里」，各版本宽容度不一致 →
                // 同一份代码有的设备能复制、有的静默失败。复制是用户明确要结果的动作，
                // 不该建立在「大概能行」上。
                UIPasteboard.general.string = body["text"] as? String ?? ""
            case "openExternal":
                if let raw = body["url"] as? String, let url = URL(string: raw) {
                    UIApplication.shared.open(url)
                }
            default:
                break
            }
        }

        // MARK: 白屏自恢复（这条不是可选项）

        /// WKWebView 的 WebContent 进程被系统回收后**不会自己恢复** —— 表现为白屏。
        /// 触发场景非常日常：长时间停留 + 反复切前后台。
        /// 处理办法只有一个：重新加载。
        func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
            webView.reload()
        }

        // MARK: 首屏失败兜底

        /// 首屏（或任何一次主框架导航）连不上 → 换成一张能重试的页面。
        /// ⚠️ 只处理**主框架**：某个 /page-img/ 页图 404 不该把整个页面换掉。
        func webView(_ webView: WKWebView,
                     didFailProvisionalNavigation navigation: WKNavigation!,
                     withError error: Error) {
            showLoadFailure(webView)
        }

        func webView(_ webView: WKWebView,
                     didFail navigation: WKNavigation!,
                     withError error: Error) {
            showLoadFailure(webView)
        }

        private func showLoadFailure(_ webView: WKWebView) {
            // 已经在兜底页上了就不要再刷 —— 否则失败会自我循环。
            if webView.url == nil { return }
            webView.loadHTMLString(loadFailureHTML, baseURL: nil)
        }

        // MARK: 站外链接

        /// 站内导航留在壳里（含兜底页上的「重试」），站外链接交给系统浏览器。
        /// 我们的内容层本来不外跳，这是兜底：将来某条解析里带了个外链，
        /// 也不会把用户困在一个没有地址栏的窗口里出不来。
        ///
        /// ⚠️ 这里刻意用 **async 版本**，而不是老的 `decisionHandler:` 版本。
        ///    原因：老版本那个闭包参数在新 SDK 里被标成了 `@MainActor`，
        ///    于是「我按旧签名实现」与「SDK 要求新签名」会直接变成
        ///    `does not conform to protocol` 这种硬错误 ——
        ///    而本机**没有 iOS SDK 可以试错**。
        ///    async 版本（iOS 15+）没有闭包参数，也就没有这层歧义。
        ///    → 判据：**没有编译器可以试错时，优先选签名歧义最小的那个写法。**
        ///
        /// ⚠️⚠️ `open(_:)` **必须写 `await`** —— 这一条是被 CI 教会的（2026-09-23）：
        ///    我原先以为「不加 await 就会落到带默认参数的同步重载上」，
        ///    实际报错是 `expression is 'async' but is not marked with 'await'`。
        ///    原因是**在 async 上下文里，同名重载会优先选 async 版本**，
        ///    与"参数给了默认值"无关。
        ///    → 判据：**同一个 API 同时有同步与 async 重载时，"要不要 await"由所处上下文决定，
        ///      不能凭"哪个更明确"来猜。**（这类判断只能靠编译器给答案。）
        func webView(_ webView: WKWebView,
                     decidePolicyFor navigationAction: WKNavigationAction) async -> WKNavigationActionPolicy {
            guard navigationAction.navigationType == .linkActivated,
                  let url = navigationAction.request.url,
                  url.scheme == "http" || url.scheme == "https",
                  url.host != ShellConfig.contentURL.host else {
                return .allow
            }
            await UIApplication.shared.open(url)
            return .cancel
        }
    }
}
