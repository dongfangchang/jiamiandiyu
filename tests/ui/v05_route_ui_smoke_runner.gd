extends Node

const RouteScreenScene := preload("res://scenes/ui/route_screen.tscn")
const RestScreenScene := preload("res://scenes/ui/rest_screen.tscn")
const RitualScreenScene := preload("res://scenes/ui/ritual_screen.tscn")
const RouteResultScreenScene := preload("res://scenes/ui/route_result_screen.tscn")
const BattleScreenScene := preload("res://scenes/ui/battle_screen.tscn")
const RouteSnapshotScript := preload("res://src/core/route_snapshot.gd")
const RitualSnapshotScript := preload("res://src/core/ritual_snapshot.gd")
const RouteCommandResultScript := preload("res://src/core/route_command_result.gd")
const SequenceStateScript := preload("res://src/core/sequence_state.gd")

var _checks := 0
var _failures: Array[String] = []
var _captured_command_type: StringName = &""
var _captured_node_id := ""
var _captured_rest_id := ""
var _captured_ritual_selections: Array[String] = []
var _hub_requests := 0


func _ready() -> void:
	await get_tree().process_frame
	_test_assets()
	await _test_route_screen()
	await _test_rest_screen()
	await _test_ritual_screen()
	await _test_route_result()
	await _test_enemy_art_mapping()
	_finish()


func _test_assets() -> void:
	var paths := [
		"res://assets/game/v0.24.0/v0.5.0/scenes/route-map.png",
		"res://assets/game/v0.24.0/v0.5.0/scenes/rest-old-house.png",
		"res://assets/game/v0.24.0/v0.5.0/scenes/ritual-tampered-obituary.png",
		"res://assets/game/v0.24.0/v0.5.0/enemies/enemy-mirror-baron.png",
		"res://assets/game/v0.24.0/v0.5.0/rituals/ritual-card-name-record.png",
		"res://assets/game/v0.24.0/v0.5.0/rituals/ritual-card-chronology.png",
		"res://assets/game/v0.24.0/v0.5.0/rituals/ritual-card-seal.png",
		"res://assets/game/v0.24.0/v0.5.0/icons/route-pending.png",
		"res://assets/game/v0.24.0/v0.5.0/icons/route-current.png",
		"res://assets/game/v0.24.0/v0.5.0/icons/route-completed.png",
		"res://assets/game/v0.24.0/v0.5.0/icons/ritual-success.png",
		"res://assets/game/v0.24.0/v0.5.0/icons/ritual-failure.png",
	]
	for path in paths:
		_expect(ResourceLoader.exists(path), "v0.5 UI art exists: %s" % path)


func _test_route_screen() -> void:
	var screen = RouteScreenScene.instantiate()
	add_child(screen)
	await get_tree().process_frame
	screen.route_command_requested.connect(func(command: RouteCommand) -> void:
		_captured_command_type = command.type
		_captured_node_id = String(command.node_id)
	)
	_hub_requests = 0
	screen.hub_requested.connect(func() -> void: _hub_requests += 1)
	var snapshot = _route_snapshot({
		"phase": "map",
		"nodes": _route_nodes("route.v050.node.first_hunt"),
		"current_node_id": "route.v050.node.first_hunt",
		"chapter_title_zh": "廷根：雨夜异常调查",
		"chapter_phase_zh": "从灵视到证据",
		"chapter_summary_zh": "沿线索确认异常。",
	})
	screen.apply_snapshot(snapshot)
	_expect(screen.get_node_count() == 5, "route screen renders five nodes")
	_expect(screen.get_node_state(0) == "available", "first node is available")
	_expect(screen.get_node_state(2) == "locked", "later rest node is locked")
	_expect(screen.get_background_path().ends_with("route-map.png"), "route art background resolves")
	_expect(screen.find_child("ChapterMapScroll", true, false) != null, "route keeps chapter map in a horizontal scroll container")
	_expect(screen.get_current_goal_text().contains("推进收益"), "route exposes the current node reward hint")
	_expect(screen.is_node_button_enabled("route.v050.node.first_hunt"), "available node button enabled")
	_expect(not screen.is_node_button_enabled("route.v050.node.mirror_pursuit"), "locked node button disabled")
	screen.request_node("route.v050.node.first_hunt")
	_expect(screen.is_pending(), "route node command enters pending")
	_expect(_captured_command_type == RouteCommand.SELECT_NODE, "route UI emits select command")
	_expect(_captured_node_id == "route.v050.node.first_hunt", "route UI emits stable node id")

	screen.apply_command_result(RouteCommandResultScript.new(
		false,
		&"node_not_available",
		[],
		snapshot,
		RitualSnapshotScript.new({"status": "inactive"}),
		_sequence_state("locked")
	))
	_expect(not screen.is_pending(), "route rejection clears pending")
	_expect(screen.get_status_text().contains("尚未解锁"), "route rejection reason is visible")

	var ascension_snapshot = _route_snapshot({
		"phase": "map",
		"nodes": _route_nodes("route.v050.node.ascension"),
		"completed_node_ids": [
			"route.v050.node.first_hunt",
			"route.v050.node.mirror_pursuit",
			"route.v050.node.old_house_rest",
			"route.v050.node.mirror_baron",
		],
		"can_begin_ascension": true,
	})
	_captured_command_type = &""
	screen.apply_snapshot(ascension_snapshot)
	screen.request_ascension()
	_expect(_captured_command_type == RouteCommand.BEGIN_ASCENSION, "route UI emits begin ascension command")
	_expect(screen.is_pending(), "ascension command enters pending")
	screen.set_pending(false)
	screen.queue_free()
	await get_tree().process_frame


