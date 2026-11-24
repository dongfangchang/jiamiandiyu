# Draft · 书桌世界站位设计稿流程

状态：draft  
角色：ui-designer  
首次：2026-11-24 · UI-X0

## 何时用

要把 EXPERIENCE 站位落到「美术可出图、架构可评审」的设计文件，且**不改 src**。

## 清单

1. 读 EXPERIENCE §2–§5、ART_BRIEF_DESK_WORLD、现网 `diary_desk_stage` DeskMesh / BookRoot / 镜头行。  
2. 定世界单位：桌面尺寸 + **打开日记足迹 = 100% 比例锚**。  
3. 俯视摆六物件（不重叠；日记中央 55–65% 视口）。  
4. 七站位镜头：diary 为基准，其余写清相对偏移与 fov。  
5. 每站 2D 版式 + T1–T4 + 输入四态。  
6. DW-ID → 站位 + 相对% 表（给 art）。  
7. 线框进 `assets/ui/wireframes/desk_world/`；现有 props SVG 拼贴即可。  
8. 报告 §10 + 请求 AR-04；无 `art/.../desk_world` 则 UI-07 保持 blocked。

## 失败模式

- 像素规格与世界足迹脱节 → art 做出的物件在桌上失调。  
- 与主会话抢改 diary_desk_stage → 违反 UI-H 边界。
