# v0.7.0 / 美术工作记录

## 状态

- 角色：美术
- 任务：新增卡面、卡组编辑背景、第二挑战徽记与修饰图标
- 状态：候选完成，等待 UI 实机审稿
- 最后更新：2026-11-08
- 下一步入口：主协调者迁移 `assets/game/v0.7.0/**` 到 `assets/game/v0.7.0/**`，UI 复审后决定通过或退回

## 依赖

- `AGENTS.md`、`docs/CURRENT_VERSION.md`、`docs/PROJECT_CHARTER.md`
- `docs/ARCHITECTURE_CONTRACT.md`、`docs/versions/v0.7.0.md`
- `art/ART_DIRECTION.md`、`art/ASSET_MANIFEST.md`
- 正式 v0.7 卡牌、牌组与挑战数据
- 美术与 UI 分离规则：美术只提交候选，UI 负责实际界面验收

## 已完成

- 8 张正式新增卡牌的无文字 512×400 卡面：
  - 守夜圆环、提灯步、灵性预感、镜中记忆。
  - 命运回声、穿刺凶兆、棺钉、第二视觉。
- 1600×900 卡组编辑/收藏背景，预留 10 个收藏格、8 个牌组槽、三套预设区和底部按钮安全区。
- 256×256 第二挑战“破碎游行”徽记。
- 三个正式 v0.7 修饰图标：
  - `challenge.modifier.obituary_echo`
  - `challenge.modifier.twin_shadow`
  - `challenge.modifier.ritual_vigil`
- 128×128 数据覆盖路线节点图标。
- 可编辑 SVG、候选 PNG、HTML 预览、渲染清单和审稿拼图。

## 修改文件

- `art/tools/generate_v070_art.mjs`
- `art/assets/svg/v0.7.0/**`
- `assets/game/v0.7.0/**`
- `art/preview/v0.7.0/index.html`
- `art/README.md`
- `art/ASSET_MANIFEST.md`

## 验证

```text
SVG XML: 14/14 passed
PNG dimensions: 14/14 matched manifest
Contact sheet: 1600 × 2300
Baked text/font-family: none
Generator dependency: Node.js built-ins + local Edge only
```

审稿拼图：`G:\guimizhizhu\art\exports\v0.7.0\contact-sheet.png`

![v0.7 art candidates](G:/guimizhizhu/assets/game/v0.7.0/contact-sheet.png)

## 困难与候选方案

| 困难 | 候选方案 | 最终解决 |
|---|---|---|
| 首轮卡面 SVG 只输出了内部图形，浏览器无法识别文档根节点 | 在 Edge 中逐张修复；重建全部卡面；手工包装根 SVG | 在生成器统一使用 `svgDoc()` 包装卡面，随后重新渲染全部候选 |
| 美术开始时正式卡牌 ID 尚未落盘 | 先使用描述性候选名；等待玩法数据；直接猜测 ID | 先完成不依赖 ID 的背景/徽记，正式数据出现后改为 8 个真实稳定 ID |
| 第二挑战实际包含三个新修饰，而最初只要求两个 | 只提供两个通用图标；为三个正式 ID 各做图标 | 将原两枚候选重映射，并补做“通宵守仪”蜡烛图标 |
| 卡面需要同时表达三类构筑方向 | 绘制完整卡牌并烘焙文字；只做抽象符号 | 使用独立无文字象征物，标题、费用和数值继续由 Godot 组合 |

## 风险

- 卡面是程序化几何占位美术，精细度适合原型，不替代商业插画。
- 卡面缩至手牌约 58px 高度时需要保持核心符号可辨，交由 UI 实机检查。
- 卡组背景空槽为 5×2 收藏区和 8 槽牌组栏；如果 UI 改成不同列数，需要重新适配。
- 第二挑战修饰图标在 32—64px 下需检查差异；美术不自行通过界面验收。

## 跨角色请求

```text
[REQUEST]
从：美术
给：主协调者
版本：v0.7.0
内容：将 assets/game/v0.7.0/** 一次性迁移到 assets/game/v0.7.0/**，更新渲染清单路径
原因：正式运行时只能引用 assets/game，不能长期保留双份候选
期望接口：迁移后 assets/game/v0.7.0/render-manifest.json 路径全部解析成功
截止检查点：UI 卡组页面接入前
[END REQUEST]
```

```text
[REQUEST]
从：美术
给：UI
版本：v0.7.0
内容：实机检查 8 张新卡缩略图、卡组编辑背景安全区、第二挑战徽记和 3 个修饰图标
原因：美术不得自行完成界面验收
期望接口：UI 在卡组编辑、第二挑战和结算截图记录通过/退回/仅 UI 适配结论
截止检查点：v0.7.0 关闭前
[END REQUEST]
```

## 下一步入口

等待主协调者迁移资源，等待 UI 完成实际界面审稿。目标检查点为新增卡面在手牌、收藏和牌组槽中均可辨识，背景不遮挡选择操作，修饰图标在 32—64px 下仍可区分。


