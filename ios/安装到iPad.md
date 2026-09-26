# 把 App 装到 iPad 上（完整步骤）

> 目标：在你自己的 iPad 上用上「建工考试助手」。
> 花费：**0 元**。代价：签名 7 天过期，靠 AltStore 自动续签（只要电脑开着、**同一个 WiFi**）。
> 前置条件：**电脑已装好 AltServer**（第 1–2 步，一次性）。
> ⚠️ **「必须同一个 WiFi」是硬约束，用「异地组网」绕不过去**（已实测，别浪费两小时）→ 想异地续签直接看 **第 4 步 B**。

---

## 需要准备什么

| 项 | 说明 |
|---|---|
| Windows 电脑 | 需要有**管理员权限** |
| USB 数据线 | ⚠️ **能传数据的**（纯充电线不行） |
| iPad + Apple ID | 免费账号就够，不需要 99 美元 |
| 同一个 WiFi | 电脑与 iPad 必须同一网络（自动续签要靠它）。⚠️ **节点小宝/蒲公英/ZeroTier 这类异地组网替代不了** —— 原因见 **第 4 步 B** |
| App 文件 | `dist/constructexam-v1.12.1-ios-unsigned.ipa`（**未签名**，由 AltStore 用你的 Apple ID 签） |

---

## 第 1 步：电脑上装 Apple 驱动 + AltServer（一次性）

### 官方直链（省得在官网里找）

| 要下的东西 | 官方直链 |
|---|---|
| **iTunes for Windows** | `https://www.apple.com/itunes/download/win64` |
| **iCloud for Windows**（独立版） | `https://updates.cdn-apple.com/2020/windows/001-39935-20200911-1A70AA56-F448-11EA-8CC0-99D41950005E/iCloudSetup.exe` |
| **AltServer for Windows** | `https://cdn.altstore.io/file/altstore/altinstaller.zip` |

> ⚠️ 这三个直链 2026-09-23 **实测都还活着**（iCloud 那个 153.7 MB、AltServer 那个 11.8 MB）。
> ⚠️ 注意 AltServer 的地址里**没有** `altserver/windows/` 这一段 —— 猜错了会 404。

### 步骤

1. 装 **iTunes** 与 **iCloud**（都用上面的**独立版**）

   > ⚠️⚠️ **不要用 Microsoft Store 版**。Store 版跑在沙箱里，不暴露 AltServer 需要的库。
   > 典型症状：`Mismatched serial number` / 登录卡住 / `Could not find AltServer`。
   > 官方原文：*"AltStore requires that you install iCloud directly from Apple in order to
   > authenticate your Apple ID."* —— **iCloud 这一项是认证 Apple ID 的关键，不能用 Store 版。**

2. 解压 `AltInstaller.zip` → 运行里面的 **`Setup.exe`**
3. 任务栏搜索 **AltServer** → **右键 → 以管理员身份运行**
   （不以管理员运行会登录失败或连不上设备）
4. Windows 防火墙弹窗 → **允许**（专用网络）

### 如果只能用 Store 版 iCloud（官方给的替代做法）

1. 先按上面装**官网版 iTunes 和 iCloud**
2. 找到 `C:\Program Files (x86)\Common Files\Apple`，把里面的
   **`Apple Application Support`** 和 **`Internet Services`** 两个文件夹复制出来，放到一个新文件夹里
3. **卸载 iCloud**（⚠️ **千万别卸 iTunes**，也绝不能卸 `Apple Mobile Device Support`）
4. 从 Microsoft Store 装 iCloud
5. 打开 AltServer 时它会让你 **"Choose Folder…"** → 指向第 2 步那个备份文件夹

---

## 第 2 步：把 AltStore 装进 iPad

1. iPad 用 **USB** 连电脑 → 解锁 → 弹「信任此电脑」时点**信任**
2. 打开 **iTunes** → 左上角设备图标 → **摘要** → 勾上 **「通过 Wi-Fi 与此 iPad 同步」** → **点「应用」并等同步完成**

   > ⭐⭐ **这一步不是可选项，是 WiFi 安装/续签的硬前提。**
   > 不勾 = `Apple Mobile Device Service` 不把 iPad 当**网络设备**暴露 → AltServer 只能走 USB
   > → iPad 上会报 `AltServer could not be found`（错误码 **1200**）。
   > 📌 **2026-09-25 实测**：本机漏了这一步 → WiFi 安装与续签 **100% 失败**、USB **100% 成功**；
   > 当时网络/Bonjour/权限全是绿的 —— 所以怎么查网络都查不出来。
   > ✅ **验证（一条命令，全链路）**：`python tools/altserver_repair.py`
   > —— 依次查 AltServer 进程/端口 → iPad 的 `_apple-mobdev2` 广播 → **usbmuxd 设备列表** → `_altserver._tcp` 注册 → 端口可达。
   > 只查 WiFi 同步用 `python tools/apple_wifi_sync_check.py <电脑局域网IP>`（应看到 iPad 广播 `_apple-mobdev2._tcp` 并解析出 IPv4）。
   > ⭐ **`[3] usbmuxd 看得见的设备` 必须是 ≥ 1** —— 这一项为 0 时，即使前面全绿 AltServer 也装不了。
   > 另外 **iTunes 要保持运行**（Windows 的 WiFi 设备发现依赖它，最小化即可，别退出）。
   > ⛔ **不要**用 `C:\ProgramData\Apple\Lockdown\<UDID>.plist` 里有没有 **`EnableWifiConnections`** 来验证 ——
   > 2026-09-25 实测：WiFi 同步**已生效**时该字段**依然不出现**、plist 修改时间也不变。这条判据本身是错的。
   > 🔧 找不到那个勾在哪：iTunes 12.13.x → **左上角那个很小的设备图标** → **摘要**。图标只在「USB 连着 + iPad 已解锁」时出现；
   > 若确认插着线还看不到，先检查 iTunes 是不是后台残留进程（`Get-Process iTunes | Select MainWindowHandle` 为 0 就是没有真窗口 → 重启 iTunes）。
3. 托盘 AltServer 图标 → **Install AltStore** → 选你的 iPad → 输入 **Apple ID 与密码**
   （只在本地用于签名，不会上传）
4. iPad 上**信任证书**：**设置 → 通用 → VPN与设备管理** →
   在 **「开发者 App」** 分组里找到 **`iPhone Developer: <你的账号> (<团队ID>)`** → 点进去 → **信任** → 弹窗再点**信任**

   > ⚠️⚠️ **这一步和「开发者模式」是两件不同的事，位置也不一样** —— 几乎每个人都会先撞一次：
   > | 要做的事 | 在哪 |
   > |---|---|
   > | **信任证书** | **设置 → 通用 → VPN与设备管理** →「开发者 App」 |
   > | **开发者模式** | **设置 → 隐私与安全性** → 最底部 |
   > 没信任证书就打开 App，会弹：**「不受信任的开发者 / 你的设备管理设置不允许…」**。
   > 它显示的开发者名形如 `iPhone Developer: 8618829280121 (6Z9F2A56X6)` —— 括号里是团队 ID，不用管。
