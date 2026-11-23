# v0.85 栅格插画源

按 `docs/design/ART_BRIEF_V085_DRAFT.md`：

| 目录 | 用途 |
|---|---|
| `scenes/` | 候选交付底图（文件名对齐 BRIEF §3，如 `battle-moretti-home*.png`） |
| `generations/` | AI/会话生成原稿存档（可带日期后缀） |
| `diary/` | 日记向原图/修图 |
| `preview/` | 试画 / study |
| `props/` | 从 `样板.jpg` 拆出的单件（烛/蜡封/桌面/书签/笔等），见 `props/README.md` |
| `reference/` | 参考样板原图副本 |

**约定**：对话里生成的章节插画**直接落到本目录**，不要留在 Cursor 缓存的 `.cursor/.../assets/`。

正式进游戏仍须主协调者迁到 `assets/game/v0.85.0/diary/`（或 BRIEF 指定路径），并更新 `art/ASSET_MANIFEST.md`。
