extends Node

const AppRootScene := preload("res://src/app/app_root.tscn")
const AppBootstrapScript := preload("res://src/app/bootstrap.gd")
const SaveMigrationsScript := preload("res://src/infrastructure/save_migrations.gd")
const PreferencesServiceScript := preload(
	"res://src/infrastructure/player_preferences_service.gd"
)
const BattleScreenScene := preload("res://scenes/ui/battle_screen.tscn")
const BattleSnapshotScript := preload("res://src/core/battle_snapshot.gd")
const BattleCommandResultScript := preload("res://src/core/battle_command_result.gd")
const BattleEventScript := preload("res://src/core/battle_event.gd")
const BattlePlayabilityScript := preload("res://src/core/battle_playability.gd")
const GachaScreenScene := preload("res://scenes/ui/gacha_screen.tscn")
const ProgressionSnapshotScript := preload("res://src/core/progression_snapshot.gd")
const RouteResultScene := preload("res://scenes/ui/route_result_screen.tscn")
const RouteSnapshotScript := preload("res://src/core/route_snapshot.gd")

const TEST_ROOT := "user://mask_whispers_v092_destructive"
const CARDS_PATH := "res://data/cards/v0.7.0/cards.json"
const ENEMIES_PATH := "res://data/enemies/v0.7.0/enemies.json"

var _passed := 0
var _failures: Array[String] = []


func _ready() -> void:
	_remove_tree(TEST_ROOT)
	DirAccess.make_dir_recursive_absolute(
		ProjectSettings.globalize_path(TEST_ROOT)
	)
	await _test_corrupt_primary_backup_restore()
	await _test_corrupt_primary_backup_restore_through_ui()
	await _test_battle_exit_resumes_without_test_profile_contamination()
	await _test_all_cards_and_enemies_remain_readable()
	await _test_pending_states_never_trap_the_player()
	await _test_battle_finish_and_exit_are_idempotent()
	await _test_unknown_reason_codes_do_not_leak()
	_test_test_profile_unlocks_all_challenges()
	_remove_tree(TEST_ROOT)
	if _failures.is_empty():
		print("V092_DESTRUCTIVE_OK checks=%d" % _passed)
		get_tree().quit(0)
		return
	for failure in _failures:
		printerr("V092_DESTRUCTIVE_FAIL: %s" % failure)
	get_tree().quit(1)


func _test_corrupt_primary_backup_restore() -> void:
	var save_directory := TEST_ROOT.path_join("corrupt_restore")
	var service = SaveMigrationsScript.create_v07_service(save_directory)
	_expect(
		service.save_slot("checkpoint", _save_envelope(8, "older")).ok,
		"backup restore setup should save the older checkpoint"
	)
	_expect(
		service.save_slot("checkpoint", _save_envelope(9, "current")).ok,
		"backup restore setup should rotate a valid backup"
	)
	_write_text(service.get_slot_path("checkpoint"), "{broken-json")
	var inspected = AppBootstrapScript.inspect_route_checkpoint_v07(
		"checkpoint",
		save_directory
	)
	_expect(inspected.ok, "corrupt checkpoint should remain inspectable")
	if inspected.ok:
		_expect(
			String(inspected.data.get("status", "")) == "corrupt",
			"corrupt checkpoint should be detected"
		)
		_expect(
			bool(inspected.data.get("backup_available", false)),
			"valid backup should be offered after primary corruption"
		)
	var restored = AppBootstrapScript.restore_checkpoint_backup(
		"checkpoint",
		save_directory
	)
	_expect(
		restored.ok,
		"restoring a valid backup must succeed even when the primary is corrupt"
	)
	if restored.ok:
		var preserved_path := String(restored.details.get(
			"preserved_path",
			""
		))
		_expect(
			not preserved_path.is_empty()
			and FileAccess.file_exists(preserved_path),
			"backup restore should preserve the replaced primary for diagnosis"
		)
		_expect(
			_read_text(preserved_path) == "{broken-json",
			"preserved primary should retain the exact damaged data"
		)
	var loaded = service.load_slot("checkpoint")
	_expect(
		loaded.ok,
		"restored checkpoint should be readable"
	)
	if loaded.ok:
		_expect(
			int(loaded.data.get("profile", {}).get("sequence", 0)) == 8,
			"restored checkpoint should contain the backup progress"
		)


