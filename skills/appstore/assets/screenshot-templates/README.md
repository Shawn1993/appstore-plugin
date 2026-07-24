# 截图模板库（代码化模板，路线 C 的素材层）

每个模板 = 自包含 HTML，画布 1290×2796（iPhone 6.9" 档）。用法：

1. 复制模板，替换 `{SCREENSHOT_PATH}`（app 原始截屏，file:// 绝对路径或相对路径）与 `<h1>/.sub` 文案
2. 换主题只改 `:root` 里的变量（背景/装饰/文字色/标题字号）
3. 出图：`npx playwright screenshot --viewport-size=1290,2796 --wait-for-timeout=1500 file://<模板>.html out.png`
4. 其他档位：改 html,body 与 viewport 尺寸（iPad 13" 用 2064×2752，机身样机改 iPad 圆角比例）

| 模板 | 版式 | 适合 |
|---|---|---|
| t1-hero | 纯色底+旋转色块，左上大标题，机身底部出血 | 首图/核心卖点 |
| t2-dark-tilt | 近黑底+辉光，eyebrow+居中标题，机身斜置 -2.4° | 氛围图/内容展示 |
| t3-top-bleed | 亮色底+装饰块，机身顶部出血，标题在下 | 功能图/列表类界面 |

版式骨架提炼自 Median.co 的 Figma 社区模板库（500+ App store screenshot templates，坐标/字号/色值取自其文件 JSON），实现为独立 HTML。文案遵循 screenshots.md 的文案原则（一图一利益点、大字动词开头）。