5. iPad 上打开**开发者模式**：**设置 → 隐私与安全性 → 拉到最底部 → 开发者模式 → 打开 → 重启 → 确认**

   > ⚠️⚠️ **全新设备上「开发者模式」这一项根本不存在** —— 这是最容易卡住人的一点。
   > Apple 的机制是：**设备先被开发工具"碰过"一次之后，这个开关才会出现。**
   > 也就是说：**必须先让 AltStore 装成功一次，它才会出现。**
   > → **设置里找不到它 = 安装还没成功**，这不是独立问题，别在设置里反复找。
   > 它出现后需要设备密码，且电量 ≥ 20%。

---

## ⚠️ 首次安装失败：按这个顺序查（覆盖绝大多数情况）

**先看一眼：AltServer 弹的报错原文是什么？** 有那一句字就能直接定位。

### 错误码对照（这是最省时间的入口）

| 错误码 | 原文 | 真正卡在哪 |
|---|---|---|
| **`-20101`** | `Your account information was entered incorrectly`（`SRP_Setp1` 失败） | ⭐ **卡在「账号名」**，不是密码。SRP 认证**第一步**就被拒 |
| `-22406` | `Your Apple ID or password is incorrect` | 账号名对、**密码错** |

### `-20101` 按这个顺序试（已实测确认就是它）

1. ⭐⭐ **Apple ID 是手机号的话，必须在前面加 `86`**
   例：`19183404909` → 输入 **`8619183404909`**
   （这是国内所有 Apple 签名工具共同的规则 —— 手机号账号要带国家码前缀）

2. ⭐⭐ **用 iCloud 主邮箱，而不是注册时的第三方邮箱**
   很多人一直记着自己注册时的 QQ/Gmail 邮箱，但 Apple 后来把账号名改成了 `xxx@icloud.com`。
   → **权威做法**：iPad 上 **设置 → 最上面的「你的名字」** → 那里显示的才是 Apple ID 的**准确账号名**。
   不要凭记忆，照它抄。

3. **把账号名全大写再试一次** —— 社区里有人就是这么解决的（Apple 侧记录的历史邮箱大小写不一致）。

4. **检查输入法残留**：账号名那一栏有没有混进全角字符或多余空格。

> 💡 为什么"没有 2FA 验证码框"其实**证明**了是账号名的问题：
> 如果账号名对了、账号开了两步验证，AltServer **一定会**弹第二个框要 6 位码。
> 它连弹都没弹就直接报 `-20101` —— 说明**根本没走到那一步**。

### 其他按发生概率排的原因

| # | 原因 | 表现 / 怎么修 |
|---|---|---|
| **1** | **两步验证（2FA）没走完**（最常见） | 输完密码后，AltServer 会**再弹一个框要 6 位验证码**（同时推送到你其他 Apple 设备）。那个框很容易被忽略或误关 → 登录失败，而**看起来像"密码错了"**。→ 重来一次，盯住第二个框 |
| **2** | **iPad 没解锁 / 没点「信任」** | 安装必须发生在 iPad **已解锁**且已「信任此电脑」的状态下。→ 解锁 iPad → 拔插一次 USB → 看到「信任此电脑」就点**信任** → 保持屏幕亮着再试 |
| **3** | **Apple ID 证书额度用完** | 报 `Maximum number of certificates reached`。免费 Apple ID 的证书数量有限。→ 到 `appleid.apple.com` 撤销旧证书 |

**另两个值得确认的**：
- **iTunes 里能不能看到这台 iPad？** 看不到的话 AltServer 也看不到（iTunes 是"设备识别"最直观的对照）
- **是不是公司/学校网络？** 那类 WiFi 常禁止设备互访（官方建议改手机热点）——走 USB 时影响较小

