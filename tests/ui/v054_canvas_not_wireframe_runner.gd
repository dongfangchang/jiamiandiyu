extends Node

## v0.54: scene PNG is the canvas; chrome modules stay translucent (not wireframe slabs).

const UiTheme := preload("res://src/ui/mask_ui_theme.gd")
const RouteCatalog := preload("res://src/ui/route_ui_catalog.gd")
const BattleScreenScript := preload("res://src/ui/battle_screen.gd")
const BattleSnapshotScript := preload("res://src/core/battle_snapshot.gd")
const BattlePlayabilityScript := preload("res://src/core/battle_playability.gd")

var _checks := 0
var _failures: Array[String] = []


func _ready() -> void:
	## Readable modules (not ghost-through); canvas shows in gutters/floor only.
	_expect(UiTheme.MODULE_ALPHA >= 0.88, "module alpha readable")
	_expect(UiTheme.C_MODULE.a >= 0.88, "C_MODULE not ghost-transparent")
	_expect(UiTheme.SAFE_BOTTOM_REVEAL >= 96, "canvas floor strip kept")

	var host := Control.new()
	host.size = Vector2(1600, 900)
	host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(host)
	UiTheme.add_background(host, RouteCatalog.ROUTE_BACKGROUND, UiTheme.C_BG, 0.22)
	await get_tree().process_frame
	_expect(host.get_node_or_null("SceneBackgroundHolder") != null, "canvas holder present")
	_expect(host.find_child("SceneBackground", true, false) != null, "scene texture present")

	var viewport := SubViewport.new()
	viewport.size = Vector2i(1600, 900)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(viewport)
	var battle = BattleScreenScript.new()
	viewport.add_child(battle)
	battle.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	battle.configure(
		"画布模块探针",
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

	for panel_name in ["BattlefieldPanel", "SidePanel", "HandPanel"]:
		var panel := battle.find_child(panel_name, true, false) as PanelContainer
		_expect(panel != null, "%s exists" % panel_name)
		if panel != null:
			var style := panel.get_theme_stylebox("panel") as StyleBoxFlat
			_expect(
				style != null and style.bg_color.a >= 0.85 and style.bg_color.a < 1.0,
				"%s readable module (not solid wireframe slab)" % panel_name
			)

	var hand := battle.find_child("HandPanel", true, false) as Control
	if hand != null:
		_expect(
			hand.get_global_rect().end.y <= 900.0 - float(UiTheme.SAFE_BOTTOM_REVEAL) + 1.0,
			"hand above bare canvas floor"
		)

	if _failures.is_empty():
		print("V054_CANVAS_NOT_WIREFRAME_OK checks=%d" % _checks)
	else:
		print("V054_CANVAS_NOT_WIREFRAME_FAIL checks=%d failures=%s" % [_checks, str(_failures)])
		for item in _failures:
			push_error(item)
	get_tree().quit(0 if _failures.is_empty() else 1)


func _expect(condition: bool, label: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(label)
