extends Node

const StartScreenScene := preload("res://scenes/ui/start_screen.tscn")
const BattleScreenScene := preload("res://scenes/ui/battle_screen.tscn")
const ResultScreenScene := preload("res://scenes/ui/result_screen.tscn")
const BattleSnapshotScript := preload("res://src/core/battle_snapshot.gd")

const OUTPUT_DIRECTORY := "res://.tools/ui-captures"


func _ready() -> void:
	DisplayServer.window_set_size(Vector2i(1600, 900))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIRECTORY))
	await get_tree().process_frame
	await _capture_start()
	await _capture_battle()
	await _capture_result()
	get_tree().quit(0)


func _capture_start() -> void:
	var screen = StartScreenScene.instantiate()
	add_child(screen)
	screen.show_checkpoint_status("loaded", {
		"content_version": "v0.3.0",
		"sequence": 9,
		"deck_size": 8,
		"created_at": "2026-11-08T02:30:00Z",
		"last_battle": {"outcome": "victory", "round_number": 5},
	})
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	_save_capture("start_screen.png")
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
