# Changelog

## v1.1.0 (2026-07-23)

首个实战验证版。相对 v1.0.0 的主要演进：

- **审计**：规则库审计时机前移（首次 archive 前）；报告固定模板（判定灯 + 必拒/风险/已核 + 下一步）；默认产出本地可视化 HTML（依据超链接溯源、术语 hover 人话解释）
- **交互**：必答题走 AskUserQuestion 卡片；开场作战地图；采集结果落盘 `.appstore/config.md` 跨会话记忆
- **新分册**：prerequisites（开发者账号/API Key 申请/App 备案办理 + 实战 FAQ）、regions（全球地区合规矩阵）、official/（ASC Help 全站 263 页索引 + 高频页速查）
- **实战回填**：8 轮真实上架复盘产生的 gotchas（仓库里有≠包里有、构建号备用策略、In Review 锁定、QQ 邮箱开通翻车等）
- **结构**：references 按知识来源分组（guides 自有 / official 官方 / preflight 第三方），信任等级显式标注
- **实测**：asc CLI 核心命令（auth doctor/search/review status）验证通过并回改

## v1.0.0 (2026-07-22)

初始发布：六阶段 SOP、内置拒审规则库（MIT 引自 app-store-preflight-skills）、构建直传、中国区专项。
