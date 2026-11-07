# 《假面低语》项目协作规则

本文件对所有参与本项目的智能体具有强制效力。若本文件与临时对话冲突，以产品经理更新后的版本文档和决策记录为准；若发现规则本身会导致错误实现，必须先记录问题并请求产品经理裁决。

## 1. 项目根目录

- 唯一有效项目根目录：`G:\guimizhizhu`
- Godot 项目入口：`project.godot`
- 不在项目内再创建第二套带 `project.godot` 的工程。
- 不把 `.tools/`、`.godot/`、导出产物或临时缓存提交到 Git。

## 2. 开工前必读

每次开始一个任务前，必须依次读取：

1. `AGENTS.md`
2. `docs/CURRENT_VERSION.md`
3. `docs/PROJECT_CHARTER.md`
4. `docs/ARCHITECTURE_CONTRACT.md`
5. `docs/versions/<当前版本>.md`
6. 自己负责角色在当前版本的报告

完成任务、遇到阻塞、修改公共接口或准备切换模块前，必须重新读取当前版本文档。

## 3. 单一事实源与版本

- 产品目标、范围、角色边界和开发路径由 `docs/CURRENT_VERSION.md` 及当前版本文档共同约束。
- 每个版本必须新建一个版本文件，例如 `docs/versions/v0.2.0.md`。历史版本不覆盖、不删除；修订通过新版本或 ADR 记录。
- 只有产品经理可编辑：
  - `AGENTS.md`
  - `docs/CURRENT_VERSION.md`
  - `docs/PROJECT_CHARTER.md`
  - `docs/TEAM_PROTOCOL.md`
  - `docs/ARCHITECTURE_CONTRACT.md`
  - `docs/VERSION_INDEX.md`
  - `docs/versions/**`
  - `docs/decisions/**`
- 其他角色只能编辑自己负责的生产文件和 `docs/reports/<version>/<role>.md`。
- 需要改变公共规则时，在自己的报告中提交变更请求，由产品经理裁决并写入 ADR 或新版本。

## 4. 角色与文件所有权

| 角色 | 负责范围 | 可编辑目录 | 禁止事项 |
|---|---|---|---|
| 产品经理 | 需求、版本、验收、路线、跨角色裁决 | `docs/**`、根目录协作文档 | 未经明确派工直接实现游戏功能 |
| UI 设计 | 信息架构、线框、交互、视觉状态、UI 实现 | `src/ui/**`、`scenes/ui/**`、`assets/ui/**`、`tests/ui/**`、UI 报告 | 修改战斗规则、数值公式、存档格式 |
| 美术 | 卡面、场景、敌人、图标、源文件与资产生成 | `art/**`、`docs/reports/<version>/art*.md` | 修改 UI 业务逻辑、正式 `assets/game/**`、规则或存档 |
| 玩法设计 | 核心循环、状态机、规则语义、边界条件 | `src/gameplay/**`、`tests/gameplay/**`、`data/cards/**`、`data/enemies/**`、`data/encounters/**`、v0.2.0 期间的 `src/core/**`、玩法报告 | 直接读写 UI、文件系统或在全局参数中硬编码平衡值 |
| 数值设计 | 成长曲线、经济、抽卡概率、战斗公式、模拟 | `data/balance/**`、`tools/simulation/**`、`tests/simulation/**`、数值报告 | 修改 UI、规则流程、存档实现或共享 schema |
| 本地数据层开发 | 离线持久化、内容加载、RNG、日志、适配器 | `src/infrastructure/**`、`src/app/**`、`data/schema/**`、`tests/infrastructure/**`、对应报告 | 创建服务器、修改 UI、代替玩法层制定规则 |
| 主协调者 | 派工、并发、集成、最终验收 | 协调所需最小范围 | 绕过产品经理静默改变范围 |

共享契约 `src/core/**`、数据 schema、`project.godot`、全局资源注册表和公共事件定义属于跨角色文件。修改前必须在角色报告中提出请求，并由产品经理指定单一负责人。

v0.2.0 临时所有权：

- `src/core/**`：玩法设计唯一负责人。
- `data/schema/**`：本地数据层唯一负责人。
- 其他角色发现需要修改时只能提交请求，不得并行修改。

v0.3.0 已关闭所有权（保留历史）：

