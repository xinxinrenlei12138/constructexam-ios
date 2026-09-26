import XCTest

/// iOS 壳的冒烟测试 —— 在**云端 macOS 的 iOS 模拟器**里跑，不需要 iPad、不需要 Mac 桌面。
///
/// ## 它回答的是哪一个问题
/// 「壳在真 iOS 上能不能起来、内容层能不能渲染出东西」——
/// 这是之前只能靠"拿 iPad 试一下"来回答的那个问题。
/// 至于业务功能（做题、统计、教材定位），主体在内容层 `app.js` 里，
/// 由 `tools/verify_webbridge.js` 在本机 Chromium 上验 —— **分工不同，不要混**。
///
/// ## ⚠️ 为什么断言全部用 `CONTAINS` 而不是精确标签
/// 网页里的元素在无障碍树里长什么样，取决于 WebKit 版本与元素的语义
/// （`<button>` 可能变成 button 而不是 staticText，图标字符可能被并进 label）。
/// 而我在本机**没有 iOS SDK、看不到模拟器**，无法试错。
/// → 判据：**在无法试错的断言里，优先用"包含关系"而不是"完全相等"**。
///
/// ## ⚠️⚠️ 2026-09-26 两次失败换来的一条硬规矩
///
/// **第一次红**：连续 3 次报「找不到『首页』/『统计』/『更多』」，
/// 而同一轮「错题」却能找到 —— 四个里过一个，最容易骗人。
/// 真因（靠**下载失败现场那张截图**才看清，猜是猜不出来的）：
/// 「启动登录」生效后冷启动落在登录页，底部 `<nav>` 因 `display:none`
/// 不在无障碍树里；「错题」是**碰巧**命中登录页说明文字里那两个字
/// （「作答记录与错题会在…」）—— 一次误命中，把结构性失败伪装成标签笔误。
/// → 判据：**测试要跟着"用户真实走的路径"走，不是跟着"页面里有哪些字符串"走。**
///
/// **第二次红**：改完断言之后仍然红，而日志里**一行 XCTAssert 都没有**。
/// 真因是**我自己加的诊断代码**：
/// ```
/// error: Failed to get matching snapshot: No matches found for Element at index 77
/// ```
/// 当时 dump 的写法是「先取一次 `descendants.count`，再按索引逐个读」——
/// 而网页是**活的**：读到第 77 个时页面重绘、树变小 → 索引失效 → XCUITest 抛错，
/// 断言根本没轮到执行。**"诊断代码"自己成了故障源，还伪装成 App 的问题。**
/// → 判据：**读"活的"对象树时，不要用「先取长度、再按索引访问」** ——
///   两次操作之间对象会变。要么一次快照读完（`debugDescription`），
///   要么每次都重新取长度比较。
///
/// **还有一条**：「先不登录，直接刷题」这个选择会被写进 localStorage，
/// 于是**第二次启动不再出现登录页** → 两条测试方法的执行顺序会互相影响。
/// → 所以两条测试都写成**与顺序无关**：登录页在就点掉，不在就直接往下走。
final class ShellSmokeTests: XCTestCase {

    /// 底部导航项的文案。取自 `index.html` 的静态 `<nav>`，
    /// **与服务端接口无关** —— 所以它们验的是"静态资源加载成功"，不受后端故障影响。
    private let tabWords = ["首页", "教材", "错题", "统计", "更多"]

    /// 本次 launch 出来的 App。存成属性是为了让截图/诊断工具能用它，
    /// 而不必把 `XCUIApplication` 一层层往下传。
    private var launchedApp: XCUIApplication!

    override func setUpWithError() throws {
        // 让多条断言都跑完再收口：一次 CI 拿到全部问题，而不是一轮一个。
        // （CI 一次约 5–10 分钟，"一轮一个"是把等待时间乘以问题数。）
        continueAfterFailure = true
    }

    // MARK: - 用例一：壳起来 + 内容层渲染 + 底部导航

