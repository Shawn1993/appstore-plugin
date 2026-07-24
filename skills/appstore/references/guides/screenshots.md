# 上架截图生产手册

## 尺寸表（提交前以 `asc screenshots sizes --all` 为准，苹果会变）

| 档位 | 竖屏 | 说明 |
|---|---|---|
| iPhone 6.9" | 1320×2868 | 当前主档 |
| iPhone 6.7" | 1290×2796 | 可由 6.9 缩放 |
| iPhone 6.5" | 1242×2688 / 1284×2778 | legacy 档，ASC 上传框标注为准 |
| iPad 13" | 2064×2752 或 2048×2732 | 声明支持 iPad 才必填 |

规则：只校验像素尺寸不管来源；前 3 张进安装列表；最多 10 张 + 3 个视频预览。

## 快速合规化（手头图尺寸不对时）

```bash
sips -z <高> <宽> in.png --out out.png                 # 比例接近直接缩放（注意高在前）
sips --resampleWidth <宽> in.png --out t.png && \
sips -p <高> <宽> --padColor FFFFFF t.png --out out.png  # 比例差大：等比缩+补边
```

坑：ASC 拒带 alpha 的 PNG（JPEG 往返去 alpha）；文件名含 macOS 截图自带的 U+202F 窄空格会报 not a valid file；P3 色域转 sRGB。

## 四条生产路线

**选路顺序**：默认走 C（代码化模板——文字永远不会错、零成本、改文案秒级重出，生成式出图画中文高频翻车且每张都要人眼验字）；只求快、展示真实功能 → A；用户要模板做不出的定制艺术风格、或已有设计稿跨设备转档 → B（需生成工具可用）；要人手反复精修排版 → D。

**A. 真机/模拟器实拍 + 合规化**：模拟器 ⌘S 原生就是正确尺寸（iPad Pro 13" 模拟器直出 2064×2752）。最快，适合功能真实展示。

**B. 设计稿艺术加工**（主流商店风格：背景+标题+机身样机内嵌真实界面）：
- 完全允许，底线=审核指南 2.3.3 真实反映功能；避免用设备边框却展示非真实内容
- 已有 iPhone 设计稿转 iPad 版：图生图转档（任何支持参考图的生成工具，如 codex CLI 的 image_generation：`codex exec -s workspace-write "Generate an image: <描述>. Save it as x.png. Use your image generation tool." -i 参考图.png`），prompt 写明 3:4 比例 + **逐条列出必须复现的中文文案**（AI 画中文最大翻车点），出图后 sips 放大到目标尺寸，逐张人眼验字后才交付
- 文字安全区：所有文案保持在中央 ~70% 宽度内（生成图常需两侧裁切）

**C. 代码化模板**（默认路线）：HTML 排版 → `npx playwright screenshot --viewport-size W,H --wait-for-timeout=1500` 直出精确尺寸。**先用 `assets/screenshot-templates/` 里的现成版式**（hero/暗色斜置/顶部出血三款起步，换 :root 变量即换主题，用法见其 README），没有合适的再自写。headline ≤6 词、benefit-first、从上到下连读成完整产品故事、ASO 关键词至少覆盖 3 个且分散在不同图。

**D. 可视化编辑器**（要反复精修排版/跨图连版/多语言迭代时）：装 [ParthJadhav/app-store-screenshots](https://github.com/ParthJadhav/app-store-screenshots)（6k+ star，MIT，`npx skills add ParthJadhav/app-store-screenshots`）——它脚手架出一个本地 Next.js 编辑器：真机边框、元素可横跨相邻截图的连版画布、拖拽调序、多语言/RTL、项目状态存 `app-store-screenshots.json` 可 git 续改，一键导出全档位合规 PNG（含 Google Play 与 1024×500 feature graphic）。其 `style-prompts/` 附 6 套从真实爆款店面提炼的深度风格规格（含量化的字号/配色/旋转角规则），做设计稿路线时可直接借用。**导出后仍要过本文档的合规检查与广告法审查**——该工具不含中国区与 2.3.3 边界知识。

## 竞品样例收集（做图前先看市场在做什么）

iTunes API 的 `screenshotUrls` 免登录直出任何 App 的商店截图原图：`itunes.apple.com/search?term=<品类词>&country=cn&entity=software&limit=10`，逐条下载 `screenshotUrls` 数组即可。用途：①摸清品类竞品的视觉水平与常用版式（同类第一名怎么排、用不用营销加工）②挑爆款版式提炼成新模板进 `assets/screenshot-templates/`。样本是真实过审且市场验证过的——比任何模板库都可信。

## 文案原则（适用所有路线）

- 每张图 = 一个用户利益点（不是功能名），大字动词开头 + 小字补充
- 状态栏用满信号满电量（iOS 惯例时间 9:41）
- 多语言截图：文字与 UI 语言一致，别英文 UI 配中文标题