func _test_corrupt_primary_backup_restore_through_ui() -> void:
	var root := TEST_ROOT.path_join("ui_restore")
	var save_directory := root.path_join("saves")
	var service = SaveMigrationsScript.create_v07_service(save_directory)
	service.save_slot("checkpoint", _save_envelope(8, "older"))
	service.save_slot("checkpoint", _save_envelope(9, "current"))
	_write_text(service.get_slot_path("checkpoint"), "{broken-json")
	var preferences_path := root.path_join("preferences.json")
	var preferences = PreferencesServiceScript.new(preferences_path)
	preferences.save_preferences({
		"settings_version": 1,
		"tutorial_seen": true,
		"fullscreen": false,
		"ui_scale": 1.0,
		"reduce_flash": false,
	})
	var controller = AppRootScene.instantiate()
	controller.configure_for_testing(
		save_directory,
		"checkpoint",
		20261108,
		preferences_path,
		root.path_join("diagnostics")
	)
	add_child(controller)
	await _wait_frames(3)
	var title_screen: Control = controller.get_current_screen()
	if title_screen != null and title_screen.has_method("get_version_text"):
		var version_text := String(title_screen.call("get_version_text"))
		_expect(
			version_text.contains("v%s" % String(
				ProjectSettings.get_setting("application/config/version", "")
			))
			and not version_text.contains("WHISPERS"),
			"title version text should use the current Chinese product version"
		)
	var restore_button := _button_by_text(controller, "恢复上次备份")
	_expect(
		restore_button != null and not restore_button.disabled,
		"title screen should expose backup recovery for a corrupt primary"
	)
	if restore_button != null:
		restore_button.pressed.emit()
	await _wait_frames(4)
	var start_screen: Control = controller.get_current_screen()
	var preference_status := start_screen.get("_preferences_status") as Label
	_expect(
		preference_status != null
		and preference_status.text.contains("备份已恢复"),
		"title-screen recovery should report success"
	)
	_expect(
		start_screen.has_method("is_continue_enabled")
		and bool(start_screen.call("is_continue_enabled")),
		"continue should become available after title-screen recovery"
	)
	controller.queue_free()
	await get_tree().process_frame


