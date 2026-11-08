extends Node

const ChallengeScreenScene := preload("res://scenes/ui/challenge_screen.tscn")
const ChallengeSnapshotScript := preload("res://src/core/challenge_snapshot.gd")
const DeckScreenScene := preload("res://scenes/ui/deck_screen.tscn")
const DeckSnapshotScript := preload("res://src/core/deck_snapshot.gd")
const RouteScreenScene := preload("res://scenes/ui/route_screen.tscn")
const RouteSnapshotScript := preload("res://src/core/route_snapshot.gd")
const RitualScreenScene := preload("res://scenes/ui/ritual_screen.tscn")
const RitualSnapshotScript := preload("res://src/core/ritual_snapshot.gd")
const UpgradeScreenScene := preload("res://scenes/ui/upgrade_screen.tscn")
const ProgressionSnapshotScript := preload("res://src/core/progression_snapshot.gd")

var _passed := 0
var _failures: Array[String] = []


func _ready() -> void:
	await _test_challenge_exit_while_pending()
	await _test_deck_back_while_pending()
	await _test_upgrade_back_while_pending()
	await _test_route_hub_while_pending()
	await _test_ritual_cancel_while_pending()
	if _failures.is_empty():
		print("V093_PENDING_NAV_OK checks=%d" % _passed)
		get_tree().quit(0)
		return
	for failure in _failures:
		printerr("V093_PENDING_NAV_FAIL: %s" % failure)
	get_tree().quit(1)


func _test_challenge_exit_while_pending() -> void:
	var screen = ChallengeScreenScene.instantiate()
	add_child(screen)
	screen.apply_snapshot(ChallengeSnapshotScript.new(_challenge_snapshot()))
	var exits := [0]
	screen.exit_requested.connect(func() -> void:
		exits[0] += 1
	)
	screen.set_pending(true)
	var button: Button = screen.get("_exit_button")
	_expect(
		button != null and not button.disabled,
		"challenge exit must stay enabled while modifier/start is pending"
	)
	screen.request_exit()
	_expect(exits[0] == 1, "pending challenge must emit one exit intent")
	screen.queue_free()
	await get_tree().process_frame


func _test_deck_back_while_pending() -> void:
	var screen = DeckScreenScene.instantiate()
	add_child(screen)
	screen.apply_snapshot(DeckSnapshotScript.new({
		"revision": 1,
		"phase": "ready",
		"required_deck_size": 8,
		"current_card_ids": [],
		"current_deck_size": 0,
		"legal": false,
		"reason_code": "deck_incomplete",
		"confirmed": false,
		"cards": [],
		"presets": [],
		"available_commands": [],
	}))
	var backs := [0]
	screen.back_requested.connect(func() -> void:
		backs[0] += 1
	)
	screen.set_pending(true)
	var button: Button = screen.get("_back_button")
	_expect(
		button != null and not button.disabled,
		"deck back must stay enabled while a deck command is pending"
	)
	screen.request_back()
	_expect(backs[0] == 1, "pending deck must emit one back intent")
	screen.queue_free()
	await get_tree().process_frame


func _test_upgrade_back_while_pending() -> void:
	var screen = UpgradeScreenScene.instantiate()
	add_child(screen)
	screen.apply_snapshot(ProgressionSnapshotScript.new({
		"revision": 1,
		"phase": "hub",
		"identity_id": "identity.reporter",
		"identity_options": [],
		"battle_modifiers": {},
		"divination_tickets": 0,
		"collection": [],
		"pity_counter": 0,
		"rare_pity": 4,
		"gacha_costs": {},
		"rarity_weights": {},
		"reward_options": [],
		"last_battle_outcome": "",
		"last_gacha_results": [],
	}))
	var backs := [0]
	screen.back_requested.connect(func() -> void:
		backs[0] += 1
	)
	screen.set_pending(true)
	var button: Button = screen.get("_back_button")
	_expect(
		button != null and not button.disabled,
		"upgrade back must stay enabled while an upgrade is pending"
	)
	screen.call("_on_back")
	_expect(backs[0] == 1, "pending upgrade must emit one back intent")
	screen.queue_free()
	await get_tree().process_frame


