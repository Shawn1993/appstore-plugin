# appstore-plugin

App Store 全生命周期管理的 Claude Code plugin。从「只给一个网站 URL」到提审通过，一条龙覆盖：

**A full-lifecycle App Store management skill for Claude Code** — from "just give me your website URL" to approved release: metadata generation, screenshot production, CLI build upload, App Store Connect walkthrough, rejection-rule audit, rejection recovery, TestFlight, and post-launch ASO. Includes China-specific compliance (ICP filing, advertising-law wording, review-mode switch pattern for hybrid apps).

## 功能

| 阶段 | 能力 |
|---|---|
| 智能采集 | 只需产品网站/repo 路径，自动解析 App 名、功能、协议页、ICP、品牌色、隐私问卷答案，必答题 ≤5 个 |
| 物料生产 | 推广文本/描述/关键词/副标题全套文案（含字符分配与去重规则）、截图三条生产路线与尺寸合规化 |
| 构建直传 | xcodebuild + ASC API Key 命令行直传，不开 Xcode；asc CLI 元数据 pull/push 自动化 |
| ASC 陪填 | App 信息/隐私问卷/定价/版本页/审核信息逐页清单（含无登录 App、出口合规等易错项标准答案） |
| 提审审计 | 内置拒审规则库（按 app 类型的检查单 + metadata/privacy/design/subscription/entitlements 规则，每条带指南编号与真实案例）+ 中国区本土化快检 |
| 被拒恢复 | 拒信条款号定位规则、Resolution Center 回复模板、申诉决策 |
| 上线运营 | 关键词研究（免费数据栈）、评分弹窗策略、评论管理、编辑精选自荐、In-App Events、A/B 测试 |

## 安装

**万能一行命令**（自动装进本机所有支持 Agent Skills 标准的 agent —— Claude Code / Codex / Gemini CLI / OpenClaw / Hermes…）：

```bash
curl -fsSL https://raw.githubusercontent.com/Shawn1993/appstore-plugin/main/install.sh | sh
```

更新也是重跑这一条。装到自定义位置：`SKILLS_DIR=<目录> sh install.sh`

<details>
<summary>各 agent 手动安装</summary>

本 skill 遵循开放的 Agent Skills 标准（SKILL.md + references/），装进任何读取 skills 目录的 agent 均可用：

| Agent | 方式 |
|---|---|
| Claude Code（plugin 方式） | `/plugin marketplace add Shawn1993/appstore-plugin` → `/plugin install appstore@appstore-plugin` |
| Claude Code（skill 方式） | 复制 `skills/appstore` → `~/.claude/skills/` |
| Codex | 复制 `skills/appstore` → `~/.codex/skills/` |
| Gemini CLI | 复制 `skills/appstore` → `~/.gemini/skills/` |
| OpenClaw | 复制 `skills/appstore` → `~/.openclaw/skills/` |
| 其他支持 SKILL.md 的 agent | 复制 `skills/appstore` → 该 agent 的 skills 目录 |
| 不支持 skills 的 agent | 把 `skills/appstore/SKILL.md` 内容并入其系统提示 / AGENTS.md，references/ 按路径随工程放置 |

> SKILL.md 正文为中文，但任何语言的用户都可直接使用——agent 读中文知识、用用户的语言回应。中国区合规知识（ICP/广告法/提审开关）正是英文世界稀缺的部分。

</details>

## 使用

装好后不需要记命令——对 Claude 说人话即可自动触发：

- 「我要上架，这是我的网站 https://…」→ 全流程
- 「审计一下会不会被拒」→ 规则库扫描出三段式报告
- 「被拒了」+ 贴拒信 → 条款定位 + 回复模板
- 「帮我出上架截图」/「关键词怎么写」→ 对应物料

## 结构

```
skills/appstore/
├── SKILL.md                    # 主路由：dispatch 表 + 六阶段 SOP + gotchas + 护栏
├── assets/
│   ├── metadata-template.md    # 提审资料全字段模板
│   └── UploadOptions.plist     # xcodebuild 直传配置
├── scripts/
│   └── refresh-sitemap.sh      # 重抓官方帮助全站索引
└── references/
    ├── guides/                 # 自有方法论
    │   ├── asc-cli.md          #   asc CLI 实战手册
    │   ├── aso-playbook.md     #   ASO 与上线后运营（零外部 API 依赖）
    │   ├── screenshots.md      #   截图尺寸与生产路线
    │   ├── regions.md          #   全球地区合规矩阵
    │   └── derived-app-audit.md#   模板/壳衍生 App 专项审计
    ├── official/               # 官方文档索引
    │   ├── index.md            #   高频官方页 + 三体系信任等级
    │   └── sitemap.md          #   ASC Help 全站 263 页
    └── preflight/              # 拒审规则库（第三方，MIT）
```

## 前置条件

- App Store Connect API Key（.p8，放 `~/.appstoreconnect/private_keys/`）——构建直传与 asc CLI 需要
- 可选：`brew install asc`（元数据自动化）、codex CLI（截图设计稿图生图）

## License

MIT。`references/preflight/` 规则库引自 [truongduy2611/app-store-preflight-skills](https://github.com/truongduy2611/app-store-preflight-skills)（MIT），见 ATTRIBUTION.md。
