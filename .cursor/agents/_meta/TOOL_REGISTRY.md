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

- id: v083-diary-desk
  role: ui-designer
  status: candidate
  purpose: 日记桌 P0 探针
  when: 改 diary_desk_stage / 日记路由后
  run: |
    .tools/godot-4.7.2/Godot.app/Contents/MacOS/Godot --headless --path . \
      res://tests/ui/v083_diary_desk_p0_runner.tscn
  notes: 本机 Godot 路径以 .tools 或环境为准；勿写死他人机器盘符
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