> 📌 **判断"登录到底成没成"的一个客观线索**：AltServer 的数据目录
> `%LOCALAPPDATA%\AltServer\` 里如果**只有 `Apple\` 这一个子目录**（它自己解包的 Apple 依赖），
> 说明**没有留下任何登录成功的痕迹** → 问题就卡在 Apple ID 那一步，而不是后面的安装步骤。

**都试过还不行？** 换 **Sideloadly**：普通窗口界面、不依赖托盘、2FA 提示更醒目、报错直接写在窗口里。功能与 AltServer 等价。

---

## 第 3 步：装我们的 App

### 方式 A：iPad 直接下载（推荐，不用数据线）

1. 在 **iPad 的 Safari** 里打开：

   ```
   https://constructexam.cadqto.com/download/constructexam-v1.12.1-ios-unsigned.ipa
   ```

2. Safari 下载完 → 打开「**文件**」App → **下载项** → 点那个 `.ipa`
3. 点右上角**分享** → 选 **AltStore**
4. AltStore 会用你的 Apple ID 签名并安装 → 主屏上出现「**建工考试助手**」图标

### 方式 B：电脑侧推（AltServer 的**隐藏菜单**）

⚠️ **`Sideload .ipa` 这一项默认是藏起来的** —— 直接右键托盘图标是看不到它的：

1. 按住键盘 **`Shift`** 不放
2. 同时**右键**系统托盘的 AltServer 图标
3. 菜单里会出现 **`Sideload .ipa`** → 点它
4. 选 `dist/constructexam-v1.12.1-ios-unsigned.ipa`
5. 可能会再让你输一次 Apple ID

> 💡 为什么要藏：这个入口防的就是"随手点到、装个来路不明的 ipa"。
> 记住这一招就够了 —— 以后装任何 ipa 都用它。

> ⚠️ **免费 Apple ID 同时只能有 3 个侧载 App，而 AltStore 自己占 1 个** → 实际只剩 2 个名额。
> 提示「证书数量已达上限」时，去 `appleid.apple.com` 撤销旧证书，或删掉不用的侧载 App。

---

## 第 4 步：设置自动续签（关键，省掉一年 52 次手动操作）

签名 **7 天**到期后 App **会直接打不开**（不是功能降级）。让它自己续：

| 在哪 | 做什么 |
|---|---|
| iPad 的 AltStore | **设置 → 刷新应用 → 始终** |
| 电脑的 AltServer | 托盘菜单 → **启用 WiFi 同步** |

之后只要 **iPad 与电脑在同一个 WiFi**，AltStore 就会在后台自动重签。

**要出远门超过 7 天？** 出门前打开 AltStore → **My Apps → 下拉刷新**（Refresh All），能再撑 7 天。

### B. 想异地续签（iPad 与电脑不在同一局域网）

> ⚠️ **先给结论，省掉两小时**：靠**异地组网**（节点小宝 / 蒲公英 / ZeroTier / Tailscale）替代「同一个 WiFi」—— **不行**。

**为什么不行**：AltServer 的无线安装/续签是**两步链**：① iPad 用 **mDNS 组播**（`224.0.0.251:5353`）**发现** AltServer；② 再直连它的 TCP 端口。
组网工具给的是**点对点三层（L3）隧道**，**不承载组播** → 第 ① 步就断，iPad 照样报 `AltServer could not be found`。
（报错文案会把人往「网络没通」上带，**但实际上单播是通的、只有发现链断了**。）

📌 **2026-09-26 实测证据（本机 + 渭南 NAS，两端都装节点小宝、隧道单播完全连通）**：

| 观察 | 结果 |
|---|---|
| 两端虚拟网卡地址 | **都是 `10.222.222.1/32`**（逐节点本地地址，不是共享网段） |
| 虚拟网路由表 | 对端是 `100.66.1.x/32` **逐主机路由** → **没有共享网段 = 没有广播域** |
| 渭南 NAS 查 `_altserver._tcp` | **空** |
| 渭南 NAS 解析 `DESKTOP-HP9AIO8.local` | **Timeout** |
| 电脑侧旁听隧道 45 秒 | **0 包** |

> 🔍 **可复用的判别法**：看到虚拟网卡是 **`/32` + 对端一串 `x.x.x.x/32` 主机路由**，就说明这是纯 L3 叠加网 —— **别指望它的组播/二层发现能用**。
> （节点小宝官网页的功能表里确实列了「二层组网 广播/组播」一行，但静态页是 JS 渲染的、勾选情况抓不到；配置里有个 `[tunnel] lan = 0` 开关名字可疑但未证实。**若坚持走这条路，只需向客服问一句**：Windows 客户端 + iOS 客户端能否开启二层组网/组播透传。）

#### 正解：让 iPad「自己签」，不再需要电脑

| 方案 | 要什么 | 异地可用 | 代价 |
|---|---|---|---|
| ⭐ **AltStore Classic 2.3+ 的 Remote AltServer**（2026-09-15 发布） | ① 把 iPad 上的 **AltStore 升到 ≥ 2.3**（要求 **iOS 17.4+**，你的 **17.7.11 ✅**；升级本身要同网/USB 做一次）② AltStore 设置 → **Set up Remote AltServer…** → **Pair with a PC** 一次 ③ iPad 装 **LocalDevVPN** 并常开 ④ **必须连 WiFi，不能只用蜂窝** | ✅ | 0 元。⚠️ 但 **LocalDevVPN 在中国区 App Store 没有** —— 实测**中国香港 / 日本 / 新加坡 / 美 / 英 都有**（Coxson Engineering LLC，**免费**，最低 iOS 14）→ **需要一个非中国区的 Apple ID**（中国香港区最好拿） |
| **SideStore** | 同理：首次配对一次 + 本机 VPN。Remote AltServer 用的就是它的 minimuxer/远程 anisette 技术 | ✅ | 同上；且 **StosVPN 已从 App Store 下架**、StikDebug 不在商店 |
| ⭐⭐ **付费开发者账号（99 美元/年）+ TestFlight** | **TestFlight 中国区 App Store 就有**（最低 iOS 16.0，你的 17.7.11 ✅） | ✅ **不需要电脑同网、也不需要 VPN** | 99 美元/年。签名 **1 年**有效；TestFlight 构建 90 天一轮，重传即可 |
| 维持现状：USB / 同 WiFi | — | ❌ | 0 元，代价是每次到期前得凑到电脑旁 |

> 💡 这件事的判断很简单：**这个 App 是你自己开发的**。只要打算长期自用或给几个人用，**99 美元那条（TestFlight）反而最省事** —— 配一次，之后一年不用管线。
> 想在 CI 里全自动传 TestFlight 也可以：项目里已有 iOS 构建流水线（GitHub Actions 出未签名 IPA），加一段归档 + 上传即可。

#### ✅ 已配好 Remote AltServer？这样验证（2026-09-26 实测）

**先纠正一个直觉**：Remote AltServer **日常安装/续签完全不经过你的电脑，但首次 setup 需要电脑一次**。

> 📌 **官方原文**（[faq.altstore.io/altstore-classic/remote-altservers](https://faq.altstore.io/altstore-classic/remote-altservers)）
> 设置四步：**① `Set up Remote AltServer…` ② `Pair with a PC` ③ 装 LocalDevVPN ④ 保证 Wi-Fi + VPN 都开**
> 日常用法：「① Connect to LocalDevVPN ② Connected to WiFi **(not cellular)** ③ **DONE!** You can now use AltStore to sideload and refresh your apps **without connecting to AltServer on your computer**」
> 官方公告另注：**iOS 27 起才能纯设备端 setup** —— 17.4~26 都绕不过那一次 `Pair with a PC`（本机 iPadOS 17.7.11 属于此列）。

三步各管什么（别混为一谈）：

| 部件 | 解决什么 | 生命周期 |
|---|---|---|
| anisette 服务器 | 苹果验证签名要的指纹头（`X-Apple-I-MD` 等）从哪来 —— 旧版由本机 AltServer 现算 | 每次签名都要，可随时换台 |
| **配对文件** | 让设备上的 `lockdownd` 相信「对面是一台已配对的 Mac」 | ⭐ 一次性生成，**持久存在设备里** |
| **LocalDevVPN** | 承载那条「假 USB 通道」的本机回环隧道 | 每次侧载都要开 |

⭐ **LocalDevVPN 不是商业 VPN**，是 **loopback VPN**（`jkcoxson/LocalDevVPN`，fork 自 SideStore 的 StosVPN；App Store 发布者 Coxson Engineering LLC，免费，iOS 14+）。它把发往「虚拟开发机」的包在设备内部掉头送回来，所以**物理上没有远端服务器**。存在理由是 iOS 的硬约束：**装 App 的请求只能经 `usbmuxd`（USB 语义）递给 `lockdownd`**。数据流：AltStore 发请求 → VPN(TUN) 拦下 L3 包重定向到本地 → **minimuxer**（在沙箱内复刻 usbmuxd 协议）转成带配对密钥的报文 → `lockdownd` 验签通过 → **系统以为正插着一台真 Mac**。

### ⚠️ LocalDevVPN 的两个 IP 值**必须不同**，且「Device IP」必须是 `10.7.0.1`

源码取证（`jkcoxson/LocalDevVPN` → `Constants.swift`）：

```swift
defaultIfaceIP = "10.7.1.1/32"   // UI 的 Tunnel IP（本方隧道接口）
defaultPeerIP  = "10.7.0.1/32"   // UI 的 Device IP（对端「虚拟开发机」）
```

`PacketTunnelProvider.swift` 只把**去往 peer 的流量**塞进隧道（`includedRoutes = [peer]` + `excludedRoutes = [.default()]`），隧道动作就是把 IPv4 头的 src/dst 对调再写回。而 **`10.7.0.1` 是 SideStore/AltStore 内部硬编码的连接目标**（`sidestore-vpn` README：「it instructs iOS to connect to a computer at 10.7.0.1」）。

⇒ **把 Device IP 改成别的（例如误填成与 Tunnel IP 相同的 `10.7.1.1`），隧道就只路由那个错地址，AltStore 连 `10.7.0.1` 时压根没进隧道 → 直接报「连不上 remote AltServer」。这是「VPN 显示 Connected 却连不上」的头号原因。**

- 正确值（默认）：Tunnel IP `10.7.1.1/32` ＋ Device IP `10.7.0.1/32`
- 另一组社区实测可用值：Tunnel IP `10.7.0.2/30` ＋ Device IP `10.7.0.1/32`
- ⚠️ `Tunnel 10.7.0.1/32` ＋ `Device 10.7.0.0/24` 会被 CIDR 校验拒（wrong format）
- ⚠️ 普通上网流量**不走隧道**，所以「VPN 开着 Safari 正常」**不能**证明配置正确

> ⚠️⚠️ **别被网上教程带偏**：绝大多数 AltStore 排错文都写「关掉 VPN / 改用 USB」—— 那是**本机 AltServer 老路线**的做法（VPN 会打断局域网 mDNS 发现）。**Remote 路线恰恰相反：VPN 必须一直开着。**

⇒ 所以电脑侧 AltServer 有没有跑、mDNS 通不通、`_altserver._tcp` 注册在不在，**日常全都与它无关**，别去那边找问题。唯一会「回连电脑」的情况：**设备重置/刷机丢了配对文件** → 必须重做一次 `Pair with a PC`。

它真正依赖的是**社区运行的 anisette 服务器**（SideStore 团队维护的那批，AltStore 2.3 内置清单与 `SideStore/anisette-servers` 同源）。anisette 数据 = 苹果服务器验证签名请求所需的指纹头（`X-Apple-I-MD` / `X-Apple-I-MD-M` / `X-MMe-Client-Info` …）。

**电脑侧体检**（测的是本机所在网络出口，与 iPad 同 WiFi 时可直接套用）：

```bash
python tools/remote_altserver_check.py
```

一条命令给出：官方清单 **15 台里哪几台现在真的能用、谁最快**（判据是响应体里有没有真 anisette 字段，光看 HTTP 200 不算）。

📌 **2026-09-26 实测**：**12~15 台可用**，最快 `Macley`(≈500–600ms)、`SideStore (.zip)`(≈800ms)、`ani.sidestore.io`(≈900ms)；每天有 2~3 台在波动（`neoarz`/`owoellen`/`WE. Studio` 这次不通、上次通）。
⇒ **国内网络访问这批服务器没问题，异地续签这条路是通的。**

**iPad 侧验证**（最终判据只能在这里）：

| # | 做什么 | 该看到什么 |
|---|---|---|
| ① | AltStore → 设置 → **Remote AltServer** | 显示已选中的远程服务器（有 `Choose Server` 可换） |
| ② | AltStore → **My Apps** → 下拉 **Refresh All** | 成功刷新 = 已生效 |
| ③ | ⭐ **铁证（两个条件需同时满足）**：iPad 连**手机热点**（脱离本机网络）**且**本机 AltServer 停掉 → 重复 ② | 仍成功 = **真的不再依赖电脑** |

> ⚠️ **别把「手机热点」和「开蜂窝」混为一谈**：热点对 iPad 而言是 **WiFi**，符合官方要求；但**只走蜂窝流量不行** —— 官方专门写了 `(not cellular)`。

### ⚠️⚠️ 必须排查这一项：iPad 上的 VPN 槽位冲突（2026-09-26 新增）

**iOS 只允许一个 VPN 同时激活**（架构约束，改不了）。多个 VPN App 共存时，后启用的会把先前的踢下线；
开了「按需连接」的配置还会在网络切换时**自动抢占槽位**。

⇒ 所以「LocalDevVPN 显示 Connected」可能只是**某一瞬间**的状态。

⚠️ **但 2026-09-26 源码取证后修正一处**：槽位被顶掉时，`OnDeviceClient.isReachable()`（到 `10.7.0.1:49152`
的 1 秒 TCP 探测）会失败，抛的是 **`Local VPN is not currently running`**，
**不是** `couldn't connect to the remote AltServer`。两个文案各对应一条代码分支，
**别再把「槽位冲突」当成这条报错的成因**（详见下面的「报错文案速查表」）。

