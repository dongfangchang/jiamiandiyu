extends Node

## BUG-0041 real-window capture: battle hand at a given window size.
## Usage (non-headless):
##   Godot --path . res://tests/ui/battle_hand_capture_runner.tscn -- \
##     --capture-size=1600x900 --capture-tag=after
## Writes .tools/ui-captures/v089_battle_hand_<WxH>_<tag>.png and prints the
## hand-card art rects so the capture can be checked against ADR-0030.

const UiContentFixture := preload("res://tests/ui/ui_content_fixture.gd")
const BattleScreenScene := preload("res://scenes/ui/battle_screen.tscn")
const BattleSnapshotScript := preload("res://src/core/battle_snapshot.gd")
const BattlePlayabilityScript := preload("res://src/core/battle_playability.gd")

const OUTPUT_DIRECTORY := "res://.tools/ui-captures"
const HAND_IDS := [
	"card.skill.coffin_nail",
	"card.skill.paper_guard",
	"card.skill.warding_circle",
	"card.skill.ink_dart",
	"card.skill.omen",
	"card.skill.second_sight",
	"card.skill.lantern_step",
]


func _ready() -> void:
	UiContentFixture.ensure()
	var size := _arg_size()
	DisplayServer.window_set_size(size)
	get_window().size = size
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIRECTORY))
	await get_tree().process_frame
	var screen = BattleScreenScene.instantiate()
	add_child(screen)
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen.configure(
		"廷根旧宅 · 失约的房客",
		{
			"card.skill.coffin_nail": "棺钉",
			"card.skill.paper_guard": "纸符护持",
			"card.skill.warding_circle": "守夜圆环",
			"card.skill.ink_dart": "墨刺",
			"card.skill.omen": "凶兆",
			"card.skill.second_sight": "第二视觉",
			"card.skill.lantern_step": "提灯步",
		},
		{"enemy.weeping_tenant": "哭泣的房客", "enemy.candle_moth": "烛焰飞蛾"},
		func(_a: StringName, _b: StringName, _d: Array) -> BattlePlayability:
			return BattlePlayabilityScript.new(true, BattlePlayability.PLAYABLE),
		{
			"card.skill.ink_dart": {"effect_text": "造成 4 点伤害"},
			"card.skill.coffin_nail": {"effect_text": "造成 6 伤害；施加 2 层标记"},
			"card.skill.paper_guard": {"effect_text": "获得 5 点护盾"},
			"card.skill.warding_circle": {"effect_text": "获得 6 点护盾"},
			"card.skill.omen": {"effect_text": "施加 2 层标记"},
			"card.skill.second_sight": {"effect_text": "抽 2 张牌"},
			"card.skill.lantern_step": {"effect_text": "获得 3 点护盾，抽 1 张牌"},
		}
	)
	screen.apply_snapshot(_snapshot())
	screen.select_card_instance(&"hand.0")
	for _i in range(4):
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	_report(screen, size)
	var tag := _arg("--capture-tag=", "after")
	var path := ProjectSettings.globalize_path(OUTPUT_DIRECTORY.path_join(
		"v089_battle_hand_%dx%d_%s.png" % [size.x, size.y, tag]
	))
	var error := get_viewport().get_texture().get_image().save_png(path)
	print("CAPTURE=%s RESULT=%s" % [path, error])
	get_tree().quit(0)


func _report(screen: Node, size: Vector2i) -> void:
	var view := Rect2(Vector2.ZERO, Vector2(size))
	var end_turn := screen.find_child("EndTurnButton", true, false) as Control
	var hand := screen.find_child("HandPanel", true, false) as Control
	print("REPORT viewport=%s hand=%s end_turn=%s" % [
		view,
		hand.get_global_rect() if hand else Rect2(),
		end_turn.get_global_rect() if end_turn else Rect2(),
	])
	var scroll := screen.find_child("HandScroll", true, false) as Control
	print("REPORT hand_scroll=%s" % (scroll.get_global_rect() if scroll else Rect2()))
	for art in screen.find_children("CardArt", "TextureRect", true, false):
		var rect := (art as Control).get_global_rect()
		print("REPORT art rect=%s aspect=%.3f stretch=%d" % [
			rect, rect.size.x / maxf(1.0, rect.size.y), (art as TextureRect).stretch_mode
		])


func _snapshot() -> BattleSnapshot:
	var hand: Array = []
	for i in range(HAND_IDS.size()):
		hand.append({
			"instance_id": "hand.%d" % i,
			"definition_id": HAND_IDS[i],
			"category": "skill",
			"cost_spirit": 2 if i == 0 else (4 if i == 5 else 1),
			"target_type": "enemy" if i in [0, 3, 4] else "self",
			"playable": i != 5,
			"blocked_reason": "insufficient_spirit" if i == 5 else "",
		})
	return BattleSnapshotScript.new({
		"revision": 3,
		"battle_id": "battle.capture",
		"phase": "player_action",
		"round_number": 2,
		"max_rounds": 10,
		"player": {
			"actor_id": "player", "hp": 46, "max_hp": 54, "block": 5,
			"spirit": 3, "max_spirit": 3, "corruption": 2, "max_corruption": 10,
			"attention": 3, "max_attention": 10, "statuses": [],
		},
		"enemies": [
			{
				"actor_id": "enemy.left", "definition_id": "enemy.weeping_tenant",
				"lane_index": 0, "hp": 12, "max_hp": 16, "block": 0, "statuses": [],
				"intent": {"intent_id": "attack", "revealed": true, "visible_fields": {"damage": 7}},
			},
			{
				"actor_id": "enemy.center", "definition_id": "enemy.candle_moth",
				"lane_index": 1, "hp": 10, "max_hp": 10, "block": 0, "statuses": [],
				"intent": {"intent_id": "attack", "revealed": false, "visible_fields": {}},
			},
		],
		"hand": hand,
		"draw_pile_count": 5,
		"discard_pile_count": 2,
		"chain": {},
		"events": [],
		"outcome": "",
		"outcome_reason": "",
	})


func _arg(prefix: String, fallback: String) -> String:
	for argument in OS.get_cmdline_user_args() + OS.get_cmdline_args():
		if String(argument).begins_with(prefix):
			return String(argument).trim_prefix(prefix)
	return fallback


func _arg_size() -> Vector2i:
	var parts := _arg("--capture-size=", "1600x900").split("x")
	if parts.size() == 2 and parts[0].is_valid_int() and parts[1].is_valid_int():
		return Vector2i(int(parts[0]), int(parts[1]))
	return Vector2i(1600, 900)
