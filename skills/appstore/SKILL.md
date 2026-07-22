---
name: appstore
description: 当用户提到 iOS/macOS App 的任何 App Store 事务时触发——上架、提审、审计/preflight、审核被拒、TestFlight、ASC 填写、元数据/截图/文案、关键词与 ASO、排名监控、评论管理、编辑精选、内购订阅配置、数据分析。Make sure to use whenever the user mentions 上架、提审、App Store、ASC、TestFlight、ASO、拒审，即使只给了一个网站或 App 名。不适用：Android 各商店上架、App 功能开发本身。
---

# App Store 全生命周期管理

## Dispatch

| 触发输入 | 走哪 |
|---|---|
| "要上架 / 出上架的东西"（无论给的是网站、repo 还是描述） | §0 智能采集 → §1 物料 → §2 构建直传 → §3 ASC 清单 → §4 审计 → 提交 |
| 只要文案/截图/某一样物料 | §0 快速采集 → §1 对应块 |
| "审计 / 会不会被拒 / preflight" | §4 |
| 审核被拒（贴拒信） | §4 拒信条款号 → 规则库定位 → 修复回环 |
| 明确要改**线上商店**的元数据/多语言/截图（"更新 App Store 上的描述"这类指向线上的表述） | references/asc-cli.md（asc metadata pull/push）|
| 只说"改描述/改文案"未指明线上 | 先一句确认：改本地文案草稿，还是推到 App Store 线上？前者走 §1，后者走 asc-cli |
| TestFlight 分发/测试组 | references/asc-cli.md TestFlight 节 |
| 上线后：关键词/排名/评论/精选/活动 | §6 + references/aso-playbook.md |
| 过审了 | §5 |

## 0. 智能采集（用户友好的核心：能自己挖的绝不问）

用户只需给**一个入口**：产品网站 URL、H5 地址、或项目 repo 路径。按下表自动挖掘，全部挖完后**一次性**把「已解析结果 + 剩余必答题」列给用户确认，不要一路追问：

| 信息 | 挖掘方式 |
|---|---|
| App 名/slogan/功能列表 | WebFetch 网站首页与 about 页；repo 则读 README/首页组件 |
| 用户协议/隐私政策 URL | 抓页脚和"我的/关于"页链接；没有 → 生成两份标准文本并给出部署方案（这是提审硬门槛） |
| ICP 备案号 | 抓网站页脚（主体号）；App 备案服务号（-XA）挖不到，列入必答题 |
| 品牌色/视觉风格 | 网站 CSS 主色、logo；用于截图设计稿风格 |
| 截图素材 | 站内产品图；或起模拟器实拍（见 references/screenshots.md） |
| 类目/关键词候选 | 由功能列表推导，按 references/aso-playbook.md 关键词规则出草稿 |
| 收集哪些数据（隐私问卷） | 扫 repo 的 SDK 依赖与网络调用；无 repo 则按功能推断后让用户确认 |
| Xcode 工程/bundle id/版本号 | repo 内 grep pbxproj |

**必答题控制在 ≤5 个**（挖不到才问）：ASC API Key 位置、App 备案服务号、付费模式、销售地区、审核联系人电话邮箱。

产出：填好的 `assets/metadata-template.md` + 截图计划 + 待办清单，用户确认后进入后续节。

## 1. 物料生产

**文案**：按 `assets/metadata-template.md` 全字段产出。描述固定结构：核心价值一句 → 【功能块】×N → 信任语 → 底部固定信息（支持语言、隐私政策、用户协议、反馈渠道）。标题/副标题/关键词的字符分配与去重规则见 references/aso-playbook.md（关键词字段不重复标题词、逗号分隔不加空格等）。

**广告法审查**（中国区必做，元数据和设计图内文字都查）：绝对化用语直接删；数量词要么可举证要么"海量"；不塞竞品名（2.3.7 风险）；境外 AI 产品名一个都不能出现（查全部 locale）。