📌 **2026-09-26 实测我们这台 iPad 装了 3 个 VPN 类 App**：`LocalDevVPN 1.3.0` + **`Clash Mi 1.0.29`** + **节点小宝**。
（USB 侧取证：`pymobiledevice3 apps list --udid <UDID>`；而 `profile list` 只看到 iFont 字体描述文件，
说明 VPN 都是 App 形式，**别因描述文件干净就认为没有 VPN**。）

**处置（代价从低到高，别跳步）**：

1. iPad `设置 → 通用 → VPN与设备管理 → VPN` → 看**全部配置**；有点 `ⓘ` → **关掉「按需连接」**。
2. 不用的 VPN 配置**直接删除**（不必卸载 App），只留 LocalDevVPN。
3. **顺序不能反**地重试一次：先开 LocalDevVPN 等 Connected → 强杀 AltStore → 重开 → `My Apps` 下拉 Refresh All。

### ⭐⭐ 报错文案速查表 —— 每句话只由一个代码分支抛出（2026-09-26 源码取证）

设备端侧载全部由 `AltStore/Managing Apps/OnDeviceClient.swift`（`classic` 分支）负责。
**因为每条文案只有一个抛出点，「用户抄回来的那一句」本身就是层级判据** —— 不要靠猜网络。

| 报错（原文） | 内部错误 | 抛出点 | 说明什么 |
|---|---|---|---|
| **`AltStore couldn't connect to the remote AltServer.`** | `OnDeviceError.connectionFailed` | `OnDeviceClient.swift:280`，`tunnel_create_rppairing` 失败 | ⭐ **到 `10.7.0.1:49152` 的 TCP 已通**（否则更早抛 `vpnNotConnected`）⇒ VPN/IP/路由/墙**全部是好的**；失败在**配对握手** → 看下面「头号根因」 |
| `Local VPN is not currently running.` | `OperationError.vpnNotConnected` (1500) | 同文件 `:233`，`isReachable()` 返回 false | VPN 没连上 / 路由不对 / 端口不对 |
| `AltStore couldn't read this device's pairing info.` | `OnDeviceError.invalidPairingFile` (0) | `OnDeviceClient.init` | 配对文件损坏或缺 `private_key` |
| `This device is no longer paired with AltStore.` | `OnDeviceError.pairingNotTrusted` (1) | `:278`（FFI `code=1 sub_code=54`） | 设备明确吊销了这条配对记录 |
| `The remote AltServer couldn't complete this operation.` | `OnDeviceError.serviceFailed` (3) | `:300` | 隧道通了，具体服务（AFC/installd/misagent）失败 |
| `AltStore couldn't reach the remote AltServer.` | `OperationError.connectionFailed` (1201) | `ServerManager.connectToRemoteServer` | **老路线**（本机/wired/wireless AltServer）连不上，与 Remote 路线无关 |

