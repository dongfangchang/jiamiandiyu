# v0.34.0 数值设计报告

版本：v0.34.0  
角色：数值设计  
任务：普通遭遇轻度策略加压  
状态：完成

## 调参表（仅普通；精英/首领沿用 v0.32）

| 敌人 | 原 hp/atk | 新 hp/atk | 其他 |
|---|---|---|---|
| 密修会成员 | 14/3 | 18/4 | 退影护盾 4→5 |
| 绑匪 | 8/3 | 12/4 | — |
| 失控的瑞尔·比伯 | 22/5 | 28/6 | — |
| 附身恶灵 | 16/4 | 20/5 | — |

## 调后抽样（普通关键格；贪心 100 局）

| 预设 | first_hunt | tenant_trace | boundary | twin_pursuit |
|---|---|---|---|---|
| ward | 100% / 3.4r / hp53.8 | 100% / 5.7r / hp53.9 | 100% / 3.0r / hp53.8 | 100% / 4.8r / hp51.7 |
| oracle | 100% / 2.6r / hp53.2 | 100% / 4.8r / hp52.9 | 100% / 1.9r / hp53.1 | 100% / 3.4r / hp49.7 |
| burst | 100% / 2.1r / hp53.9 | 100% / 5.2r / hp51.3 | 100% / 2.2r / hp53.9 | 100% / 4.8r / hp50.5 |
| echo | 100% / 2.9r / hp53.2 | 100% / 6.4r / hp49.3 | 100% / 2.8r / hp53.8 | 100% / 5.8r / hp48.0 |

精英/首领抽样与 v0.32 终值一致量级（ward mirror_pursuit 83%、echo broken_baron 53%）。  
价值审计未改卡面：`V031_CARD_VALUE_AUDIT_OK checks=145`。

## 修改文件

- `data/enemies/v0.7.0/enemies.json`
- `docs/design/TINGEN_CANON.md`（生命/攻击表与版本注记）
- 本报告

```text
版本：v0.34.0
角色：数值设计
任务：普通遭遇轻度策略加压
状态：完成
修改文件：data/enemies/v0.7.0/enemies.json, docs/design/TINGEN_CANON.md, docs/reports/v0.34.0/numerical_designer.md
依赖：v0.34 版本文档授权；产品经理临时写入 enemies 战斗数值字段
验证：上表抽样；V031_CARD_VALUE_AUDIT_OK；V031_CANON_SAMPLING_DONE
困难与候选方案：加压过猛会压低 early 胜率并扭曲教学节奏；候选为只加 hp 不加 atk
最终解决：四名普通小幅双抬 + 密修会退影护盾 +1；胜率仍满但回合与残余生命体现压力
风险：真人操作压力高于贪心；首战教学若仍过松可再单点加绑匪
跨角色请求：协调者回归后；产品经理安排悬停可发现性试玩再关版
下一步入口：真人试玩 / 版本验证关闭
```
