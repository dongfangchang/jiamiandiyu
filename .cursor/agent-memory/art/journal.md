# Journal · art

> 追加写，旧条目不删。格式见 `.cursor/agents/_meta/SKILL_LOOP.md` §3。

## Log

- 2026-11-24 · boot：角色记忆目录初始化。

### Retro · 2026-11-24 · 美术建议与缺口盘点（只读）
1. 目标是否达成？证据：对照 `ART_BRIEF_V085` / `ART_DIRECTION` / `art/assets/raster/v0.85.0` / `assets/game/v0.85.0`，产出优先级建议 + 缺口清单；未改生产资产。
2. 哪一步最耗时或最易错？易把「候选已齐」当成「玩家可见完成」——日记/卡面仍卡在真窗口审稿与共用框层，不在再出新图。
3. 可沉淀为 Skill 的步骤？盘点核对表：BRIEF §3/§4 → art 源目录 → assets/game|ui 正式路径 → 尺寸断言（1260×1770 / 512×390 / 128 蜡封）。
4. 该进 Tool Registry 的命令？`find`+`sips` 批量量尺寸；暂不晋升（一次性审计）。
5. 下次同一类任务，第一条该读？`diary-page-art`（竖图）或 `prop-keying`（道具）；学习不靠 GitHub App。

### Retro · 2026-11-24 · ART-DW-X1 书桌世界道具批
1. 目标是否达成？证据：DW-01…07 全部落在 `art/assets/raster/desk_world/<object>/`，尺寸对齐 BRIEF，各有 `*_shadow.png` + README；总览 `…/_overview/desk_world_x1_overview_2048.png`；报告 `docs/reports/v0.88.0/art.md`。未迁 `assets/game`。
2. 哪一步最耗时或最易错？深色皮面洪水抠图 tol 过大易抠穿；生成图易夹带烛/杂物 → 必须目视后重出 v2；竖构图物件塞进横画布会留白，需在 README 标明。
3. 可沉淀为 Skill 的步骤？Desk-world 道具流水线：BRIEF 表 → 正俯视+深炭底生成 → 低 tol 洪水抠 / 品红窗 → 定尺寸 fit → 阴影派生 → 2048 总览 → 按 DW-ID 请 UI-07。Draft 候选：`desk-world-prop-batch`（未晋升，等 UI 审稿一轮验证）。
4. 该进 Tool Registry 的命令？本机 `.tools/art_venv` + Pillow 批处理；正式可迁到 `art/tools/` 脚本后再登记（暂不写死绝对盘符）。
5. 下次同一类任务，第一条该读？`ART_BRIEF_DESK_WORLD.md` §0 + 已有 `desk_world/*/README.md`；先查 `DESK_WORLD_STATIONS.md` 是否要改比例。

### Retro · 2026-11-24 · ART-DW-X1-fix（UI-07 退回）
1. 目标是否达成？证据：`dossier/open.png` 换成皮夹+双空白纸；`candle_lit` 由 `candle_out` 叠焰，body 错配 0%；README 全目录补齐；overview/报告已更新。待 UI 复审。
2. 哪一步最耗时或最易错？「开档案夹」生成反复滑向烫金开书 → 必须 closed 参考图 + 硬约束「双内页纸、禁烫金角」；双态轮廓不能靠两次独立生成。
3. 可沉淀为 Skill 的步骤？开合态：先定合态/熄灭母版，再派生开态/点燃；双态 alpha 对账（body xor，焰区可豁免）。已写入 draft `desk-world-prop-batch` 补充。
4. 该进 Tool Registry 的命令？Pillow 合成焰 + mask xor 校验；仍暂不晋升到正式 tools。
5. 下次同一类任务，第一条该读？UI 退回表 + `DESK_WORLD_STATIONS.md` §5；先锁定母版再派生。

### Retro · 2026-11-24 · ART-DW-X2（DW-11…18）+ 余力 ART-01
1. 目标是否达成？证据：X2 全套落在 `desk_world/<object>/` + shadows/README；墨迹 4 张 L 模式阈值；总览 x2；报告 X2 节；ART-01 desk_wood 2048 + 蜡封三态在 `v0.85.0/desk_materials/`。未迁 assets/game；未开 X3。
2. 哪一步最耗时或最易错？祭坛/页框生成易夹带字母与英文标题 → 必须几何-only 重出或底栏 scrub；2048 墨晕纯 Python 双环极慢 → 下次数组化。
3. 可沉淀为 Skill 的步骤？Desk-world 批：BRIEF → 正俯视炭底生成 → 禁字约束 + 失败重出 → flood_dark / chroma → fit → shadow → 双态 alpha 对账 → 2048 总览 → UI-07。更新 draft `desk-world-prop-batch`（墨迹程序化 + 页框 chroma）。
4. 该进 Tool Registry 的命令？仍用本机 art_venv + Pillow；正式脚本化后再登记（勿写绝对盘符）。
5. 下次同一类任务，第一条该读？`ART_BRIEF_DESK_WORLD` §0/§2 + `DESK_WORLD_STATIONS` §5 + 本批 README；程序化优先做 DW-14/15。

