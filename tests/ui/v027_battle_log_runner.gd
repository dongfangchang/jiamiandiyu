extends Node

const BattleScreenScene := preload("res://scenes/ui/battle_screen.tscn")
const BattleSnapshotScript := preload("res://src/core/battle_snapshot.gd")

var _checks := 0
var _failures: Array[String] = []


func _ready() -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1600, 900)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(viewport)
	var screen = BattleScreenScene.instantiate()
	viewport.add_child(screen)
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen.configure(
		"战斗记录滚动测试",
		{"card.skill.ink_dart": "墨刺"},
		{"enemy.weeping_tenant": "哭泣的房客"},
		Callable()
	)
	screen.apply_snapshot(_snapshot())
	await get_tree().process_frame
	await get_tree().process_frame

	var log_scroll: ScrollContainer = screen.get("_event_scroll")
	_expect(log_scroll != null, "battle log should use a dedicated scroll container")
	if log_scroll != null:
		_expect(
			log_scroll.vertical_scroll_mode == ScrollContainer.SCROLL_MODE_AUTO,
			"battle log should scroll vertically"
		)
		_expect(
			log_scroll.horizontal_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED,
			"battle log should never scroll horizontally"
		)

	for index in range(14):
		screen.call("_append_event", "测试记录 %02d：灵界回声" % index)
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	_expect(screen.get_event_count() == 10, "battle log keeps a bounded sliding window")
	if log_scroll != null:
		var bar := log_scroll.get_v_scroll_bar()
		_expect(
			log_scroll.scroll_vertical >= int(bar.max_value - bar.page) - 1,
			"battle log follows the newest event (scroll=%d max=%d page=%d)" % [
				log_scroll.scroll_vertical,
				int(bar.max_value),
				int(bar.page),
			]
		)

	var hand_row: HBoxContainer = screen.get("_hand_row")
	_expect(hand_row != null, "hand panel remains mounted beside the battle log")
	_expect(
		hand_row != null and hand_row.get_child_count() == 8,
		"battle log growth must not remove hand cards"
	)
	if _failures.is_empty():
		print("V027_BATTLE_LOG_OK checks=%d" % _checks)
		get_tree().quit(0)
		return
	for failure in _failures:
		printerr("V027_BATTLE_LOG_FAIL %s" % failure)
	get_tree().quit(1)


func _snapshot() -> BattleSnapshot:
	var hand: Array = []
	for index in range(8):
		hand.append({
			"instance_id": "log.card.%02d" % index,
			"definition_id": "card.skill.ink_dart",
			"category": "skill",
			"cost_spirit": 1,
			"target_type": "enemy",
		})
	return BattleSnapshotScript.new({
		"revision": 1,
		"battle_id": "battle.log",
		"phase": "player_action",
		"round_number": 1,
		"max_rounds": 10,
		"enemy_pressure_bonus": 0,
		"chain": {"count": 0, "threshold": 3, "damage": 1, "draw": 1, "spirit": 1},
		"player": {
			"actor_id": "player", "hp": 20, "max_hp": 20, "block": 0,
			"spirit": 3, "max_spirit": 3, "corruption": 0, "max_corruption": 10,
			"attention": 0, "max_attention": 10,
		},
		"enemies": [{
			"actor_id": "enemy.01", "definition_id": "enemy.weeping_tenant",
			"lane_index": 0, "hp": 12, "max_hp": 12, "block": 0, "statuses": [],
			"intent": {"revealed": true, "visible_fields": {"damage": 4}},
		}],
		"hand": hand,
		"draw_pile_count": 8,
		"discard_pile_count": 0,
		"outcome": "",
	})


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(message)
