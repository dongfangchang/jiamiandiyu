extends Node

const ChallengeScreenScene := preload("res://scenes/ui/challenge_screen.tscn")
const ChallengeResultScreenScene := preload(
	"res://scenes/ui/challenge_result_screen.tscn"
)
const RouteScreenScene := preload("res://scenes/ui/route_screen.tscn")
const StartScreenScene := preload("res://scenes/ui/start_screen.tscn")
const ChallengeSnapshotScript := preload("res://src/core/challenge_snapshot.gd")
const ChallengeCommandResultScript := preload(
	"res://src/core/challenge_command_result.gd"
)
const RouteSnapshotScript := preload("res://src/core/route_snapshot.gd")

var _checks := 0
var _failures: Array[String] = []
var _captured_command_type: StringName = &""
var _captured_modifier_id := ""
var _hub_requests := 0
var _retry_requests := 0


func _ready() -> void:
	await get_tree().process_frame
	_test_assets()
	await _test_challenge_screen()
	await _test_challenge_result()
	await _test_challenge_route_context()
	await _test_start_entry()
	_finish()


func _test_assets() -> void:
	var paths := [
		"res://assets/game/v0.6.0/scenes/challenge-selection.png",
		"res://assets/game/v0.6.0/scenes/challenge-result.png",
		"res://assets/game/v0.6.0/icons/challenge-emblem.png",
		"res://assets/game/v0.6.0/icons/modifier-pressure-advance.png",
		"res://assets/game/v0.6.0/icons/modifier-mirror-echo.png",
		"res://assets/game/v0.6.0/icons/modifier-compact-deck.png",
		"res://assets/game/v0.6.0/icons/challenge-success.png",
		"res://assets/game/v0.6.0/icons/challenge-failure.png",
	]
	for path in paths:
		_expect(ResourceLoader.exists(path), "challenge UI art exists: %s" % path)


func _test_challenge_screen() -> void:
	var screen = ChallengeScreenScene.instantiate()
	add_child(screen)
	await get_tree().process_frame
	screen.challenge_command_requested.connect(
		func(command: ChallengeCommand) -> void:
			_captured_command_type = command.type
			_captured_modifier_id = String(command.modifier_id)
	)
	var locked = _challenge_snapshot({
		"phase": "locked",
		"unlocked": false,
		"sequence": _sequence(false),
	})
	screen.apply_snapshot(locked)
	_expect(screen.get_modifier_count() == 3, "challenge screen renders three modifiers")
	_expect(screen.get_requirement_text().contains("锁定"), "locked requirement is explicit")
	_expect(not screen.can_start(), "locked challenge cannot start")
	_expect(screen.get_background_path().ends_with("challenge-selection.png"), "challenge selection art resolves")

	_captured_command_type = &""
	screen.request_modifier("modifier.rushed_reflection")
	_expect(_captured_command_type == &"", "locked modifier selection emits no command")
	_expect(screen.get_status_text().contains("尚未解锁"), "locked rejection text is visible")

	var unlocked = _challenge_snapshot({
		"phase": "modifier_selection",
		"unlocked": true,
		"sequence": _sequence(true),
	})
	screen.apply_snapshot(unlocked)
	_expect(not screen.can_start(), "challenge requires a selected modifier")
	screen.set_reward_labels({
		"reward.divination_tickets": "灵界占卜券",
	})
	_expect(screen.get_reward_text().contains("占卜券"), "challenge reward labels are injected")

	screen.request_modifier("modifier.tainted_margins")
	_expect(screen.is_pending(), "modifier selection enters pending")
	_expect(_captured_command_type == ChallengeCommand.SELECT_MODIFIER, "modifier UI emits stable command")
	_expect(_captured_modifier_id == "modifier.tainted_margins", "modifier UI emits stable id")
	var selected = _challenge_snapshot({
		"phase": "modifier_selection",
		"unlocked": true,
		"sequence": _sequence(true),
		"selected_modifier_id": "modifier.tainted_margins",
		"selected_modifier": _modifiers()[1],
	})
	screen.apply_command_result(ChallengeCommandResultScript.new(
		true,
		&"ok",
		[],
		selected,
		null
	))
	_expect(not screen.is_pending(), "accepted modifier clears pending")
	_expect(screen.can_start(), "selected modifier enables challenge start")

	_captured_command_type = &""
	screen.request_start()
	_expect(_captured_command_type == ChallengeCommand.START_CHALLENGE, "challenge UI emits start command")
	_expect(screen.is_pending(), "challenge start enters pending")
	screen.apply_command_result(ChallengeCommandResultScript.new(
		true,
		&"ok",
		[],
		_challenge_snapshot({
			"phase": "active",
			"unlocked": true,
			"selected_modifier_id": "modifier.tainted_margins",
			"selected_modifier": _modifiers()[1],
			"sequence": _sequence(true),
		}),
		null
	))
	_expect(screen.get_status_text().contains("挑战档案"), "accepted start updates status")
	screen.queue_free()
	await get_tree().process_frame


