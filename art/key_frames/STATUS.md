# 目标帧进度（ADR-0037）

风格规则：环境 = A 油画暗室，纸面 = B 铜版插画（ADR-0037 附录 A）。  
**2026-11-25 追加**：文字/菜单载体必须落在场景物件上（纸页、书签、索引卡），承接烛光暖橙与阴影；禁止低饱和纯白便签悬浮叠层。后续站位 **art + ui-designer 共同决策**。

用户拍板后签字稿命名为 `approved.png`。

| 站位 | 任务 | 方案 | 状态 | 签字稿 |
|---|---|---|---|---|
| title 标题页 | ART-KEY-02 | A → `candidate_v2` | **已签字** | `art/key_frames/title/approved.png` |
| diary 日记页 | ART-KEY-02b（联合 UI） | v3 | **批注中** | — |
| desk 桌面总览 | ART-KEY-03-rev（联合 UI） | options_v2 · 1/2/3 | **待选** | — |
| dossier 身份档案 | ART-KEY-04 | 2 | 待出图（联合 UI；阻塞：diary/desk 风格闸） | — |
| cardbox 卡匣 | ART-KEY-05 | 3 | 待出图（联合 UI） | — |
| altar 祈愿台 | ART-KEY-06 | 2 | 待出图（联合 UI） | — |
| battle 战斗 | ART-KEY-07 | 3 | 待出图（联合 UI） | — |
| diary_variants 日记变体 | ART-KEY-08 | 1×5 | 待出图（联合 UI） | — |
| drawer 挑战卷宗 | ART-KEY-09 | 2 | 待出图（联合 UI） | — |
| transitions 过渡 | ART-KEY-10 | 1×3 组 | 待出图（联合 UI） | — |
| settings 系统纸签 | ART-KEY-11 | 2 | 待出图（联合 UI） | — |

## 用户裁决记录（2026-11-25）

- **title**：`candidate_v2` **通过** → `approved.png`
- **diary**：`candidate_v2` **不通过** → `candidate_v3` **已交批注**（印纸重做）
- **desk**：overview 三方案 **全不通过**（白底便签）→ `options_v2` **待选**

## 路径

- 签字：`art/key_frames/title/approved.png`
- 批注中：`art/key_frames/diary/candidate_v3.png`
- 待选：`art/key_frames/desk/options_v2/{1,2,3,overview}.png`
- 驳回留档：`art/key_frames/diary/candidate_v2.png`、`art/key_frames/desk/options/{1,2,3,overview}.png`
