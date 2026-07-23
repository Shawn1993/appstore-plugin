---
name: appstore
description: 当用户提到 iOS/macOS App 的任何 App Store 事务时触发——上架、提审、审计/preflight、审核被拒、TestFlight、ASC 填写、元数据/截图/文案、关键词与 ASO、排名监控、评论管理、编辑精选、内购订阅配置、数据分析，以及开发者账号注册、ASC API Key 申请、中国区 App 备案办理。Make sure to use whenever the user mentions 上架、提审、App Store、ASC、TestFlight、ASO、拒审，即使只给了一个网站或 App 名。不适用：Android 各商店上架、App 功能开发本身。
---

# App Store 全生命周期管理

> 各分册里的规格数字是核实过的速查缓存；涉及尺寸/字数等硬规格且事关提交成败时，按 references/official/index.md 的官方页先核对再执行。

**文件地图**（按知识来源分三组）：
- `references/guides/` — 自有方法论：prerequisites（开发者账号/API Key 申请/App 备案办理）、asc-cli（CLI 手册）、aso-playbook（ASO 运营）、screenshots（截图生产）、regions（地区合规）、derived-app-audit（模板/壳衍生 App 专项）
- `references/official/` — 官方文档索引：index（高频页+信任等级说明）、sitemap（ASC Help 全站 263 页，`scripts/refresh-sitemap.sh` 可重抓）
- `references/preflight/` — 第三方拒审规则库（MIT 引入，信任等级见 official/index.md）
- `assets/` — 模板：metadata-template（提审资料全字段）、audit-report-template.md/.html（审计报告）、report-viewer.html + report-data-template.json（交付页固定壳与数据 schema，配 scripts/build-report.py）、UploadOptions.plist（直传配置）

## Dispatch

**任何分支开工前**：先找项目根的 `.appstore/config.md`（§0 的落盘产物）——有就直接读取 App ID/Key/市场等既定事实，别重问用户。

| 触发输入 | 走哪 |
|---|---|
| "要上架 / 出上架的东西"（无论给的是网站、repo 还是描述） | §0 智能采集 → §1 物料 → §2 构建直传 → §3 ASC 清单 → §4 审计 → 提交 |
| 只要文案/截图/某一样物料 | §0 快速采集 → §1 对应块 |
| "审计 / 会不会被拒 / preflight" | §4 |
| 审核被拒（贴拒信） | §4 拒信条款号 → 规则库定位 → 修复回环 |
| 明确要改**线上商店**的元数据/多语言/截图（"更新 App Store 上的描述"这类指向线上的表述） | references/guides/asc-cli.md（asc metadata pull/push）|
| 只说"改描述/改文案"未指明线上 | 先一句确认：改本地文案草稿，还是推到 App Store 线上？前者走 §1，后者走 asc-cli |
| TestFlight 分发/测试组 | references/guides/asc-cli.md TestFlight 节 |
| 上线后：关键词/排名/评论/精选/活动 | §6 + references/guides/aso-playbook.md |
| 过审了 | §5 |
| "怎么申请开发者账号 / API Key / App 备案"或采集时答"还没有" | references/guides/prerequisites.md 对应节 |

## 交互与产出规范（贯穿所有节）

