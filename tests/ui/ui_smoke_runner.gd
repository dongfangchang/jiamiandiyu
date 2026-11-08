extends Node

const StartScreenScene := preload("res://scenes/ui/start_screen.tscn")
const BattleScreenScene := preload("res://scenes/ui/battle_screen.tscn")
const ResultScreenScene := preload("res://scenes/ui/result_screen.tscn")
const BattleSnapshotScript := preload("res://src/core/battle_snapshot.gd")
const BattleCommandResultScript := preload("res://src/core/battle_command_result.gd")
const BattlePlayabilityScript := preload("res://src/core/battle_playability.gd")

var _checks := 0
var _failures: Array[String] = []
var _captured_command: BattleCommand


func _ready() -> void:
	await get_tree().process_frame
	await _test_start_screen()
	await _test_battle_screen()
	await _test_result_screen()
	_finish()


func _test_start_screen() -> void:
	var screen = StartScreenScene.instantiate()
	add_child(screen)
	await get_tree().process_frame
	_expect(not screen.is_continue_enabled(), "continue disabled with no checkpoint")
	_expect(
		screen.get_version_text().contains("本地离线原型"),
		"start screen shows the current product label without a checkpoint"
	)
	_expect(
		screen.get_version_text().contains("v0.9.2")
		and not screen.get_version_text().contains("WHISPERS"),
		"start screen shows the current Chinese version without English branding"
	)
	_expect(
		screen.get_summary_text().contains("未选择"),
		"no-checkpoint summary avoids inventing an identity"
	)
	screen.show_checkpoint_status("loaded", {
		"content_version": "v0.4.0",
		"sequence": 9,
		"deck_size": 8,
		"identity_id": "identity.reporter",
		"divination_tickets": 7,
		"collection_count": 6,
		"pity_counter": 2,
		"rare_pity": 4,
		"created_at": "2026-11-08T00:00:00Z",
		"last_battle": {"outcome": "victory", "round_number": 4},
	})
	_expect(screen.is_continue_enabled(), "continue enabled with loaded checkpoint")
	_expect(screen.get_status_text().contains("检查点"), "start screen shows checkpoint status")
	_expect(
		screen.get_version_text().contains("v0.9.2"),
		"loaded checkpoints must not replace the current product version"
	)
	_expect(screen.get_summary_text().contains("记者"), "summary shows resolved identity")
	_expect(screen.get_summary_text().contains("占卜券：7"), "summary shows ticket count")
	_expect(screen.get_summary_text().contains("2/4"), "summary shows pity progress")
	_expect(screen.get_summary_text().contains("收藏：6"), "summary shows collection count")
	screen.show_checkpoint_status("corrupt", {}, "checksum mismatch")
	_expect(not screen.is_continue_enabled(), "corrupt checkpoint disables continue")
	_expect(
		screen.get_summary_text().contains("原始存档已保留"),
		"corrupt checkpoint explains the safe state"
	)
	screen.queue_free()
	await get_tree().process_frame


func _test_battle_screen() -> void:
	var screen = BattleScreenScene.instantiate()
	add_child(screen)
	await get_tree().process_frame
	screen.command_requested.connect(_on_command_requested)
	screen.configure(
		"廷根旧宅",
		{
			&"card.skill.ink_dart": "墨刺",
			&"card.skill.focus": "凝神",
		},
		{&"enemy.weeping_tenant": "哭泣的房客"},
		func(_card_id: StringName, _target_id: StringName) -> BattlePlayability:
			return BattlePlayabilityScript.new(true, BattlePlayability.PLAYABLE)
	)
	_expect(
		screen.get_background_path().ends_with("battle-tingen-old-house.png"),
		"battle screen uses the dedicated battle background"
	)
	_expect(
		ResourceLoader.exists(screen.get_enemy_art_path(&"enemy.weeping_tenant"))
		and ResourceLoader.exists(screen.get_enemy_art_path(&"enemy.candle_moth"))
		and ResourceLoader.exists(screen.get_enemy_art_path(&"enemy.mirror_hound")),
		"all three formal enemy illustrations resolve"
	)
	_expect(
		ResourceLoader.exists(screen.get_card_art_path(&"card.skill.ink_dart"))
		and ResourceLoader.exists(screen.get_card_art_path(&"card.skill.second_look")),
		"formal card illustrations resolve"
	)
	_expect(
		screen.get_enemy_art_path(&"enemy.unknown") == "",
		"unknown enemy has no misleading reused artwork"
	)
	screen.apply_snapshot(_snapshot("player_action", 0, "player.action.001"))
	_expect(screen.get_selected_card_id() == &"", "battle starts without selection")
	screen.select_card_instance(&"player.action.001")
	_expect(screen.get_selected_card_id() == &"player.action.001", "card selection recorded")
	screen.select_target(&"enemy.left")
	screen.play_selected()
	_expect(screen.is_pending(), "command enters pending state")
	_expect(_captured_command != null and _captured_command.card_instance_id == &"player.action.001", "play command emitted")
	var result = BattleCommandResultScript.new(
		true,
		&"ok",
		[],
		_snapshot("enemy_action", 1, "player.insight.002")
	)
	screen.apply_command_result(result)
	_expect(not screen.is_pending(), "pending clears after command result")
	_expect(screen.get_event_count() >= 1, "event feed remains available")
	screen.configure(
		"廷根旧宅",
		{&"card.skill.ink_dart": "墨刺"},
		{&"enemy.weeping_tenant": "哭泣的房客"},
		func(_card_id: StringName, _target_id: StringName) -> BattlePlayability:
			return BattlePlayabilityScript.new(false, BattlePlayability.INVALID_TARGET)
	)
	_captured_command = null
	screen.select_card_instance(&"player.insight.002")
	screen.select_target(&"enemy.left")
	screen.play_selected()
	_expect(_captured_command == null, "invalid playability blocks command")
	_expect(screen.get_status_text().contains("目标无效"), "invalid target reason is displayed")
	screen.set_pending(true)
	var rejected = BattleCommandResultScript.new(
		false,
		&"insufficient_spirit",
		[],
		BattleSnapshotScript.new(screen.get_snapshot_data())
	)
	screen.apply_command_result(rejected)
	_expect(not screen.is_pending(), "rejected command clears pending")
	_expect(screen.get_status_text().contains("灵性不足"), "rejected reason is displayed")
	screen.cancel_selection()
	_expect(screen.get_selected_card_id() == &"", "cancel clears selection")
	screen.queue_free()
	await get_tree().process_frame