func _test_rest_screen() -> void:
	var screen = RestScreenScene.instantiate()
	add_child(screen)
	await get_tree().process_frame
	screen.route_command_requested.connect(func(command: RouteCommand) -> void:
		_captured_command_type = command.type
		_captured_rest_id = String(command.rest_id)
	)
	var snapshot = _route_snapshot({
		"phase": "rest_pending",
		"selected_node_id": "route.v050.node.old_house_rest",
		"rest_options": _rest_options(),
	})
	screen.apply_snapshot(snapshot)
	_expect(screen.get_option_count() == 2, "rest screen renders two options")
	_expect(screen.get_option_effect_text(0).contains("生命 +12"), "rest displays healing effect from snapshot")
	_expect(screen.get_option_effect_text(1).contains("污染 -2"), "rest displays corruption effect from snapshot")
	_expect(
		screen.get_option_effect_text(1).contains("下一战灵性上限 +1"),
		"rest displays next-battle spirit cap growth from snapshot"
	)
	_expect(screen.get_background_path().ends_with("rest-old-house.png"), "rest art background resolves")
	screen.select_rest("rest.bandage")
	_expect(screen.is_pending(), "rest command enters pending")
	_expect(_captured_command_type == RouteCommand.USE_REST, "rest UI emits use rest command")
	_expect(_captured_rest_id == "rest.bandage", "rest UI emits stable rest id")
	screen.apply_command_result(RouteCommandResultScript.new(
		false,
		&"rest_not_available",
		[],
		snapshot,
		RitualSnapshotScript.new({"status": "inactive"}),
		_sequence_state("locked")
	))
	_expect(screen.get_status_text().contains("不可用"), "rest rejection reason is visible")
	screen.queue_free()
	await get_tree().process_frame