    func testShellRendersContentLayer() {

        let web = bootApp()

        dumpTree(web, why: "用例一：页面就绪")

        // ---------- 冷启动的落点 ----------
        // 只有两种合法状态：
        //   ① 登录页（本机没选过「先不登录」）→ 走一次真实的跳过路径
        //   ② 主界面（那个选择被持久化在 localStorage 里了）
        // 「两种都不是」= 壳或内容层坏了 —— 这才是要断言的。
        let skip = descendant(of: web, labelContains: "先不登录")
        if skip.exists || skip.waitForExistence(timeout: 25) {
            print("===> 冷启动落在【登录页】→ 点「先不登录，直接刷题」")
            skip.tap()
        } else {
            print("===> 冷启动直接进【主界面】（「先不登录」的选择已被持久化）")
        }

        // ---------- 断言 1：底部五个导航项都在 ----------
        // 覆盖"登录门禁之后确实进了主界面"这件事。
        var navHits = 0
        for word in tabWords {
            let e = descendant(of: web, labelContains: word)
            let ok = e.waitForExistence(timeout: 30)
            if ok { navHits += 1 }
            XCTAssertTrue(ok, "底部导航里找不到「\(word)」—— 内容层渲染不完整或没进主界面")
        }
        // 兜底：即使个别标签因 WebKit 语义变化而失配，也不该全灭。
        XCTAssertGreaterThanOrEqual(navHits, 3,
            "五个导航项只命中 \(navHits) 个 —— 更像整块没渲染，而不是个别标签变了")

        // ---------- 断言 2：无障碍树里得有足够多的元素 ----------
        // 区分"页面是空白"与"页面有东西但我找错了名字"。
        let count = stableCount(web)
        XCTAssertGreaterThan(count, 10,
                             "无障碍树里只有 \(count) 个元素 —— 页面很可能是空白的")

        attach(name: "shell-after-load")
    }

    // MARK: - 用例二：壳的版本号真的传进页面了吗

    /// 「更多 → 关于」显示的 App 版本号，来源是
    ///   `ShellConfig.appVersion`（壳）→ 注入 JS 的 `Native.appVersion()` → `app.js` 的 `APP_VERSION`。
    ///
    /// 2026-09-26 之前 `ShellConfig.appVersion` 是**手写的** `"1.5.0"`，与安卓的
    /// `versionName` 各存一份，**已经静默漂了七轮**（APK 到 1.12.0 了，iOS 仍报 1.5.0），
    /// 用户在两台设备上看到的版本号互相矛盾，**且没有任何一处会报错**。
    /// 现在改成运行时读 Info.plist 的 `CFBundleShortVersionString`（唯一源）。
    ///
    /// ⚠️ 这条链**在本地无法验证**（本机没有 iOS SDK / 模拟器），
    /// 而它又恰恰是"改了等于没改也看不出来"的那一类 —— 所以必须在真实模拟器上跑。
    ///
    /// ⚠️ 断言用**正则**而不是写死版本号：写死会让它每发一版就红一次，
    /// 然后被顺手改成新值 —— 那样它就退化成"复述一遍版本号"，什么都不验。
    /// 匹配 `x.y.z` 这个**形状**才是要守的东西：壳一旦读不到 Info.plist
    /// （回落到占位串 `unknown`），这里立刻红。
    func testAboutPanelShowsVersion() {

        let web = bootApp()

        // 与用例一同理：登录页在就点掉，不在就直接往下走（顺序无关）。
        let skip = descendant(of: web, labelContains: "先不登录")
        if skip.exists || skip.waitForExistence(timeout: 25) { skip.tap() }

        let more = descendant(of: web, labelContains: "更多")
        guard more.waitForExistence(timeout: 60) else {
            dumpTree(web, why: "用例二：等不到底部「更多」")
            XCTFail("底部导航没出来，进不去「更多」")
            return
        }
        more.tap()

        let ver = web.descendants(matching: .any)
            .matching(NSPredicate(format: "label MATCHES %@", "^[0-9]+\\.[0-9]+\\.[0-9]+$"))
            .firstMatch
        let found = ver.waitForExistence(timeout: 30)
        dumpTree(web, why: "用例二：更多面板")
        if found {
            // ⭐ 把真实值打进 CI 日志 —— 这是"壳到底报了什么版本"的唯一直接证据。
            print("=====> 运行时 App 版本 = \(ver.label)")
        }
        XCTAssertTrue(found,
                      "「更多 → 关于」里没看到形如 x.y.z 的版本号 —— 壳的 appVersion 没传进页面"
                      + "（若壳读不到 Info.plist，会回落到占位串 unknown）")
    }

    // MARK: - 工具