⭐ `connect` 与 `reach` 只差一个动词，却指向**两条完全不同的代码路径**，抄原文时别记错。
⭐ `Remote AltServer` 界面里那个**绿点只等于 `isReachable()` 为真，不验证配对握手** ——
所以「显示 Connected 却一刷就失败」是**正常现象**，别把绿点当成功判据。

**最快的一个判据：Error Log 列表行上直接印着错误码**（`AltStore.OnDeviceError 2`），
数字就是对号入座 —— 不用点进去、不用猜文案：

| 列表里的错误码 | = 哪条 | 含义 |
|---|---|---|
| `AltStore.OnDeviceError 0` | `invalidPairingFile` | 配对文件读不出来 |
| `AltStore.OnDeviceError 1` | `pairingNotTrusted` | 设备**主动** Reset 了连接（FFI `code=1/sub=54`）→ 记录被吊销 |
| **`AltStore.OnDeviceError 2`** | **`connectionFailed`** | ⭐ TCP 通了但**配对握手失败** → 「头号根因」 |
| `AltStore.OnDeviceError 3` | `serviceFailed` | 隧道通了，具体服务失败 |

**要更硬的证据**：AltStore 把底层 FFI 错误存进 `NSUnderlyingErrorKey`（域 `IdeviceError`，含 `code`/`subCode`/原始 message）。
⚠️ **它不在列表行上**，必须点那一行右侧的 **`⋯` 菜单** → **`View More Details`** 才会展开
（`ErrorDetailsViewController` → `formattedDetailedDescription`，里面有一项就叫 **`Underlying Error`**）。
列表行本身只显示 `localizedDescription` + `recoverySuggestion` 两句。

⚠️ 官方 FAQ（`faq.altstore.io/getting-started/error-codes`）**完全没有 `OnDeviceError` 条目** ——
这套 Remote 路线是 2026-08 才有的新东西，官方文档还没覆盖。
所以 App 里那个 `Search FAQ` 菜单项对这类错**查不到任何东西**，别在那儿浪费时间；
真答案只在 GitHub issue/PR 和源码里。

**顺手排除掉一个容易误认的**：PR #1812（端口不一定是 49152，实测见过 49621）——**排除**。
若真是端口不对，**`isReachable()` 的 TCP 探测会先失败**，报的是 `Local VPN is not currently running`，
**不是** `couldn't connect to the remote AltServer`（#1812 正文原话：*"fails the reachability probe…
The resulting log suggests the VPN is down"*）。**文案不同 ⇒ 不是同一种病。**

### ⭐⭐ 先救急：Remote 开关开着时，**经典路径被彻底切断（没有回退）**

这是本轮最有操作价值的一条发现（`RefreshAppOperation.swift:49` 原文）：

```swift
// Sideload on-device when Remote AltServer is set up and preferred; fall back to AltServer otherwise.
if UserDefaults.shared.prefersRemoteAltServer
{
    try await self.refreshOnDevice(profiles: ...)   // ← 只走这条
}
else if let server = self.context.server
{
    try await self.refreshViaServer(...)            // ← 走电脑
}
else { throw OperationError.serverNotFound }
```

注释里的 *fall back to AltServer otherwise* **不是「失败后回退」**，而是「**开关关着时才走**」——
`if/else if` 之间**没有 catch、没有重试**。`AppManager.prepareServer()` 同理：
开关开着时它**根本不会去 `findServer()`** 找本机 AltServer。

⇒ 结论：**只要 `Prefer Remote AltServer` 是开着的，刷新就 100% 卡死在设备端，永远不会去试电脑。**
⇒ 所以**眼下要立刻恢复可用**，就一步：`Settings` → 把 **`Prefer Remote AltServer` 关掉**
（`togglePrefersRemoteAltServer` 只是单纯改偏好，无二次确认），然后插线或同 WiFi，
并保证电脑上 AltServer 开着、勾了 Wi-Fi sync → `My Apps` 刷新即可。
**代价为零**：这只丢「不用电脑」的便利，**不丢 anisette 身份、不用重新 2FA**（与下面的 Reset 不同）。

### ⚠️⚠️ 头号根因：**AltServer 每装一次 AltStore，Remote 路线就断一次**（官方 issue #1800，未修复）

**机制**（源码 + PR #1800 diff 双向确认）：AltServer 每次通过 USB 安装 AltStore，**都会与设备重新配对**，
并把新记录**打包进它装上去的那个 App**（`Bundle.main.pairingFileURL`）；而**设备只信任最新那条记录**。
但 AltStore **只在自身 keychain 为空时**才采用打包进来的记录
（`SettingsViewController.swift:632`，注释原文 *"Promote bundled pairing file on first setup only"*）——
于是它继续用 keychain 里那条**已被吊销的旧记录**，握手失败 → 报 `couldn't connect to the remote AltServer`。

**触发条件**：用 AltServer（数据线）重装过一次 AltStore。官方 issue #1800 原文：
*"The only recovery is **Reset Remote AltServer**, which also discards the anisette identity and the
selected server, so it costs a new identity and a two-factor challenge."*

⭐⭐ **这条根因是「逐字对上」的，不是推测**：PR #1800 正文原话 ——
*"after any reinstall through AltServer the next on-device install or refresh **fails with "AltStore couldn't
connect to the remote AltServer"**"*，而且作者在真机上**故意关掉修复逻辑复现了同一条报错**。
报错文案一模一样 ⇒ 我们这条 `OnDeviceError 2` 就是它。

**恢复步骤（当前发行版唯一可行路径）**

1. iPad → AltStore → `Settings` → **`Remote AltServer`** → 拉到底 → **`Reset Remote AltServer`** → Reset
   （`clearRemoteAltServer()` 清 5 样：`prefersRemoteAltServer=false`、配对文件、`preferredAnisetteServerURL`、
   anisette 身份 `anisetteADIPB`、并置 `ignoresBundledPairingFile=true`）
   - 💡 副作用是好的：它顺手把 Remote 开关关了 ⇒ **经典路径立刻恢复可用**（见上面「先救急」）
2. 回 `Settings` → **`Set up Remote AltServer…`** → `Begin Setup`
   - ⚠️ **必须插电脑**：iOS 17 上配对步骤是 **`Connect to Computer`**
     （*"Plug this device into your computer with a cable, then open AltServer"*）→ 点 `Pair with AltServer`
   - ⚠️ 前置：**已用 Apple ID 登录**（没登录会先跳登录）
3. `Install LocalDevVPN`（已装过则直接过）→ Finish
4. 关掉再开 LocalDevVPN 等「已连接」→ **强杀 AltStore** → 重开 → `My Apps` 下拉 Refresh All

