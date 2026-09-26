# iOS 壳（免费 Apple ID 侧载方案）

> 目标：**不花一分钱**把「建工考试助手」装进自己的 iPad。
> 代价：签名 **7 天**过期，需要定期续签。这件事的成本不是钱，是「记得续」。
> 本文件只讲**怎么做**；为什么这么选、以及被否掉的方案，见主仓库的决策记录。

**许可**：MIT（见同目录 `LICENSE`）。
⚠️ **本目录是发布目标**：主仓库的 `ios/` 与公开镜像仓库的 `ios/` **逐字相同**，
改动一律回主仓库，由 `tools/publish_ios_repo.sh` 生成镜像内容。

---

## 一、三台「机器」的分工（先看这张表，能省很多困惑）

| 角色 | 谁 | 干什么 | 为什么它不能换 |
|---|---|---|---|
| **写壳** | 我（本地 Windows） | 写 Swift 源码、`project.yml`、CI 工作流 | —— |
| **编译** | GitHub 的 macOS runner | 把 Swift 编成 `.app` → 打成**未签名** `.ipa` | ⚠️ **编译 iOS App 只能用 Xcode，而 Xcode 只能跑在 macOS 上**（沙箱 + 私有 SDK 全绑死）。这一条绕不过去，只能借别人的机器 |
| **签名 + 装机** | 你的 Windows + iPad | 用你的免费 Apple ID 给 ipa 签名并安装，之后每 7 天续签 | ⚠️ 签名要用你的 Apple ID 证书，只有你能做 |

> **判据：「构建」和「分发」是两件事。** 前者绕不开 macOS，后者可以完全绕开 App Store。

---

## 二、目录结构

```
ios/
├── README.md                      ← 本文件
├── project.yml                    ← XcodeGen 的工程描述（.xcodeproj 由它生成，不入库）
└── ShellApp/
    └── Sources/
        ├── ConstructExamApp.swift ← 入口（就是一块铺满屏的 WKWebView）
        └── ShellWebView.swift     ← 壳的全部实质：桥 + 白屏自恢复 + 首屏失败兜底
```

**没有任何资源文件** —— 页面从网上取（见下一节）。这是刻意的。

---

## 三、前置条件（✅ 已完成，2026-09-23）

内容层必须挂在 **HTTPS** 上，且与 API **同源**：

```
https://constructexam.cadqto.com/app/          ← index.html / app.css / app.js / web-bridge.js
https://constructexam.cadqto.com/api/...       ← 同上一个域（nginx 反代到 127.0.0.1:8787）
```

已实测（逐端点）：`/app/` `200 text/html`、`/app/app.js` `200 application/javascript`、
`/api/subjects` 返回 4 个科目；首页 `/` 与 APK 下载**无回归**。

### ⚠️ 这一条是硬耦合，务必知道
`ShellWebView.swift` 里的 HTTP **走页面自己的同源 `fetch`，不经原生桥**。
- 安卓必须经原生桥 —— 它的页面在 `file://`/assetloader 源下，`fetch` 会被同源策略拦（见 `web/NativeBridge.kt` 开头）。
- iOS 这一版页面就在自家域上 → `fetch` 直接可用，省掉「大响应体 → JS 字符串转义 → evaluateJavaScript」这条又慢又脆的路。

**所以：一旦把内容改成打进包的本地资源，HTTP 那一段必须改回走原生。** 改之前先读 `ShellWebView.swift` 顶部那段注释。

---

## 四、操作步骤

### 步骤 1：仓库已经在 GitHub 上了（公开镜像仓库）

编译用的仓库是**公开**的：

```
https://github.com/xinxinrenlei12138/constructexam-ios
```

**为什么公开**：GitHub 的 macOS runner 按 **10× 倍率**计费（私有仓库免费额度 2000 分钟/月
≈ 实际只有 200 分钟 macOS 时间），而**公开仓库的标准 runner 不计费**。
这个仓库里只有壳的源码与工作流，**不含任何密钥**（它要去取的内容地址本身就是公开的）。

⚠️ **它是「发布目标」，不是源。** 源在私有主仓库里，要改请回主仓库改。
这个仓库里的 `ios/` 与主仓库的 `ios/` 是**逐字相同的两份副本**，而且这是刻意维持的 ——
若在这里单独改，下一轮同步就会把你的改动冲掉。
（判据：**派生出来的第二份副本，必须有且只有一条生成路径。**）

### 步骤 2：跑 CI，拿到未签名 ipa

**往仓库推一次代码就会自动触发**（也可以在 Actions 页面点 `Run workflow`）。
等 `构建 iOS 未签名 IPA` 跑完，在 **Artifacts** 里下载 `ConstructExam-unsigned-ipa`，
解压得到 `ConstructExam-unsigned.ipa`。

> ⚠️ **第一次大概率会编译失败，那是正常的，不是白折腾。**
> 这份 Swift 是在**一台没有 macOS 的机器上**写的（没有 iOS SDK 可验证），
> 所以它现在是**未验证状态**。
> 好在失败时工作流会把 `xcodebuild` 的完整日志**提交回仓库**的 `ios/build.log` ——
> 所以不必去 Actions 页面翻日志，**直接读那个文件就是全部错误**。
> 把它给我，我按错误改；改完再推一次，通常一两轮收敛。
> 编译通过后那份日志会被自动删掉，不会留在仓库里误导后来人。

### 步骤 3：Windows 上装 AltServer / AltStore（一次性）

**AltStore 比 Sideloadly 好在一个地方：它能后台自动续签**，所以推荐它。

**前提（这一条最容易踩）**：

