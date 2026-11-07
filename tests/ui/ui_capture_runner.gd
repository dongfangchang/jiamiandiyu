extends Node

const StartScreenScene := preload("res://scenes/ui/start_screen.tscn")
const BattleScreenScene := preload("res://scenes/ui/battle_screen.tscn")
const ResultScreenScene := preload("res://scenes/ui/result_screen.tscn")
const IdentityScreenScene := preload("res://scenes/ui/identity_screen.tscn")
const RewardScreenScene := preload("res://scenes/ui/reward_screen.tscn")
const GachaScreenScene := preload("res://scenes/ui/gacha_screen.tscn")
const UpgradeScreenScene := preload("res://scenes/ui/upgrade_screen.tscn")
const BattleSnapshotScript := preload("res://src/core/battle_snapshot.gd")
const ProgressionSnapshotScript := preload("res://src/core/progression_snapshot.gd")

const OUTPUT_DIRECTORY := "res://.tools/ui-captures"


func _ready() -> void:
	DisplayServer.window_set_size(Vector2i(1600, 900))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIRECTORY))
	await get_tree().process_frame
	await _capture_start()
	await _capture_identity()
	await _capture_reward()
	await _capture_gacha()
	await _capture_upgrade()
	await _capture_battle()
	await _capture_result()
	get_tree().quit(0)


func _capture_start() -> void:
	var screen = StartScreenScene.instantiate()
	add_child(screen)
	screen.show_checkpoint_status("loaded", {
		"content_version": "v0.4.0",
		"sequence": 9,
		"deck_size": 12,
		"identity_id": "identity.reporter",
		"divination_tickets": 7,
		"collection_count": 6,
		"pity_counter": 2,
		"rare_pity": 4,
		"created_at": "2026-11-08T02:30:00Z",
		"last_battle": {"outcome": "victory", "round_number": 5},
	})
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	_save_capture("start_screen.png")
	screen.queue_free()
	await get_tree().process_frame


func _capture_identity() -> void:
	var screen = IdentityScreenScene.instantiate()
	add_child(screen)
	screen.apply_snapshot(_progression_snapshot({
		"phase": "identity_selection",
		"identity_id": "",
		"identity_options": _identity_options(""),
	}))
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	_save_capture("identity_screen.png")
	screen.queue_free()
	await get_tree().process_frame


func _capture_reward() -> void:
	var screen = RewardScreenScene.instantiate()
	add_child(screen)
	screen.apply_snapshot(_progression_snapshot({
		"phase": "reward",
		"identity_options": _identity_options("identity.reporter"),
		"reward_options": [
			{"id": "reward.divination_tickets", "display_name_zh": "灵界占卜券", "kind": "divination_tickets", "amount": 3},
			{"id": "reward.ink_dart_fragments", "display_name_zh": "墨刺残页", "kind": "card_fragments", "amount": 6},
		],
	}))
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	_save_capture("reward_screen.png")
	screen.queue_free()
	await get_tree().process_frame


func _capture_gacha() -> void:
	var screen = GachaScreenScene.instantiate()
	add_child(screen)
	screen.configure(_card_names())
	screen.apply_snapshot(_progression_snapshot({
		"last_gacha_results": [
			{"definition_id": "card.skill.paper_guard", "rarity": "common", "duplicate": true, "fragments": 6},
			{"definition_id": "card.skill.omen", "rarity": "rare", "duplicate": false, "fragments": 0},
			{"definition_id": "card.skill.insight", "rarity": "common", "duplicate": false, "fragments": 0},
		],
	}))
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	_save_capture("gacha_screen.png")
	screen.queue_free()
	await get_tree().process_frame


func _capture_upgrade() -> void:
	var screen = UpgradeScreenScene.instantiate()
	add_child(screen)
	screen.configure(_card_names(), {
		"card.skill.ink_dart": ["造成 4 点伤害", "造成 5 点伤害", "造成 6 点伤害", "造成 7 点伤害"],
		"card.skill.paper_guard": ["获得 5 点护盾", "获得 6 点护盾", "获得 7 点护盾", "获得 8 点护盾"],
		"card.skill.calm_breath": ["恢复 4 点生命", "恢复 5 点生命", "恢复 6 点生命", "恢复 7 点生命"],
		"card.skill.focus": ["获得 1 点灵性", "获得 2 点灵性", "获得 3 点灵性", "获得 4 点灵性"],
	})
	screen.apply_snapshot(_progression_snapshot({
		"divination_tickets": 4,
		"collection": [
			{"definition_id": "card.skill.ink_dart", "copies": 3, "level": 1, "fragments": 8, "max_level": 3, "next_upgrade_cost": 12},
			{"definition_id": "card.skill.paper_guard", "copies": 2, "level": 0, "fragments": 6, "max_level": 3, "next_upgrade_cost": 6},
			{"definition_id": "card.skill.calm_breath", "copies": 2, "level": 2, "fragments": 24, "max_level": 3, "next_upgrade_cost": 24},
			{"definition_id": "card.skill.focus", "copies": 1, "level": 0, "fragments": 2, "max_level": 3, "next_upgrade_cost": 6},
		],
	}))
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	_save_capture("upgrade_screen.png")
	screen.queue_free()
	await get_tree().process_frame