### Retro · 2026-11-24 · ART-DQ（DQ-01…06）+ ART-DW-07b
1. 目标是否达成？证据：`diary_quality/dq01…06` + `index_card/` 齐；尺寸对 BRIEF §5；总览与示意对比；报告 `docs/reports/v0.89.0/art.md`。未迁 assets/game；未碰主会话 UI。
2. 哪一步最耗时或最易错？书口/丝带生成易夹带印刷字或墨渍 → 程序化书口 + 清洁丝带重出；索引卡线数要对账到恰好 6 行。
3. 可沉淀为 Skill 的步骤？日记站材质批：BRIEF §5 → 生成远景/材质 → 接缝/PBR 派生 → 装饰程序化 → contact shadow 从物件 alpha → 示意对比。可并入 draft `desk-world-prop-batch` 的「材质/正视板」分支（暂不晋升）。
4. 该进 Tool Registry 的命令？`.tools/art_venv` + Pillow 批处理；ComfyUI 本机未就绪，仍用 Cursor GenerateImage。
5. 下次同一类任务，第一条该读？`ART_BRIEF_DESK_WORLD` §5 + EXPERIENCE §5.1；先定「能程序化的」（书口/涂鸦/接触阴影）再生成。

### Retro · 2026-11-25 · ART-KEY-01（三方向目标帧）
1. 目标是否达成？证据：`art/key_frames/directions/{A,B,C}/{title,diary}.png` ×6 @1600×900 + `overview.png` + `README.md`；报告已写；未做画面实现、未迁 assets/game。
2. 哪一步最耗时或最易错？生成器中文不可靠 → 必须无字底图 + 思源宋体 Pillow 叠字；三方向要强制差异（油画 / 铜版 / 透视），否则用户无法选型。
3. 可沉淀为 Skill 的步骤？目标帧流水线：ADR-0037 站位 → 三方向差异化提示词（禁字）→ 生成 16:9 → 放大 1600×900 → 思源宋体叠真实文案 → 3×2 总览 → README（光/色板/材质/实现难度）。Draft 候选：`target-frame-directions`（未晋升，等用户选型一轮验证）。
4. 该进 Tool Registry 的命令？`.tools/art_venv` + Pillow 叠字/总览；暂不写死绝对盘符。
5. 下次同一类任务，第一条该读？ADR-0037 + 本目录 README + `diary-page-art`（左页无字）；有 `references/` 先读再出。

### Retro · 2026-11-25 · ART-KEY-02（candidate_v2 批注修改）
1. 目标是否达成？证据：`art/key_frames/{title,diary}/candidate_v2.png` @1600×900；STATUS 批注中；报告已写；对比度标题≈15 / 日记≈5.3；未自称 approved、未开 03…11、未迁 assets/game。
2. 哪一步最耗时或最易错？「启」叠字易漂到蜡旁 → 必须在无字底图上做圆域红点检测再居中；混合 A 环境+B 纸面要双参考出图，否则日记又变纯铜版房。
3. 可沉淀为 Skill 的步骤？目标帧批注轮：读附录批注 → 禁字底图（参考已选方向）→ Pillow 思源叠字（字号/对比度断言）→ 蜡封单枚压印对齐 → STATUS=批注中 → 等签字。并入 draft `target-frame-directions`（仍不晋升，等签字轮验证）。
4. 该进 Tool Registry 的命令？仍 `.tools/art_venv` + Pillow；蜡心检测可进脚本后再登记。
5. 下次同一类任务，第一条该读？ADR-0037 附录 A/B + `art/key_frames/STATUS.md` + 上一版 candidate；先对已签字/已选锚点再改。

### Retro · 2026-11-25 · ART-KEY-03（desk 三方案待选）
1. 目标是否达成？证据：`art/key_frames/desk/options/{1,2,3,overview}.png` @1600×900 + README；STATUS desk=待选；报告已写；对比度≈7.56；未自称 approved、未开 04…11、未迁 assets/game。
2. 哪一步最耗时或最易错？底图自带索引卡过小/过暗 → 必须叠可读尺寸 B 纸面索引卡再排六行；方案差异要在构图（俯角/雨窗进深/近景）与悬停项上同时钉死，否则 overview 选型无效。
3. 可沉淀为 Skill 的步骤？站位多方案目标帧：ADR 附录 A → 对照已有 candidate/approved → 禁字底图×N → Pillow 索引卡/纸面叠字（字号+对比度断言）→ overview 并排+一句话差异 → README（构图+实现方式）→ STATUS=待选。并入 draft `target-frame-directions`。
4. 该进 Tool Registry 的命令？仍 `.tools/art_venv` + Pillow；大 PNG `optimize=True` 易卡住 → 默认关 optimize。
5. 下次同一类任务，第一条该读？ADR-0037 附录 A + `art/key_frames/STATUS.md` + 上一站位 candidate/approved；先定三方案「一句话差异」再出图。