func _test_battle_exit_resumes_without_test_profile_contamination() -> void:
	var root := TEST_ROOT.path_join("exit_resume")
	var save_directory := root.path_join("saves")
	var service = SaveMigrationsScript.create_v07_service(save_directory)
	service.save_slot("checkpoint", _save_envelope(8, "normal"))
	var normal_before := _read_text(service.get_slot_path("checkpoint"))
	var preferences_path := root.path_join("preferences.json")
	var preferences = PreferencesServiceScript.new(preferences_path)
	preferences.save_preferences({
		"settings_version": 1,
		"tutorial_seen": true,
		"fullscreen": false,
		"ui_scale": 1.0,
		"reduce_flash": false,
	})
	var controller = AppRootScene.instantiate()
	controller.configure_for_testing(
		save_directory,
		"checkpoint",
		20261108,
		preferences_path,
		root.path_join("diagnostics")
	)
	add_child(controller)
	await _wait_frames(3)
	var test_button := _button_by_text(controller, "测试档案")
	_expect(test_button != null, "title screen should expose the test profile")
	if test_button != null:
		test_button.pressed.emit()
	await _wait_frames(4)
	_expect(
		String(controller.get_current_route()) == "map",
		"test profile should enter the route map"
	)
	var enter_battle := _button_by_text(controller, "进入夜间战斗")
	if enter_battle != null:
		enter_battle.pressed.emit()
	await _wait_frames(3)
	var node_button := _button_by_text(controller, "前往节点")
	_expect(node_button != null, "route map should expose the first event")
	if node_button != null:
		node_button.pressed.emit()
	await _wait_frames(4)
	_expect(
		String(controller.get_current_route()) == "battle",
		"selected battle node should enter battle"
	)
	var exit_button := _button_by_text(controller, "退出战斗")
	if exit_button != null:
		exit_button.pressed.emit()
	await _wait_frames(2)
	var battle_screen: Control = controller.get_current_screen()
	if battle_screen != null and battle_screen.has_method(
		"is_exit_confirmation_visible"
	):
		var confirmation: ConfirmationDialog = battle_screen.get(
			"_exit_confirmation"
		)
		if confirmation != null:
			confirmation.emit_signal("confirmed")
	await _wait_frames(4)
	_expect(
		String(controller.get_current_route()) == "start",
		"confirmed battle exit should return to the title"
	)
	var continue_button := _button_by_text(controller, "继续上次战斗")
	_expect(
		continue_button != null and not continue_button.disabled,
		"battle exit should leave the nearest checkpoint resumable"
	)
	if continue_button != null and not continue_button.disabled:
		continue_button.pressed.emit()
	await _wait_frames(4)
	_expect(
		String(controller.get_current_route()) == "map",
		"continue after battle exit should restore the route map"
	)
	var test_checkpoint = AppBootstrapScript.inspect_route_checkpoint_v07(
		"test_checkpoint",
		save_directory
	)
	_expect(
		test_checkpoint.ok
		and String(test_checkpoint.data.get("status", "")) == "loaded",
		"test profile should use its own readable checkpoint"
	)
	var normal_after := _read_text(service.get_slot_path("checkpoint"))
	_expect(
		normal_after == normal_before,
		"test profile must not mutate the normal checkpoint"
	)
	controller.show_start_screen()
	await _wait_frames(3)
	var challenge_button := _button_by_text(controller, "进入挑战档案")
	_expect(
		challenge_button != null and not challenge_button.disabled,
		"test profile should expose all challenges from the title screen"
	)
	if challenge_button != null and not challenge_button.disabled:
		challenge_button.pressed.emit()
	await _wait_frames(4)
	_expect(
		String(controller.get_current_route()) == "challenge_hub",
		"test profile challenge entry should open the challenge hub"
	)
	var challenge_hub: Control = controller.get_current_screen()
	if (
		challenge_hub != null
		and challenge_hub.has_method("request_challenge")
	):
		challenge_hub.call(
			"request_challenge",
			"challenge.v060.mirror_echoes"
		)
	await _wait_frames(4)
	_expect(
		String(controller.get_current_route()) == "challenge_select",
		"test profile should open a challenge's modifier selection"
	)
	controller.queue_free()
	await get_tree().process_frame


