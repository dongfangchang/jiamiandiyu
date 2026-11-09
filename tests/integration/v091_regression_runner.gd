extends Node

const BattleScreenScene := preload("res://scenes/ui/battle_screen.tscn")
const GachaScreenScene := preload("res://scenes/ui/gacha_screen.tscn")
const RouteResultScene := preload("res://scenes/ui/route_result_screen.tscn")
const BattleSnapshotScript := preload("res://src/core/battle_snapshot.gd")
const BattleCommandResultScript := preload("res://src/core/battle_command_result.gd")
const BattleEventScript := preload("res://src/core/battle_event.gd")
const BattlePlayabilityScript := preload("res://src/core/battle_playability.gd")
const ProgressionSnapshotScript := preload("res://src/core/progression_snapshot.gd")
const ProgressionCommandResultScript := preload(
	"res://src/core/progression_command_result.gd"
)
const RouteSnapshotScript := preload("res://src/core/route_snapshot.gd")
const AppBootstrapScript := preload("res://src/app/bootstrap.gd")

const TEST_ROOT := "user://mask_whispers_v091_regression"

var _passed := 0
var _failures: Array[String] = []


func _ready() -> void:
	_remove_tree(TEST_ROOT)
	await _test_battle_readability_and_exit()
	await _test_gacha_exit_during_pending()
	await _test_route_failure_reason()
	_test_profile()
	_remove_tree(TEST_ROOT)
	if _failures.is_empty():
		print("V091_REGRESSION_OK checks=%d" % _passed)
		get_tree().quit(0)
		return
	for failure in _failures:
		printerr("V091_REGRESSION_FAIL: %s" % failure)
	get_tree().quit(1)


func _test_battle_readability_and_exit() -> void:
	var screen = BattleScreenScene.instantiate()
	add_child(screen)
	screen.configure(
		"雨夜测试",
		{&"card.skill.coffin_nail": "棺钉"},
		{&"enemy.weeping_tenant": "哭泣的房客"},
		func(_card_id: StringName, _target_id: StringName) -> BattlePlayability:
			return BattlePlayabilityScript.new(
				true,
				BattlePlayability.PLAYABLE
			),
		{
			"card.skill.coffin_nail": {
				"name": "棺钉",
				"description": "钉住敌人。",
				"effect_text": "造成 6 伤害；施加 2 层标记",
				"level": 1,
			},
		}
	)
	screen.apply_snapshot(_battle_snapshot())
	await get_tree().process_frame
	_expect(
		not String(screen.get_card_art_path(&"card.skill.coffin_nail")).is_empty(),
		"new cards must have battle art"
	)
	for definition_id in [
		"card.skill.warding_circle",
		"card.skill.lantern_step",
		"card.skill.whispered_hunch",
		"card.skill.mirrored_memory",
		"card.skill.fated_echo",
		"card.skill.piercing_omen",
		"card.skill.coffin_nail",
		"card.skill.second_sight",
	]:
		_expect(
			ResourceLoader.exists(screen.get_card_art_path(StringName(definition_id))),
			"all v0.7 cards must have a battle image: %s" % definition_id
		)
	_expect(
		_contains_label_text(screen, "造成 6 伤害"),
		"battle hand must display card effects"
	)
	_expect(
		not _contains_internal_id(screen),
		"battle interface must not expose internal English IDs"
	)
	var command_events := [0]
	screen.command_requested.connect(func(_command: BattleCommand) -> void:
		command_events[0] += 1
	)
	screen.select_card_instance(&"test.coffin_nail.001")
	var target_button := _button_named(screen, "TargetButton")
	_expect(
		target_button != null and not target_button.disabled,
		"enemy cards should highlight valid targets"
	)
	screen.select_target(&"enemy.test")
	screen.play_selected()
	screen.play_selected()
	_expect(
		command_events[0] == 1,
		"rapid duplicate card clicks must submit only one command"
	)
	var exit_events := [0]
	screen.exit_requested.connect(func() -> void:
		exit_events[0] += 1
	)
	screen.call("_request_exit")
	_expect(
		bool(screen.is_exit_confirmation_visible()),
		"battle exit should require confirmation"
	)
	var dialog: ConfirmationDialog = screen.get("_exit_confirmation")
	dialog.emit_signal("confirmed")
	_expect(exit_events[0] == 1, "confirmed battle exit should emit once")

	var damage_event := BattleEventScript.new(&"DamageApplied", {
		"target_id": "player",
		"amount": 4,
		"hp_before": 10,
		"hp_after": 6,
	})
	var result := BattleCommandResultScript.new(
		true,
		&"ok",
		[damage_event],
		_battle_snapshot()
	)
	screen.apply_command_result(result)
	_expect(
		int(screen.get_visual_effect_count()) > 0,
		"damage should produce a visual feedback effect"
	)
	var ended_snapshot_data := _battle_snapshot().to_dictionary()
	ended_snapshot_data["outcome"] = "victory"
	ended_snapshot_data["outcome_reason"] = "enemies_defeated"
	var finished_count := [0]
	screen.battle_finished.connect(func(_snapshot: BattleSnapshot) -> void:
		finished_count[0] += 1
	)
	var finished_result := BattleCommandResultScript.new(
		true,
		&"ok",
		[],
		BattleSnapshotScript.new(ended_snapshot_data)
	)
	screen.apply_command_result(finished_result)
	screen.apply_command_result(finished_result)
	_expect(
		finished_count[0] == 1,
		"battle finish must emit exactly once"
	)
	screen.queue_free()
	await get_tree().process_frame