- `src/core/**`：玩法设计唯一负责人。
- `data/cards/**`、`data/enemies/**`、`data/encounters/**`：玩法设计唯一负责人。
- `data/schema/**`：本地数据层唯一负责人。
- `tests/integration/**`：主协调者负责最终集成验证；具体角色提供测试数据或诊断，不并行编辑。
- `assets/game/**`：主协调者负责一次受控资源迁移与路径更新；迁移完成后其他角色只读。
- UI、玩法、数值和数据层继续只编辑各自目录及 `docs/reports/v0.3.0/<role>.md`。

v0.4.0 已关闭所有权（保留历史）：

- `src/core/**`：玩法设计唯一负责人。
- `data/cards/**`、`data/enemies/**`、`data/encounters/**`：玩法设计唯一负责人。
- `data/balance/**`、`tools/simulation/**`、`tests/simulation/**`：数值设计。
- `data/schema/**`：本地数据层唯一负责人。
- `src/app/**`、`src/infrastructure/**`、`tests/infrastructure/**`：本地数据层开发。
- `src/ui/**`、`scenes/ui/**`、`assets/ui/**`、`tests/ui/**`：UI 设计。
- `art/**`：美术独占；正式 PNG 只能由主协调者受控迁移到 `assets/game/**`。
- `tests/integration/**` 与 `assets/game/**`：主协调者。
- 所有角色在 `docs/reports/v0.4.0/<role>.md` 记录本版本工作。
- UI 与美术是独立角色。美术提交候选资产和制作记录，UI 必须从实际游戏界面审稿并明确通过、退回或仅 UI 适配；美术不得自行验收。

v0.5.0 已关闭所有权（保留历史）：

- `src/core/**`：玩法设计唯一负责人。
- `data/cards/**`、`data/enemies/**`、`data/encounters/**`、`data/routes/**`、`data/rituals/**`：玩法设计。
- `data/balance/**`、`tools/simulation/**`、`tests/simulation/**`：数值设计。
- `data/schema/**`：本地数据层唯一负责人。
- `src/app/**`、`src/infrastructure/**`、`tests/infrastructure/**`：本地数据层开发。
- `src/ui/**`、`scenes/ui/**`、`assets/ui/**`、`tests/ui/**`：UI 设计。
- `art/**`：美术独占；正式 PNG 只能由主协调者受控迁移到 `assets/game/**`。
- `tests/integration/**`、`assets/game/**`、`project.godot`：主协调者。
- 所有角色在 `docs/reports/v0.5.0/<role>.md` 记录本版本工作。
- UI 与美术保持独立；美术提交候选，UI 在实际界面审稿后才可通过。

v0.6.0 当前所有权：

- `src/core/**`：玩法设计唯一负责人。
- `src/gameplay/**`、`tests/gameplay/**`、正式内容目录：玩法设计。
- `data/balance/**`、`tools/simulation/**`、`tests/simulation/**`：数值设计。
- `data/schema/**`：本地数据层唯一负责人。
- `src/app/**`、`src/infrastructure/**`、`tests/infrastructure/**`：本地数据层开发。
- `src/ui/**`、`scenes/ui/**`、`assets/ui/**`、`tests/ui/**`：UI 设计。
- `art/**`：美术独占；正式资产由主协调者迁移到 `assets/game/v0.6.0/**`。
- `tests/integration/**`、`assets/game/**`、`build/**`、`export_presets.cfg`、`project.godot`：主协调者。
- 所有角色在 `docs/reports/v0.6.0/<role>.md` 记录本版本工作。
- UI 与美术保持独立；美术提交候选，UI 在实际界面审稿后才可通过。

## 5. 协作与同步

- 所有智能体共享同一文件系统，禁止同时编辑同一文件。
- 不得覆盖、回滚或整理其他角色的未提交修改。
- 官方进度记录写在 `docs/reports/<version>/<role>.md`，聊天消息不能替代文档。
- 每个角色必须记录：
  - 本版本目标和当前任务
  - 依赖的接口、数据和其他角色交付物
  - 已完成内容和验证结果
  - 困难、至少一个候选方案、最终选择
  - 风险、未解决问题和下一步入口
  - 对其他角色的请求
- 同步触发条件，满足任意一项立即执行：
  - 开始任务时
  - 完成任务或形成阶段性结果时
  - 连续开发 30 分钟
  - 累计修改 10 个项目文件
  - 修改任何共享契约、数据 schema、存档格式或公共路径
  - 发现 S1/S2 缺陷
- 产品经理在每个阶段完成后必须阅读所有角色报告，检查范围漂移、循环依赖和隐性技术债，再决定是否关闭版本。

