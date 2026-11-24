extends Node

const UiContentFixture := preload("res://tests/ui/ui_content_fixture.gd")

## v0.52: 7th hand card stays inside HandPanel; HP meters not clipped;
## SceneDim is a bottom-clearing gradient veil.

const BattleScreenScript := preload("res://src/ui/battle_screen.gd")
const BattleSnapshotScript := preload("res://src/core/battle_snapshot.gd")
const BattlePlayabilityScript := preload("res://src/core/battle_playability.gd")
const UiTheme := preload("res://src/ui/mask_ui_theme.gd")
const SceneCatalog := preload("res://src/ui/scene_ui_catalog.gd")
const RouteCatalog := preload("res://src/ui/route_ui_catalog.gd")

var _checks := 0
var _failures: Array[String] = []


func _ready() -> void:
	UiContentFixture.ensure()
	_expect(SceneCatalog.dim_for("battle") <= 0.30, "battle dim modest")
	_expect(RouteCatalog.ROUTE_BACKGROUND_DIM <= 0.40, "route dim modest")
	_expect(UiTheme.SAFE_BOTTOM_REVEAL >= 96, "bottom reveal margin reserved")

	var host := Control.new()
	host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	host.custom_minimum_size = Vector2(1600, 900)
	host.size = Vector2(1600, 900)
	add_child(host)
	UiTheme.add_background(host, RouteCatalog.route_background(), UiTheme.C_BG, 0.22)
	await get_tree().process_frame
	var dim := host.get_node_or_null("SceneDim")
	_expect(dim is TextureRect, "SceneDim is gradient texture")
	var bg := host.find_child("SceneBackground", true, false) as TextureRect
	_expect(bg != null, "SceneBackground exists")
	var holder := host.get_node_or_null("SceneBackgroundHolder") as Control
	_expect(holder != null, "SceneBackgroundHolder exists")

	var viewport := SubViewport.new()
	viewport.size = Vector2i(1600, 900)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(viewport)
	var screen = BattleScreenScript.new()
	viewport.add_child(screen)
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen.configure(
		"画框血条背景探针",
		{"card.skill.ink_dart": "墨刺"},
		{"enemy.candle_moth": "密修会成员"},
		func(_a: StringName, _b: StringName, _discard_ids: Array) -> BattlePlayability:
			return BattlePlayabilityScript.new(true, BattlePlayability.PLAYABLE),
		{}
	)
	var hand: Array = []
	for i in range(8):
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
			"corruption": 2, "max_corruption": 10, "attention": 1, "max_attention": 10,
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

	var header := screen.find_child("BattleHeader", true, false) as Control
	_expect(header != null and header.size.y >= 56.0, "header tall enough for meters")
	var health := screen.get("_health_meter") as Control
	_expect(health != null, "health meter exists")
	if health != null and header != null:
		var meter_rect := health.get_global_rect()
		var header_rect := header.get_global_rect()
		_expect(
			meter_rect.end.y <= header_rect.end.y + 0.5,
			"health meter bottom inside header"
		)
		var bar := health.find_child("MeterBar", true, false) as Control
		_expect(bar != null and bar.get_global_rect().size.y >= 8.0, "hp bar visible height")
		if bar != null:
			_expect(
				bar.get_global_rect().end.y <= header_rect.end.y + 0.5,
				"hp ProgressBar not clipped by header"
			)

	var hand_panel := screen.find_child("HandPanel", true, false) as Control
	var hand_scroll := screen.find_child("HandScroll", true, false) as Control
	var row: HBoxContainer = screen.get("_hand_row")
	_expect(hand_panel != null and hand_panel.clip_contents, "HandPanel clips to frame")
	_expect(hand_scroll != null and hand_scroll.clip_contents, "HandScroll clips overflow")
	_expect(row != null and row.get_child_count() >= 7, "at least 7 hand cards")
	if hand_panel != null and row != null and row.get_child_count() >= 7:
		var seventh := row.get_child(6) as Control
		var panel_rect := hand_panel.get_global_rect()
		## Without scroll, card 7 may start past the right edge — that is OK
		## only if clipping is on. Visible painted overflow must not escape.
		_expect(hand_panel.clip_contents, "seventh card cannot paint past frame")
		if seventh != null:
			var card_rect := seventh.get_global_rect()
			## If the card is still fully left of the panel right edge, good;
			## otherwise horizontal scroll must be available.
			if card_rect.end.x > panel_rect.end.x + 1.0:
				var scroll := hand_scroll as ScrollContainer
				_expect(
					scroll != null
					and scroll.get_h_scroll_bar().max_value
						> scroll.get_h_scroll_bar().page + 1.0,
					"overflow cards reachable by horizontal scroll"
				)

	var enemy_hp := screen.find_child("EnemyHpLabel", true, false) as Control
	_expect(enemy_hp != null, "enemy hp label present")
	if enemy_hp != null:
		var lane := enemy_hp.get_parent()
		while lane != null and not (lane is PanelContainer):
			lane = lane.get_parent()
		if lane is Control:
			var lane_rect := (lane as Control).get_global_rect()
			_expect(
				enemy_hp.get_global_rect().end.y <= lane_rect.end.y + 0.5,
				"enemy hp inside lane clip"
			)

	var btn := screen.find_child("SelectButton", true, false) as Control
	if btn != null:
		_expect(btn.get_global_rect().end.y <= 900.5, "select button above fold")

	if _failures.is_empty():
		print("V052_FRAME_HP_BG_OK checks=%d" % _checks)
	else:
		print("V052_FRAME_HP_BG_FAIL checks=%d failures=%s" % [_checks, str(_failures)])
		for item in _failures:
			push_error(item)
	get_tree().quit(0 if _failures.is_empty() else 1)


func _expect(condition: bool, label: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(label)