func _test_gacha_exit_during_pending() -> void:
	var screen = GachaScreenScene.instantiate()
	add_child(screen)
	screen.configure({
		"card.skill.coffin_nail": "棺钉",
	})
	var back_events := [0]
	var draw_events := [0]
	screen.back_requested.connect(func() -> void:
		back_events[0] += 1
	)
	screen.draw_requested.connect(func(_count: int) -> void:
		draw_events[0] += 1
	)
	screen.apply_snapshot(ProgressionSnapshotScript.new({
		"revision": 2,
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
	}))
	var refreshed_snapshot := ProgressionSnapshotScript.new({
		"revision": 3,
		"phase": "hub",
		"identity_id": "identity.reporter",
		"identity_options": [],
		"battle_modifiers": {},
		"divination_tickets": 3,
		"collection": [],
		"pity_counter": 1,
		"rare_pity": 4,
		"gacha_costs": {"single": 2, "triple": 5},
		"rarity_weights": {"common": 85, "rare": 15},
		"reward_options": [],
		"last_battle_outcome": "",
		"last_gacha_results": [{
			"definition_id": "card.skill.coffin_nail",
			"rarity": "rare",
			"duplicate": false,
			"fragments": 0,
		}],
	})
	screen.apply_command_result(ProgressionCommandResultScript.new(
		true,
		&"ok",
		[],
		refreshed_snapshot
	))
	_expect(
		int(screen.get_result_count()) == 1,
		"gacha result should refresh immediately after a successful draw"
	)
	_expect(
		String(screen.get_card_name("card.skill.coffin_nail")) == "棺钉",
		"gacha result should show the Chinese card name"
	)
	screen.request_draw(1)
	screen.request_draw(1)
	_expect(
		draw_events[0] == 1,
		"gacha must ignore duplicate requests while pending"
	)
	var back_button: Button = screen.get("_back_button")
	_expect(
		not back_button.disabled,
		"gacha back button must remain enabled while pending"
	)
	screen.call("_on_back")
	_expect(back_events[0] == 1, "gacha exit should emit during pending")
	_expect(not bool(screen.is_pending()), "gacha exit should clear pending")
	screen.apply_snapshot(refreshed_snapshot)
	_expect(screen.get_result_count() == 0, "reentering gacha must not replay persisted results")
	_expect(refreshed_snapshot.data.last_gacha_results.size() == 1, "clearing presentation must preserve settlement history")
	screen.queue_free()
	await get_tree().process_frame


func _test_route_failure_reason() -> void:
	var screen = RouteResultScene.instantiate()
	add_child(screen)
	screen.show_result(RouteSnapshotScript.new({
		"display_name_zh": "廷根旧宅调查",
		"route_outcome": "failed",
		"end_reason": "battle_defeat",
		"completed_node_ids": ["node.one"],
		"nodes": [{"id": "node.one"}, {"id": "node.two"}],
		"sequence": {"current_sequence": 9},
		"run_state": {
			"hp": 0,
			"max_hp": 54,
			"corruption": 2,
			"max_corruption": 10,
			"attention": 1,
			"max_attention": 10,
		},
	}), "saved")
	_expect(
		String(screen.get_title_text()).contains("探索失败"),
		"route failure should use a clear title"
	)
	var detail: Label = screen.get("_detail_label")
	_expect(
		detail.text.contains("战斗中生命降至 0"),
		"route failure should show the exact reason"
	)
	var retry_events := [0]
	screen.retry_requested.connect(func() -> void:
		retry_events[0] += 1
	)
	var retry_button: Button = screen.get("_retry_button")
	_expect(
		retry_button != null and not retry_button.disabled,
		"failed route should expose retry"
	)
	if retry_button != null:
		retry_button.pressed.emit()
	_expect(retry_events[0] == 1, "route retry should emit once")
	screen.queue_free()
	await get_tree().process_frame


