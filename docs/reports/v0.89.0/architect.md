# v0.89.0 · 架构师报告

## AR-05 · 渲染器评估 → ADR-0035

版本：v0.89.0  
角色：架构师  
任务：AR-05（ADR-0034 D4）  
状态：完成

### 修改文件

- `docs/decisions/ADR-0035-desk-world-renderer.md`（决策）
- `tools/architecture/ar05_renderer_compare_runner.gd` / `.tscn`
- `tools/architecture/ar05_run_compare.sh`
- `docs/reports/v0.89.0/ar05_renderer/**`（缩略图、report.txt、METRICS.md）
- `.cursor/agents/architect/tasks.md`

### 依赖

- 日记站现有公开捕获入口（`get_desk_stage` / `force_render_for_capture`）；**未改** UI 生产文件。
- Godot 4.7.2；macOS M4 真窗口（禁止 headless 截 3D）。

### 验证

```text
tools/architecture/ar05_run_compare.sh
# 或逐法：
# Godot --path . --rendering-method <gl_compatibility|mobile|forward_plus> \
#   res://tools/architecture/ar05_renderer_compare_runner.tscn
```

| method | driver | fps_avg | 入库缩略图 |
|---|---|---|---|
| gl_compatibility | opengl3 | 20.2 | `ar05_renderer/gl_compatibility_*_thumb.png` |
| mobile | metal | 32.2 | `ar05_renderer/mobile_*_thumb.png` |
| forward_plus | metal | 17.4 | `ar05_renderer/forward_plus_*_thumb.png` |

全分辨率：`.tools/ui-captures/ar05_renderer/`（git 忽略，可复跑脚本再生）。

### 困难与候选方案

1. 保持 Compatibility + 美术假阴影 → 拒（D4 明确要评 SSAO/后期）。  
2. 默认 Mobile（帧率最好）→ 无 SSAO，P0-3 天花板不够。  
3. **默认 Forward+**，Mobile 作性能档 → 采纳。

### 最终解决

见 ADR-0035：桌面默认 **Forward+**；Compatibility 降级为应急；UI-P0-3 可开 SSAO/glow/ACES。`project.godot` 切换由协调者在授权合入时落地（本任务评估不合入该行，避免与主会话 UI P0 抢文件）。

### 风险

- 2920×1753 全开 FX ≈17 fps；需质量开关。  
- 仅测 M4；Windows Vulkan 真机冒烟仍须协调者补一刀。

### 跨角色请求

- **主协调者**：合入 `rendering_method=forward_plus`（及 mobile 覆盖）；冒烟 Windows。  
- **UI（UI-P0-3）**：按 ADR-0035 接口开后期；勿再按 Compatibility 假设调光。  
- **产品**：配置合入后改 `ORIENTATION.md` 渲染器一句。

### 下一步入口

- UI-P0-3 解阻（渲染器结论已出）。  
- AR-06 仍 blocked（UI-X0-rev）。  
- AR-03 / AR-03b 仍等 UI P0 合并。

---

## AR-07 · 可读性测试补「遮挡」维度

版本：v0.89.0  
角色：架构师  
任务：AR-07  
状态：完成

### 测试设计

完整舞台（`DiaryChapterScreen` → `DeskStage`，已跑 `DeskQuality.apply_*`）上，对左右页各 7 个 UV 采样点：

| 采样 | UV |
|---|---|
| 四角 | (0.06,0.06) (0.94,0.06) (0.06,0.94) (0.94,0.94) |
| 题名 / 正文 / 蜡封 | (0.50,0.10) / (0.50,0.42) / (0.50,0.78) |

从 `DeskCamera` 到采样世界坐标做**开线段**，与站内其他**可见** `MeshInstance3D` 的世界 AABB 做 slab 相交；`_book_root` 下网格允许。命中页面以外（如 `RoomBackplate`）即 `clear=false`。

选用几何 AABB 而非 `PhysicsRayQuery`：书页/背景板无碰撞体，headless 不造生产 StaticBody。

公开钩子（只读，不改规则）：

- `page_uv_to_world(is_left, uv)`
- `get_page_occlusion_report() -> {clear, hits, quality_backplate_present, ...}`

### 修改文件

- `src/ui/diary_page_occlusion.gd`（新）
- `src/ui/diary_desk_stage.gd`（仅上述钩子；**不含** RoomBack 摆放修复）
- `tests/ui/diary_readability_runner.gd`（§6 遮挡断言）
- `docs/reports/v0.89.0/architect.md`、`.cursor/agents/architect/tasks.md`

### 验证

```text
# f875b79 / 当前 origin 坏摆放 (0.52,-0.78) + rot X=-62° → 失败
Godot --headless --path . res://tests/ui/diary_readability_runner.tscn
# DIARY_READABILITY_FAIL ... hits=8: left/corner_tl←RoomBackplate ... EXIT=1

# 修好后 (1.05,-1.72) upright → 通过（工作区 UI WIP 或后续 UI 提交）
# DIARY_READABILITY_OK checks=43
```

坏摆放证据（同进程注入 f875b79 姿态）：`clear` good→true / bad→false，`hits=8`，遮挡体均为 `RoomBackplate`（题名/正文/上角）。

### 困难与候选方案

1. PhysicsRayQuery + 临时碰撞体 → 拒（污染舞台 / headless 脆弱）。  
2. 屏幕空间深度/抓帧 → 拒（非 headless 默认门）。  
3. **几何线段 vs AABB** → 采纳。

### 最终解决

方案 3 + 公开 `get_page_occlusion_report`；书本子树白名单避免假阳性。

### 风险

- AABB 比精确三角网格略宽；极薄擦边可能误报（未见）。  
- 本提交保留 f875b79 坏 `RoomBack`，默认门会红直到 UI 合入摆放修复——属预期。  
- 未 push（勿把未修好 UI / 红门强推远程，除非主会话裁决）。

### 跨角色请求

- **UI**：把 RoomBack 挪出镜头→书页锥体（工作区已有 upright `(0,1.05,-1.72)` 候选）；合入后本 runner 应绿。  
- **主协调者**：AR-07 合入后与 UI-P0-3-fix 同门验收。

### 下一步入口

- UI 修 RoomBack → `diary_readability_runner` 全绿。  
- AR-06 / AR-03 仍按原阻塞。

---

```text
版本：v0.89.0
角色：架构师
任务：AR-07 可读性遮挡维度
状态：完成
修改文件：diary_page_occlusion.gd、diary_desk_stage 钩子、diary_readability_runner、architect.md、tasks
依赖：DeskQuality 完整舞台；公开 page_uv_to_world / get_page_occlusion_report
验证：坏摆放 EXIT=1 hits=8 RoomBackplate；修好后 OK checks=43
困难与候选方案：PhysicsRay / 抓帧 / 几何 AABB（采纳）
最终解决：相机→采样线段 vs 非书本可见网格 AABB
风险：默认门在 UI 修板前为红；AABB 近似
跨角色请求：UI 合入 RoomBack 修复；协调者同门验收
下一步入口：UI-P0-3-fix RoomBack
```