⚠️⚠️ **只重跑 setup 而不 Reset 是无效的**：向导步骤由 `RemoteAltServerSetupView.makePlan()` 决定，
`if Keychain.shared.devicePairingFile == nil` 才插入配对步骤 —— 记录还在（哪怕是废的）就**直接跳过配对**。
**必须先 Reset 把 keychain 清空。**

**修复状态**：PR **#1800 `Keep on-device installs working after AltServer reinstalls AltStore` 仍为 OPEN**
（`classic` 分支 HEAD 上查无 `adoptBundledPairingFileIfNeeded`）⇒ **任何已发布版本都带这个 bug**。
修好后的行为是：每次侧载前比对打包记录的 hash，变了就自动采用 —— 今后重装无需再 Reset。

⚠️ **而且这个病会复发**：Reset 会把 `ignoresBundledPairingFile` 永久置为 `true`，
而「采用打包记录」那段代码要求它**为 false**（`SettingsViewController.swift:632` 的三个条件之一）。
⇒ Reset 之后，自动采用这条路**永久关闭**了 —— 今后**每再用 AltServer 装/更新一次 AltStore，
就还得再走一遍这 4 步**。
**在 #1800 发版之前，铁律是：不要用 AltServer 重装/更新 AltStore；万不得已做了，就重做上面 4 步。**

**其余报错的处置**：

| 报错（原文） | 含义 | 处置 |
|---|---|---|
| `Remote AltServer sent invalid response` | 那台服务器抽风 | 等几分钟，或 `Choose Server` 换一台 |
| `The remote AltServer "[server]" is currently unavailable` | 那台服务器下线了 | 换一台（先跑 `remote_altserver_check.py` 看谁活着） |
| `The data couldn't be read because it isn't in the correct format`（`NSCocoaErrorDomain 3840`） | ⚠️ **与服务器无关**：国内运营商到苹果开发者服务器的连通性问题；且**回环 VPN 占掉了 iOS 唯一的 VPN 槽位**，代理挤不进去 | 与上面几条是**两类病，别混诊**。社区做法：换**自带 TUN、且环回地址可填 `10.7.0.1` 的代理客户端** |

---

### ⛔ 如果不想再跟这套工具纠缠：替代方案怎么选（2026-09-26 全网核实）

**先把免费方案的天花板说清楚**（苹果的硬限制，与工具无关，换哪家都躲不掉）：
免费 Apple ID 签名 **7 天过期**、**同时最多 3 个 App**、**每周最多 10 个 App ID**，且**没有推送/iCloud/TestFlight**。
**「永久不过期」只有 TrollStore（受机型+版本死限）或越狱 + AppSync 能做到**，其余都是 7 天或 365 天。
⚠️ 别信「第三方签名服务就永久了」——那是**共享企业证书，苹果成批吊销**，一掉签所有 App 同时失效。

| 方案 | 需要电脑 | 到期 | 钱 | 风险 / 备注 |
|---|---|---|---|---|
| **① 关掉 `Prefer Remote AltServer`**，走经典路径 | **每 7 天**（同 WiFi 即可，**不必插线**） | 7 天 | 0 | 电脑要开着且勾 Wi-Fi sync；跨网络不行 |
| **② 换 SideStore** | **仅一次** | 7 天 | 0 | 助手 App 会被下架（**StosVPN 已下架，官方改用 LocalDevVPN**）；iOS 大版本升级可能打断 |
| **③ ①/② + 付费开发者账号** | 7 → **365 天** | 365 天 | **¥688/年** | 无签名风险，只是每年续 |
| **④ 付费账号 + TestFlight（官方渠道）** | **从不** | **90 天/构建** | ¥688/年 | 每 90 天传一个新构建；**内部测试员 ≤100 免审核**，上传即可用 |
| **⑤ PWA 加到主屏幕** | 从不 | 不过期 | 0 | ⚠️ iOS 可能回收网站存储；无推送。而我们的进度在 localStorage/IndexedDB，且云备份「只上传不下载」→ **不推荐** |

**⭐ 为什么 SideStore 在架构上更抗我们踩的这个坑 —— 差别在「配对文件归谁保管」**

| | AltStore Remote | SideStore |
|---|---|---|
| 配对记录在哪 | **keychain + App bundle 里**，用户**碰不到** | **用户手里的一个文件**（`.mobiledevicepairing`） |
| 失效了怎么办 | **只能整体 `Reset Remote AltServer`** → 丢 anisette + 重做 setup + 2FA | **重新生成再导入一个文件**，anisette 与登录态都留着 |
| 生成方式 | 向导里 `Pair with AltServer`（自动） | `JitterbugPair` / `iLoader` / `idevice-pair` 手工生成 |

⇒ #1800 之所以恶心，一半是那个 bug，**一半是「配对记录埋在 keychain，出问题只能推倒重来」这个设计**。SideStore 把这一半消掉了。

⚠️ **SideStore 硬性前置**：
- `LocalDevVPN` **必须「已连接」**（它就是回环隧道，地址同样是 `10.7.0.1`；**iPad 上已装好 1.3.0**）
- ⚠️ **iOS 同一时刻只允许一个 VPN**：用 SideStore 时必须关掉 Clash Mi / 节点小宝，否则抢槽位
- 装法二选一：**iLoader**（官方推荐）或 **AltServer 隐藏菜单 `Sideload .ipa`**（`Shift` + 点托盘图标）
- 免费账号下 **3 个 App 上限是共享的**（SideStore 自己也占 1 个）→ 换 SideStore 就别同时留着 AltStore

### ⚠️⚠️ SideStore 的「版本陷阱」有两个，不止 503 那一个（2026-09-26 设备端取证）

装完 iLoader 后首次刷新若报 **`.rppairing UDID not found`**，**不是配对文件坏、也不是 VPN 问题**：

- 设备端日志逐字为：`tcpProbe 10.7.0.1:49152 (protocol: .rppairing) -> **reachable**`
  → `tunnel_create_rppairing failed with **code: 16**, message: InternalError("**TLS tunnel: Operation Timeout**")`
  ⇒ **TCP 通、TLS 握手超时** ⇒ VPN / 两个 IP / 路由 / 防火墙 / 被墙 / anisette 服务器**全部无关**。
- 两层原因叠在一起：
  1. iLoader 在 **iOS ≥ 17.4** 写的是**「二合一」plist**（lockdown 键 + rppairing 键同在一个文件里，源码
     `pairing.rs`：`plist!(dict { :< lockdown_plist, :< rppairing_plist })`），而**旧版解析器先查 rppairing 键**
     ⇒ 该文件**必然被判成 `.rppairing`**；
  2. **`0.7.0-alpha`（09-11 构建）的 RemotePairing TLS 隧道本身有 bug** —— 上游 **issue #1592**
     （症状/错误码/安装方式 iLoader→Import IPA/VPN LocalDevVPN/构建日期全部一致）被开发者以
     **“sidestore has fix”** 关闭，修复落在 **`a5d7f3c updated submodules to latest`（2026-09-18）**。