func _test_route_hub_while_pending() -> void:
	var screen = RouteScreenScene.instantiate()
	add_child(screen)
	screen.apply_snapshot(RouteSnapshotScript.new(_route_snapshot()))
	var hubs := [0]
	screen.hub_requested.connect(func() -> void:
		hubs[0] += 1
	)
	screen.set_pending(true)
	var button: Button = screen.get("_hub_button")
	_expect(
		button != null and not button.disabled,
		"route hub must stay enabled while node selection is pending"
	)
	screen.call("_on_hub")
	_expect(hubs[0] == 1, "pending route must emit one hub intent")
	screen.queue_free()
	await get_tree().process_frame


func _test_ritual_cancel_while_pending() -> void:
	var screen = RitualScreenScene.instantiate()
	add_child(screen)
	screen.apply_snapshot(RitualSnapshotScript.new(_ritual_snapshot()))
	var commands: Array[RouteCommand] = []
	screen.route_command_requested.connect(func(command: RouteCommand) -> void:
		commands.append(command)
	)
	screen.set_pending(true)
	var button: Button = screen.get("_cancel_button")
	_expect(
		button != null and not button.disabled,
		"ritual cancel must stay enabled while a ritual command is pending"
	)
	screen.request_cancel()
	_expect(
		commands.size() == 1 and commands[0].type == RouteCommand.CANCEL_RITUAL,
		"pending ritual must emit one cancel command"
	)
	screen.queue_free()
	await get_tree().process_frame


func _challenge_snapshot() -> Dictionary:
	return {
		"revision": 1,
		"challenge_id": "challenge.v060.mirror_echoes",
		"display_name_zh": "镜厅余响",
		"description_zh": "测试挑战。",
		"phase": "modifier_selection",
		"unlocked": true,
		"required_sequence": 8,
		"route_id": "route.v070.first_case",
		"selected_modifier_id": "",
		"selected_modifier": {},
		"modifiers": [{
			"id": "modifier.rushed_reflection",
			"display_name_zh": "倒影提前",
			"description_zh": "测试修饰。",
			"effects": {},
		}],
		"completion_reward": {},
		"challenge_outcome": "",
		"route": {},
		"ritual": {"status": "inactive"},
		"sequence": {
			"pathway_id": "seer",
			"pathway_name_zh": "占卜家",
			"current_sequence": 8,
			"next_sequence": 7,
			"next_sequence_name_zh": "魔术师",
			"advancement_state": "completed",
		},
		"available_commands": ["select_modifier"],
	}


func _route_snapshot() -> Dictionary:
	return {
		"revision": 1,
		"route_id": "route.v070.first_case",
		"display_name_zh": "测试路线",
		"phase": "map",
		"current_node_id": "",
		"available_node_id": "route.v070.node.first_hunt",
		"selected_node_id": "",
		"completed_node_ids": [],
		"nodes": [{
			"id": "route.v070.node.first_hunt",
			"type": "normal",
			"display_name_zh": "雨夜双影",
			"state": "available",
		}],
		"run_state": {
			"hp": 10,
			"max_hp": 10,
			"spirit": 3,
			"max_spirit": 3,
			"corruption": 0,
			"max_corruption": 10,
			"attention": 0,
			"max_attention": 10,
		},
		"rest_options": [],
		"route_outcome": "",
		"sequence": {
			"pathway_id": "seer",
			"pathway_name_zh": "占卜家",
			"current_sequence": 9,
			"next_sequence": 8,
			"next_sequence_name_zh": "小丑",
			"advancement_state": "locked",
		},
		"ritual": {"status": "inactive"},
		"can_begin_ascension": false,
	}


func _ritual_snapshot() -> Dictionary:
	return {
		"status": "in_progress",
		"ritual_id": "ritual.v070.tampered_obituary",
		"display_name_zh": "被篡改的讣告",
		"step_index": 0,
		"step_count": 3,
		"hints_used": 0,
		"hinted_step_indices": [],
		"errors": 0,
		"hint_text": "",
		"corruption": 0,
		"spirit": 3,
		"result": "",
		"step": {
			"id": "step.test",
			"type": "select_id",
			"title_zh": "测试步骤",
			"clue_zh": "测试线索。",
			"min_selections": 1,
			"max_selections": 1,
			"options": [{
				"id": "option.test",
				"display_name_zh": "测试证物",
			}],
		},
	}


func _expect(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
	else:
		_failures.append(message)
