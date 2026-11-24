extends Node

## v0.72: DIARY_008 — catalog keeps base + gold overwrite layers, node_id stable.
## Retired 2D-book layer nodes (PenRewriteStamp etc.) are no longer asserted (v0.86 R0-03).

const DiaryScreenScript := preload("res://src/ui/diary_chapter_screen.gd")
const RouteSnapshotScript := preload("res://src/core/route_snapshot.gd")
const DiaryCatalogScript := preload("res://src/ui/diary_ui_catalog.gd")

const TENANT := "route.v028.first_stage.node.tenant_trace"
const OVERWRITE := "「笔尖一顿——这段字被改成了另一个人的口供。」"
const BASE_SNIPPET := "灵摆指向废弃楼"

var _checks := 0
var _failures: Array[String] = []


func _ready() -> void:
	var catalog := DiaryCatalogScript.new()
	_expect(catalog.ensure_loaded(), "diary volume loads")
	var view: Dictionary = catalog.build_view({
		"display_name_zh": "第一卷·小丑：廷根值夜者",
		"phase": "map",
		"available_node_id": "route.v028.first_stage.node.first_hunt",
		"unlocked_node_ids": ["route.v028.first_stage.node.first_hunt"],
		"completed_node_ids": [],
		"clue_annotations": {
			TENANT: "【0-08】墨迹改写了尚未读到的字句。",
		},
		"clue_overlays": {
			TENANT: {
				"text_zh": OVERWRITE,
				"source": "0-08",
				"margin_note_zh": "笔改过",
			},
		},
		"run_state": {
			"hp": 30, "max_hp": 30, "spirit": 10, "max_spirit": 10,
			"corruption": 2, "max_corruption": 10, "attention": 1, "max_attention": 10,
		},
		"nodes": [],
	})
	var rewritten_clue := _find_clue(view, TENANT)
	_expect(not rewritten_clue.is_empty(), "catalog finds rewritten clue by node_id")
	_expect(String(rewritten_clue.get("node_id", "")) == TENANT, "node_id unchanged after overlay")
	_expect(bool(rewritten_clue.get("rewritten_by_pen", false)), "catalog marks rewritten_by_pen")
	var base_zh := String(rewritten_clue.get("base_text_zh", ""))
	var overwrite_zh := String(rewritten_clue.get("overwrite_text_zh", ""))
	_expect(base_zh.find(BASE_SNIPPET) >= 0, "base_text_zh keeps Roselle original")
	_expect(overwrite_zh == OVERWRITE, "overwrite_text_zh is overlay line")
	_expect(base_zh != overwrite_zh, "base and overwrite differ")
	_expect(String(rewritten_clue.get("text_zh", "")) == OVERWRITE, "text_zh primary is overwrite")

	var screen: Control = DiaryScreenScript.new()
	add_child(screen)
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen.apply_snapshot(RouteSnapshotScript.new({
		"display_name_zh": "第一卷·小丑：廷根值夜者",
		"phase": "map",
		"available_node_id": "route.v028.first_stage.node.first_hunt",
		"unlocked_node_ids": ["route.v028.first_stage.node.first_hunt"],
		"completed_node_ids": [],
		"clue_annotations": {
			TENANT: "【0-08】墨迹改写了尚未读到的字句。",
		},
		"clue_overlays": {
			TENANT: {
				"text_zh": OVERWRITE,
				"source": "0-08",
				"margin_note_zh": "笔改过",
			},
		},
		"run_state": {
			"hp": 30, "max_hp": 30, "spirit": 10, "max_spirit": 10,
			"corruption": 2, "max_corruption": 10, "attention": 1, "max_attention": 10,
		},
		"nodes": [],
	}))
	await get_tree().process_frame
	await get_tree().process_frame

	_expect(
		screen.find_children("*", "OptionButton", true, false).is_empty(),
		"no OptionButton on diary path"
	)

	if _failures.is_empty():
		print("V072_DIARY_008_LAYERS_OK checks=%d" % _checks)
	else:
		print("V072_DIARY_008_LAYERS_FAIL checks=%d failures=%s" % [_checks, str(_failures)])
		for failure in _failures:
			push_error(failure)
	await get_tree().process_frame
	get_tree().quit(0 if _failures.is_empty() else 1)


func _find_clue(view: Dictionary, node_id: String) -> Dictionary:
	for spread_value in view.get("spread_list", []):
		if not spread_value is Dictionary:
			continue
		for clue_value in spread_value.get("clues", []):
			if clue_value is Dictionary and String(clue_value.get("node_id", "")) == node_id:
				return clue_value
	return {}


func _expect(cond: bool, label: String) -> void:
	_checks += 1
	if not cond:
		_failures.append(label)
