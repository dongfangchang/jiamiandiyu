extends Node

const BattleScreenScene := preload("res://scenes/ui/battle_screen.tscn")
const BattleSnapshotScript := preload("res://src/core/battle_snapshot.gd")

const VIEWPORTS: Array[Vector2i] = [Vector2i(1600, 900), Vector2i(1100, 700)]

var _checks := 0
var _failures: Array[String] = []


func _ready() -> void:
	for viewport_size in VIEWPORTS:
		await _test_viewport(viewport_size)
	if _failures.is_empty():
		print("V025_VIEWPORT_GUIDANCE_OK checks=%d" % _checks)
		get_tree().quit(0)
		return
	for failure in _failures:
		printerr("V025_VIEWPORT_GUIDANCE_FAIL %s" % failure)
	get_tree().quit(1)


func _test_viewport(viewport_size: Vector2i) -> void:
	var viewport := SubViewport.new()
	viewport.size = viewport_size
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(viewport)
	var screen = BattleScreenScene.instantiate()
	viewport.add_child(screen)
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen.configure("窄视口提示测试", {}, {&"enemy.weeping_tenant": "哭泣的房客"}, Callable())
	screen.apply_snapshot(_snapshot())
	await get_tree().process_frame
	await get_tree().process_frame
	var page_scroll: ScrollContainer = screen.get("_screen_scroll")
	var vertical_bar := page_scroll.get_v_scroll_bar()
	var hint: String = screen.get_scroll_hint_text()
	if viewport_size == Vector2i(1600, 900):
		_expect(vertical_bar.max_value <= vertical_bar.page + 1.0, "standard viewport has no page overflow")
		_expect(hint.is_empty(), "standard viewport hides scroll guidance")
	else:
		_expect(vertical_bar.max_value > vertical_bar.page + 1.0, "small viewport exposes page overflow")
		_expect(hint.contains("滑动"), "small viewport explains how to reveal actions")
	viewport.queue_free()
	await get_tree().process_frame


func _snapshot() -> BattleSnapshot:
	var hand: Array = []
	for index in range(8):
		hand.append({
			"instance_id": "viewport.card.%02d" % index,
			"definition_id": "card.skill.ink_dart",
			"category": "skill",
			"cost_spirit": index % 3,
			"target_type": "enemy" if index % 2 == 0 else "self",
		})
	return BattleSnapshotScript.new({
		"revision": 1,
		"battle_id": "battle.viewport_guidance",
		"phase": "player_action",
		"round_number": 1,
		"max_rounds": 10,
		"enemy_pressure_bonus": 0,
		"chain": {"count": 0, "threshold": 3, "damage": 1, "draw": 1, "spirit": 1},
		"player": {"actor_id": "player", "hp": 20, "max_hp": 20, "block": 0, "spirit": 3, "max_spirit": 3, "corruption": 0, "max_corruption": 10, "attention": 0, "max_attention": 10},
		"enemies": [{"actor_id": "enemy.01", "definition_id": "enemy.weeping_tenant", "lane_index": 0, "hp": 12, "max_hp": 12, "block": 0, "statuses": [], "intent": {"revealed": true, "visible_fields": {"damage": 4}}}],
		"hand": hand,
		"draw_pile_count": 8,
		"discard_pile_count": 0,
		"outcome": "",
	})


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(message)