func _test_ritual_screen() -> void:
	var screen = RitualScreenScene.instantiate()
	add_child(screen)
	await get_tree().process_frame
	screen.route_command_requested.connect(func(command: RouteCommand) -> void:
		_captured_command_type = command.type
		_captured_ritual_selections = command.ritual_selections.duplicate()
	)
	var step_one := _ritual_snapshot({
		"status": "in_progress",
		"step_index": 0,
		"step_count": 3,
		"step": {
			"id": "step.names",
			"type": "select_ids",
			"title_zh": "姓名记录",
			"clue_zh": "门框上刻着两个相邻的 W。",
			"min_selections": 2,
			"max_selections": 2,
			"options": [
				{"id": "name.elin_ward", "display_name_zh": "艾琳·沃德"},
				{"id": "name.thomas_ward", "display_name_zh": "托马斯·沃德"},
				{"id": "name.mira_finch", "display_name_zh": "米拉·芬奇"},
			]
		}
	})
	screen.apply_snapshot(step_one)
	_expect(screen.get_background_path().ends_with("ritual-tampered-obituary.png"), "ritual art background resolves")
	_expect(screen.get_step_title() == "姓名记录", "ritual screen reads step title")
	_expect(
		screen.get_hint_button_text().contains("1 灵性"),
		"ritual hint button displays snapshot spirit cost"
	)
	screen.select_option("name.elin_ward")
	_expect(not screen.is_submit_enabled(), "ritual submit disabled before minimum selection")
	screen.select_option("name.thomas_ward")
	_expect(screen.get_selected_ids().size() == 2, "ritual records two selected names")
	_expect(screen.is_submit_enabled(), "ritual submit enabled at selection target")
	screen.submit_step()
	_expect(_captured_command_type == RouteCommand.SUBMIT_RITUAL_STEP, "ritual UI emits submit step")
	_expect(_captured_ritual_selections.size() == 2, "ritual UI sends selected ids")
	_expect(screen.is_pending(), "ritual submit enters pending")

	var step_two := _ritual_snapshot({
		"status": "in_progress",
		"step_index": 1,
		"step_count": 3,
		"step": {
			"id": "step.chronology",
			"type": "ordered_ids",
			"title_zh": "事件顺序",
			"clue_zh": "死亡墨迹覆盖了出生日期。",
			"min_selections": 3,
			"max_selections": 3,
			"options": [
				{"id": "event.birth", "display_name_zh": "出生"},
				{"id": "event.death", "display_name_zh": "死亡"},
				{"id": "event.burial", "display_name_zh": "埋葬"},
			]
		}
	})
	screen.apply_command_result(RouteCommandResultScript.new(
		true,
		&"ok",
		[],
		_route_snapshot({}),
		step_two,
		_sequence_state("available")
	))
	_expect(screen.get_step_title() == "事件顺序", "ritual advances to chronology step")
	_expect(screen.get_selected_ids().is_empty(), "ritual clears selection on new step")
	screen.select_option("event.birth")
	screen.select_option("event.death")
	screen.select_option("event.burial")
	_expect(screen.get_selected_ids() == ["event.birth", "event.death", "event.burial"], "ritual preserves ordered selections")
	var no_spirit := _ritual_snapshot({
		"status": "in_progress",
		"step_index": 1,
		"step_count": 3,
		"spirit": 0,
		"hint_spirit_cost": 1,
		"step": step_two.to_dictionary().get("step", {}),
	})
	screen.apply_snapshot(no_spirit)
	_captured_command_type = &""
	screen.request_hint()
	_expect(_captured_command_type == RouteCommand.REQUEST_RITUAL_HINT, "ritual hint request still reaches domain when spirit is low")
	screen.set_pending(false)
	screen.apply_command_result(RouteCommandResultScript.new(
		false,
		&"insufficient_spirit",
		[],
		_route_snapshot({}),
		no_spirit,
		_sequence_state("available")
	))
	_expect(screen.get_status_text().contains("灵性不足"), "ritual insufficient spirit rejection is visible")
	screen.apply_snapshot(step_two)
	_captured_command_type = &""
	screen.request_hint()
	_expect(_captured_command_type == RouteCommand.REQUEST_RITUAL_HINT, "ritual UI emits hint command")
	_expect(screen.is_pending(), "ritual hint enters pending")
	screen.set_pending(false)
	screen.apply_command_result(RouteCommandResultScript.new(
		false,
		&"hint_already_used",
		[],
		_route_snapshot({}),
		step_two,
		_sequence_state("available")
	))
	_expect(screen.get_status_text().contains("已经使用"), "ritual hint rejection is visible")
	screen.request_cancel()
	_expect(_captured_command_type == RouteCommand.CANCEL_RITUAL, "ritual UI emits cancel command")
	screen.set_pending(false)
	screen.apply_snapshot(_ritual_snapshot({"status": "completed", "result": "success"}))
	_expect(screen.get_status_text().contains("归档"), "ritual success result is shown")
	screen.queue_free()
	await get_tree().process_frame


func _test_route_result() -> void:
	var screen = RouteResultScreenScene.instantiate()
	add_child(screen)
	await get_tree().process_frame
	_hub_requests = 0
	screen.hub_requested.connect(func() -> void: _hub_requests += 1)
	var completed_snapshot = _route_snapshot({
		"phase": "completed",
		"route_outcome": "completed",
		"completed_node_ids": [
			"route.v050.node.first_hunt",
			"route.v050.node.mirror_pursuit",
			"route.v050.node.old_house_rest",
			"route.v050.node.mirror_baron",
			"route.v050.node.ascension",
		],
		"sequence": {
			"pathway_name_zh": "占卜家",
			"current_sequence": 8,
			"next_sequence_name_zh": "小丑",
		},
	})
	screen.show_result(completed_snapshot, "saved")
	_expect(screen.get_title_text() == "晋升完成", "route result marks ascension success")
	_expect(screen.get_save_text().contains("已保存"), "route result displays save success")
	_expect(screen.get_background_path().ends_with("ritual-tampered-obituary.png"), "success result uses ritual art")
	_expect(screen.get_route_outcome() == "completed", "route result exposes completed outcome")
	screen.set_save_state("failed")
	_expect(screen.get_save_text().contains("失败"), "route result displays save failure")
	screen.show_result(_route_snapshot({
		"phase": "failed",
		"route_outcome": "failed",
		"completed_node_ids": ["route.v050.node.first_hunt"],
	}), "backup")
	_expect(screen.get_title_text() == "探索失败", "route result marks route failure")
	_expect(screen.get_save_text().contains("备份"), "route result displays backup recovery")
	screen.queue_free()
	await get_tree().process_frame


