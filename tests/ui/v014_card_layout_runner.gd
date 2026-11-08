extends Node

const BattleScreenScene := preload("res://scenes/ui/battle_screen.tscn")
const BattleSnapshotScript := preload("res://src/core/battle_snapshot.gd")
const BattlePlayabilityScript := preload("res://src/core/battle_playability.gd")

const TEST_SIZES: Array[Vector2i] = [
	Vector2i(1600, 900),
	Vector2i(1366, 768),
		Vector2i(1333, 750),
	Vector2i(1280, 720),
]

var _passed := 0
var _failures: Array[String] = []


func _ready() -> void:
	for viewport_size in TEST_SIZES:
		await _test_viewport(viewport_size)
	if _failures.is_empty():
		print("V014_CARD_LAYOUT_OK checks=%d" % _passed)
		get_tree().quit(0)
		return
	for failure in _failures:
		printerr("V014_CARD_LAYOUT_FAIL: %s" % failure)
	get_tree().quit(1)


func _test_viewport(viewport_size: Vector2i) -> void:
	var viewport := SubViewport.new()
	viewport.size = viewport_size
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(viewport)
	var screen = BattleScreenScene.instantiate()
	viewport.add_child(screen)
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen.configure(
		"裁切布局测试",
		_card_names(),
		{"enemy.weeping_tenant": "哭泣的房客"},
		func(_card_id: StringName, _target_id: StringName) -> BattlePlayability:
			return BattlePlayabilityScript.new(
				true,
				BattlePlayability.PLAYABLE
			),
		_card_details()
	)
	screen.apply_snapshot(_snapshot())
	await get_tree().process_frame
	await get_tree().process_frame

	var page_scroll: ScrollContainer = screen.get("_screen_scroll")
	_expect(page_scroll != null, "battle page should provide a scroll fallback")
	if page_scroll == null:
		viewport.queue_free()
		return
	var vertical_bar := page_scroll.get_v_scroll_bar()
	var horizontal_bar := page_scroll.get_h_scroll_bar()
	if viewport_size == TEST_SIZES[0]:
		_expect(
			vertical_bar.max_value <= vertical_bar.page + 1.0
			and horizontal_bar.max_value <= horizontal_bar.page + 1.0,
			"standard viewport should not need page scrolling"
		)
	else:
		_expect(
			vertical_bar.max_value > vertical_bar.page + 1.0,
			"small viewport should expose vertical scrolling"
		)
		page_scroll.scroll_vertical = int(vertical_bar.max_value)
		await get_tree().process_frame

	var hand_row: HBoxContainer = screen.get("_hand_row")
	_expect(
		hand_row != null and hand_row.get_child_count() == 8,
		"layout audit should render all eight cards"
	)
	if hand_row == null or hand_row.get_child_count() == 0:
		viewport.queue_free()
		return
	var first_button := _find_button_text(hand_row, "选择手牌")
	if first_button == null:
		first_button = _find_button_text(hand_row, "已选择")
	_expect(first_button != null, "hand card should expose a selection control")
	if first_button != null:
		var viewport_rect := Rect2(
			Vector2.ZERO,
			Vector2(viewport_size)
		)
		var button_rect := first_button.get_global_rect()
		_expect(
			viewport_rect.intersects(button_rect)
			and button_rect.end.y <= viewport_rect.end.y + 1.0,
			"hand selection control should be reachable at %s" % viewport_size
		)
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		_save_layout_capture(viewport, viewport_size)
	viewport.queue_free()
	await get_tree().process_frame


func _snapshot() -> BattleSnapshot:
	var hand: Array = []
	var ids := _card_names().keys()
	for index in range(8):
		hand.append({
			"instance_id": "layout.card.%02d" % index,
			"definition_id": String(ids[index]),
			"category": "skill",
			"cost_spirit": index % 3,
			"target_type": "enemy" if index % 2 == 0 else "self",
		})
	return BattleSnapshotScript.new({
		"revision": 1,
		"battle_id": "battle.layout",
		"phase": "player_action",
		"round_number": 1,
		"max_rounds": 10,
		"enemy_pressure_bonus": 0,
		"chain": {
			"count": 1,
			"threshold": 3,
			"damage": 1,
			"draw": 1,
			"spirit": 1,
		},
		"player": {
			"actor_id": "player",
			"hp": 20,
			"max_hp": 20,
			"block": 0,
			"spirit": 3,
			"max_spirit": 3,
			"corruption": 0,
			"max_corruption": 10,
			"attention": 0,
			"max_attention": 10,
			"statuses": [],
		},
		"hand": hand,
		"draw_pile_count": 4,
		"discard_pile_count": 2,
		"enemies": [{
			"actor_id": "enemy.layout",
			"definition_id": "enemy.weeping_tenant",
			"lane_index": 0,
			"hp": 12,
			"max_hp": 12,
			"block": 0,
			"statuses": [],
			"intent": {
				"revealed": true,
				"visible_fields": {"damage": 3},
			},
		}],
		"outcome": "",
		"outcome_reason": "",
	})


func _card_names() -> Dictionary:
	return {
		"card.skill.ink_dart": "墨刺",
		"card.skill.paper_guard": "纸符护持",
		"card.skill.calm_breath": "静息",
		"card.skill.focus": "凝神",
		"card.skill.insight": "洞察",
		"card.skill.omen": "凶兆",
		"card.skill.whisper": "低语",
		"card.skill.second_look": "再看一眼",
	}


func _card_details() -> Dictionary:
	var details := {}
	for definition_id in _card_names():
		details[definition_id] = {
			"name": _card_names()[definition_id],
			"description": "布局测试卡牌。",
			"effect_text": "造成 4 伤害；施加 2 层标记",
			"level": 1,
		}
	return details


func _find_button_text(root: Node, text_value: String) -> Button:
	if root is Button and (root as Button).text == text_value:
		return root as Button
	for child in root.get_children():
		var found := _find_button_text(child, text_value)
		if found != null:
			return found
	return null


func _save_layout_capture(
	viewport: SubViewport,
	viewport_size: Vector2i
) -> void:
	var image := viewport.get_texture().get_image()
	if image == null or image.is_empty():
		_expect(false, "layout capture should render at %s" % viewport_size)
		return
	var output_directory := ProjectSettings.globalize_path(
		"res://.tools/ui-captures"
	)
	DirAccess.make_dir_recursive_absolute(output_directory)
	var path := output_directory.path_join(
		"card_layout_%dx%d.png" % [viewport_size.x, viewport_size.y]
	)
	var error := image.save_png(path)
	_expect(error == OK, "layout capture should save at %s" % viewport_size)


func _expect(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
	else:
		_failures.append(message)
