# v0.8.0 / 产品经理验收记录

## 状态

- 版本：`v0.8.0`
- 状态：已关闭
- 最后更新：2026-11-08

## 验收结论

v0.8 完成首次引导、设置与玩法说明、新游戏确认、备份恢复和设置持久化。版本没有新增卡牌、敌人、路线或挑战修饰。

## 证据

```text
PREFERENCES_TESTS_OK checks=16
SYSTEM_UI_SMOKE_OK checks=7
UI_SMOKE_OK checks=33
V07_DECK_UI_SMOKE_OK checks=46
APP_V07_INTEGRATION_OK checks=131
main scene --quit-after 5: exit 0
V0.8 standalone build: exit 0
```

独立构建：`build/windows/MaskWhispers_v0.8.exe`，大小 123,842,568 字节，SHA-256
`4C897C7A1601DD8F501AF4A545B6C5C8C4D720DBBECCE6417FB6A25935F83928`。

最终标准文件名 `MaskWhispers.exe` 当时被正在试玩的旧进程占用，因此 v0.8
使用版本化文件名完成导出和项目外启动验证，未终止正在运行的用户游戏。

## 遗留风险

- 真实人工鼠标试玩与完整流程计时仍未完成。
- 减少闪烁偏好当前没有明显可见差异，因为现有界面未使用强闪烁动画。
- 设置界面采用基础主题，后续可继续统一装饰。