- **必答题一次问完，不要散文追问**：有结构化提问能力的 agent（如 Claude Code 的 AskUserQuestion）出选项卡片；没有的就一条消息列齐全部问题与候选项。能给选项的都给选项（付费模式 = 免费/付费/含内购；目标市场 = 多选），不分多轮
- **开场亮作战地图**：走全流程时先给六阶段 checklist（采集→物料→构建→ASC→审计→提交），每完成一段勾一段再继续——用户随时知道走到哪
- **长产出交文件不刷屏**：提审资料等成体系产出写成文件交付（复制粘贴友好），对话里只给摘要
- **审计报告默认收尾于可视化 HTML 文件**：写到项目 `.appstore/audit-report.html`，对话里只报总判定和文件路径；本地文件即最终交付（Claude Code 用户明确要可分享链接时才发布为 claude.ai Artifact，其他 agent 无此能力则始终本地文件）。网页填充 `assets/audit-report-template.html`（判定灯/分区卡/依据 chip/术语 tooltip 样式全内置，禁止重写 CSS），结构与写作三规则见 audit-report-template.md（依据超链接溯源、标题说人话讲后果、术语带 hover 解释）；md 归档版同规则
- **全流程（上架一条龙）最终收尾于一体化交付页**（viewer 数据驱动，不手写 HTML）：只产出纯数据文件 `.appstore/report-data.json`（字段参考 `assets/report-data-template.json`；值里可用内联 `<span class="ev">`/`<span class="t" data-tip>`），然后 `python3 scripts/build-report.py .appstore/report-data.json .appstore/delivery-report.html` 组装——固定壳 `assets/report-viewer.html`（左侧栏对齐 ASC 后台、字段卡一键复制、字符数由壳现算超限标红）由脚本注入数据输出单文件。脚本会做 schema 校验与截图路径检查，报错就改 JSON 重跑。浏览器验证渲染后，对话里只报总判定和文件路径。只做单项任务（只审计/只文案）时仍用对应单项交付，不强行套壳
- **提审资料按 `assets/metadata-template.md`**——不许自由发挥结构

## 0. 智能采集（用户友好的核心：能自己挖的绝不问）

用户只需给**一个入口**：产品网站 URL、H5 地址、或项目 repo 路径。按下表自动挖掘，全部挖完后**一次性**产出「采集确认卡」——已解析结果表 + 结构化必答题（形式见上方交互规范），不要一路追问：

| 信息 | 挖掘方式 |
|---|---|
| App 名/slogan/功能列表 | 抓取网站首页与 about 页（用 agent 的网页抓取能力）；repo 则读 README/首页组件 |
| 用户协议/隐私政策 URL | 抓页脚和"我的/关于"页链接；没有 → 生成两份标准文本并给出部署方案（这是提审硬门槛） |
| ICP 备案号 | 抓网站页脚（主体号）；App 备案服务号（-XA）挖不到，列入必答题 |
| 品牌色/视觉风格 | 网站 CSS 主色、logo；用于截图设计稿风格 |
| 截图素材 | 站内产品图；或起模拟器实拍（见 references/guides/screenshots.md） |
| 类目/关键词候选 | 由功能列表推导，按 references/guides/aso-playbook.md 关键词规则出草稿 |
| 收集哪些数据（隐私问卷） | 扫 repo 的 SDK 依赖与网络调用；无 repo 则按功能推断后让用户确认 |
| Xcode 工程/bundle id/版本号 | repo 内 grep pbxproj |

**必答题控制在 ≤5 个**（挖不到才问）：ASC API Key 位置、付费模式、目标市场（决定走 references/guides/regions.md 哪些合规门槛，含中国区则追问 App 备案服务号）、审核联系人电话邮箱。**用户答"还没有"的项**（无开发者账号/无 Key/无备案）→ 把 references/guides/prerequisites.md 对应节给用户照做，备案和公司账号是周级依赖要最先启动。

产出：填好的 `assets/metadata-template.md` + 截图计划 + 待办清单，用户确认后进入后续节。**并把采集结果与必答题答案落盘到项目根 `.appstore/config.md`**（App 名/Apple ID/bundle id/Key ID/Issuer ID/目标市场/协议 URL/提审开关地址等）——这是跨会话记忆，日后发版、改元数据、运营都从它读起。

## 1. 物料生产

**文案**：按 `assets/metadata-template.md` 全字段产出。描述固定结构：核心价值一句 → 【功能块】×N → 信任语 → 底部固定信息（支持语言、隐私政策、用户协议、反馈渠道）。标题/副标题/关键词的字符分配与去重规则见 references/guides/aso-playbook.md（关键词字段不重复标题词、逗号分隔不加空格等）。

