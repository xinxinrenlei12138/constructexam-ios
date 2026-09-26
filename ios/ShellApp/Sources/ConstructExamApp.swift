import SwiftUI
import UIKit

/// iOS 壳的入口。
///
/// 整个 App 只有一屏：`ShellWebView` —— 一块铺满全屏的 `WKWebView`。
/// 分工与 Android 侧 `ui/ConstructExamApp.kt` 完全一致：
/// **壳不做业务，业务全在内容层**（线上 `/app/` 那一份 `www`）。
///
/// 所以这个文件里**不该长出任何业务代码**。要加功能，先问一句：
/// 这件事是不是应该做在内容层（两端共享），而不是只做给 iOS？
/// 判据：**只写在壳里的功能，等于给两端各自留了一份会漂移的实现。**
@main
struct ConstructExamApp: App {
    var body: some Scene {
        WindowGroup {
            ShellWebView()
                // 整屏交给页面。安全区不由壳处理 ——
                // app.css 的 `--safe-t/--safe-b` 取自 env(safe-area-inset-*)，
                // 壳再让一次就会出现「双份留白」。
                .ignoresSafeArea()
                // ⚠️ 必须写 `Color(uiColor:)` 而不是 `Color(.systemBackground)`。
                //    后者要编译器从上下文反推 `UIColor`，而 `Color` 上并没有一个
                //    参数类型宽松的 `init(_:)` 能稳稳接住它 —— 在没有 Mac 可以试错的情况下，
                //    这种「靠类型推断才成立」的写法是最不该出现在第一版里的东西。
                .background(Color(uiColor: .systemBackground))
        }
    }
}
