extends Node

const BattleScreenScene := preload("res://scenes/ui/battle_screen.tscn")
const BattleSnapshotScript := preload("res://src/core/battle_snapshot.gd")
const BattlePlayabilityScript := preload("res://src/core/battle_playability.gd")
const AppControllerScript := preload("res://src/app/app_controller.gd")

var _passed := 0
var _failures: Array[String] = []


func _ready() -> void:
	await _test_status_badge()
	_test_mark_explanation()
	if _failures.is_empty():
		print("V011_STATUS_KEYWORD_OK checks=%d" % _passed)
		get_tree().quit(0)
		return
	for failure in _failures:
		printerr("V011_STATUS_KEYWORD_FAIL: %s" % failure)
	get_tree().quit(1)


func _test_status_badge() -> void:
	var host := Control.new()
	host.custom_minimum_size = Vector2(1600, 900)
	host.size = Vector2(1600, 900)
	add_child(host)
	var screen = BattleScreenScene.instantiate()
	host.add_child(screen)
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await get_tree().process_frame
	screen.configure(
		"标记说明",
		{"card.skill.ink_dart": "墨刺"},
		{"enemy.weeping_tenant": "哭泣的房客"},
		func(_card_id: StringName, _target_id: StringName) -> BattlePlayability:
			return BattlePlayabilityScript.new(
				true,
				BattlePlayability.PLAYABLE
			),
		{}
	)
	screen.apply_snapshot(BattleSnapshotScript.new({
		"revision": 1,
		"battle_id": "battle.status",
		"phase": "player_action",
		"round_number": 1,
		"max_rounds": 10,
		"enemy_pressure_bonus": 0,
		"player": {
			"actor_id": "player",
			"hp": 10,
			"max_hp": 10,
			"block": 0,
			"spirit": 3,
			"max_spirit": 3,
			"corruption": 0,
			"max_corruption": 10,
			"attention": 0,
			"max_attention": 10,
			"statuses": [],
		},
		"hand": [{
			"instance_id": "test.ink.001",
			"definition_id": "card.skill.ink_dart",
			"category": "skill",
			"cost_spirit": 1,
			"target_type": "enemy",
		}],
		"draw_pile_count": 0,
		"discard_pile_count": 0,
		"enemies": [{
			"actor_id": "enemy.test",
			"definition_id": "enemy.weeping_tenant",
			"lane_index": 0,
			"hp": 10,
			"max_hp": 10,
			"block": 0,
			"statuses": [{
				"status_id": "mark",
				"stacks": 2,
				"duration": 2,
			}],
			"intent": {
				"revealed": true,
				"visible_fields": {"damage": 2},
			},
		}],
		"outcome": "",
		"outcome_reason": "",
	}))
	_expect(
		_contains_label_text(screen, "标记 2"),
		"enemy lane should display mark stacks"
	)
	var selection_events: Array[StringName] = []
	screen.selection_changed.connect(func(
		card_instance_id: StringName,
		_target_id: StringName
	) -> void:
		selection_events.append(card_instance_id)
	)
	var card_panel := _find_meta(screen, "battle_instance_id")
	_expect(card_panel != null, "hand card should expose a clickable panel")
	if card_panel != null:
		_expect(
			not String(card_panel.tooltip_text).contains("实例 ID"),
			"hand card must not expose internal instance IDs in tooltip"
		)
		var click := InputEventMouseButton.new()
		click.button_index = MOUSE_BUTTON_LEFT
		click.pressed = true
		card_panel.gui_input.emit(click)
	_expect(
		selection_events == [&"test.ink.001"],
		"clicking anywhere on the card should select the hand card once"
	)
	var commands: Array[BattleCommand] = []
	screen.command_requested.connect(func(command: BattleCommand) -> void:
		commands.append(command)
	)
	var target_button := _find_button_name(screen, "TargetButton")
	_expect(
		target_button != null and not target_button.disabled,
		"whole-card selection should enable valid enemy targets"
	)
	if target_button != null:
		target_button.pressed.emit()
	screen.play_selected()
	_expect(
		commands.size() == 1
		and commands[0].card_instance_id == &"test.ink.001"
		and commands[0].target_id == &"enemy.test",
		"whole-card selection should allow playing after choosing a target"
	)
	var select_button := _find_button_text(screen, "已选择")
	var relative_bottom: float = (
		select_button.get_global_rect().end.y
		- screen.get_global_rect().position.y
	) if select_button != null else INF
	_expect(
		select_button != null
		and relative_bottom <= screen.size.y,
		"hand selection button must remain inside the 1600x900 viewport"
	)
	screen.queue_free()
	host.queue_free()
	await get_tree().process_frame


func _test_mark_explanation() -> void:
	var controller = AppControllerScript.new()
	var text := String(controller.call("_format_card_effects", {
		"effects": [{
			"effect_id": "apply_status",
			"status_id": "mark",
			"stacks": 2,
		}],
	}))
	_expect(
		text.contains("附加等量伤害"),
		"card details should explain what mark does"
	)
	controller.free()


func _contains_label_text(root: Node, needle: String) -> bool:
	if root is Label and (root as Label).text.contains(needle):
		return true
	for child in root.get_children():
		if _contains_label_text(child, needle):
			return true
	return false


func _find_meta(root: Node, key: String) -> Control:
	if root is Control and root.has_meta(key):
		return root as Control
	for child in root.get_children():
		var found := _find_meta(child, key)
		if found != null:
			return found
	return null


func _find_button_text(root: Node, text_value: String) -> Button:
	if root is Button and (root as Button).text == text_value:
		return root as Button
	for child in root.get_children():
		var found := _find_button_text(child, text_value)
		if found != null:
			return found
	return null


func _find_button_name(root: Node, node_name: String) -> Button:
	if root is Button and root.name == node_name:
		return root as Button
	for child in root.get_children():
		var found := _find_button_name(child, node_name)
		if found != null:
			return found
	return null


func _expect(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
	else:
		_failures.append(message)