func _test_all_cards_and_enemies_remain_readable() -> void:
	var cards_document := _read_json_object(CARDS_PATH)
	var enemies_document := _read_json_object(ENEMIES_PATH)
	_expect(not cards_document.is_empty(), "card data should load")
	_expect(not enemies_document.is_empty(), "enemy data should load")
	if cards_document.is_empty() or enemies_document.is_empty():
		return
	var card_definitions: Array = cards_document.get("cards", [])
	var enemy_definitions: Array = enemies_document.get("enemies", [])
	_expect(card_definitions.size() == 40, "destructive audit must cover all 40 cards")
	var card_labels := {}
	var card_details := {}
	var hand: Array = []
	for index in range(card_definitions.size()):
		var definition: Dictionary = card_definitions[index]
		var definition_id := String(definition.get("id", ""))
		var display_name := String(definition.get("display_name_zh", ""))
		card_labels[definition_id] = display_name
		card_details[definition_id] = {
			"name": display_name,
			"description": String(definition.get("description_zh", "")),
			"effect_text": _card_effect_text(definition),
			"level": 1,
		}
		hand.append({
			"instance_id": "v092.%02d" % index,
			"definition_id": definition_id,
			"category": String(definition.get("category", "skill")),
			"cost_spirit": int(definition.get("cost_spirit", 0)),
			"target_type": String(definition.get("target_type", "none")),
		})
	var enemy_labels := {}
	var enemies: Array = []
	for index in range(enemy_definitions.size()):
		var definition: Dictionary = enemy_definitions[index]
		var definition_id := String(definition.get("id", ""))
		enemy_labels[definition_id] = String(
			definition.get("display_name_zh", "")
		)
		enemies.append({
			"actor_id": "enemy.v092.%02d" % index,
			"definition_id": definition_id,
			"lane_index": mini(index, 2),
			"hp": 12,
			"max_hp": 12,
			"block": 0,
			"statuses": [],
			"intent": {
				"revealed": true,
				"visible_fields": {"kind": "attack", "damage": 2},
			},
		})
	var screen = BattleScreenScene.instantiate()
	add_child(screen)
	screen.configure(
		"破坏性可读性审计",
		card_labels,
		enemy_labels,
		func(_card_id: StringName, _target_id: StringName) -> BattlePlayability:
			return BattlePlayabilityScript.new(
				true,
				BattlePlayability.PLAYABLE
			),
		card_details
	)
	screen.apply_snapshot(_battle_snapshot(hand, enemies))
	await get_tree().process_frame
	_expect(
		not _contains_internal_id(screen),
		"battle UI must not leak any internal stable ID"
	)
	for definition_value in card_definitions:
		var definition: Dictionary = definition_value
		var definition_id := StringName(definition.get("id", ""))
		var display_name := String(definition.get("display_name_zh", ""))
		var effect_text := _card_effect_text(definition)
		_expect(
			ResourceLoader.exists(screen.get_card_art_path(definition_id)),
			"every card must resolve to an existing battle image: %s" % definition_id
		)
		_expect(
			_contains_label_text(screen, display_name),
			"every card must show its Chinese name: %s" % definition_id
		)
		_expect(
			_contains_label_text(screen, effect_text),
			"every card must show its effect in the battle hand: %s" % definition_id
		)
	for definition_value in enemy_definitions:
		var definition: Dictionary = definition_value
		var definition_id := StringName(definition.get("id", ""))
		var display_name := String(definition.get("display_name_zh", ""))
		_expect(
			ResourceLoader.exists(screen.get_enemy_art_path(definition_id)),
			"every enemy must resolve to an existing battle image: %s" % definition_id
		)
		_expect(
			String(screen.call("_enemy_name", definition_id)) == display_name,
			"every enemy must resolve to its Chinese name: %s" % definition_id
		)
	screen.queue_free()
	await get_tree().process_frame


func _test_pending_states_never_trap_the_player() -> void:
	var gacha = GachaScreenScene.instantiate()
	add_child(gacha)
	gacha.configure({"card.skill.coffin_nail": "棺钉"})
	gacha.apply_snapshot(_progression_snapshot(1))
	var draw_count := [0]
	var back_count := [0]
	gacha.draw_requested.connect(func(_count: int) -> void:
		draw_count[0] += 1
	)
	gacha.back_requested.connect(func() -> void:
		back_count[0] += 1
	)
	gacha.request_draw(1)
	gacha.request_draw(1)
	gacha.request_draw(3)
	_expect(
		draw_count[0] == 1,
		"rapid gacha clicks must submit exactly one request"
	)
	var back_button: Button = gacha.get("_back_button")
	_expect(back_button != null and not back_button.disabled,
		"gacha back must remain enabled while pending")
	gacha.call("_on_back")
	_expect(
		back_count[0] == 1 and not gacha.is_pending(),
		"leaving a pending gacha must clear the lock exactly once"
	)
	gacha.queue_free()
	await get_tree().process_frame

	var battle = BattleScreenScene.instantiate()
	add_child(battle)
	battle.configure(
		"挂起审计",
		{"card.skill.coffin_nail": "棺钉"},
		{"enemy.weeping_tenant": "哭泣的房客"},
		func(_card_id: StringName, _target_id: StringName) -> BattlePlayability:
			return BattlePlayabilityScript.new(
				true,
				BattlePlayability.PLAYABLE
			),
		{
			"card.skill.coffin_nail": {
				"name": "棺钉",
				"description": "钉住敌人。",
				"effect_text": "造成 6 伤害",
				"level": 1,
			},
		}
	)
	battle.apply_snapshot(_battle_snapshot([{
		"instance_id": "test.coffin_nail.001",
		"definition_id": "card.skill.coffin_nail",
		"category": "skill",
		"cost_spirit": 2,
		"target_type": "enemy",
	}], [_test_enemy()]))
	battle.set_pending(true)
	var exit_button: Button = battle.get("_exit_button")
	_expect(
		exit_button != null and not exit_button.disabled,
		"battle exit must remain available while a command is pending"
	)
	battle.call("_request_exit")
	_expect(
		bool(battle.is_exit_confirmation_visible()),
		"pending battle must still open the exit confirmation"
	)
	battle.queue_free()
	await get_tree().process_frame


