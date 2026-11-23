# v0.9.1 / QA 执行记录

## 状态

- 版本：`v0.9.1`
- QA 状态：通过
- 最后更新：2026-11-08

## 已通过

```text
V091_REGRESSION_OK checks=19
APP_V07_INTEGRATION_OK checks=131
UI_SMOKE_OK checks=33
PROGRESSION_UI_SMOKE_OK checks=41
V06_CHALLENGE_UI_SMOKE_OK checks=40
V07_DECK_UI_SMOKE_OK checks=46
SYSTEM_UI_SMOKE_OK checks=9
GAMEPLAY_TESTS_OK checks=131
PROGRESSION_TESTS_OK checks=103
ROUTE_TESTS_OK checks=99
CHALLENGE_TESTS_OK checks=89
V07_DECK_TESTS_OK checks=178
V07_CHALLENGE_TESTS_OK checks=38
Main scene exit=0
```

专项回归覆盖：

- 战斗显示中文卡名、效果、图像和退出确认。
- 请求中重复点击只提交一次。
- 受击生成视觉反馈。
- 抽卡 pending 时可返回，退出清除 pending。
- 路线失败显示具体原因。
- 测试档案拥有全部 16 卡和足够资源。

实际窗口截图已重新生成，战斗手牌不再出现英文内部 ID。

## 已解决阻断项

旧测试仍期望标题“路线中断”，新 UI 使用更明确的“探索失败”。测试预期已按
新交互更新，并重新运行通过。

## 结论

统一 QA 脚本 27 组检查全部通过，允许关闭 v0.9.1。