func _test_challenge_result() -> void:
	var screen = ChallengeResultScreenScene.instantiate()
	add_child(screen)
	await get_tree().process_frame
	_hub_requests = 0
	_retry_requests = 0
	screen.hub_requested.connect(func() -> void: _hub_requests += 1)
	screen.retry_requested.connect(func() -> void: _retry_requests += 1)
	var success = _challenge_snapshot({
		"phase": "completed",
		"unlocked": true,
		"challenge_outcome": "completed",
		"selected_modifier_id": "modifier.fractured_deck",
		"selected_modifier": _modifiers()[2],
		"sequence": _sequence(true),
		"route": _route_data(true),
	})
	screen.set_reward_labels({"reward.divination_tickets": "灵界占卜券"})
	screen.show_result(success, "saved")
	_expect(screen.get_title_text() == "挑战完成", "challenge success title is explicit")
	_expect(screen.get_reward_text().contains("占卜券"), "challenge success shows reward")
	_expect(screen.get_save_text().contains("已保存"), "challenge success shows saved state")
	_expect(screen.is_retry_enabled(), "challenge success allows retry")
	_expect(screen.get_background_path().ends_with("challenge-result.png"), "challenge result art resolves")

	var failure = _challenge_snapshot({
		"phase": "failed",
		"unlocked": true,
		"challenge_outcome": "failed",
		"selected_modifier_id": "modifier.rushed_reflection",
		"selected_modifier": _modifiers()[0],
		"sequence": _sequence(true),
		"route": _route_data(false),
	})
	screen.show_result(failure, "backup")
	_expect(screen.get_title_text() == "挑战中断", "challenge failure title is explicit")
	_expect(screen.get_reward_text().contains("局外收藏"), "challenge failure explains retained collection")
	_expect(screen.get_save_text().contains("备份"), "challenge failure shows backup recovery")
	screen.set_save_state("failed")
	_expect(screen.get_save_text().contains("失败"), "challenge save failure is visible")
	screen.queue_free()
	await get_tree().process_frame


func _test_challenge_route_context() -> void:
	var screen = RouteScreenScene.instantiate()
	add_child(screen)
	await get_tree().process_frame
	screen.set_challenge_context("镜厅余响", "染墨页边")
	_expect(
		screen.get_challenge_context_text().contains("挑战"),
		"route screen displays challenge context"
	)
	_expect(
		screen.get_challenge_context_text().contains("染墨页边"),
		"route screen displays selected modifier"
	)
	screen.clear_challenge_context()
	_expect(screen.get_challenge_context_text().is_empty(), "challenge context can be cleared")
	screen.queue_free()
	await get_tree().process_frame


func _test_start_entry() -> void:
	var screen = StartScreenScene.instantiate()
	add_child(screen)
	await get_tree().process_frame
	screen.show_checkpoint_status("loaded", {
		"content_version": "v0.6.0",
		"sequence": 8,
		"challenge_available": true,
	})
	_expect(screen.is_challenge_enabled(), "start screen enables unlocked challenge")
	_expect(screen.get_challenge_hint_text().contains("已解锁"), "start screen explains challenge unlock")
	screen.show_checkpoint_status("loaded", {
		"content_version": "v0.6.0",
		"sequence": 9,
		"challenge_available": false,
		"challenge_reason": "完成序列 8 晋升后开放",
	})
	_expect(not screen.is_challenge_enabled(), "start screen disables locked challenge")
	_expect(screen.get_challenge_hint_text().contains("序列 8"), "locked challenge reason is visible")
	screen.queue_free()
	await get_tree().process_frame


