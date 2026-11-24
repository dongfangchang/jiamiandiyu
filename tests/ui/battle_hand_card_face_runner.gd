extends Node

## BUG-0041 regression: battle hand cards (and the cast animation) use the
## shared card face; the art keeps the 512:390 window aspect and is never
## stretched; hand + end-turn stay reachable at 1600x900 and 1100x700
## (ADR-0030); unplayable cards are dimmed from the snapshot flag only.

const UiContentFixture := preload("res://tests/ui/ui_content_fixture.gd")
const CardFace := preload("res://src/ui/common/card_face.gd")
const BattleScreenScene := preload("res://scenes/ui/battle_screen.tscn")
const BattleSnapshotScript := preload("res://src/core/battle_snapshot.gd")
const BattlePlayabilityScript := preload("res://src/core/battle_playability.gd")
const BattleCommandResultScript := preload("res://src/core/battle_command_result.gd")
const BattleEventScript := preload("res://src/core/battle_event.gd")

const VIEWPORTS: Array[Vector2i] = [Vector2i(1600, 900), Vector2i(1100, 700)]
const ASPECT := 512.0 / 390.0
const ASPECT_TOLERANCE := 0.05
const HAND_IDS := [
	"card.skill.coffin_nail",
	"card.skill.paper_guard",
	"card.skill.warding_circle",
	"card.skill.ink_dart",
	"card.skill.omen",
	"card.skill.second_sight",
	"card.skill.lantern_step",
]
const BLOCKED_INDEX := 5

var _checks := 0
var _failures: Array[String] = []


func _ready() -> void:
	UiContentFixture.ensure()
	for viewport_size in VIEWPORTS:
		## As the real window lays it out (project stretch settings) ...
		await _check_viewport(viewport_size, _window_logical_size(viewport_size))
		## ... and raw, unscaled: everything must still be reachable by scrolling.
		await _check_viewport(viewport_size, viewport_size)
	if _failures.is_empty():
		print("BATTLE_HAND_CARD_FACE_OK checks=%d" % _checks)
		get_tree().quit(0)
		return
	for failure in _failures:
		printerr("BATTLE_HAND_CARD_FACE_FAIL %s" % failure)
	get_tree().quit(1)


func _window_logical_size(window_size: Vector2i) -> Vector2i:
	## canvas_items + keep aspect: the UI is laid out at the base size and
	## scaled uniformly into the window.
	var mode := String(ProjectSettings.get_setting("display/window/stretch/mode", "disabled"))
	var aspect := String(ProjectSettings.get_setting("display/window/stretch/aspect", "keep"))
	if mode == "disabled" or aspect != "keep":
		return window_size
	return Vector2i(
		int(ProjectSettings.get_setting("display/window/size/viewport_width", window_size.x)),
		int(ProjectSettings.get_setting("display/window/size/viewport_height", window_size.y))
	)


