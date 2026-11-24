extends Node

const UiContentFixture := preload("res://tests/ui/ui_content_fixture.gd")

## v0.53: scene canvas floor band is bare — no UI chrome over y≈800–900;
## background covers the viewport and pins texture bottom to canvas bottom.

const BattleScreenScript := preload("res://src/ui/battle_screen.gd")
const BattleSnapshotScript := preload("res://src/core/battle_snapshot.gd")
const BattlePlayabilityScript := preload("res://src/core/battle_playability.gd")
const UiTheme := preload("res://src/ui/mask_ui_theme.gd")
const RouteCatalog := preload("res://src/ui/route_ui_catalog.gd")

var _checks := 0
var _failures: Array[String] = []


func _ready() -> void:
	UiContentFixture.ensure()
	_expect(UiTheme.SAFE_BOTTOM_REVEAL >= 96, "canvas floor strip ≥96px")

	var host := Control.new()
	host.custom_minimum_size = Vector2(1600, 900)
	host.size = Vector2(1600, 900)
	host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(host)
	UiTheme.add_background(host, RouteCatalog.route_background(), UiTheme.C_BG, 0.22)
	await get_tree().process_frame
	await get_tree().process_frame

	var holder := host.get_node_or_null("SceneBackgroundHolder") as Control
	var bg := host.find_child("SceneBackground", true, false) as TextureRect
	_expect(holder != null and holder.clip_contents, "background holder clips cover")
	_expect(bg != null, "SceneBackground exists")
	if holder != null and bg != null and bg.texture != null:
		UiTheme.layout_scene_background(holder, bg)
		await get_tree().process_frame
		_expect(
			absf(bg.get_rect().end.y - holder.size.y) <= 1.0,
			"background texture bottom pinned to canvas bottom"
		)
		_expect(
			bg.size.x + 0.5 >= holder.size.x and bg.size.y + 0.5 >= holder.size.y,
			"background covers full canvas (no letterbox)"
		)

	var dim := host.get_node_or_null("SceneDim") as TextureRect
	_expect(dim != null, "SceneDim gradient present")

	var viewport := SubViewport.new()
	viewport.size = Vector2i(1600, 900)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(viewport)
	var battle = BattleScreenScript.new()
	viewport.add_child(battle)
	battle.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	battle.configure(
		"画布底部探针",
		{"card.skill.ink_dart": "墨刺"},
		{"enemy.candle_moth": "密修会成员"},
		func(_a: StringName, _b: StringName, _discard_ids: Array) -> BattlePlayability:
			return BattlePlayabilityScript.new(true, BattlePlayability.PLAYABLE),
		{}
	)
	battle.apply_snapshot(BattleSnapshotScript.new({
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
		"hand": [{
			"instance_id": "probe.0",
			"definition_id": "card.skill.ink_dart",
			"category": "skill",
			"cost_spirit": 1,
			"target_type": "enemy",
		}],
		"draw_pile_count": 10,
		"discard_pile_count": 0,
		"chain": {},
		"events": [],
	}))
	await get_tree().process_frame
	await get_tree().process_frame

	var hand_panel := battle.find_child("HandPanel", true, false) as Control
	_expect(hand_panel != null, "hand panel exists")
	if hand_panel != null:
		var floor_y := 900.0 - float(UiTheme.SAFE_BOTTOM_REVEAL)
		_expect(
			hand_panel.get_global_rect().end.y <= floor_y + 1.0,
			"hand chrome ends above bare canvas floor"
		)
		_expect(
			hand_panel.get_global_rect().end.y < 900.0,
			"hand does not cover viewport bottom edge"
		)

	if _failures.is_empty():
		print("V053_CANVAS_FLOOR_OK checks=%d" % _checks)
	else:
		print("V053_CANVAS_FLOOR_FAIL checks=%d failures=%s" % [_checks, str(_failures)])
		for item in _failures:
			push_error(item)
	get_tree().quit(0 if _failures.is_empty() else 1)


func _expect(condition: bool, label: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(label)
