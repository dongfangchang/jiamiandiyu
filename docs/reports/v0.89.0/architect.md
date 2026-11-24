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

```text
版本：v0.89.0
角色：架构师
任务：AR-05 渲染器评估 → ADR-0035
状态：完成
修改文件：ADR-0035、tools/architecture/ar05_*、docs/reports/v0.89.0/architect.md、ar05_renderer/**
依赖：日记站捕获 API；未改 src/ui 生产实现
验证：三渲染器真窗口截图 + FPS 报告；缩略图入库
困难与候选方案：Compat 假阴影 / Mobile 无 SSAO / Forward+ 采纳
最终解决：桌面默认 Forward+；见 ADR-0035
风险：HiDPI 帧率；Windows 未在本机复测
跨角色请求：协调者改 project.godot；UI-P0-3 开后期
下一步入口：UI-P0-3；AR-06 待 UI-X0-rev
```