func _check_viewport(viewport_size: Vector2i, logical_size: Vector2i) -> void:
	var raw := logical_size == viewport_size
	var tag := "%dx%d%s" % [viewport_size.x, viewport_size.y, " raw" if raw else " window"]
	var viewport := SubViewport.new()
	viewport.size = viewport_size
	if not raw:
		viewport.size_2d_override = logical_size
		viewport.size_2d_override_stretch = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(viewport)
	var screen = BattleScreenScene.instantiate()
	viewport.add_child(screen)
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen.configure(
		"卡面回归",
		{},
		{"enemy.weeping_tenant": "哭泣的房客"},
		func(_a: StringName, _b: StringName, _d: Array) -> BattlePlayability:
			return BattlePlayabilityScript.new(true, BattlePlayability.PLAYABLE),
		{"card.skill.coffin_nail": {"name": "棺钉", "effect_text": "造成 6 伤害；施加 2 层标记"}}
	)
	screen.apply_snapshot(_snapshot())
	await _frames(3)
	var view := Rect2(Vector2.ZERO, Vector2(logical_size))

	var cards: Array[Control] = []
	for node in screen.find_children("*", "PanelContainer", true, false):
		if (node as Control).has_meta("battle_instance_id"):
			cards.append(node as Control)
	_expect(cards.size() == HAND_IDS.size(), "%s all %d hand cards rendered (got %d)" % [tag, HAND_IDS.size(), cards.size()])
	for card in cards:
		var definition_id := String(card.get_meta("battle_definition_id", ""))
		_check_face(card, definition_id, "%s hand %s" % [tag, definition_id])
		var body := card.find_child("HandCardBody", true, false) as Control
		var blocked := definition_id == HAND_IDS[BLOCKED_INDEX]
		_expect(
			body != null and (body.modulate.r < 0.9) == blocked,
			"%s %s dimmed only when snapshot says unplayable" % [tag, definition_id]
		)
		var button := card.find_child("SelectButton", true, false) as Control
		_expect(
			button != null and button.get_global_rect().end.y <= card.get_global_rect().end.y + 0.5
				and button.size.y >= 20.0,
			"%s %s select button fully inside card" % [tag, definition_id]
		)

	var end_turn := screen.find_child("EndTurnButton", true, false) as Control
	var hand := screen.find_child("HandPanel", true, false) as Control
	var page := screen.find_child("BattlePageScroll", true, false) as ScrollContainer
	_expect(end_turn != null and hand != null and page != null, "%s end-turn, hand panel, page scroll exist" % tag)
	if end_turn == null or hand == null or page == null:
		viewport.queue_free()
		return
	for card in cards:
		_expect(
			hand.get_global_rect().encloses(card.get_global_rect()),
			"%s card %s inside hand panel" % [tag, card.get_meta("battle_definition_id")]
		)
	if not raw:
		_expect(view.encloses(end_turn.get_global_rect()), "%s end-turn button inside window" % tag)
		_expect(view.encloses(hand.get_global_rect()), "%s hand panel inside window" % tag)
	else:
		## ADR-0030: what does not fit is carried by its own scroll container.
		for target in [end_turn] + cards:
			page.ensure_control_visible(target)
			await _frames(2)
			_expect(
				view.encloses((target as Control).get_global_rect()),
				"%s %s reachable by page scroll" % [tag, target.name]
			)

	## Cast animation: same face, same aspect.
	var events: Array[BattleEvent] = [
		BattleEventScript.new(&"CardPlayed", {"definition_id": HAND_IDS[0], "target_id": "enemy.01"}),
	]
	screen.apply_command_result(BattleCommandResultScript.new(true, &"ok", events, null))
	await _frames(1)
	var cast := screen.find_child("CastCard", true, false) as Control
	_expect(cast != null, "%s cast animation builds a card face" % tag)
	if cast != null:
		_check_face(cast, HAND_IDS[0], "%s cast" % tag)

	viewport.queue_free()
	await _frames(1)


func _check_face(root: Control, definition_id: String, label: String) -> void:
	var art := root.find_child(CardFace.NAME_ART, true, false) as TextureRect
	_expect(art != null, "%s has art" % label)
	if art == null:
		return
	var rect := art.get_global_rect()
	var aspect := rect.size.x / maxf(rect.size.y, 1.0)
	_expect(
		absf(aspect - ASPECT) <= ASPECT_TOLERANCE,
		"%s art aspect %.3f within %.2f±%.2f (rect %s)" % [label, aspect, ASPECT, ASPECT_TOLERANCE, rect]
	)
	_expect(art.stretch_mode != TextureRect.STRETCH_SCALE, "%s art is not stretched" % label)
	_expect(rect.size.y >= 90.0, "%s art is a window, not a strip (h=%.0f)" % [label, rect.size.y])
	_expect(art.modulate == Color.WHITE, "%s art carries no tint" % label)
	_expect(CardFace.face_art_path(art) == CardFace.art_path(definition_id), "%s shows the shared art path" % label)


func _snapshot() -> BattleSnapshot:
	var hand: Array = []
	for i in range(HAND_IDS.size()):
		hand.append({
			"instance_id": "face.%d" % i,
			"definition_id": HAND_IDS[i],
			"category": "skill",
			"cost_spirit": 4 if i == BLOCKED_INDEX else 1,
			"target_type": "enemy" if i % 2 == 0 else "self",
			"playable": i != BLOCKED_INDEX,
			"blocked_reason": "insufficient_spirit" if i == BLOCKED_INDEX else "",
		})
	return BattleSnapshotScript.new({
		"revision": 1,
		"battle_id": "battle.card_face",
		"phase": "player_action",
		"round_number": 1,
		"max_rounds": 10,
		"enemy_pressure_bonus": 0,
		"chain": {"count": 0, "threshold": 3, "damage": 1, "draw": 1, "spirit": 1},
		"player": {
			"actor_id": "player", "hp": 20, "max_hp": 20, "block": 0, "spirit": 3,
			"max_spirit": 3, "corruption": 0, "max_corruption": 10, "attention": 0,
			"max_attention": 10, "statuses": [],
		},
		"enemies": [{
			"actor_id": "enemy.01", "definition_id": "enemy.weeping_tenant", "lane_index": 0,
			"hp": 12, "max_hp": 12, "block": 0, "statuses": [],
			"intent": {"revealed": true, "visible_fields": {"damage": 4}},
		}],
		"hand": hand,
		"draw_pile_count": 8,
		"discard_pile_count": 0,
		"outcome": "",
	})


func _frames(count: int) -> void:
	for _index in range(count):
		await get_tree().process_frame


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(message)