**截图**：尺寸表、sips 缩放/补边、设计稿艺术加工边界（2.3.3）、codex-draw 图生图 iPhone→iPad 的实测流程，全在 references/screenshots.md。

**协议页**：必须是自有域名可公开访问的 URL，App 内入口与 ASC 填写同源一致。

## 2. 构建直传（低自由度：照抄，别改 flag）

前置：ASC API Key（.p8 放 `~/.appstoreconnect/private_keys/`）。

```bash
# 1) bump 构建号（每次上传必须 +1）
sed -i '' 's/CURRENT_PROJECT_VERSION = N;/CURRENT_PROJECT_VERSION = N+1;/g' <App>.xcodeproj/project.pbxproj

# 2) archive
xcodebuild -workspace <App>.xcworkspace -scheme <App> -configuration Release \
  -destination 'generic/platform=iOS' -archivePath build/<App>.xcarchive \
  -authenticationKeyPath ~/.appstoreconnect/private_keys/AuthKey_<KEYID>.p8 \
  -authenticationKeyID <KEYID> -authenticationKeyIssuerID <ISSUERID> \
  -allowProvisioningUpdates archive

# 3) 直传 ASC（assets/UploadOptions.plist，改 teamID）
xcodebuild -exportArchive -archivePath build/<App>.xcarchive \
  -exportOptionsPlist UploadOptions.plist \
  -authenticationKeyPath ~/.appstoreconnect/private_keys/AuthKey_<KEYID>.p8 \
  -authenticationKeyID <KEYID> -authenticationKeyIssuerID <ISSUERID> \
  -allowProvisioningUpdates
```

看到 `Uploaded <App>` + `EXPORT SUCCEEDED` 才算成功；处理 10-30 分钟。archive 分钟级，放后台。元数据侧的自动化（不点网页）用 asc CLI：references/asc-cli.md。

## 3. ASC 逐页清单（陪填）

**App 信息**：名称/副标题(30)/主类别选垂直小类目而非"工具"大杂类（细分榜+编辑专题都按类目挑）/内容版权/年龄分级问卷/ICP 备案号。
**法规**：DSA（只发中国区不设）、加密文稿（HTTPS 豁免跳过）、其余按业务。
**App 隐私**：政策 URL + 问卷（无账号 App：反馈内容+联系方式→App 功能/不关联/不追踪，其余不收集）。答完必须点「发布」。
**价格销售**：档位；供应情况默认 175 区，服务器在境内只勾中国大陆（之后加区不重审）。
**版本页**：截图 → 文案 → 版权（与 ICP 备案主体一致）→ 构建版本选最新 → 审核信息（无登录必须取消「需要登录」勾选 + 备注模板见 assets/metadata-template.md）→ 发布选项（有服务端开关选手动）。
**提交**：「添加以供审核」→ 出口合规「是→仅豁免加密(HTTPS)」→ 提交。周期 1-3 天。

## 4. 审计（提审前必跑；被拒也走这）

**规则库审计**（规则内置于本 skill 的 `references/preflight/`，MIT 引自 app-store-preflight-skills，见其 ATTRIBUTION.md）：先读 `references/preflight/guidelines/by-app-type/all_apps.md` 再叠 app 类型清单（订阅/UGC/儿童/AI/游戏…），逐条过 `references/preflight/rules/{metadata,privacy,design,subscription,entitlements}/`（每条带指南编号+检测法+真实拒审案例），产出 Rejections/Warnings/Passed 三段报告，可修的修完重扫。**被拒**：拿拒信条款号在 rules/ 里 grep 定位对策；回复审核团队时用 rules/metadata/review_notes_template.md。

