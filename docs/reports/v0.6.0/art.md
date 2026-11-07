# v0.6.0 / 美术工作记录

## 状态

- 状态：完成；正式资产已迁移，UI 实际界面审稿通过
- 最后更新：2026-11-08
- 下一步入口：进入 v0.7 卡池与第二挑战美术；继续遵守美术提交、UI 审稿的独立分工

## 本版本目标

为序列 8 后可重复挑战提供独立视觉，包括挑战选择、数据驱动修饰、挑战结算、模式徽记和牌组限制标识。保持旧档案、铜版画、暗金与干血红方向，不复用官方角色或来源不明图片。

## 依赖

- `AGENTS.md`、`docs/CURRENT_VERSION.md`、`docs/PROJECT_CHARTER.md`
- `docs/ARCHITECTURE_CONTRACT.md`、`docs/versions/v0.6.0.md`
- `art/ART_DIRECTION.md`、`art/ASSET_MANIFEST.md`
- 美术与 UI 分离规则：美术只提交候选，UI 负责实际界面验收

## 已完成

- 1600×900 挑战选择背景，预留三个修饰卡安全区。
- 1600×900 挑战结算背景，预留中央印章和结算信息区域。
- 6 个 128×128 数据驱动修饰徽记：
  - 压力提前
  - 镜厅回响
  - 奖励限制
  - 紧凑牌组
  - 强化护盾
  - 首领阶段提前
- 128×128 挑战成功/失败印章。
- 256×256 挑战模式徽记。
- 128×128 牌组限制标识。
- 可编辑 SVG、渲染 PNG、HTML 预览、渲染清单和审稿拼图。

## 修改文件

- `art/tools/generate_v060_art.mjs`
- `art/assets/svg/v0.6.0/**`
- `assets/game/v0.6.0/**`
- `art/preview/v0.6.0/index.html`
- `art/README.md`
- `art/ASSET_MANIFEST.md`

## 验证

```text
SVG XML: 12/12 passed
PNG dimensions: 12/12 matched manifest
Contact sheet: 1600 × 2300
Baked text/font-family: none
Generator dependency: Node.js built-ins + local Edge only
```

审稿拼图：`G:\guimizhizhu\assets\game\v0.6.0\contact-sheet.png`

![v0.6 challenge art candidates](G:/guimizhizhu/assets/game/v0.6.0/contact-sheet.png)

## 困难与候选方案

| 困难 | 候选方案 | 最终选择 |
|---|---|---|
| 挑战界面需要三个同时可读的修饰槽，但直接绘制整张卡会限制 UI 布局 | 生成完整挑战卡；只生成背景和独立徽记 | 背景保留空槽，徽记独立输出，由 UI 组合文字和状态 |
| 修饰数量多于首版三个 | 每个徽记单独命名；使用通用装饰图标 | 生成 6 个独立候选，玩法确定后只接入实际使用的修饰 ID |
| 挑战结果需要区分成功/失败而不烘焙文字 | 生成两枚镜像印章 | 成功使用金线对勾，失败使用血线叉号，语义不依赖中文 |
| 挑战视觉容易变成普通战斗换色 | 引入破碎镜片、档案框和独立面具徽记 | 用镜厅碎片围绕中央档案印记，和普通遭遇保持区别 |

## 风险

- 6 个修饰 ID 目前是候选命名，玩法角色确定正式 ID 后需要做一次映射核对。
- 背景空槽尺寸按 3 列设计；若 UI 改成两列，需要调整锚点或重新导出版本。
- 图标缩至 32—48px 时，复杂镜片纹理可能损失；UI 应保留足够对比度和标签。

## 跨角色请求

```text
[REQUEST]
从：美术
给：玩法设计
版本：v0.6.0
内容：请确认最终挑战修饰稳定 ID；当前候选为 pressure_advance、mirror_echo、restricted_reward、compact_deck、reinforced_guard、early_phase
原因：UI 图标映射必须以正式 ID 为准
期望接口：挑战修饰只读快照包含 icon_asset_id
截止检查点：UI 挑战页面接入前
[END REQUEST]
```

```text
[REQUEST]
从：美术
给：UI 设计
版本：v0.6.0
内容：挑战选择背景包含三个并列空槽；挑战结算背景中央圆形区域用于印章。请在接入后检查 32—48px 徽记可读性、背景对比度和结果信息遮挡
原因：美术不得自行完成界面验收
期望接口：UI 实际截图与通过/退回结论
截止检查点：v0.6.0 UI 验收
[END REQUEST]
```

## 下一步入口

正式资产已迁移到 `assets/game/v0.6.0/**`，UI 已完成实际界面审稿并判定原型范围通过。