func _challenge_snapshot(overrides: Dictionary) -> ChallengeSnapshot:
	var data := {
		"revision": 3,
		"challenge_id": "challenge.v060.mirror_echoes",
		"display_name_zh": "镜厅余响",
		"description_zh": "再次进入廷根旧宅，以一条修饰和已有收藏挑战镜厅男爵。",
		"phase": "modifier_selection",
		"unlocked": true,
		"required_sequence": 8,
		"selected_modifier_id": "",
		"selected_modifier": {},
		"modifiers": _modifiers(),
		"completion_reward": {
			"reward.divination_tickets": 2,
			"reward.ink_dart_fragments": 4,
		},
		"challenge_outcome": "",
		"route": _route_data(false),
		"ritual": {"status": "inactive"},
		"sequence": _sequence(true),
		"available_commands": ["select_modifier"],
	}
	for key in overrides:
		data[key] = overrides[key]
	return ChallengeSnapshotScript.new(data)


func _modifiers() -> Array:
	return [
		{
			"id": "modifier.rushed_reflection",
			"display_name_zh": "倒影提前",
			"description_zh": "敌人阶段提前两回合出现。",
			"effects": {"phase_round_delta": -2},
		},
		{
			"id": "modifier.tainted_margins",
			"display_name_zh": "染墨页边",
			"description_zh": "带着三点污染与一点被注视进入路线。",
			"effects": {
				"starting_corruption_delta": 3,
				"starting_attention_delta": 1,
			},
		},
		{
			"id": "modifier.fractured_deck",
			"display_name_zh": "残缺牌组",
			"description_zh": "纸符护持被移出牌组，但奖励增加。",
			"effects": {
				"remove_definition_ids": ["card.skill.paper_guard"],
				"completion_reward": {"reward.divination_tickets": 1},
			},
		},
	]


func _route_data(completed: bool) -> Dictionary:
	return {
		"route_id": "route.v050.first_case",
		"display_name_zh": "镜厅余响",
		"phase": "completed" if completed else "failed",
		"route_outcome": "completed" if completed else "failed",
		"completed_node_ids": (
			[
				"route.v050.node.first_hunt",
				"route.v050.node.mirror_pursuit",
				"route.v050.node.old_house_rest",
				"route.v050.node.mirror_baron",
				"route.v050.node.ascension",
			]
			if completed
			else ["route.v050.node.first_hunt"]
		),
		"nodes": [
			{"id": "route.v050.node.first_hunt"},
			{"id": "route.v050.node.mirror_pursuit"},
			{"id": "route.v050.node.old_house_rest"},
			{"id": "route.v050.node.mirror_baron"},
			{"id": "route.v050.node.ascension"},
		],
		"run_state": {
			"hp": 32,
			"max_hp": 54,
			"corruption": 3,
			"max_corruption": 10,
			"attention": 2,
			"max_attention": 10,
		},
	}


func _sequence(completed: bool) -> Dictionary:
	return {
		"pathway_id": "seer",
		"pathway_name_zh": "占卜家",
		"current_sequence": 8 if completed else 9,
		"next_sequence": 8,
		"next_sequence_name_zh": "小丑",
		"advancement_state": "completed" if completed else "locked",
	}


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("V06_CHALLENGE_UI_SMOKE_OK checks=%d" % _checks)
		get_tree().quit(0)
		return
	for failure in _failures:
		printerr("V06_CHALLENGE_UI_SMOKE_FAIL %s" % failure)
	print("V06_CHALLENGE_UI_SMOKE_FAIL checks=%d failures=%d" % [
		_checks,
		_failures.size(),
	])
	get_tree().quit(1)