**广告法审查**（中国区必做，元数据和设计图内文字都查）：绝对化用语直接删；数量词要么可举证要么"海量"；不塞竞品名；境外 AI 产品名禁入（规则细节见 references/preflight/rules/metadata/china_storefront.md）。

**截图**：尺寸表、sips 缩放/补边、设计稿艺术加工边界（2.3.3）、图生图跨设备转档流程，全在 references/guides/screenshots.md。

**协议页**：必须是自有域名可公开访问的 URL，App 内入口与 ASC 填写同源一致。

## 2. 构建直传（低自由度：照抄，别改 flag）

前置：ASC API Key（.p8 放 `~/.appstoreconnect/private_keys/`；没有 Key → 按 references/guides/prerequisites.md §2 申请）。使用 key 的任何命令前**自动检查并修复文件权限**（非 600 先 `chmod 600` 再继续，不打扰用户——权限过宽 asc 直接拒跑）。

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

看到 `Uploaded <App>` + `EXPORT SUCCEEDED` 才算成功；处理 10-30 分钟。archive 分钟级，放后台。元数据侧的自动化（不点网页）用 asc CLI：references/guides/asc-cli.md。

## 3. ASC 逐页清单（陪填）

**App 信息**：名称/副标题(30)/主类别选垂直小类目而非"工具"大杂类（细分榜+编辑专题都按类目挑）/内容版权/年龄分级问卷/ICP 备案号。
**法规**：按目标市场过 references/guides/regions.md（欧盟发行必做 DSA 交易者声明；中国区 ICP/版号；加密文稿 HTTPS 豁免跳过）。
**App 隐私**：政策 URL + 问卷（无账号 App：反馈内容+联系方式→App 功能/不关联/不追踪，其余不收集）。答完必须点「发布」。
**价格销售**：档位；供应情况默认全选 175 区——改为按目标市场勾选（选区策略与各区门槛见 references/guides/regions.md；之后加减区不重审）。
**版本页**：截图 → 文案 → 版权（与 ICP 备案主体一致）→ 构建版本选最新 → 审核信息（无登录必须取消「需要登录」勾选 + 备注模板见 assets/metadata-template.md）→ 发布选项（有服务端开关选手动）。
**提交**：「添加以供审核」→ 出口合规「是→仅豁免加密(HTTPS)」→ 提交。周期 1-3 天。

## 4. 审计（跑两遍；被拒也走这）

**时机**：代码级规则（隐私清单、entitlements、4.2 信号）在**第一次 archive 之前**跑——审计发现的问题几乎都要改代码出新构建，放在流程末尾等于白打一个包；元数据/截图类快检在点提交前再过一遍。

**规则库审计**（规则内置于本 skill 的 `references/preflight/`，MIT 引自 app-store-preflight-skills，见其 ATTRIBUTION.md）：先读 `references/preflight/guidelines/by-app-type/all_apps.md` 再叠 app 类型清单（订阅/UGC/儿童/AI/游戏…），逐条过 `references/preflight/rules/{metadata,privacy,design,subscription,entitlements}/`（每条带指南编号+检测法+真实拒审案例），按 `assets/audit-report-template.md` 出报告（总判定灯 + 必拒/风险/已核三段表 + 下一步），可修的修完重扫更新报告。**被拒**：拿拒信条款号在 rules/ 里 grep 定位对策；回复审核团队时用 rules/metadata/review_notes_template.md。

**本土化快检**（规则库不覆盖的中国区项）：
- [ ] 构建版本 = 含全部修复的最新 build
- [ ] TARGETED_DEVICE_FAMILY 与截图档位一致（声明 iPad 就必须有 iPad 截图）
- [ ] 首启流程在最小 iPhone 和 iPad（如声明）各过一遍
- [ ] 模板/老项目/壳衍生的 App：已按 references/guides/derived-app-audit.md 专项过一遍（品牌残留、提审开关、断网可用）
- [ ] 元数据+设计图无广告法违禁词、ICP 已填

