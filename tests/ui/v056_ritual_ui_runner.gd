extends Node

## v0.56 ritual UI: always-visible source/lore + soft-fail copy (no wipe).

const RitualScreenScript := preload("res://src/ui/ritual_screen.gd")
const RitualSnapshotScript := preload("res://src/core/ritual_snapshot.gd")

var _checks := 0
var _failures: Array[String] = []


func _ready() -> void:
	await _run()


func _run() -> void:
	var screen = RitualScreenScript.new()
	add_child(screen)
	screen.apply_snapshot(RitualSnapshotScript.new({
		"display_name_zh": "小丑晋升考核",
		"description_zh": "按日记守则起誓并完成三问。",
		"source_zh": "罗塞尔日记·末叶守则",
		"status": "in_progress",
		"step_index": 0,
		"step_count": 3,
		"step_titles": ["扮演守则", "晋升流程", "小丑本质"],
		"corruption": 6,
		"max_corruption": 10,
		"spirit": 1,
		"errors": 1,
		"hint_spirit_cost": 1,
		"hint_text": "",
		"hinted_step_indices": [],
		"step": {
			"type": "select_id",
			"title_zh": "占卜家扮演守则",
			"clue_zh": "引导向好；不可尽信占卜。",
			"lore_zh": "日记旁注：注视会涨。别聊真名。",
			"min_selections": 1,
			"max_selections": 1,
			"options": [
				{"id": "rule.guide_good", "label_zh": "引导向好；不可尽信占卜"},
				{"id": "rule.wrong", "label_zh": "尽信占卜"},
			],
		},
	}))
	await get_tree().process_frame
	_expect(screen.find_child("OptionButton", true, false) == null, "no OptionButton on ritual")
	var source := screen.find_child("SourceLabel", true, false) as Label
	_expect(source != null and source.visible, "source always visible")
	_expect(
		source != null and source.text.find("罗塞尔日记") >= 0,
		"source shows diary origin"
	)
	_expect(_find_label_containing(screen, "日记旁注") != null, "lore always visible")
	_expect(_find_label_containing(screen, "不灭章") != null, "soft-fail policy on ritual page")

	screen.apply_snapshot(RitualSnapshotScript.new({
		"display_name_zh": "小丑晋升考核",
		"source_zh": "罗塞尔日记·末叶守则",
		"description_zh": "考核未通过。",
		"status": "failed",
		"corruption": 8,
		"max_corruption": 10,
		"spirit": 0,
		"errors": 2,
		"step_titles": ["扮演守则", "晋升流程", "小丑本质"],
		"step_index": 1,
		"step_count": 3,
	}))
	await get_tree().process_frame
	_expect(_find_label_containing(screen, "可再次起誓") != null, "soft-fail result invites retry")
	_expect(
		_find_label_containing(screen, "可回日记重考") != null,
		"soft-fail status keeps chapter"
	)
	_finish()


func _find_label_containing(root: Node, needle: String) -> Label:
	if root is Label:
		var label := root as Label
		if label.text.find(needle) >= 0:
			return label
	for child in root.get_children():
		var found := _find_label_containing(child, needle)
		if found != null:
			return found
	return null


func _expect(condition: bool, label: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(label)


func _finish() -> void:
	if _failures.is_empty():
		print("V056_RITUAL_UI_OK checks=%d" % _checks)
		get_tree().quit(0)
	else:
		print("V056_RITUAL_UI_FAIL checks=%d failures=%s" % [_checks, str(_failures)])
		get_tree().quit(1)
