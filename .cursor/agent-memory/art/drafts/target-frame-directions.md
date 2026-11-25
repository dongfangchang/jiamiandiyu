# Draft · target-frame-directions

status: draft（未晋升；等 ART-KEY-02 签字轮再验证）  
owner: art

## 触发

ADR-0037 目标帧：方向选型或批注修改（`art/key_frames/**`）。

## 步骤

1. 读 ADR-0037（附录 A 风格分层 / 附录 B 批注）+ `art/key_frames/STATUS.md`。
2. 出**无字** 16:9 底图（GenerateImage）；中文不可靠，禁在插画里画字。
3. 混合风格时双参考：环境参考 A、纸面参考 B；同一烛/桌/书要在提示词里钉死。
4. Pillow + `assets/ui/fonts/SourceHanSerifSC-Regular.otf` 叠真实文案；菜单≥22 / 正文≥20；对比度断言 ≥4.5。
5. 蜡封「启」：在无字底图上圆域红点检测找蜡心，再叠字；禁止第二枚红章。
6. 交付 `candidate_vN.png`；STATUS=批注中；**不**自称 approved。
7. 报告写路径+构图；tasks 证据 + Retro；commit/push 含 `.cursor/**`。

## 失败模式

- 日记又变纯铜版房间 → 环境参考丢失。
- 「启」漂在蜡旁 → 未对底图检测蜡心。
- 对比度不够 → 右页偏暗未做羊皮纸 wash。
