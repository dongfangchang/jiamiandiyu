# Draft · ACTIVE_PLAN 与 CURRENT 指针对齐

- status: draft
- owner: product-manager
- 验证次数: 1（2026-11-24 PM-02）

## 何时用

`docs/ACTIVE_PLAN.md` 抬头/§0 与 `docs/CURRENT_VERSION.md` 版本号或 ROADMAP 阶段不一致时。

## 清单

1. 读 `CURRENT_VERSION.md` 指针（版本、阶段、框架引用）。  
2. 改 ACTIVE_PLAN 抬头日期 +「当前版本」一行，显式写 ROADMAP 阶段与框架文件。  
3. 重写 §0 总览表「当前执行」行；过期阶段行改为「历史完成」并指向归档。  
4. **过期勾选表**：整表下移「已勾销归档」，加归档备注；**保留原 ✅/⬜**，勿静默改历史结论；未验真窗标「结转至当前版保留项」。  
5. 在当版 `docs/reports/<ver>/product_manager.md` 写裁决摘要 + Retro。  
6. 更新本角色 `tasks.md` → done + 证据。

## 失败模式

- 把旧 ⬜ 改成 ✅ 假装关版。  
- 只改正文不改抬头，新人仍读到旧版本号。
