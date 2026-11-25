# 工具注册表（Tool Registry）

> 角色把**已验证**的命令/脚本登记在此，供发现与复用。  
> 格式：一行一个配方。新增只追加；废弃加 `status: deprecated`。

## 登记格式

```yaml
- id: unique-kebab-id
  role: art|ui-designer|coordinator|...
  status: draft|candidate|stable|deprecated
  purpose: 一句话
  when: 触发场景
  run: |
    可复制命令
  notes: 可选坑点
  skill: 可选关联 .cursor/skills/<id>
```

## 已注册

- id: run-tests-default
  role: coordinator
  status: stable
  purpose: 默认测试门
  when: 集成验收 / 推送前
  run: |
    tools/run_tests.sh
  notes: Windows 用 tools/run_tests.ps1
  skill: godot-probe-gate

- id: desk-world-migrate-import
  role: coordinator
  status: candidate
  purpose: 书桌世界 PNG 迁入 + Godot import（保护并行 project.godot）
  when: UI 审过 art 候选后迁入 assets/game/desk_world
  run: |
    HASH=$(shasum -a 256 project.godot | awk '{print $1}')
    # 仅复制 *.png，排除 _work/_overview/README；保留 art 候选
    .tools/godot-4.7.2/Godot.app/Contents/MacOS/Godot --headless --path . --import
    test "$(shasum -a 256 project.godot | awk '{print $1}')" = "$HASH" \
      || echo "WARN: project.godot changed by import — restore sibling ownership"
    tools/run_tests.sh
  notes: Godot --import 可能抹掉 [rendering]；并行 CO-AR05 时必须前后比对哈希并还原

- id: v083-diary-desk
  role: ui-designer
  status: candidate
  purpose: 日记桌 P0 探针
  when: 改 diary_desk_stage / 日记路由后
  run: |
    .tools/godot-4.7.2/Godot.app/Contents/MacOS/Godot --headless --path . \
      res://tests/ui/v083_diary_desk_p0_runner.tscn
  notes: 本机 Godot 路径以 .tools 或环境为准；勿写死他人机器盘符

- id: diary-quality-wiring
  role: ui-designer
  status: candidate
  purpose: UI-P0-3 DQ/Forward+ 接线探针
  when: 改 diary_desk_quality / page_pair 右页装饰 / CloseBookmark 丝带后
  run: |
    .tools/godot-4.7.2/Godot.app/Contents/MacOS/Godot --headless --path . \
      res://tests/ui/diary_quality_wiring_runner.tscn
  notes: 真窗截图用非 headless v084_diary_desk_capture_runner（默认门排除 *capture*）
  skill: godot-probe-gate

- id: diary-quality-fps-capture
  role: ui-designer
  status: candidate
  purpose: Forward+ 日记站双分辨率截图 + HiDPI 暖机 fps
  when: 调 diary_desk_quality / project.godot 渲染器或后期预算后
  run: |
    .tools/godot-4.7.2/Godot.app/Contents/MacOS/Godot --path . --rendering-method forward_plus \
      res://tests/ui/v089_diary_quality_capture_runner.tscn
  notes: 必须带显示，勿 --headless；产物 docs/reports/v0.89.0/ui_p0_3_fix_diary_*.png；看 V089_DQ_FPS 行
  skill: godot-probe-gate

- id: key-props
  role: art
  status: candidate
  purpose: 按 props.manifest 抠图输出到 assets/ui
  when: 标题/桌面道具源图更新后
  run: |
    # 需本机 Godot；详见 docs/design/PROP_PIPELINE.md
    "$GODOT" --headless --path . --script art/tools/key_props.gd
  notes: 深色道具 tolerance 约 0.05–0.12
  skill: prop-keying

- id: diary-art-export-size
  role: art
  status: candidate
  purpose: 开页插画统一到 1260×1770
  when: 生成日记竖图后入库
  run: |
    # 使用仓库 .tools/imgvenv（若存在）+ Pillow 裁切；见 art 报告
    .tools/imgvenv/bin/python -c "print('see agent-memory/art/drafts/diary-page-resize.md')"
  notes: 交付同时同步 assets/game/v0.85.0/diary/ 须 coordinator 确认所有权
  skill: diary-page-art

- id: diary-readability-occlusion
  role: architect
  status: candidate
  purpose: 日记可读性底线 + AR-07 页遮挡（headless）
  when: 改 DeskCamera / RoomBack / DeskQuality / 页网格后
  run: |
    "$GODOT" --headless --path . res://tests/ui/diary_readability_runner.tscn
  notes: 须在 DeskQuality 完整舞台上；坏 RoomBack（f875b79 lean）应 FAIL；书本子树不计入遮挡
  skill: godot-probe-gate

- id: ar05-renderer-compare
  role: architect
  status: candidate
  purpose: 日记站三渲染器同镜头截图 + FPS（ADR-0035 复跑）
  when: 渲染器争议 / 改 DeskWorld 光照后期前后对照
  run: |
    tools/architecture/ar05_run_compare.sh
  notes: 必须带显示，勿 --headless；产物 .tools/ui-captures/ar05_renderer/；缩略图可拷 docs/reports/<ver>/ar05_renderer/
  skill:
