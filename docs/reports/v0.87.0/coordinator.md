# v0.87.0 主协调者报告（轨道 D：R1-05、R1-06）

```text
版本：v0.87.0
角色：主协调者
任务：轨道 D 资源与数据归档（R1-05 assets/game 无引用目录与重复副本；R1-06 v0.2.0 草案数据与 schema）
状态：完成（部分候选按保守规则保留，见“风险”）
修改文件：
  删除 assets/game/{v0.3.0,v0.4.0,v0.5.0,v0.6.0,v0.7.0,cards,enemies,icons,templates}/**（92 个资源 + 88 个 .import）
  删除 data/schema/v0.2.0/content_envelope.schema.json
  data/schema/v0.2.0/README.md（标注该 schema 已归档）
  art/ASSET_MANIFEST.md（新增「v0.87 归档」）
  docs/reports/v0.87.0/coordinator.md
依赖：docs/versions/v0.87.0.md §2 归档方式；docs/architecture/REVIEW_2026-11-24.md AR-44 / AR-45 / AR-56
验证：见下
困难与候选方案：见下
最终解决：见下
风险：见下
跨角色请求：见下
下一步入口：见下
```

## 1. 归档标签

- `archive/pre-v0.87-assets` → `dbdcdeac74468cb21d8fbfea3f25f908732dbebc`（删除前的分支基点）。仅建在本地，由主会话推送。
- 恢复：`git checkout archive/pre-v0.87-assets -- <path>`。

## 2. 引用集构建方法

扫描范围：`src/`、`scenes/`、`data/`、`tests/`、`tools/`、`art/tools/`、`addons/`、`project.godot`、`export_presets.cfg`，以及 `assets/` 内的 `.json/.tscn/.tres`（排除 `.import`）。

1. 抽取所有 `assets/...` 字面量，按 `assets/game/<顶层目录>` 归并。
2. 动态拼接：检查 `"res://assets/game/" +`、`%s`、`path_join` 一类写法，以及 `*_BASE`、`*_DIR` 常量（如 `STATUS_ICON_BASE`、`ART_DIR`、`PROP_DIR`、`V07_CARD_DIR`），对应目录整体保留。运行时代码没有以版本号拼出 `assets/game/<ver>` 的写法；`content_version` 字符串只用于 `data/`。
3. uid：收集候选目录全部 `.import` 中的 `uid://`（88 个），在上述范围内反查，结果为零。

结果：运行时实际引用的顶层目录为 `v0.24.0`、`v0.41.0`、`v0.42.0`、`v0.44.0`、`v0.45.0`、`v0.46.0`、`v0.48.0`、`v0.54.0`、`v0.85.0`。`scenes`、`v0.13.0`、`v0.47.0`、`v0.49.0` 仅作为 `art/tools` 渲染脚本的输出目录出现。

## 3. 已删除

| 路径 | 大小 | 文件（不含 .import） |
|---|---:|---:|
| `assets/game/v0.3.0/` | 4.3 MB | 27 |
| `assets/game/v0.4.0/` | 1.8 MB | 13 |
| `assets/game/v0.5.0/` | 3.6 MB | 14 |
| `assets/game/v0.6.0/` | 0.9 MB | 14 |
| `assets/game/v0.7.0/` | 3.1 MB | 16 |
| `assets/game/cards/` | 2.6 MB | 5 |
| `assets/game/enemies/` | 0.2 MB | 1 |
| `assets/game/icons/` | 0.5 MB | 1 |
| `assets/game/templates/` | 0.5 MB | 1 |
| `data/schema/v0.2.0/content_envelope.schema.json` | <0.01 MB | 1 |

合计约 **17.4 MB**；`assets/` 从 158.2 MB 降到 140.8 MB（`du -sk`）。

## 4. 保留及原因

- `assets/game/{scenes,v0.13.0,v0.47.0,v0.49.0}/`（约 1.5 MB）：审查列为候选，但 `art/tools/render_title_svg.gd`、`render_v013_cards.gd`、`render_v047_p3_scenes.gd`、`render_v049_shell_scenes.gd`、`generate_v047_p3_scenes.mjs`、`generate_v049_shell_scenes.mjs` 把它们写成输出路径。按“出现过前缀即保留”的保守规则暂不删除。
- 逐字节重复（AR-56），`assets/` 内只有 3 组，每组两份都有引用：
  - `assets/ui/diary/desk_wood.png` 与 `assets/ui/diary/props/desk-wood.png`：前者由 `diary_desk_stage.gd` 直接引用，后者由 `prop_ui_catalog.gd` 的 `PROP_DIR` 引用。
  - `assets/ui/diary/wax_seal_available.png` 与 `assets/ui/diary/props/wax-seal.png`：引用情况同上。
  - `assets/game/v0.24.0/cards/card-identity-reporter.png` 与 `assets/game/v0.24.0/templates/card-frame.png`：前者被 `ui_preview.gd` 引用，后者登记在 `v0.24.0/render-manifest.json`。
  - `assets/game/v0.85.0` 与 `art/**` 之间的重复：按派工要求不动 `art/**`，不在本轮处理。
- `data/balance/v0.2.0/balance_draft.json`、`data/schema/v0.2.0/battle_cards.schema.json`：`tests/infrastructure/test_runner.gd` 第 83、235、294、327 行仍在读取。该目录属其他轨道，本轮不改，所以两份文件保留。因此 R1-06 没有需要随之删除的测试。

## 5. 验证

- `Godot --headless --path . --import`：rc=0，无缺失资源报错。
- `tools/run_tests.sh`：`run_tests: pass=85 fail=0 skipped=9 guard_block=0`，与基线一致。`tests/golden/golden_replay_runner.tscn` PASS，黄金文件无改动。
- `Godot --headless --path . --quit`：rc=0，输出 2 行，无 error / missing。

## 6. 困难与候选方案

- 问题：`art/tools` 中的输出路径算不算“引用”。
  - 方案 A：只看读取方，删除这 4 个目录，需要时重新渲染。
  - 方案 B：按保守规则保留。
  - 最终选择 B。省下的空间约 1.5 MB，不值得冒误删风险；交由美术或产品经理裁决。
- 问题：资产提交 amend 时误把暂存的 schema 删除一起带了进去。已用 `git reset --soft` 回到基点，重新拆成两个提交，没有丢弃任何工作。

## 7. 风险

- `data/schema/v0.2.0/README.md` 和 `data/balance/v0.2.0/README.md` 仍然描述 `balance_draft.json` 是数值事实源。实际是否还有运行时读取方，应在 R2 由数据层确认。
- 本地标签尚未推送；推送前，`main` 上的删除不能视为“可恢复”。

## 8. 跨角色请求

- 美术：确认 `assets/game/{scenes,v0.13.0,v0.47.0,v0.49.0}` 是否可以归档，以及相应的 `art/tools` 脚本是否随之退役。
- 本地数据层 / 测试轨道：`tests/infrastructure/test_runner.gd` 如果不再需要 v0.2.0 草案，请改为读取正式数据。之后可删除 `balance_draft.json`、`battle_cards.schema.json`（AR-44 剩余部分）。

## 9. 下一步入口

- 主会话推送 `archive/pre-v0.87-assets`，然后合并本分支。
- AR-56 中 `assets/game/v0.85.0` 与 `art/**` 的重复，以及 AR-54（`art/.gdignore`）和 AR-55（git 体积 / LFS），留待后续版本处理。
