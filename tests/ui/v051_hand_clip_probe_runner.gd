extends Node

const BattleScreenScript := preload("res://src/ui/battle_screen.gd")
const BattleSnapshotScript := preload("res://src/core/battle_snapshot.gd")
const BattlePlayabilityScript := preload("res://src/core/battle_playability.gd")

var _checks := 0
var _failures: Array[String] = []


func _ready() -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1600, 900)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(viewport)
	var screen = BattleScreenScript.new()
	viewport.add_child(screen)
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen.configure(
		"手牌截断探针",
		{"card.skill.ink_dart": "墨刺"},
		{"enemy.candle_moth": "密修会成员"},
		func(_a: StringName, _b: StringName) -> BattlePlayability:
			return BattlePlayabilityScript.new(true, BattlePlayability.PLAYABLE),
		{}
	)
	var hand: Array = []
	for i in range(5):
		hand.append({
			"instance_id": "probe.%d" % i,
			"definition_id": "card.skill.ink_dart",
			"category": "skill",
			"cost_spirit": 1,
			"target_type": "enemy",
		})
	screen.apply_snapshot(BattleSnapshotScript.new({
		"revision": 1,
		"battle_id": "battle.probe",
		"phase": "player_action",
		"round_number": 1,
		"max_rounds": 10,
		"player": {
			"hp": 40, "max_hp": 54, "block": 0, "spirit": 3, "max_spirit": 3,
			"corruption": 0, "max_corruption": 10, "attention": 0, "max_attention": 10,
			"statuses": [],
		},
		"enemies": [{
			"actor_id": "e1", "definition_id": "enemy.candle_moth",
			"display_name_zh": "密修会成员", "hp": 10, "max_hp": 10, "block": 0,
			"lane_index": 0, "intent": {}, "statuses": [], "traits": [],
		}],
		"hand": hand,
		"draw_pile_count": 10,
		"discard_pile_count": 0,
		"chain": {},
		"events": [],
	}))
	await get_tree().process_frame
	await get_tree().process_frame

	var page_scroll: ScrollContainer = screen.get("_screen_scroll")
	var content: Control = screen.get("_content_root")
	var hand_panel := screen.find_child("HandPanel", true, false) as Control
	var hand_scroll := screen.find_child("HandScroll", true, false) as Control
	var row: HBoxContainer = screen.get("_hand_row")
	print(
		"PROBE screen=%s content_size=%s content_min=%s scroll_max=%s page=%s"
		% [
			screen.size,
			content.size if content else Vector2.ZERO,
			content.custom_minimum_size if content else Vector2.ZERO,
			page_scroll.get_v_scroll_bar().max_value if page_scroll else -1,
			page_scroll.get_v_scroll_bar().page if page_scroll else -1,
		]
	)
	var header := screen.find_child("BattleHeader", true, false) as Control
	var status := screen.find_child("BattleStatusStrip", true, false) as Control
	if status == null:
		status = screen.find_child("StatusStrip", true, false) as Control
	var middle := screen.find_child("BattleMiddle", true, false) as Control
	print(
		"PROBE mins header=%s status=%s middle=%s hand=%s content_combined=%s"
		% [
			header.get_combined_minimum_size() if header else Vector2.ZERO,
			status.get_combined_minimum_size() if status else Vector2.ZERO,
			middle.get_combined_minimum_size() if middle else Vector2.ZERO,
			hand_panel.get_combined_minimum_size() if hand_panel else Vector2.ZERO,
			content.get_combined_minimum_size() if content else Vector2.ZERO,
		]
	)
	print(
		"PROBE hand_panel_size=%s hand_panel_global=%s hand_scroll=%s hand_scroll_global=%s"
		% [
			hand_panel.size if hand_panel else Vector2.ZERO,
			hand_panel.get_global_rect() if hand_panel else Rect2(),
			hand_scroll.size if hand_scroll else Vector2.ZERO,
			hand_scroll.get_global_rect() if hand_scroll else Rect2(),
		]
	)
	if row != null and row.get_child_count() > 0:
		var card := row.get_child(0) as Control
		var btn := card.find_child("SelectButton", true, false) as Control
		print(
			"PROBE card=%s card_global=%s btn=%s btn_global=%s"
			% [
				card.size,
				card.get_global_rect(),
				btn.size if btn else Vector2.ZERO,
				btn.get_global_rect() if btn else Rect2(),
			]
		)
		print(
			"PROBE btn_end_y=%.1f viewport=900 card_clips=%s"
			% [
				btn.get_global_rect().end.y if btn else -1.0,
				card.clip_contents,
			]
		)
		_expect(btn != null, "select button exists")
		if btn != null:
			_expect(btn.get_global_rect().end.y <= 901.0, "select button inside 1600x900")
			_expect(
				hand_scroll.get_global_rect().end.y + 0.5 >= card.get_global_rect().end.y,
				"card bottom inside HandScroll"
			)
			_expect(
				card.get_global_rect().size.y + 0.5 >= btn.get_global_rect().size.y,
				"button not larger than card"
			)
			# Button must not be clipped away inside the card panel.
			_expect(
				card.get_global_rect().end.y + 0.5 >= btn.get_global_rect().end.y,
				"button bottom inside card panel"
			)

	viewport.queue_free()
	_finish()


func _finish() -> void:
	if _failures.is_empty():
		print("V051_HAND_CLIP_PROBE_OK checks=%d" % _checks)
		get_tree().quit(0)
		return
	for failure in _failures:
		printerr("V051_HAND_CLIP_PROBE_FAIL %s" % failure)
	get_tree().quit(1)


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(message)
