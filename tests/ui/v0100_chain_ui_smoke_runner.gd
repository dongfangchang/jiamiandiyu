extends Node

const BattleScreenScene := preload("res://scenes/ui/battle_screen.tscn")
const BattleSnapshotScript := preload("res://src/core/battle_snapshot.gd")
const BattleCommandResultScript := preload("res://src/core/battle_command_result.gd")
const BattleEventScript := preload("res://src/core/battle_event.gd")
const BattlePlayabilityScript := preload("res://src/core/battle_playability.gd")

var _passed := 0
var _failures: Array[String] = []


func _ready() -> void:
	await _test_chain_progress_and_burst()
	await _test_missing_chain_field_is_safe()
	if _failures.is_empty():
		print("V0100_CHAIN_UI_OK checks=%d" % _passed)
		get_tree().quit(0)
		return
	for failure in _failures:
		printerr("V0100_CHAIN_UI_FAIL: %s" % failure)
	get_tree().quit(1)


func _test_chain_progress_and_burst() -> void:
	var screen = BattleScreenScene.instantiate()
	add_child(screen)
	screen.configure(
		"连携测试",
		{"card.skill.ink_dart": "墨刺"},
		{"enemy.weeping_tenant": "哭泣的房客"},
		func(_card_id: StringName, _target_id: StringName) -> BattlePlayability:
			return BattlePlayabilityScript.new(
				true,
				BattlePlayability.PLAYABLE
			),
		{
			"card.skill.ink_dart": {
				"name": "墨刺",
				"description": "测试。",
				"effect_text": "造成 4 伤害",
				"level": 1,
			},
		}
	)
	screen.apply_snapshot(_snapshot(2, 3))
	_expect(
		screen.get_chain_text() == "连携 2 / 3",
		"battle UI should show the incoming chain state"
	)
	var result := BattleCommandResultScript.new(
		true,
		&"ok",
		[BattleEventScript.new(&"ChainTriggered", {
			"count": 3,
			"damage": 1,
			"draw": 1,
			"spirit": 1,
		})],
		_snapshot(0, 3)
	)
	screen.apply_command_result(result)
	_expect(
		int(screen.get_visual_effect_count()) > 0,
		"chain trigger should produce visible feedback"
	)
	_expect(
		screen.get_chain_text() == "连携 0 / 3",
		"battle UI should reset chain after the burst"
	)
	screen.queue_free()
	await get_tree().process_frame


func _test_missing_chain_field_is_safe() -> void:
	var screen = BattleScreenScene.instantiate()
	add_child(screen)
	screen.configure(
		"旧快照",
		{"card.skill.ink_dart": "墨刺"},
		{"enemy.weeping_tenant": "哭泣的房客"},
		func(_card_id: StringName, _target_id: StringName) -> BattlePlayability:
			return BattlePlayabilityScript.new(
				true,
				BattlePlayability.PLAYABLE
			),
		{}
	)
	screen.apply_snapshot(_snapshot_without_chain())
	var chain_label: Label = screen.get("_chain_label")
	_expect(
		chain_label != null and not chain_label.visible,
		"snapshots without chain data should hide the chain badge"
	)
	screen.queue_free()
	await get_tree().process_frame


func _snapshot(chain_count: int, threshold: int) -> BattleSnapshot:
	return BattleSnapshotScript.new({
		"revision": 3 if chain_count == 0 else 2,
		"battle_id": "battle.v0100.ui",
		"phase": "player_action",
		"round_number": 2,
		"max_rounds": 10,
		"enemy_pressure_bonus": 0,
		"chain": {
			"count": chain_count,
			"threshold": threshold,
			"damage": 1,
			"draw": 1,
			"spirit": 1,
		},
		"player": _player(),
		"hand": [_hand_card()],
		"draw_pile_count": 4,
		"discard_pile_count": 1,
		"enemies": [_enemy()],
		"outcome": "",
		"outcome_reason": "",
	})


func _snapshot_without_chain() -> BattleSnapshot:
	return BattleSnapshotScript.new({
		"revision": 1,
		"battle_id": "battle.v0100.legacy",
		"phase": "player_action",
		"round_number": 1,
		"max_rounds": 10,
		"enemy_pressure_bonus": 0,
		"player": _player(),
		"hand": [_hand_card()],
		"draw_pile_count": 4,
		"discard_pile_count": 0,
		"enemies": [_enemy()],
		"outcome": "",
		"outcome_reason": "",
	})


func _player() -> Dictionary:
	return {
		"actor_id": "player",
		"hp": 10,
		"max_hp": 10,
		"block": 0,
		"spirit": 2,
		"max_spirit": 3,
		"corruption": 0,
		"max_corruption": 10,
		"attention": 0,
		"max_attention": 10,
		"statuses": [],
	}


func _hand_card() -> Dictionary:
	return {
		"instance_id": "test.card.001",
		"definition_id": "card.skill.ink_dart",
		"category": "skill",
		"cost_spirit": 1,
		"target_type": "enemy",
	}


func _enemy() -> Dictionary:
	return {
		"actor_id": "enemy.test",
		"definition_id": "enemy.weeping_tenant",
		"lane_index": 0,
		"hp": 10,
		"max_hp": 10,
		"block": 0,
		"statuses": [],
		"intent": {
			"revealed": true,
			"visible_fields": {"damage": 2},
		},
	}


func _expect(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
	else:
		_failures.append(message)