- ✅ **解法**：把 SideStore 换成**含修复的构建**（`nightly` tag 指向 `develop` HEAD，例如
  `0.7.0-20260920.1479+0dd743f7`）——它的构建时间**晚于修复提交**。装完后新版会自动调
  `MaintenanceManager.migratePairingFiles()` 把那份二合一文件**拆成 `PairingFile_Lockdown.plist` +
  `PairingFile_RemoteRP.plist`**，并删除旧文件。
- ⚠️ **版本判据「按天算」，别看标签**：这类 bug 修得快，**构建时间早于上游修复提交 = 带病版本**。
  本例 `0.7.0-alpha` 是「官方 Stable 但已知有 bug」，`nightly` 反而才是修好的那个。
- 🔧 **取证手法（可复用）**：SideStore 的调试日志走 `print()`，**不进系统 syslog**，但会写进 App 内文件
  `Documents/ConsoleLogs/console_*.log` ⇒ 电脑上直接读：
  `MSYS_NO_PATHCONV=1 python -m pymobiledevice3 apps afc --documents com.SideStore.SideStore.<TEAMID>`
  然后 `cat ConsoleLogs/<文件>` 或 `cat ALTPairingFile.mobiledevicepairing`
  （⚠️ `apps pull` 与 shell 的 `get` 在该容器报 `AFC_E_OBJECT_NOT_FOUND` status 8，**`cat` 可用**）。

**一句话决策**
- **电脑就在旁边** → **①**，零成本，别折腾
- **必须在没有电脑的地方续签** → **② SideStore**（免费）或 **④ TestFlight**（花钱，最省心）
- **已经在做 iOS 分发、迟早要上架** → 直接 **¥688/年**，顺带把 ①/② 的 7 天变 365 天，**这笔钱不是额外开销**

---

## 第 5 步：日常使用注意事项

| ⚠️ | 说明 |
|---|---|
| **不要卸载这个 App** | 卸载会清空本地数据（学习进度在 localStorage/IndexedDB）。而**云备份目前是「只上传不下载」**——服务端有副本，但**没有恢复入口**，丢了拉不回来 |
| 需要联网 | 题库与解析都在服务器上；断网启动会显示一张「没能连上服务器」的重试页 |
| 7 天没续签 | App 打不开 → 打开 AltStore → Refresh All，或让电脑与 iPad 同 WiFi 等它自动续 |

---

## 排错表

> 下面带「官方」标签的，措辞与判断来自 AltStore 官方 FAQ，不是我猜的。

| 症状 | 先查这个 |
|---|---|
| `Mismatched serial number` / 连不上 | iTunes、iCloud 是不是 **Microsoft Store 版**？换成 Apple 官网独立版 |
| AltServer 菜单里看不到 iPad | USB 线是否支持传数据；iTunes 里 WiFi 同步是否勾上；防火墙 |
| **登录卡住 / 转很久** | ① 是不是**公司/学校 WiFi**？那类网络常禁止设备互访 → **改用手机热点**（iPad 也要连同一个热点）② 防火墙是否放行 AltServer ③ **iTunes 与 iCloud 是否都开着** ④ 官方兜底：**插 USB**，能解决几乎所有连接问题（代价是后台自动刷新走不了 WiFi） |
| `Could not find AltServer`（同 WiFi、无 USB；**USB 一切正常**） | ⭐⭐ **2026-09-25 定位：两道关卡，缺一不可**：<br>**【关卡 1】iTunes 里的「通过 Wi-Fi 与此 iPad 同步」没开** —— 不开这一项，`Apple Mobile Device Service` 就不把 iPad 当**网络设备**暴露，AltServer 只能走 USB → WiFi 下报 `could not be found`（错误码 **1200**）。**这一关已修好。**<br>**【关卡 2】让 iPad 端重新发现 AltServer** —— 即使 AltServer 的注册完全正常，iPad 上的 AltStore 也可能**攥着旧记录不放**（AltServer 每次重启端口都会变：55649 → 63529 → 63876 …）→ 报 `could not be found`。**处置必须成对做**：重启 AltServer **并且**在 iPad 上**强制退出 AltStore 再打开**（只做一半无效）。<br>✅ **成功基准（2026-09-25 现场抓包）**：`from 192.168.0.28 QUERY '_altserver._tcp.local PTR'` → `SELF from 192.168.0.12 RESP` 含 `PTR + TXT(serverID) + SRV=…:63876 + A=192.168.0.12` → 紧接着 iPad 追问该实例的 SRV → 装成功。<br>⚠️ **别用 usbmuxd 的设备数判成败**：实测装成功那一刻，本机 `DeviceList` 依然为空（Windows 上它似乎只列 USB 设备）。<br>🔧 仍不通时的兜底：以**管理员**身份重启 AMDS（`net stop` / `net start` Apple Mobile Device Service；普通权限会报「无法打开计算机上的服务」，**不是服务坏了**）。<br>🔧 **判定（一条命令，全链路）**：`python tools/altserver_repair.py` —— 依次查 进程/端口 → `_apple-mobdev2` 广播 → **usbmuxd 设备列表** → `_altserver._tcp` 注册 → 端口可达；其中 **`[3]` 设备数必须 ≥ 1**。只查 WiFi 同步用 `python tools/apple_wifi_sync_check.py <电脑局域网IP>`。<br>🔧 **修复**：USB 连 iPad（解锁）→ 打开 **iTunes** → **左上角那个很小的设备图标** → **摘要** → 勾「**通过 Wi-Fi 与此 iPad 同步**」→ **点「应用」** → 拔线（保持同一 WiFi）→ iPad 上**强制退出 AltStore 再打开** → 重试。<br>✅ **复验**：重跑 `apple_wifi_sync_check.py`，应看到 `_apple-mobdev2` 广播 + 解析出 IPv4。<br>⛔ **三条判据已被实测证伪，别再拿来判定**：① 配对记录里的 `EnableWifiConnections` 字段 —— **WiFi 同步已生效时它依然不出现**（本机实测，plist 修改时间也没变）；② `TCP 62078 OPEN` —— 与 WiFi 同步无关，OPEN 也照样失败；③ **「`mdns_resolve.py` 探到 `_altserver` 无应答」≠ Bonjour 注册丢了** —— 那是工具自己的 **QCLASS bug**（QU 位加到了 QTYPE 上、QCLASS 写成 12 而非 1 → mDNSResponder **静默忽略整条查询**），工具只能被动截获公告包，表现为「刚重启能探到、过一两分钟探不到」。已修；⭐ **查询类工具必须先拿一个「必定有应答」的服务（如 `_services._dns-sd._udp.local`）做阳性对照**，否则会把工具 bug 当成被测对象的故障。<br>⚠️ 前置：iTunes / iCloud **必须是 Apple 官网独立版**（Store 版会让设备发现失效）；AltServer 建议**以管理员身份运行**。<br>📌 **已排除（都实测过，别再查）**：iPad「本地网络」权限已开；iPad 自身 mDNS 正常；iPad 的 **TCP 62078 在 WiFi 上 OPEN**；跨 AP / 跨频段 mDNS 通（打印机有应答、0.16 的 `_dosvc` 也有应答）；**AltServer 的 Bonjour 广播完全正常**（`_altserver._tcp` 的 PTR/SRV/TXT/A 实时应答，端口 63876 可连）；Windows 防火墙对 AltServer 入站已放行（Private+Public）；Clash Verge 未接管网络（TUN 关、系统代理关、allow-lan false）；Bonjour Service 与 AMDS 均在运行。<br>🧰 工具：`tools/apple_wifi_sync_check.py`（WiFi 同步体检）、`tools/mdns_resolve.py`（AltServer 广播体检）、`tools/mdns_capture.py`（实时旁听）。
| **iPad 与电脑不在同一个局域网，想续签** | ⛔ **AltServer 做不到** —— 异地组网（节点小宝/蒲公英/ZeroTier/Tailscale）给的是纯 L3 隧道，**不运 mDNS 组播**，发现链直接断（2026-09-26 实测：NAS 查 `_altserver._tcp` 为空、电脑旁听隧道 45 秒 0 包）→ **换机制**：① **AltStore Classic 2.3 的 Remote AltServer**（需 iOS 17.4+、LocalDevVPN）② **SideStore** ③ **TestFlight**（99 美元/年，最省事）。详见 **第 4 步 B** |
| AltStore 里没有 **+** 号 | 装成 AltStore **PAL** 了（那是欧盟/日本/巴西专用，且要 iOS 18+）。要装 Classic |
| **AltStore 自己的窗口又小又居中** | ⚠️ **这是正常的，不是故障**：AltStore Classic 是 **iPhone 应用**，没做 iPad 版 → iPad 用「iPhone 兼容模式」显示它，居中一块手机尺寸画布。→ 想放大就点它**右下角那个小图标**（切「放大/Scale Up」）。**我们自己的 App 不受这个影响**（见下方说明） |
| **弹「不受信任的开发者」** | ⭐ **这是"没信任证书"，不是"没开开发者模式"**。→ **设置 → 通用 → VPN与设备管理 →「开发者 App」→ 点 `iPhone Developer: <账号>` → 信任**。（开发者模式在「隐私与安全性」里，别找错地方） |
| 装完点开闪退 | **开发者模式**开了吗（设置 → 隐私与安全性 → 最底部）？证书信任了吗（VPN与设备管理）？ |
| ⭐⭐ **AltStore 本体打开就闪退**（不是我们那个 App） | ⭐ **2026-09-26：这可能就是 `could not be found` 的真因** —— AltStore 启动后能发出 Bonjour 查询，但在进入「追问 SRV」之前**进程就崩了** → 表现为 iPad **只问 PTR、从不追问 SRV**，而电脑侧全链路全绿（现场抓包实证：iPad 反复发 `_altserver._tcp.local PTR` 且握有满 TTL 的新记录，说明应答收到了，却始终不进入 resolve）。<br>🔍 **判据**：电脑侧 mDNS/TCP 全绿（`altserver_repair.py --probe` 无红）+ iPad 在发 `_altserver._tcp` PTR 查询、**却从不追问 SRV** → 优先怀疑 **iPad 侧 AltStore 进程崩溃**，别再修网络。<br>🔧 **处置**：AltStore **不在 App Store，没有第二条路** → 只能用电脑的 AltServer **重装 AltStore**：① **插 USB**（故意走 USB，绕开当前 WiFi 发现链）② AltServer **托盘图标** → **Install AltStore** → 选 iPad → 输入 Apple ID ③ **拔线前先 `Refresh All` 成功一次** ④ 重开后**重新登录 Apple ID**、重开后台刷新。<br>⛔ **教训：不要手动清 AltStore 的数据/缓存** —— 清了只能靠电脑重装；要腾空间请清别的。 |
| 页面白屏 | 壳会自恢复一次；仍白屏就用 Safari 直接打开 `https://constructexam.cadqto.com/app/` 对照 |
| App 打不开、提示需要重新验证 | 签名过期 → AltStore → Refresh All |
| 什么都试了还不行 | 官方三条通用检查：**以管理员身份运行 AltServer**、**iTunes/iCloud 从 Apple 官网装**、**换个 Apple ID**（可以免费建一个专用于 AltStore） |