func _test_battle_finish_and_exit_are_idempotent() -> void:
	var screen = BattleScreenScene.instantiate()
	add_child(screen)
	screen.configure(
		"重复结算审计",
		{"card.skill.coffin_nail": "棺钉"},
		{"enemy.weeping_tenant": "哭泣的房客"},
		func(_card_id: StringName, _target_id: StringName) -> BattlePlayability:
			return BattlePlayabilityScript.new(
				true,
				BattlePlayability.PLAYABLE
			),
		{
			"card.skill.coffin_nail": {
				"name": "棺钉",
				"description": "钉住敌人。",
				"effect_text": "造成 6 伤害",
				"level": 1,
			},
		}
	)
	screen.apply_snapshot(_battle_snapshot([{
		"instance_id": "test.coffin_nail.001",
		"definition_id": "card.skill.coffin_nail",
		"category": "skill",
		"cost_spirit": 2,
		"target_type": "enemy",
	}], [_test_enemy()]))
	var finished_count := [0]
	screen.battle_finished.connect(func(_snapshot: BattleSnapshot) -> void:
		finished_count[0] += 1
	)
	var ended_data := _battle_snapshot([], [_test_enemy()]).to_dictionary()
	ended_data["revision"] = 2
	ended_data["outcome"] = "victory"
	ended_data["outcome_reason"] = "enemies_defeated"
	var ended_result := BattleCommandResultScript.new(
		true,
		&"ok",
		[BattleEventScript.new(&"BattleEnded", {
			"outcome": "victory",
		})],
		BattleSnapshotScript.new(ended_data)
	)
	screen.apply_command_result(ended_result)
	screen.apply_command_result(ended_result)
	_expect(
		finished_count[0] == 1,
		"repeated delivery of the same battle result must emit finish once"
	)
	var exit_count := [0]
	screen.exit_requested.connect(func() -> void:
		exit_count[0] += 1
	)
	screen.call("_request_exit")
	var confirmation: ConfirmationDialog = screen.get("_exit_confirmation")
	confirmation.emit_signal("confirmed")
	confirmation.emit_signal("confirmed")
	_expect(
		exit_count[0] == 1,
		"duplicate dialog confirmation emissions must emit the exit intent once"
	)
	screen.queue_free()
	await get_tree().process_frame


