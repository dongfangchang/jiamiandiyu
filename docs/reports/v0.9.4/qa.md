# v0.9.4 / QA 工作记录

## 状态

- 状态：通过
- 当前任务：界面真实性与回归门禁
- 最后更新：2026-11-08

## 检查

- 成功路线无 `end_reason` 时不得显示“规则层未提供原因”。
- 奖励必须选择时不得显示不可用返回承诺。
- 路线标题区必须存在专用高对比容器。

```text
V094_RESPONSE_TRUTH_OK checks=6
V0.9.4 QA PASS: 30 checks
```

## 构建

- `build\windows\MaskWhispers_v0.9.4.exe`
- 大小：`123763448` 字节
- SHA-256：`22808784DA237A6B6EBB3EAFBC99347FFED7519D3BF5DE5E48710F83584962DE`
- 项目外启动退出码：`0`