## 6. 路径与依赖规范

- 代码和资源引用统一使用 `res://` 相对项目路径。
- 禁止在运行时代码中写 `G:\`、`C:\` 或其他本机绝对路径。
- 文件命名使用小写 `snake_case`；稳定内容 ID 使用点分命名，例如 `card.identity.reporter`。
- UI 不得包含规则判断；玩法层不得依赖 `Control`、`Node` 场景树或具体界面。
- 玩法层不得直接调用 `FileAccess`、文件路径、存档或真实 RNG。
- 本地数据层通过端口/适配器实现存档、内容加载和随机数；不得反向依赖 UI。
- 只允许单向依赖：

```text
ui -> app -> gameplay -> core
infrastructure -> app/gameplay ports + core
app/bootstrap -> concrete ui, gameplay, infrastructure
```

- 禁止循环依赖。跨模块通信优先使用稳定命令、事件或只读视图模型。
- 所有内容、数值和文本通过稳定 ID 连接，禁止用显示名称作为主键。
- 同一事实只能有一个定义源；生成数据必须标明来源和生成命令。
- 新增第三方依赖前必须由产品经理和本地数据层开发共同评审，记录来源、授权、版本和维护成本。

## 7. 数据、存档与兼容

- 所有内容数据带 `schema_version`。
- 存档带 `save_version`、内容版本和 RNG 种子。
- 存档加载必须先校验再迁移；无法安全迁移时给出明确错误，不部分覆盖原存档。
- 卡牌效果使用目标、条件、触发器和已注册效果 ID 表达，禁止把任意脚本路径直接作为内容数据。
- 随机事件和抽卡必须支持可复现种子，便于测试与复核。
- 不允许把平衡数值散落在 UI 或玩法脚本中；数值必须来自 `data/balance/**`。
- 卡牌或能力自身的效果与金额属于该内容的唯一定义，存放在 `data/cards/**` 或对应内容目录；`data/balance/**` 只维护全局战斗参数、经济与概率。数值设计负责审核卡牌金额，但不得建立第二份同名卡牌定义。

## 8. Bug 与质量门

- 禁止“看到报错就继续加条件分支”的叠补丁式修复。
- 修复顺序固定为：复现 -> 定位根因 -> 评估影响面 -> 前向修复或替换局部模块 -> 回归验证。
- S0/S1 缺陷立即停止相关开发；先判断能否在现有实现上安全前向修复，避免丢弃已验证工作。
- 默认不直接回滚代码。只有以下情况允许回滚：
  - 故障导致游戏无法启动、无法进入核心流程或持续崩溃。
  - 存档、用户数据或项目文件面临破坏风险。
  - 当前结构已无法安全前向修复，继续修改只会扩大影响面。
  - 用户明确要求回滚。
- 逻辑错误、UI 错误、数值错误以及其他仍可运行的缺陷，应保留现有代码，定位根因后局部重构或替换故障模块。
- 任何回滚必须先记录原因、目标检查点、影响文件、恢复范围和用户影响，并由产品经理确认；禁止使用 `git reset`、`git checkout --` 等命令静默丢弃工作。
- 如果故障来自错误结构，应替换或重构故障模块，不在错误抽象上继续累积兼容分支。
- 每个 S1/S2 缺陷必须有 `docs/bugs/BUG-xxxx.md` 记录症状、复现、根因、影响范围、修复策略、回归测试和涉及的版本。
- 合并前最低质量门：
  - Godot 无解析错误
  - 关键数据可加载
  - 新增规则有自动化或可重复验证
  - 存档格式变化有迁移方案
  - 没有新增绝对路径、循环依赖或重复定义

## 9. 范围纪律

- 当前是个人本地离线项目，不实现多人、服务器、账号、联网同步、真实付费抽卡或长期运营系统。
- 不为了“以后再扩展”提前制作空架构、插件系统或多城市内容框架。
- 未进入当前版本验收标准的系统不得顺手开工。
- 发现新点子时写入当前版本报告的“候选池”，由产品经理排入后续版本。

## 10. 完成汇报格式

任务结束时必须在自己的报告中写明：

```text
版本：
角色：
任务：
状态：完成 / 部分完成 / 阻塞
修改文件：
依赖：
验证：
困难与候选方案：
最终解决：
风险：
跨角色请求：
下一步入口：
```

汇报只陈述实际完成和实际验证的内容，不把设计意图写成已实现功能。