## 5. 过审后

"等待开发者发布"→ 先做服务端切换（壳 App 开关切回远程）→ 点发布。推广文本/定价/销售地区可随时改不触发重审（截图、描述、关键词则要随新版本提交），时效内容放推广文本。上线即做：编辑精选提名（传统文化/教育题材中国区有优势）、开启评分弹窗策略（见 aso-playbook）。

## 6. 上线后运营（按需读 references/guides/aso-playbook.md）

- **关键词与排名**：免费栈 = iTunes Search API（无需注册，`itunes.apple.com/search?term=X&country=cn&entity=software`，结果顺序≈排名代理）+ ASC「App 分析」真实搜索来源词。可写 cron 定时拉排名存库。付费估算量（Appeeky $8/月起）等有真实曝光数据再上
- **评论管理**：差评回复策略、版本更新置顶回复
- **增长面**：自定义产品页（不同渠道不同截图）、in-app events、A/B 测试商店页
- **数据**：asc CLI 拉 analytics/销售报表（references/guides/asc-cli.md）

## Gotchas（普适项）

- ⚠️ **声明 iPad = 审核员真的用 iPad 测**（这就是 §4 要求 iPad 过主流程的原因）；不想适配就 `TARGETED_DEVICE_FAMILY = 1` 先 iPhone-only，后续版本加 iPad 无额外门槛
- ⚠️ **ICP 三个号别混**：ASC 填 **App 备案服务号**（`粤ICP备XXX号-2A`，字母 A 后缀），不是主体号也不是网站号。工信部另要求 App 内展示此号（我的/关于页，苹果不查、监管抽查）
- ⚠️ **无登录 App**：审核信息「需要登录」默认勾着，必须取消；勾着+空账号密码必打回
- ⚠️ **出口合规别答"无加密"**：用了 HTTPS 就属于"豁免的加密"（正确选项见 §3）；Info.plist 加 `ITSAppUsesNonExemptEncryption = NO` 可免每次提交弹这一问
- ⚠️ **截图必填档位以报错为准**：ASC 界面常显示多余的可选 tab（如 Apple Watch），只有「无法添加以供审核」错误里点名的档位才必须补
- ⚠️ **仓库里有 ≠ 包里有**：关键资源（隐私清单、内置 H5 包、字体）可能躺在目录里却没进 target——提审前直接 `ls` archive 的 `.app` 内部验证实物存在（实战案例：PrivacyInfo.xcprivacy 在仓库躺了几个版本，pbxproj 零引用，包里一直没有）
- ⚠️ **构建号便宜，多传备用**：同一版本可上传多个 build；审核中发现新问题就修好传下一个号备着——被拒时版本页直接换 build 重提，远快于撤回修改。审核中（In Review）截图/元数据/构建都锁定，撤回会丢排队位置，非致命问题等结果再说
- ⚠️ **拒审类规则不在这里重复维护**：中国区境外 AI 敏感词、隐私清单（PrivacyInfo.xcprivacy）、订阅元数据双链接等均以 `references/preflight/rules/` 为唯一出处——§4 审计会逐条过，别凭记忆答，以规则文件为准

## 护栏

- 🚫 「提交以供审核」「发布此版本」只指导用户点或经明确同意代点——提审时机与上线节奏是用户的决策
- 🚫 不塞竞品商标进关键词/文案，用户坚持也先讲清 2.3.7 拒审风险
- 🚫 一切写生产 ASC 的操作（构建上传、metadata push、screenshots apply）：写前必有依据（构建号已 +1；`--dry-run` diff 已给用户看过并确认——"改描述"可能只是改本地草稿，指向不明先问一句），写后必有证据（`EXPORT SUCCEEDED` / push 成功回显），没证据不许说"传好了"，失败原样贴日志
- 🚫 §0 采集只读公开页面与用户 repo，不登录、不抓第三方竞品后台数据