func _test_unknown_reason_codes_do_not_leak() -> void:
	var route_result = RouteResultScene.instantiate()
	add_child(route_result)
	route_result.show_result(RouteSnapshotScript.new({
		"display_name_zh": "异常路线",
		"route_outcome": "failed",
		"end_reason": "unexpected_internal_reason",
		"completed_node_ids": [],
		"nodes": [{"id": "node.one"}],
		"sequence": {"current_sequence": 9},
		"run_state": {
			"hp": 1,
			"max_hp": 10,
			"corruption": 0,
			"max_corruption": 10,
			"attention": 0,
			"max_attention": 10,
		},
	}), "saved")
	var detail: Label = route_result.get("_detail_label")
	_expect(
		not detail.text.contains("unexpected_internal_reason"),
		"route result must not leak unknown internal reason codes"
	)
	route_result.queue_free()
	await get_tree().process_frame

	var battle = BattleScreenScene.instantiate()
	add_child(battle)
	var battle_reason := String(battle.call(
		"_reason_text",
		&"unexpected_battle_reason"
	))
	_expect(
		not battle_reason.contains("unexpected_battle_reason"),
		"battle status must not leak unknown internal reason codes"
	)
	for status_id in [&"mark", &"weaken"]:
		var status_name := String(battle.call("_status_name", status_id))
		_expect(
			status_name != String(status_id)
			and not status_name.contains("_"),
			"battle status effects must use Chinese names: %s" % status_id
		)
	battle.queue_free()
	await get_tree().process_frame


func _test_test_profile_unlocks_all_challenges() -> void:
	var save_directory := TEST_ROOT.path_join("test_profile")
	for challenge_id in [
		"challenge.v060.mirror_echoes",
		"challenge.v070.broken_procession",
	]:
		var challenge = AppBootstrapScript.start_challenge_v07(
			20261108,
			{
				"save_directory": save_directory,
				"test_profile": true,
				"challenge_id": challenge_id,
				"sequence_state": {
					"pathway_id": "seer",
					"pathway_name_zh": "占卜家",
					"current_sequence": 8,
					"next_sequence": 7,
					"next_sequence_name_zh": "魔术师",
					"advancement_state": "completed",
					"completed_challenge_ids": [
						"challenge.v060.mirror_echoes",
					],
				},
			},
			"test_checkpoint",
			false,
			true
		)
		_expect(
			challenge.ok,
			"test profile should initialize challenge %s" % challenge_id
		)
		if challenge.ok:
			_expect(
				bool(challenge.data.get_challenge_snapshot().data.get(
					"unlocked",
					false
				)),
				"test profile should unlock challenge %s" % challenge_id
			)


func _battle_snapshot(hand: Array, enemies: Array) -> BattleSnapshot:
	return BattleSnapshotScript.new({
		"revision": 1,
		"battle_id": "v092.test",
		"phase": "player_action",
		"round_number": 1,
		"max_rounds": 10,
		"enemy_pressure_bonus": 0,
		"player": {
			"actor_id": "player",
			"hp": 10,
			"max_hp": 10,
			"block": 0,
			"spirit": 9,
			"max_spirit": 9,
			"corruption": 0,
			"max_corruption": 10,
			"attention": 0,
			"max_attention": 10,
			"statuses": [],
		},
		"hand": hand,
		"draw_pile_count": 1,
		"discard_pile_count": 0,
		"enemies": enemies,
		"outcome": "",
		"outcome_reason": "",
	})


func _test_enemy() -> Dictionary:
	return {
		"actor_id": "enemy.test",
		"definition_id": "enemy.weeping_tenant",
		"lane_index": 0,
		"hp": 12,
		"max_hp": 12,
		"block": 0,
		"statuses": [],
		"intent": {
			"revealed": true,
			"visible_fields": {"kind": "attack", "damage": 2},
		},
	}


func _progression_snapshot(revision: int) -> ProgressionSnapshot:
	return ProgressionSnapshotScript.new({
		"revision": revision,
		"phase": "hub",
		"identity_id": "identity.reporter",
		"identity_options": [],
		"battle_modifiers": {},
		"divination_tickets": 5,
		"collection": [],
		"pity_counter": 0,
		"rare_pity": 4,
		"gacha_costs": {"single": 2, "triple": 5},
		"rarity_weights": {"common": 85, "rare": 15},
		"reward_options": [],
		"last_battle_outcome": "",
		"last_gacha_results": [],
	})


