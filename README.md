# constructexam-ios

「建工考试助手」的 **iOS 壳**，以及一个用 GitHub Actions 把它编译成
**未签名 IPA** 的工作流 —— 供免费 Apple ID 侧载安装到自己的 iPad。

## 怎么用

1. 往本仓库推一次代码（或在 Actions 页面点 `Run workflow`）
2. 等 `构建 iOS 未签名 IPA` 跑完，在 **Artifacts** 里下载 `ConstructExam-unsigned-ipa`
3. 解压得到 `ConstructExam-unsigned.ipa`，用 AltStore / Sideloadly 签名安装

**完整步骤（含 AltStore 的前置条件、7 天续签、常见错误）→ [ios/README.md](ios/README.md)**

## 注意

- ⚠️ 编译失败时，`xcodebuild` 的完整日志会被自动提交到 `ios/build.log` ——
  出问题**直接读那个文件**，不必去 Actions 页面翻。编译通过后它会被自动删除。
- ⚠️ 本仓库是**发布目标，不是源**。源码在主仓库，这里的 `ios/` 是逐字副本；
  在这里单改会被下一轮同步冲掉。
- 壳本身**不含内容**：页面从 `https://constructexam.cadqto.com/app/` 加载，
  与 `/api/` 同源，所以 HTTP 走页面自己的 `fetch`，不需要原生桥。

## 许可

MIT，见 [LICENSE](LICENSE)。