func _test_enemy_art_mapping() -> void:
	var battle = BattleScreenScene.instantiate()
	add_child(battle)
	await get_tree().process_frame
	# v0.31.0 canon re-theme: enemy.mirror_baron is now 失控的老尼尔 (red-eyed
	# monster art) and enemy.mirror_hound_echo is 燕尾服小丑 (top-hat art).
	_expect(
		battle.get_enemy_art_path(&"enemy.mirror_baron").ends_with("enemy-candle-moth.png"),
		"lost-control Old Neil uses the red-eyed monster art"
	)
	_expect(
		battle.get_enemy_art_path(&"enemy.mirror_hound_echo").ends_with("enemy-mirror-baron.png"),
		"the Suited Clown uses the top-hat art"
	)
	battle.queue_free()
	await get_tree().process_frame


func _route_nodes(available_id: String) -> Array:
	var entries := [
		["route.v050.node.first_hunt", "normal", "雨夜双影"],
		["route.v050.node.mirror_pursuit", "elite", "回声追猎"],
		["route.v050.node.old_house_rest", "rest", "旧宅喘息"],
		["route.v050.node.mirror_baron", "boss", "镜厅男爵"],
		["route.v050.node.ascension", "ritual", "被篡改的讣告"],
	]
	var available_index := -1
	for index in range(entries.size()):
		if String(entries[index][0]) == available_id:
			available_index = index
			break
	var result: Array = []
	for index in range(entries.size()):
		var entry: Array = entries[index]
		var state := "locked"
		if available_index >= 0 and index < available_index:
			state = "completed"
		elif index == available_index:
			state = "available"
		result.append({
			"id": String(entry[0]),
			"type": String(entry[1]),
			"display_name_zh": String(entry[2]),
			"investigation_goal_zh": "确认异常并保留一条可复核的目击线索。" if index == 0 else "",
			"reward_hint_zh": "保留灵视带来的调查优势。" if index == 0 else "",
			"state": state,
		})
	return result


func _route_snapshot(overrides: Dictionary) -> RouteSnapshot:
	var data := {
		"revision": 4,
		"route_id": "route.v050.first_case",
		"display_name_zh": "廷根旧宅调查",
		"phase": "map",
		"current_node_id": "route.v050.node.first_hunt",
		"available_node_id": "route.v050.node.first_hunt",
		"selected_node_id": "",
		"completed_node_ids": [],
		"nodes": _route_nodes("route.v050.node.first_hunt"),
		"run_state": {
			"hp": 42,
			"max_hp": 54,
			"spirit": 3,
			"max_spirit": 3,
			"corruption": 3,
			"max_corruption": 10,
			"attention": 2,
			"max_attention": 10,
		},
		"rest_options": [],
		"route_outcome": "",
		"sequence": _sequence_state("locked").to_dictionary(),
		"ritual": {"status": "inactive"},
		"can_begin_ascension": false,
	}
	for key in overrides:
		data[key] = overrides[key]
	return RouteSnapshotScript.new(data)


func _ritual_snapshot(overrides: Dictionary) -> RitualSnapshot:
	var data := {
		"status": "in_progress",
		"ritual_id": "ritual.v050.tampered_obituary",
		"display_name_zh": "被篡改的讣告",
		"step_index": 0,
		"step_count": 3,
		"hints_used": 0,
		"hinted_step_indices": [],
		"errors": 0,
		"hint_text": "",
		"hint_spirit_cost": 1,
		"corruption": 2,
		"spirit": 3,
		"result": "",
	}
	for key in overrides:
		data[key] = overrides[key]
	return RitualSnapshotScript.new(data)


func _rest_options() -> Array:
	return [
		{
			"id": "rest.bandage",
			"display_name_zh": "包扎伤口",
			"description_zh": "恢复生命。",
			"effects": {"hp_delta": 12, "corruption_delta": 0, "attention_delta": 0},
		},
		{
			"id": "rest.seal_echo",
			"display_name_zh": "封锁回声",
			"description_zh": "降低污染。",
			"effects": {
				"hp_delta": 0,
				"corruption_delta": -2,
				"attention_delta": 1,
				"max_spirit_delta": 1,
			},
		},
	]


func _sequence_state(advancement_state: String) -> SequenceState:
	return SequenceStateScript.new({
		"pathway_id": "seer",
		"pathway_name_zh": "占卜家",
		"current_sequence": 9,
		"next_sequence": 8,
		"next_sequence_name_zh": "小丑",
		"advancement_state": advancement_state,
	})


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("V05_ROUTE_UI_SMOKE_OK checks=%d" % _checks)
		get_tree().quit(0)
		return
	for failure in _failures:
		printerr("V05_ROUTE_UI_SMOKE_FAIL %s" % failure)
	print("V05_ROUTE_UI_SMOKE_FAIL checks=%d failures=%d" % [_checks, _failures.size()])
	get_tree().quit(1)