func _test_profile() -> void:
	var started = AppBootstrapScript.start_route_v07(
		20261108,
		{
			"save_directory": TEST_ROOT.path_join("saves"),
			"test_profile": true,
		},
		"test_checkpoint",
		false
	)
	_expect(started.ok, "test profile should start")
	if not started.ok:
		return
	var progression = started.data.get_progression_snapshot()
	var owned_count := 0
	for card_value in progression.data.get("collection", []):
		if int(card_value.get("copies", 0)) > 0:
			owned_count += 1
	_expect(owned_count == 40, "test profile should own all forty cards")
	_expect(
		int(progression.data.get("divination_tickets", 0)) >= 99,
		"test profile should provide sufficient tickets"
	)
	for card_value in progression.data.get("collection", []):
		if int(card_value.get("copies", 0)) <= 0:
			continue
		var definition_id := StringName(card_value.get("definition_id", ""))
		var display_name: String = started.data.card_display_name(definition_id)
		_expect(
			display_name != String(definition_id)
			and not display_name.contains("card.skill."),
			"test profile must resolve every card to a Chinese display name"
		)
	var preserved_progression: Dictionary = (
		started.data.progression.export_persistent_state()
	)
	preserved_progression["phase"] = "hub"
	preserved_progression["reward_option_ids"] = []
	var preserved_deck: Dictionary = (
		started.data.deck_engine.export_persistent_state()
	)
	var retry = AppBootstrapScript.start_route_v07(
		20261109,
		{
			"save_directory": TEST_ROOT.path_join("saves"),
			"progression_state": preserved_progression,
			"deck_state": preserved_deck,
		},
		"retry_checkpoint",
		false
	)
	_expect(retry.ok, "failed route retry state should initialize")
	if retry.ok:
		var retry_collection := 0
		for card_value in retry.data.get_progression_snapshot().data.get(
			"collection",
			[]
		):
			if int(card_value.get("copies", 0)) > 0:
				retry_collection += 1
		_expect(
			retry_collection == 40,
			"route retry must preserve collection and upgrades"
		)
	var challenge = AppBootstrapScript.start_challenge_v07(
		20261110,
		{
			"save_directory": TEST_ROOT.path_join("saves"),
			"test_profile": true,
			"challenge_id": "challenge.v070.broken_procession",
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
		"test_challenge_checkpoint",
		false,
		true
	)
	_expect(challenge.ok, "test profile should open the second challenge")
	if challenge.ok:
		_expect(
			bool(challenge.data.get_challenge_snapshot().data.get(
				"unlocked",
				false
			)),
			"test profile should unlock the second challenge"
		)


func _battle_snapshot() -> BattleSnapshot:
	return BattleSnapshotScript.new({
		"revision": 1,
		"battle_id": "test.battle",
		"phase": "player_action",
		"round_number": 1,
		"max_rounds": 10,
		"enemy_pressure_bonus": 0,
		"player": {
			"actor_id": "player",
			"hp": 10,
			"max_hp": 10,
			"block": 0,
			"spirit": 3,
			"max_spirit": 3,
			"corruption": 0,
			"max_corruption": 10,
			"attention": 0,
			"max_attention": 10,
			"statuses": [],
		},
		"hand": [{
			"instance_id": "test.coffin_nail.001",
			"definition_id": "card.skill.coffin_nail",
			"category": "skill",
			"cost_spirit": 2,
			"target_type": "enemy",
		}],
		"draw_pile_count": 4,
		"discard_pile_count": 0,
		"enemies": [{
			"actor_id": "enemy.test",
			"definition_id": "enemy.weeping_tenant",
			"lane_index": 0,
			"hp": 12,
			"max_hp": 12,
			"block": 0,
			"statuses": [],
			"intent": {"revealed": false, "visible_fields": {}},
		}],
		"outcome": "",
		"outcome_reason": "",
	})


func _contains_label_text(root: Node, needle: String) -> bool:
	if root is Label and (root as Label).text.contains(needle):
		return true
	for child in root.get_children():
		if _contains_label_text(child, needle):
			return true
	return false


func _button_named(root: Node, node_name: String) -> Button:
	if root is Button and root.name == node_name:
		return root as Button
	for child in root.get_children():
		var found := _button_named(child, node_name)
		if found != null:
			return found
	return null


func _contains_internal_id(root: Node) -> bool:
	if root is Label:
		var text_value := (root as Label).text
		if (
			text_value.contains("card.skill.")
			or text_value.contains("enemy.")
			or text_value.contains("identity.")
		):
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