| 项 | 要求 |
|---|---|
| 系统 | Windows 10 / 11 **64 位** |
| iTunes | ⚠️ **必须从 Apple 官网下载**，**不能**用 Microsoft Store 版 |
| iCloud | 同上，Apple 官网版 |
| 权限 | 一台管理员账户的电脑 |
| 线材 | **能传数据的 USB 线**（纯充电线不行） |

> ⚠️ **为什么不能用 Microsoft Store 版**：Store 版跑在沙箱里，不暴露 AltServer 需要的库 →
> 典型症状是 `Mismatched serial number` 或一开始就连不上。
> 已经装了 Store 版的话：先卸载 iTunes 和 iCloud（Store 版），再从 Apple 官网装独立版。

然后：

1. 装 AltServer → 它常驻右下角托盘
2. iPad 用 USB 线连电脑 → 两边都点「信任」
3. 打开 iTunes，勾上 **Wi-Fi 同步**
4. 托盘图标 → `Install AltStore` → 选你的 iPad → 输入 Apple ID（**只用本地签名，不上传**）
5. iPad 上完成信任：**设置 → 通用 → VPN与设备管理 → 你的 Apple ID → 信任**
6. 打开 iPad 上的 AltStore → `我的账户` → 用同一个 Apple ID 登录

**还要开开发者模式**（iPadOS 16+ 必需）：
设置 → 隐私与安全 → 拉到最底部 → **开发者模式** → 打开 → 重启 → 确认。
> 看不到这一项？**先用侧载工具装一次（或与电脑配对过一次）它才会出现** —— 不需要 Mac。
> 要求设备有密码、电量 ≥ 20%。

### 步骤 4：装我们的 ipa

把 `ConstructExam-unsigned.ipa` 传到 iPad（AirDrop / 文件 App / 网盘都行），然后在「文件」里
点它 → 共享 → **AltStore** → 由 AltStore 用你的 Apple ID 签名并安装。
或者直接在电脑上：托盘 AltServer → `Install .ipa`。

装完主屏上会出现「**建工考试助手**」的图标。

### 步骤 5：让它自己续签（关键，省掉一年 52 次手动操作）

- iPad 上 AltStore → **设置 → 刷新应用 → 始终**
- 电脑上 AltServer 托盘 → **启用 Wi-Fi 同步**
- 之后只要 **iPad 和电脑在同一个 WiFi**，AltStore 就会在后台自动续签

> 要出远门超过 7 天？出门前打开 AltStore → `我的应用` → 下拉刷新一次，能再撑 7 天。

---

## 五、诚实的限制清单

### 已核实、一定会遇到的
| 现象 | 说明 |
|---|---|
| **7 天到期后 App 直接打不开** | 不是「功能降级」，是签名失效。续签后即恢复 |
| 免费 Apple ID 同时只能有 **3 个** 侧载 App | ⚠️ **AltStore 自己占 1 个** → 实际只剩 2 个名额 |
| 提示「证书数量已达上限」 | 去 `appleid.apple.com` 撤销旧证书，或删掉不用的侧载 App |
| 续签要 iPad 和电脑**同一 WiFi** | 公司/访客网络常禁止设备互访 → 回家再刷新 |

### 这份壳暂时**没做**的（不是坏了，是没做）
| 缺什么 | 影响 | 为什么 |
|---|---|---|
| **侧滑返回** | 返回要用页面左上角自绘的 `‹` | 本 App **不用 URL 路由**（无 pushState/hash），WKWebView 里根本没有「历史」可回，开了手势也是划了没反应 |
| 断网可用 | 打开时若没网，会显示一张「没能连上服务器」的重试页 | 内容从网上取（这一步换来的是：改内容不用重装 App） |
| 推送 / Widget / 后台任务 | 都没有 | 需要付费账号的能力，且本来也没做 |

### ⚠️ 一条要提前知道的**数据**风险
侧载的 App 在**重签（覆盖安装）**时数据容器会保留 → 本地进度不会丢。
但**卸载再装会清空**。而云备份目前是**「只上传不下载」**（服务端有副本，但**没有恢复入口**）
—— 所以**不要卸载它**，丢了拉不回来。

---

## 六、排错

| 症状 | 先查这个 |
|---|---|
| CI 里 `xcodebuild` 报错 | 把日志贴给我，我按错误改代码 |
| `Mismatched serial number` | iTunes/iCloud 是不是 Microsoft Store 版？换成 Apple 官网独立版 |
| AltServer 菜单里看不到 iPad | USB 线是否支持数据传输；iTunes 里 Wi-Fi 同步是否勾上；防火墙 |
| 装完点开闪退 / 打不开 | 开发者模式开了吗（设置 → 隐私与安全 → 最底部）？证书信任了吗（VPN与设备管理）？ |
| 页面白屏 | 壳会自恢复一次；若一直白，看是不是 `/app/` 出问题了 —— 直接在 iPad Safari 打开 `https://constructexam.cadqto.com/app/` 对照 |

---

## 七、可选升级（不着急做）

- **SideStore**：AltStore 的分支，**首次配对之后不再需要电脑**（用本地 VPN 骗过系统完成续签）。
  代价是首次设置更绕。如果你经常不在电脑旁，值得考虑。
- **TrollStore**：只在特定 iOS 版本区间可用，装完**永久免签、不需要续签**。
  ⚠️ 需要先确认 iPad 的系统版本是否落在支持区间内 —— 报一下「设置 → 通用 → 关于本机 → 软件版本」我帮你查。

---

## 八、与 PWA 的关系（两条路不冲突）

同一份 `www` 既喂给这个壳，也喂给「加到主屏」的 PWA。
所以：**iOS 壳可以后补，PWA 今天就能用**；反过来先做壳也不浪费。
两条路的共同前置条件都是第三节那一件事（已完成）。
