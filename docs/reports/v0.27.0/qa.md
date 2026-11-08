版本：v0.27.0
角色：QA
任务：验证战斗记录滑动窗口、卡牌数据元数据和既有回归门。
状态：完成
修改文件：`tests/ui/v027_battle_log_runner.gd`、`tests/ui/v027_battle_log_runner.tscn`、`tests/gameplay/v027_attack_catalog_runner.gd`、`tests/gameplay/v027_attack_catalog_runner.tscn`
依赖：Godot 4.7.2 headless、既有玩法/UI/整合 runner。
验证：`V027_BATTLE_LOG_OK checks=7`、`V027_ATTACK_CATALOG_OK checks=513`、`V014_CARD_LAYOUT_OK checks=20`、`V025_VIEWPORT_GUIDANCE_OK checks=4`、`UI_SMOKE_OK checks=33`、`GAMEPLAY_TESTS_OK checks=131`、`PROGRESSION_TESTS_OK checks=103`、`APP_V07_INTEGRATION_OK checks=132`、`PROGRESSION_UI_SMOKE_OK checks=52`、`V05_ROUTE_UI_SMOKE_OK checks=62`、`V07_DECK_UI_SMOKE_OK checks=59`、`V07_DECK_TESTS_OK checks=274`、`V013_CARD_PACK_OK checks=44`、`V07_BACKEND_TESTS_OK checks=43`、`V091_REGRESSION_OK checks=74`、`V092_DESTRUCTIVE_OK checks=175`、`V093_PENDING_NAV_OK checks=10`、`PASS infrastructure tests: 150` 均通过；JSON 结构和 40 张卡牌必填元数据已通过解析。
困难与候选方案：事件列表布局问题在静态代码中不等于真实窗口问题；专项同时检查容器类型、滚动方向、窗口上限、自动跟随和手牌子树存在。40 张卡牌扩展也暴露了旧的 20 张断言，已同步更新相关回归门。
最终解决：以 14 条注入事件验证最近 10 条保留、自动跟随末尾且八张手牌仍挂载。
风险：正式卡牌美术和抗性运行时仍排在后续切片；本版本仅以设计元数据和回退图保障可读性。
跨角色请求：版本门前提供真实 1600×900 与 1100×700 截图。
下一步入口：运行 `V027_BATTLE_LOG_OK`，再执行 v0.26.0 兼容门和 `git diff --check`。