**本土化快检**（规则库不覆盖的中国区项）：
- [ ] 构建版本 = 含全部修复的最新 build
- [ ] TARGETED_DEVICE_FAMILY 与截图档位一致（声明 iPad 必有 iPad 截图且 iPad 实测过）
- [ ] App 内协议 URL 是本 App 的，非模板老 App 残留
- [ ] 首启流程在最小 iPhone 和 iPad（如声明）各过一遍
- [ ] 启动屏/设置页无老 App 品牌残留（拼音水印放大看）
- [ ] 壳 App：提审开关已切"接口空→本地包"，断网启动功能完整
- [ ] 元数据+设计图无广告法违禁词、ICP 已填

## 5. 过审后

"等待开发者发布"→ 先做服务端切换（壳 App 开关切回远程）→ 点发布。推广文本/定价/地区/截图之后随时改不重审，时效内容放推广文本。上线即做：编辑精选提名（传统文化/教育题材中国区有优势）、开启评分弹窗策略（见 aso-playbook）。

## 6. 上线后运营（按需读 references/aso-playbook.md）

- **关键词与排名**：免费栈 = iTunes Search API（无需注册，`itunes.apple.com/search?term=X&country=cn&entity=software`，结果顺序≈排名代理）+ ASC「App 分析」真实搜索来源词。可写 cron 定时拉排名存库。付费估算量（Appeeky $8/月起）等有真实曝光数据再上
- **评论管理**：差评回复策略、版本更新置顶回复
- **增长面**：自定义产品页（不同渠道不同截图）、in-app events、A/B 测试商店页
- **数据**：asc CLI 拉 analytics/销售报表（references/asc-cli.md）

## Gotchas（普适项）

- ⚠️ **声明 iPad = 审核员真的用 iPad 测**：提审前必须在 iPad（真机或模拟器）过一遍主流程；不想适配就 `TARGETED_DEVICE_FAMILY = 1` 先 iPhone-only，后续版本加 iPad 无额外门槛。App 源自模板/老项目/壳 → 必读 references/derived-app-audit.md（品牌残留四查处、iPad 三必炸点、壳提审开关等专项）
- ⚠️ **ICP 三个号别混**：ASC 填 **App 备案服务号**（`粤ICP备XXX号-2A`，字母 A 后缀），不是主体号也不是网站号。工信部另要求 App 内展示此号（我的/关于页，苹果不查、监管抽查）
- ⚠️ **无登录 App**：审核信息「需要登录」默认勾着，必须取消；勾着+空账号密码必打回
- ⚠️ **出口合规**：HTTPS 是「是→仅豁免加密」不是"无加密"；Info.plist `ITSAppUsesNonExemptEncryption = NO` 免每次弹窗
- ⚠️ **截图必填档位以报错为准**：ASC 界面常显示多余的可选 tab（如 Apple Watch），只有「无法添加以供审核」错误里点名的档位才必须补
- ⚠️ **中国区敏感词查全部 locale**：ChatGPT/Gemini 等境外 AI 名任何语言版本出现都算（preflight 规则库实测案例）
- ⚠️ **PrivacyInfo.xcprivacy 被三方 SDK 传染性要求**：自己没调 Required Reason API，SDK 用了 UserDefaults 也要有隐私清单，缺了 ITMS 警告
- ⚠️ **订阅双链接**：ToS/隐私政策在 App Store 描述和 App 内购买页都要有，缺任一处是独立拒审项

## 护栏

- 🚫 「提交以供审核」「发布此版本」只指导用户点或经明确同意代点——提审时机与上线节奏是用户的决策
- 🚫 不塞竞品商标进关键词/文案，用户坚持也先讲清 2.3.7 拒审风险
- 🚫 构建/元数据直传改的是生产 ASC 记录：构建号先 +1，没看到 `EXPORT SUCCEEDED`（或 asc push 成功回显）不许说"传好了"，失败原样贴日志
- 🚫 `asc metadata push` / `screenshots apply` 这类写线上的命令：必须先 `--dry-run` 把 diff 展示给用户、用户确认后才执行真推——"改描述"这种话永远可能只是改本地草稿，指向不明时先问一句
- 🚫 §0 采集只读公开页面与用户 repo，不登录、不抓第三方竞品后台数据