---

## 你的设备适配情况（已逐项实测确认）

| 项 | 你的设备 | 本 App 的要求 | 结论 |
|---|---|---|---|
| 系统 | iPadOS **17.7.11** | `MinimumOSVersion = 15.0` | ✅ 可安装 |
| 机型 | iPad 2018（第六代，A10 Fusion） | `UIRequiredDeviceCapabilities = [arm64]` | ✅ A10 正是 arm64 |
| 屏幕 | 9.7" **4:3**（逻辑 768×1024） | 自适应布局 | ✅ 已按 768×1024 与 1024×768 两个方向实测排版 |
| 图标 | — | iPad 专用图标 | ✅ 包内含 `AppIcon76x76@2x~ipad.png` |

**验证方式**：把线上页面按 **768×1024** 与 **1024×768** 精确分辨率渲染出来逐一看过 ——
四个科目、题型分布、底部导航都排得开，无溢出、无拥挤。

### ⚠️ TrollStore 用不了（已核实）

它只支持 **iOS 14.0 – 16.6.1、16.7 RC 和 17.0**；**17.0.1 及以后永不支持**
（它依赖的 CoreTrust 漏洞已被 Apple 修掉）。你的 **17.7.11 不在范围内**。
→ 所以 **AltStore + 7 天续签是你唯一可行的路**，别在 TrollStore 上花时间。

### ⚠️ 一个要留意的点：内存

iPad 2018 是 **2 GB 内存**。本 App 的内容层是 WebView + 一个不算小的 JS 应用，
内存紧张时 iOS 可能回收 WebView 进程。

**壳里已经处理了这件事**：进程被回收后会自动 `reload()`，所以最坏情况是「页面重新加载一次」，
不会白屏死掉。如果你在用的时候遇到偶发的「页面闪一下重新加载」，那就是这个机制在工作，属正常。

---

## 一句话安装流程

1. **电脑（一次性）**：Apple 官网版 iTunes + iCloud → AltServer → `Install AltStore` → iPad 上信任证书 + 开开发者模式
2. **iPad**：Safari 打开 `https://constructexam.cadqto.com/download/constructexam-v1.12.1-ios-unsigned.ipa` → 「文件」里分享给 AltStore
3. **之后**：AltStore 设「刷新应用：始终」+ AltServer 开「WiFi 同步」，每 7 天自动续签
4. **想彻底不依赖电脑**（异地也能续签）：AltStore 升到 **≥ 2.3** → 设置里 **Set up Remote AltServer…**（配一次）→ 装 **LocalDevVPN** → 之后**连 WiFi 就能自己签**（第 4 步 B）
