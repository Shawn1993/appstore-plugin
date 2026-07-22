# 模板/壳衍生 App 专项审计

> 仅当 App 源自旧项目改造、购买的模板、或 WebView 壳时读本册。全新原生工程跳过。

## 品牌残留固定四查处（提审前逐处 grep）

1. **launch storyboard**：放大看每个 label——老 app 的拼音水印/slogan 常以 10pt 小字藏在底部
2. **常量文件**：用户协议/隐私政策 URL 是否还指向老 app 的文档域名
3. **微信等三方 SDK**：appid/secret/universalLink 常量 + Info.plist 的 wx URL scheme
4. **entitlements**：associated-domains 里的老域名（applinks/webcredentials）

原则：未启用的三方能力**清空常量并停掉注册调用**（如 WXApi.registerApp），比换成假值干净——假值照样是待解释的关联。

## 声明 iPad 前的三个必炸点（模板工程通病）

审核员会真的用 iPad 测。老 iPhone 模板在 iPad 上的高发炸点：

1. **按屏宽线性放大字号的自绘弹窗**：iPad 屏宽是 iPhone 2.5 倍，字号爆掉压过写死坐标。修法：布局参考宽度钳制 `min(屏宽, 500)`，iPhone 数值不变
2. **只声明竖屏 → iPadOS 窗口化横屏黑边**：加 `INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad` 四方向，并确认主视图用约束而非写死 frame
3. **启动屏在大屏暴露残留**：小字在 iPhone 上没人注意，13 寸上一目了然

不想处理：`TARGETED_DEVICE_FAMILY = 1` 先 iPhone-only 上架，后续版本加 iPad 无额外门槛。

## 壳 App（WebView）提审开关模式

- 后端接口约定："返回空 → 加载内置本地 H5 包；返回 URL → 加载远程"。提审版本进 audit 名单或全局置空；过审后改配置文件即时切换，不发版
- 本地包必须经 **WKURLSchemeHandler 自定义 scheme** 提供：file:// 直载时 H5 的 fetch 本地 JSON 会被同源策略拦死
- 自定义 scheme 页面发外部请求带 `Origin: <scheme>://<host>`（**实测不是 null**）——API 服务端 CORS 要按 scheme 前缀放行，否则本地包模式下所有接口调用被浏览器拦
- 提审前断网启动验证：App 功能应完整（审核员网络环境不可控）

## 模拟器验证技巧

- 沙盒 App 的 UserDefaults 用 `simctl spawn defaults` 写不进（Domain not found）：卸载重装重置，或直写容器 plist（`simctl get_app_container <udid> <bundle> data` + PlistBuddy）
- `simctl launch --console-pty` 启动的 app 生命周期绑在控制台进程上，kill 控制台连带杀 app——截图前别杀