func _test_result_screen() -> void:
	var screen = ResultScreenScene.instantiate()
	add_child(screen)
	await get_tree().process_frame
	var snapshot = _snapshot("battle_ended", 0, "player.insight.002")
	snapshot.data["outcome"] = "victory"
	snapshot.data["outcome_reason"] = "enemies_defeated"
	screen.show_result(snapshot, "廷根旧宅", "saved")
	_expect(screen.get_result_text() == "胜利", "result screen displays victory")
	_expect(screen.get_save_text().contains("已保存"), "result screen displays save confirmation")
	_expect(screen.is_return_enabled(), "result screen enables return")
	snapshot.data["outcome"] = "defeat"
	snapshot.data["outcome_reason"] = "player_died"
	screen.show_result(snapshot, "廷根旧宅", "saved")
	_expect(screen.get_result_text() == "失败", "result screen displays defeat")
	_expect(
		screen.get_retry_text() == "返回白昼档案",
		"defeat navigation matches the actual hub destination"
	)
	screen.queue_free()
	await get_tree().process_frame


func _snapshot(phase: String, revision: int, first_card_instance_id: String) -> BattleSnapshot:
	return BattleSnapshotScript.new({
		"revision": revision,
		"battle_id": "encounter.test.1",
		"phase": phase,
		"round_number": 5,
		"max_rounds": 10,
		"enemy_pressure_bonus": 1,
		"player": {
			"actor_id": "player",
			"hp": 48,
			"max_hp": 54,
			"block": 0,
			"spirit": 3,
			"max_spirit": 3,
			"corruption": 1,
			"max_corruption": 10,
			"attention": 2,
			"max_attention": 10,
			"statuses": [],
		},
		"hand": [
			{
				"instance_id": first_card_instance_id,
				"definition_id": "card.skill.ink_dart",
				"category": "skill",
				"cost_spirit": 1,
				"target_type": "enemy",
			},
			{
				"instance_id": "player.focus.001",
				"definition_id": "card.skill.focus",
				"category": "skill",
				"cost_spirit": 0,
				"target_type": "self",
			},
		],
		"draw_pile_count": 4,
		"discard_pile_count": 1,
		"enemies": [
			{
				"actor_id": "enemy.left",
				"definition_id": "enemy.weeping_tenant",
				"lane_index": 0,
				"hp": 12,
				"max_hp": 16,
				"block": 0,
				"statuses": [],
				"intent": {
					"intent_id": "attack",
					"revealed": true,
					"visible_fields": {"damage": 7},
				},
			},
		],
		"outcome": "",
		"outcome_reason": "",
	})


func _on_command_requested(command: BattleCommand) -> void:
	_captured_command = command


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("UI_SMOKE_OK checks=%d" % _checks)
		get_tree().quit(0)
		return
	for failure in _failures:
		printerr("UI_SMOKE_FAIL %s" % failure)
	print("UI_SMOKE_FAIL checks=%d failures=%d" % [_checks, _failures.size()])
	get_tree().quit(1)