func _card_effect_text(definition: Dictionary) -> String:
	var parts: Array[String] = []
	for effect_value in definition.get("effects", []):
		if not effect_value is Dictionary:
			continue
		var effect: Dictionary = effect_value
		match String(effect.get("effect_id", "")):
			"damage":
				parts.append("造成 %d 伤害" % int(effect.get("amount", 0)))
			"block":
				parts.append("获得 %d 护盾" % int(effect.get("amount", 0)))
			"heal":
				parts.append("恢复 %d 生命" % int(effect.get("amount", 0)))
			"spirit":
				parts.append("获得 %d 灵性" % int(effect.get("amount", 0)))
			"draw":
				parts.append("抽 %d 张牌" % int(effect.get("count", 0)))
			"apply_status":
				parts.append("施加 %d 层%s" % [
					int(effect.get("stacks", 0)),
					_status_text(String(effect.get("status_id", ""))),
				])
			"remove_status":
				parts.append("移除%s" % _status_text(
					String(effect.get("status_id", ""))
				))
			"reveal_intent":
				parts.append("揭示敌人意图")
			"risk":
				parts.append("污染 %+d" % int(effect.get("amount", 0)))
			"discard":
				parts.append("弃置 %d 张牌" % int(effect.get("count", 0)))
			_:
				parts.append("特殊效果")
	return "；".join(parts)


func _status_text(status_id: String) -> String:
	match status_id:
		"mark":
			return "标记"
		"weaken":
			return "削弱"
		_:
			return "未知状态"


func _save_envelope(sequence: int, marker: String) -> Dictionary:
	return {
		"save_version": 5,
		"content_version": "v0.7.0",
		"created_at": "2026-11-08T00:00:00Z",
		"rng_seed": 20261108,
		"profile": {
			"pathway": "seer",
			"sequence": sequence,
			"identity_id": "identity.reporter",
		},
		"run": {
			"checkpoint_kind": "route",
			"marker": marker,
		},
		"collection": {},
		"progression": {
			"phase": "hub",
			"identity_id": "identity.reporter",
			"collection": {},
		},
		"route": {"phase": "map"},
		"challenge": {"phase": "inactive"},
		"deck": {
			"initialized": true,
			"state": {
				"current_card_ids": [],
				"presets": [],
				"confirmed": false,
			},
		},
	}


func _read_json_object(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parser := JSON.new()
	var parse_result := parser.parse(file.get_as_text())
	file.close()
	if parse_result != OK or not parser.data is Dictionary:
		return {}
	return parser.data


func _read_text(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var text_value := file.get_as_text()
	file.close()
	return text_value


func _write_text(path: String, text_value: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(text_value)
	file.flush()
	file.close()


func _wait_frames(count: int) -> void:
	for _index in range(count):
		await get_tree().process_frame


func _button_by_text(root: Node, text_value: String) -> Button:
	if root is Button and (root as Button).text == text_value:
		return root as Button
	for child in root.get_children():
		var found := _button_by_text(child, text_value)
		if found != null:
			return found
	return null


func _contains_label_text(root: Node, needle: String) -> bool:
	if root is Label and (root as Label).text.contains(needle):
		return true
	for child in root.get_children():
		if _contains_label_text(child, needle):
			return true
	return false


func _contains_internal_id(root: Node) -> bool:
	if root is Label:
		var text_value := (root as Label).text
		for prefix in [
			"card.",
			"enemy.",
			"identity.",
			"challenge.",
			"encounter.",
		]:
			if text_value.contains(prefix):
				return true
	for child in root.get_children():
		if _contains_internal_id(child):
			return true
	return false


func _expect(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
	else:
		_failures.append(message)


func _remove_tree(relative_path: String) -> void:
	var absolute_path := ProjectSettings.globalize_path(relative_path)
	if not DirAccess.dir_exists_absolute(absolute_path):
		return
	var directory := DirAccess.open(absolute_path)
	if directory == null:
		return
	for file_name in directory.get_files():
		DirAccess.remove_absolute(absolute_path.path_join(file_name))
	for child_name in directory.get_directories():
		_remove_tree(relative_path.path_join(child_name))
	DirAccess.remove_absolute(absolute_path)