func _capture_battle() -> void:
	var screen = BattleScreenScene.instantiate()
	add_child(screen)
	screen.configure(
		"廷根旧宅 · 失约的房客",
		{
			&"card.skill.ink_dart": "墨刺",
			&"card.skill.paper_guard": "纸符护持",
			&"card.skill.insight": "洞察",
		},
		{
			&"enemy.weeping_tenant": "哭泣的房客",
			&"enemy.candle_moth": "烛焰飞蛾",
			&"enemy.mirror_hound": "镜中猎犬",
		},
		Callable()
	)
	screen.apply_snapshot(_battle_snapshot())
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	_save_capture("battle_screen.png")
	screen.queue_free()
	await get_tree().process_frame


func _capture_result() -> void:
	var screen = ResultScreenScene.instantiate()
	add_child(screen)
	var snapshot := _battle_snapshot()
	snapshot.data["outcome"] = "victory"
	snapshot.data["outcome_reason"] = "enemies_defeated"
	screen.show_result(snapshot, "廷根旧宅 · 失约的房客", "saved")
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	_save_capture("result_screen.png")
	screen.queue_free()


func _save_capture(file_name: String) -> void:
	var image := get_viewport().get_texture().get_image()
	var path := ProjectSettings.globalize_path(OUTPUT_DIRECTORY.path_join(file_name))
	var error := image.save_png(path)
	print("CAPTURE=%s RESULT=%s" % [path, error])


func _progression_snapshot(overrides: Dictionary) -> ProgressionSnapshot:
	var data := {
		"revision": 8,
		"phase": "hub",
		"identity_id": "identity.reporter",
		"identity_options": _identity_options("identity.reporter"),
		"battle_modifiers": {"starting_attention": -1},
		"divination_tickets": 7,
		"collection": [
			{"definition_id": "card.skill.ink_dart", "copies": 2, "level": 0, "fragments": 4, "max_level": 3, "next_upgrade_cost": 6},
		],
		"pity_counter": 2,
		"rare_pity": 4,
		"gacha_costs": {"single": 2, "triple": 5},
		"rarity_weights": {"common": 85, "rare": 15},
		"reward_options": [],
		"last_battle_outcome": "victory",
		"last_gacha_results": [],
	}
	for key in overrides:
		data[key] = overrides[key]
	return ProgressionSnapshotScript.new(data)


func _identity_options(selected_id: String) -> Array:
	return [
		{"id": "identity.reporter", "display_name_zh": "记者", "description_zh": "维持调查网络，以一篇报道换取更多线索。", "battle_modifiers": {"starting_attention": -1}, "selected": selected_id == "identity.reporter"},
		{"id": "identity.doctor", "display_name_zh": "医生", "description_zh": "熟悉身体与污染的边界，以更好的体魄进入战斗。", "battle_modifiers": {"max_hp_bonus": 4}, "selected": selected_id == "identity.doctor"},
		{"id": "identity.gravedigger", "display_name_zh": "守墓人", "description_zh": "替遗忘的名字收殓，能从重复的命运中拾取更多残片。", "battle_modifiers": {}, "selected": selected_id == "identity.gravedigger"},
	]


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


func _battle_snapshot() -> BattleSnapshot:
	return BattleSnapshotScript.new({
		"revision": 17,
		"battle_id": "encounter.tingen_old_house.20261108",
		"phase": "player_action",
		"round_number": 5,
		"max_rounds": 10,
		"enemy_pressure_bonus": 1,
		"player": {
			"actor_id": "player",
			"hp": 46,
			"max_hp": 54,
			"block": 5,
			"spirit": 3,
			"max_spirit": 3,
			"corruption": 2,
			"max_corruption": 10,
			"attention": 3,
			"max_attention": 10,
			"statuses": [],
		},
		"hand": [
			{
				"instance_id": "player.action.017",
				"definition_id": "card.skill.ink_dart",
				"category": "skill",
				"cost_spirit": 1,
				"target_type": "enemy",
			},
			{
				"instance_id": "player.guard.003",
				"definition_id": "card.skill.paper_guard",
				"category": "skill",
				"cost_spirit": 1,
				"target_type": "self",
			},
			{
				"instance_id": "player.insight.005",
				"definition_id": "card.skill.insight",
				"category": "skill",
				"cost_spirit": 0,
				"target_type": "none",
			},
		],
		"draw_pile_count": 5,
		"discard_pile_count": 2,
		"enemies": [
			{
				"actor_id": "enemy.left",
				"definition_id": "enemy.weeping_tenant",
				"lane_index": 0,
				"hp": 12,
				"max_hp": 16,
				"block": 0,
				"statuses": [{"status_id": "mark", "stacks": 2, "duration": 2}],
				"intent": {
					"intent_id": "attack",
					"revealed": true,
					"visible_fields": {"damage": 7},
				},
			},
			{
				"actor_id": "enemy.center",
				"definition_id": "enemy.candle_moth",
				"lane_index": 1,
				"hp": 10,
				"max_hp": 10,
				"block": 0,
				"statuses": [],
				"intent": {
					"intent_id": "attack",
					"revealed": false,
					"visible_fields": {},
				},
			},
			{
				"actor_id": "enemy.right",
				"definition_id": "enemy.mirror_hound",
				"lane_index": 2,
				"hp": 0,
				"max_hp": 12,
				"block": 0,
				"statuses": [],
				"intent": {
					"intent_id": "attack",
					"revealed": false,
					"visible_fields": {},
				},
			},
		],
		"outcome": "",
		"outcome_reason": "",
	})
