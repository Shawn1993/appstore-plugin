# asc CLI 实战手册（App-Store-Connect-CLI，`brew install asc`）

> 元数据/TestFlight/截图/提审/定价的命令行自动化。认证：`asc auth login` 或 env `ASC_KEY_ID`/`ASC_ISSUER_ID`/`ASC_PRIVATE_KEY_PATH`（与 xcodebuild 直传同一把 .p8）。拿不准用 `asc auth doctor`。

## 全局规范

- 输出 TTY 感知：终端 table、管道里 minified JSON；`--pretty` 只对 JSON 生效
- 破坏性操作都要 `--confirm`；全量列表用 `--paginate`
- 命令发现：`asc search "自然语言"` / `asc schema --pretty "GET /v1/apps"` / `asc capabilities --area release`
- ID 解析：别 `head -1` 猜，`--output table` 人工确认或用确定性 bundle-id 查：`asc apps list --bundle-id com.x.y`
- **zero/one/many 范式**：list 结果 0 个→create，1 个→复用，>1 个→停下要显式 ID（v2 version 资源没有 delete，误建清不掉）

## 元数据 pull/push（替代网页手填）

```bash
asc metadata pull --app "APP_ID" --version "1.2.3" --platform IOS --dir "./metadata"
# 树结构：metadata/app-info/*.json + metadata/version/<ver>/*.json
asc metadata validate --dir "./metadata" --output table        # 订阅 App 加 --subscription-app
asc metadata push --app "APP_ID" --version "1.2.3" --dir "./metadata" --dry-run   # 先看 diff
asc metadata push --app "APP_ID" --version "1.2.3" --dir "./metadata"             # 再真推
# 关键词专用：
asc metadata keywords diff --app "APP_ID" --version "1.2.3" --dir "./metadata"
```

坑：copyright 不是本地化字段（用 `asc versions update --copyright`）。字段索引权重与免审改动规则见 references/aso-playbook.md §1。

## 构建与上传

```bash
asc builds info --app "APP_ID" --latest --platform IOS         # 最新 build → .data.id
asc xcode version edit --next-build-number --app "APP_ID" --platform IOS  # build 号过低一步修
asc publish appstore --app "APP_ID" --ipa "./App.ipa" --version "1.2.3" --wait --submit --confirm  # 端到端
asc builds expire-all --app "APP_ID" --older-than 90d --dry-run
```

坑：`asc builds upload` 只上传不做端到端，完整流用 `asc publish`；.pkg 必须显式 `--version --build-number`。

## TestFlight

```bash
asc testflight groups create --app "APP_ID" --name "内测组"
asc testflight testers add --app "APP_ID" --email "x@y.com" --group "内测组"
asc builds add-groups --build-id "BUILD_ID" --group "GROUP_ID"
asc builds test-notes create --build-id "BUILD_ID" --locale "zh-Hans" --whats-new "本次测试要点"
asc publish testflight --app "APP_ID" --ipa "./app.ipa" --group "GROUP_ID" --wait
asc testflight crashes list --app "APP_ID"                     # 崩溃triage
```

## 截图

```bash
asc screenshots sizes --all --output table      # 尺寸矩阵权威源，永远别硬编码
asc screenshots validate --path "./resized" --device-type "IPHONE_67"
asc screenshots upload --version-localization "LOC_ID" --path "./final" --device-type "IPHONE_67"
```

坑：ASC 拒带 alpha 通道的 PNG（JPEG 往返一次去 alpha）；macOS 截图文件名含 U+202F 窄空格会报 "not a valid file"，先重命名；Display P3 转 sRGB。

## 提审与发布

```bash
asc validate --app "APP_ID" --version "1.2.3" --platform IOS --strict --output table  # 提审就绪门禁
asc review doctor --app "APP_ID" --version "1.2.3"             # 阻塞项有序解释
asc release stage --app "APP_ID" --version "1.2.3" --build "BUILD_ID" --metadata-dir "./metadata/version/1.2.3" --confirm
asc review submit --app "APP_ID" --version "1.2.3" --build "BUILD_ID" --dry-run
asc submit status --version-id "VERSION_ID"
asc review history --app "APP_ID" --version "1.2.3" --paginate # 区分当前卡审 vs 历史
```

坑：一个 version 已有 review submission 时别建第二个；审核变慢别急着 cancel；无 retry 命令——cancel→修→re-validate→重提。

## 多语言

```bash
asc localizations download --version "VERSION_ID" --path "./loc"
asc localizations upload --version "VERSION_ID" --path "./loc" --dry-run
asc apps info edit --app "APP_ID" --version-id "VID" --locale "en-US" --whats-new "..." --keywords "a,b,c"
```

坑：keywords 禁直译（按当地真实搜索词重研）；超长重写不截断；欧语用正式敬语；whatsNew 前 ~170 字符是折叠前唯一可见段。

## 定价 / 订阅（有内购再看）

```bash
asc subscriptions pricing prices import --subscription-id "SUB_ID" --input "./ppp.csv" --dry-run
asc validate subscriptions --strict        # 任何跨系统同步前的硬门禁，零写入也要跑
```

坑：v2 版本作用域资源（subscription/IAP/group 的 version）没有 delete 且父删不级联——别建着玩；本地化 create 必须带非空 description。

## 设计模式（写自动化脚本时套用）

- **dry-run → confirm 三段式**：validate 先、dry-run 次、加 `--confirm` 终
- **audit-first**：批量操作默认只读对账，写需显式确认，per-item 失败继续最后汇总
- **门禁证据留存**：`asc validate --strict` 的 JSON 重定向存 `./audit/` 保留退出码
- **canonical 目录**：`./metadata` 树是多工具共享契约，别自创布局
