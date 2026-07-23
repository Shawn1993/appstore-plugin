# 准备工作指南（第一次上架前的三件周边事）

> §0 采集发现缺什么，就把对应节发给用户照做。三件事都是一次性的。

## 1. Apple 开发者账号（一切的前提，$99/年）

- 入口：https://developer.apple.com/programs/enroll/ ，用 Apple ID（开双重认证）申请
- **个人 vs 公司**：个人账号开发者名称显示为个人姓名，注册最快（当天-2天）；公司账号显示公司名、可加团队成员，但需要 **DUNS 邓白氏编码**（免费申请，中国公司走邓白氏中国官网，1-2 周）+ 营业执照一致性核验
- 中国开发者注意：身份验证在 Apple Developer App（手机）里完成刷脸/证件；年费可用国内信用卡
- 选择建议：不确定就先个人（之后可转公司账号，App 和评分保留）；版权主体想写公司名、或多人协作 → 直接公司账号

## 2. App Store Connect API Key（自动化的钥匙，本 skill 一切 CLI 能力的前提）

**申请步骤**（需 Account Holder 或 Admin 角色操作）：

1. 登录 https://appstoreconnect.apple.com → 右上「用户和访问」→「集成」tab →「App Store Connect API」→ 团队密钥（Team Keys）
2. 首次使用需先点「申请访问权限」（Request Access，即刻通过）
3. 「+」生成密钥：起名（如 `ci-key`）、**选角色**——推荐 **App Manager**（能传包/改元数据/提审，权限够用且不给财务面）；只读需求选 Developer；要动协议税务才用 Admin
4. 下载 `.p8` 文件——**只有这一次下载机会**，错过只能作废重建；同页记下 **Key ID**（10 位）和页面顶部的 **Issuer ID**（UUID，全团队共用一个）

**存放规范**：

```bash
mkdir -p ~/.appstoreconnect/private_keys
mv ~/Downloads/AuthKey_XXXXXXXXXX.p8 ~/.appstoreconnect/private_keys/
chmod 600 ~/.appstoreconnect/private_keys/AuthKey_XXXXXXXXXX.p8   # 权限宽了 asc 会拒跑
```

xcodebuild 和 asc CLI 都默认从这个目录找 key。**三件套（.p8 + Key ID + Issuer ID）妥善备份**——.p8 等同于团队操作权限，泄漏了立刻在 ASC 撤销；换机器只需拷这一个目录。

**验证可用**：`brew install asc && ASC_KEY_ID=<KeyID> ASC_ISSUER_ID=<IssuerID> ASC_PRIVATE_KEY_PATH=~/.appstoreconnect/private_keys/AuthKey_<KeyID>.p8 asc auth doctor`

## 3. 中国区 App 备案（只发中国大陆才需要）

前提：备案主体已有 ICP 主体备案（网站备案过就有）。App 备案是主体备案下新增一个 App 服务：

1. 在你服务器/域名所在的云平台备案控制台（阿里云/腾讯云等都有「App 备案」入口）发起，选择已有主体新增 App 服务
2. 需要准备：App 名称、**iOS Bundle ID**（对 Android 还要公钥/签名 MD5）、服务内容描述、负责人实名+人脸核验
3. 周期：平台初审 1-2 天 + 管局审核 3-15 个工作日（各省不同）；通过后短信/平台下发**服务号**（`省ICP备XXXXXXXX号-NA`，字母 A 结尾即 App 服务）
4. 拿到号后两处使用：ASC「App 信息」页的 ICP 栏；App 内「我的/关于」页展示并可跳 beian.miit.gov.cn
5. 查询与核对：https://beian.miit.gov.cn

**时间规划**：备案是上架路径上最长的外部依赖（可能 2-3 周），立项就该启动，别等 App 做完。开发者账号（公司版含 DUNS 也要 1-2 周）同理。其余环节（Key、协议页、物料）都是小时级。