    /// 启动 App 并等到内容层真的渲染出来。返回 WebView 元素。
    private func bootApp() -> XCUIElement {
        let app = XCUIApplication()
        app.launch()
        launchedApp = app

        // 断言：WKWebView 存在。
        // 这一条通过，就同时证明了：App 起来了、WKWebView 建起来了、
        // 而且**内容层的 HTML 已经加载**（否则不会出现 web view 元素树）。
        let web = app.webViews.firstMatch
        guard web.waitForExistence(timeout: 120) else {
            dumpAppDiagnostics(why: "120 秒内没有出现 WKWebView")
            XCTFail("WKWebView 没出现 —— 壳没起来，或内容层根本没加载成功")
            return web
        }

        // 断言：页面标题渲染出来了（index.html 的 <h1 id="title">建工考试助手</h1>）。
        if !descendant(of: web, labelContains: "建工").waitForExistence(timeout: 90) {
            dumpTree(web, why: "等不到页面标题")
            XCTFail("页面标题「建工考试助手」没出现 —— 内容层没渲染出来")
        }
        return web
    }

    /// 在任何元素类型里，找 label **包含** 给定文字的节点。
    ///
    /// 为什么要跨类型找：网页元素在无障碍树里的类型不稳定
    /// （button / staticText / other / link 都可能是），
    /// 只查一类会得到"明明看得见却说找不到"这种最难查的失败。
    private func descendant(of web: XCUIElement, labelContains text: String) -> XCUIElement {
        web.descendants(matching: .any)
            .matching(NSPredicate(format: "label CONTAINS %@", text))
            .firstMatch
    }

    /// 等页面"静下来"，返回稳定的节点数。
    ///
    /// ⚠️ 为什么要等：网页是活的（状态条、题库数、渐入动画都会改树）。
    /// 读到一半树变了，就是那个 `Element at index 77` 的成因。
    @discardableResult
    private func stableCount(_ web: XCUIElement, timeout: TimeInterval = 20) -> Int {
        guard web.exists else { return 0 }
        let deadline = Date().addingTimeInterval(timeout)
        var last = -1
        while Date() < deadline {
            let n = web.descendants(matching: .any).count
            if n > 0 && n == last { return n }
            last = n
            Thread.sleep(forTimeInterval: 1.0)
        }
        return max(last, 0)
    }

    /// 把 WebView 的无障碍树**一次快照**读出来并打印（有界）。
    ///
    /// ⚠️⚠️ 为什么用 `debugDescription` 而不是"按索引遍历"：
    ///    后者是「先取一次 count、再 `element(boundBy: i)`」——
    ///    两次操作之间页面会重绘，索引随即失效 →
    ///    `Failed to get matching snapshot: No matches found for Element at index 77`
    ///    → **测试直接红，而断言连跑都没跑到**（实测踩过，见文件头）。
    ///    `debugDescription` 是**单次**快照，没有"两次操作之间的窗口"。
    ///
    /// ⚠️ 为什么要有界（limit）：整棵树在真实页面上是几千行，
    ///    无界打印会把 CI 日志淹掉 —— 而**日志被淹和没有日志是同一种效果**。
    ///    截图负责回答"看起来像什么"，这里负责回答"断言用来比对的 label 到底是什么"。
    private func dumpTree(_ web: XCUIElement, why: String, limit: Int = 260) {
        print("")
        print("==================== 无障碍树：\(why) ====================")
        // ⚠️ 元素不存在时**绝不能**去读它 —— 那正是会抛 snapshot 错误的情形。
        guard web.exists else {
            print("（跳过：WebView 元素不存在，没有树可读）")
            print("==================== 结束 ====================")
            print("")
            return
        }
        print("--- 静默后的节点数：\(stableCount(web)) ---")
        let lines = web.debugDescription.split(separator: "\n", omittingEmptySubsequences: false)
        for line in lines.prefix(limit) {
            print("  \(line)")
        }
        if lines.count > limit {
            print("  …（共 \(lines.count) 行，已截断到 \(limit) 行）")
        }
        print("==================== 结束 ====================")
        print("")
    }

    /// 连 WebView 都还没出现时的现场（这时连树都没有，只能看应用级元素）。
    private func dumpAppDiagnostics(why: String) {
        print("")
        print("==================== 诊断：\(why) ====================")
        print(launchedApp.debugDescription)
        print("==================== 诊断结束 ====================")
        print("")
    }

    private func attach(name: String) {
        guard let app = launchedApp else { return }
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = name
        shot.lifetime = .keepAlways
        add(shot)
    }
}
