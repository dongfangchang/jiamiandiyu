extends Node

const RewardScreenScene := preload("res://scenes/ui/reward_screen.tscn")
const RouteResultScene := preload("res://scenes/ui/route_result_screen.tscn")
const ProgressionSnapshotScript := preload("res://src/core/progression_snapshot.gd")
const RouteSnapshotScript := preload("res://src/core/route_snapshot.gd")

var _passed := 0
var _failures: Array[String] = []


func _ready() -> void:
	await _test_completed_route_reason()
	await _test_reward_navigation_copy()
	if _failures.is_empty():
		print("V094_RESPONSE_TRUTH_OK checks=%d" % _passed)
		get_tree().quit(0)
		return
	for failure in _failures:
		printerr("V094_RESPONSE_TRUTH_FAIL: %s" % failure)
	get_tree().quit(1)


func _test_completed_route_reason() -> void:
	var screen = RouteResultScene.instantiate()
	add_child(screen)
	screen.show_result(RouteSnapshotScript.new({
		"display_name_zh": "廷根旧宅调查",
		"route_outcome": "completed",
		"end_reason": "",
		"completed_node_ids": ["a", "b", "c", "d", "e"],
		"nodes": [{"id": "a"}, {"id": "b"}, {"id": "c"}, {"id": "d"}, {"id": "e"}],
		"sequence": {"current_sequence": 8},
		"run_state": {
			"hp": 42,
			"max_hp": 54,
			"corruption": 3,
			"max_corruption": 10,
			"attention": 2,
			"max_attention": 10,
		},
	}), "saved")
	var detail: Label = screen.get("_detail_label")
	_expect(
		detail.text.contains("三步晋升仪式完成"),
		"completed route must infer completion when the reason is missing"
	)
	_expect(
		not detail.text.contains("规则层未提供原因"),
		"successful route summary must not contradict its title"
	)
	screen.queue_free()
	await get_tree().process_frame


func _test_reward_navigation_copy() -> void:
	var screen = RewardScreenScene.instantiate()
	add_child(screen)
	screen.apply_snapshot(ProgressionSnapshotScript.new({
		"revision": 1,
		"phase": "reward",
		"identity_id": "identity.reporter",
		"identity_options": [],
		"battle_modifiers": {},
		"divination_tickets": 3,
		"collection": [],
		"pity_counter": 0,
		"rare_pity": 4,
		"gacha_costs": {},
		"rarity_weights": {},
		"reward_options": [{
			"id": "reward.divination_tickets",
			"display_name_zh": "灵界占卜券",
			"kind": "divination_tickets",
			"amount": 3,
		}],
		"last_battle_outcome": "victory",
		"last_gacha_results": [],
	}))
	var hub_button: Button = screen.get("_hub_button")
	_expect(
		hub_button != null and not hub_button.visible,
		"reward screen must hide unavailable hub navigation"
	)
	_expect(
		not screen.get_status_text().contains("或返回"),
		"reward status must not promise unavailable navigation"
	)
	_expect(
		screen.get_status_text().contains("必须选择"),
		"reward status should state the mandatory choice"
	)
	screen.queue_free()
	await get_tree().process_frame


func _expect(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
	else:
		_failures.append(message)
