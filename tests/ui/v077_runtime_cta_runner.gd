extends Node

## v0.77: instantiate hub/exit screens and assert live button labels.
## v0.86 R0-03: dropped source-text greps and the retired route_screen check.

const IdentityScreenScene := preload("res://scenes/ui/identity_screen.tscn")
const RewardScreenScene := preload("res://scenes/ui/reward_screen.tscn")
const GachaScreenScene := preload("res://scenes/ui/gacha_screen.tscn")
const DiaryScreenScript := preload("res://src/ui/diary_chapter_screen.gd")
const ProgressionSnapshotScript := preload("res://src/core/progression_snapshot.gd")
const RouteSnapshotScript := preload("res://src/core/route_snapshot.gd")

var _checks := 0
var _failures: Array[String] = []


func _ready() -> void:
	await _check_identity()
	await _check_reward()
	await _check_gacha()
	await _check_diary()
	if _failures.is_empty():
		print("V077_RUNTIME_CTA_OK checks=%d" % _checks)
	else:
		print("V077_RUNTIME_CTA_FAIL checks=%d failures=%s" % [_checks, str(_failures)])
		for failure in _failures:
			push_error(failure)
	get_tree().quit(0 if _failures.is_empty() else 1)


func _hub_snapshot():
	return ProgressionSnapshotScript.new({
		"revision": 1,
		"phase": "hub",
		"identity_id": "identity.reporter",
		"identity_options": [{
			"id": "identity.reporter",
			"display_name_zh": "记者",
			"description_zh": "用笔记录廷根的异常。",
			"selected": true,
			"battle_modifiers": {"starting_spirit_bonus": 1},
			"passive_text_zh": "开局多 1 灵性",
		}],
		"battle_modifiers": {},
		"divination_tickets": 3,
		"collection": [{"definition_id": "card.skill.ink_dart", "copies": 1}],
		"pity_counter": 1,
		"rare_pity": 4,
		"gacha_costs": {"single": 2, "triple": 5},
		"rarity_weights": {"common": 85, "rare": 15},
		"reward_options": [],
		"last_battle_outcome": "victory",
		"last_gacha_results": [],
	})


func _check_identity() -> void:
	var screen = IdentityScreenScene.instantiate()
	add_child(screen)
	await _wait_frames(2)
	screen.apply_snapshot(_hub_snapshot())
	await _wait_frames(2)
	_expect(_find_button(screen, "打开日记") != null, "identity exposes 打开日记")
	_expect(_find_button(screen, "进入夜间战斗") == null, "identity hides 进入夜间战斗")
	_expect(screen.find_children("*", "OptionButton", true, false).is_empty(), "identity no OptionButton")
	screen.queue_free()
	await _wait_frames(1)


func _check_reward() -> void:
	var screen = RewardScreenScene.instantiate()
	add_child(screen)
	await _wait_frames(2)
	_expect(_find_button(screen, "回日记") != null, "reward exposes 回日记")
	_expect(_find_button(screen, "返回白昼档案") == null, "reward hides 返回白昼档案")
	screen.queue_free()
	await _wait_frames(1)


func _check_gacha() -> void:
	var screen = GachaScreenScene.instantiate()
	add_child(screen)
	await _wait_frames(2)
	screen.apply_snapshot(_hub_snapshot())
	await _wait_frames(2)
	_expect(_find_button(screen, "回日记") != null, "gacha exposes 回日记")
	_expect(_find_button(screen, "返回白昼档案") == null, "gacha hides 返回白昼档案")
	_expect(screen.find_children("*", "OptionButton", true, false).is_empty(), "gacha no OptionButton")
	screen.queue_free()
	await _wait_frames(1)


func _check_diary() -> void:
	var screen = DiaryScreenScript.new()
	add_child(screen)
	await _wait_frames(2)
	screen.apply_snapshot(RouteSnapshotScript.new({
		"display_name_zh": "第一卷·小丑：廷根值夜者",
		"phase": "map",
		"available_node_id": "route.v028.first_stage.node.first_hunt",
		"unlocked_node_ids": ["route.v028.first_stage.node.first_hunt"],
		"completed_node_ids": [],
		"run_state": {
			"hp": 44, "max_hp": 54, "spirit": 3, "max_spirit": 3,
			"corruption": 2, "max_corruption": 10, "attention": 3, "max_attention": 10,
		},
		"nodes": [],
	}))
	await _wait_frames(3)
	_expect(_find_button(screen, "合上") != null, "diary exposes 合上")
	_expect(screen.find_children("*", "OptionButton", true, false).is_empty(), "diary no OptionButton")
	screen.queue_free()
	await _wait_frames(1)


func _find_button(root: Node, text: String) -> Button:
	for node in root.find_children("*", "Button", true, false):
		var button := node as Button
		if button != null and String(button.text) == text:
			return button
	return null


func _expect(cond: bool, label: String) -> void:
	_checks += 1
	if not cond:
		_failures.append(label)


func _wait_frames(count: int) -> void:
	for _i in count:
		await get_tree().process_frame
