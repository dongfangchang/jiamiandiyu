extends Node

const AppRootScene := preload("res://src/app/app_root.tscn")

const TEST_ROOT := "user://mask_whispers_app_integration_v04"
const IDENTITY_ID := "identity.reporter"
const UPGRADE_CARD_ID := "card.skill.ink_dart"

var _checks := 0
var _failures: Array[String] = []
var _app: Control


func _ready() -> void:
	await get_tree().process_frame
	_remove_tree(TEST_ROOT)
	_app = AppRootScene.instantiate()
	_app.configure_for_testing(TEST_ROOT, "flow_slot", 424242)
	add_child(_app)
	await get_tree().process_frame

	await _test_start_route()
	await _test_new_campaign_identity()
	await _test_identity_to_hub()
	await _test_hub_to_real_battle()
	await _test_battle_to_reward()
	await _test_reward_and_gacha()
	await _test_upgrade_and_next_battle()
	await _test_checkpoint_continue()
	await _test_corrupt_checkpoint_state()

	_remove_tree(TEST_ROOT)
	_finish()


func _test_start_route() -> void:
	_expect(_app.get_current_route() == &"start", "app starts on start route")
	var start = _app.get_current_screen()
	_expect(start != null, "start screen is mounted")
	_expect(not start.is_continue_enabled(), "continue disabled without checkpoint")
	_expect(start.get_status_text().contains("尚未"), "start shows empty checkpoint state")
	await get_tree().process_frame


func _test_new_campaign_identity() -> void:
	_app.get_current_screen().new_game_requested.emit()
	await get_tree().process_frame
	await get_tree().process_frame
	_expect(_app.get_current_route() == &"identity", "new game routes to identity selection")
	_expect(_app.get_session() != null, "campaign session is retained")
	var snapshot = _app.get_progression_snapshot()
	_expect(snapshot != null and snapshot.data.get("phase", "") == "identity_selection", "progression is in identity phase")
	var screen = _app.get_current_screen()
	_expect(screen.get_selected_identity_id() == "", "identity screen starts without selection")
	screen.choose_identity(IDENTITY_ID)
	await get_tree().process_frame
	await get_tree().process_frame


func _test_identity_to_hub() -> void:
	_expect(_app.get_current_route() == &"hub", "identity selection routes to hub")
	var snapshot = _app.get_progression_snapshot()
	_expect(String(snapshot.data.get("identity_id", "")) == IDENTITY_ID, "selected identity persists in snapshot")
	_expect(String(snapshot.data.get("phase", "")) == "hub", "hub phase is active")
	var screen = _app.get_current_screen()
	_expect(screen.has_hub_actions(), "hub actions are available")
	screen.battle_requested.emit()
	await get_tree().process_frame
	await get_tree().process_frame


func _test_hub_to_real_battle() -> void:
	_expect(_app.get_current_route() == &"battle", "hub enters a real battle")
	var battle = _app.get_current_screen()
	_expect(battle.get_snapshot_data().size() > 0, "battle screen receives a real snapshot")
	_expect(
		String(battle.get_snapshot_data().get("battle_id", "")).contains("first_hunt"),
		"formal first-hunt encounter is active"
	)
	await _fight_until_finished()


func _test_battle_to_reward() -> void:
	_expect(_app.get_current_route() == &"reward", "victory routes from battle to reward")
	var screen = _app.get_current_screen()
	_expect(screen.get_option_count() == 2, "reward screen receives two choices")
	var snapshot = _app.get_progression_snapshot()
	_expect(String(snapshot.data.get("phase", "")) == "reward", "progression enters reward phase")


func _test_reward_and_gacha() -> void:
	var reward_screen = _app.get_current_screen()
	reward_screen.claim_reward("reward.ink_dart_fragments")
	await get_tree().process_frame
	await get_tree().process_frame
	_expect(_app.get_current_route() == &"hub", "reward claim routes back to hub")

	var hub = _app.get_current_screen()
	hub.gacha_requested.emit()
	await get_tree().process_frame
	await get_tree().process_frame
	_expect(_app.get_current_route() == &"gacha", "hub opens spirit-world gacha")
	var gacha = _app.get_current_screen()
	var tickets_before := int(_app.get_progression_snapshot().data.get("divination_tickets", 0))
	gacha.request_draw(1)
	await get_tree().process_frame
	await get_tree().process_frame
	var snapshot = _app.get_progression_snapshot()
	_expect(snapshot.data.get("last_gacha_results", []).size() == 1, "single draw produces one result")
	_expect(
		int(snapshot.data.get("divination_tickets", 0)) == tickets_before - 2,
		"single draw deducts two tickets"
	)
	_expect(gacha.get_result_count() == 1, "gacha screen displays one result")
	gacha.back_requested.emit()
	await get_tree().process_frame
	await get_tree().process_frame
	_expect(_app.get_current_route() == &"hub", "gacha returns to hub")


func _test_upgrade_and_next_battle() -> void:
	var hub = _app.get_current_screen()
	hub.upgrade_requested.emit()
	await get_tree().process_frame
	await get_tree().process_frame
	_expect(_app.get_current_route() == &"upgrade", "hub opens card upgrade screen")
	var upgrade = _app.get_current_screen()
	_expect(upgrade.get_card_row_count() > 0, "upgrade screen displays owned upgradeable cards")
	upgrade.request_upgrade(UPGRADE_CARD_ID)
	await get_tree().process_frame
	await get_tree().process_frame
	_expect(_collection_level(UPGRADE_CARD_ID) == 1, "ink dart upgrades to level one")
	upgrade.back_requested.emit()
	await get_tree().process_frame
	await get_tree().process_frame
	_expect(_app.get_current_route() == &"hub", "upgrade returns to hub")

	_app.get_current_screen().battle_requested.emit()
	await get_tree().process_frame
	await get_tree().process_frame
	_expect(_app.get_current_route() == &"battle", "hub starts the next battle")
	_expect(_collection_level(UPGRADE_CARD_ID) == 1, "upgraded level remains active in the next battle")


func _test_checkpoint_continue() -> void:
	_app.show_start_screen()
	await get_tree().process_frame
	var start = _app.get_current_screen()
	_expect(start.is_continue_enabled(), "checkpoint enables continue after the short loop")
	_expect(
		String(_app.get_last_checkpoint_summary().get("identity_id", "")) == IDENTITY_ID,
		"checkpoint summary preserves identity"
	)
	start.continue_requested.emit()
	await get_tree().process_frame
	await get_tree().process_frame
	_expect(_app.get_current_route() == &"hub", "continue restores the progression hub")
	_expect(_collection_level(UPGRADE_CARD_ID) == 1, "continue restores upgraded collection")


func _fight_until_finished() -> void:
	var commands_sent := 0
	for _round_index in 12:
		if _app.get_current_route() != &"battle":
			break
		var battle = _app.get_current_screen()
		var data: Dictionary = battle.get_snapshot_data()
		var hand: Array = data.get("hand", [])
		for card_value in hand.duplicate():
			if _app.get_current_route() != &"battle" or not card_value is Dictionary:
				break
			var card: Dictionary = card_value
			var instance_id := StringName(card.get("instance_id", ""))
			if instance_id.is_empty():
				continue
			battle.select_card_instance(instance_id)
			if String(card.get("target_type", "")) == "enemy":
				var target_id := _first_alive_enemy(battle.get_snapshot_data())
				if target_id.is_empty():
					break
				battle.select_target(target_id)
			battle.play_selected()
			commands_sent += 1
			await get_tree().process_frame
		if _app.get_current_route() != &"battle":
			break
		battle.end_turn()
		commands_sent += 1
		await get_tree().process_frame
		await get_tree().process_frame
	_expect(commands_sent > 0, "battle automation sent real UI commands")


func _first_alive_enemy(snapshot: Dictionary) -> StringName:
	for enemy_value in snapshot.get("enemies", []):
		if not enemy_value is Dictionary:
			continue
		var enemy: Dictionary = enemy_value
		if int(enemy.get("hp", 0)) > 0:
			return StringName(enemy.get("actor_id", ""))
	return &""


func _collection_level(definition_id: String) -> int:
	var snapshot = _app.get_progression_snapshot()
	if snapshot == null:
		return -1
	for card_value in snapshot.data.get("collection", []):
		if not card_value is Dictionary:
			continue
		if String(card_value.get("definition_id", "")) == definition_id:
			return int(card_value.get("level", 0))
	return -1


func _test_corrupt_checkpoint_state() -> void:
	var saves = AtomicSaveService.new(TEST_ROOT)
	var checkpoint_path: String = saves.get_slot_path("flow_slot")
	var file := FileAccess.open(checkpoint_path, FileAccess.WRITE)
	_expect(file != null, "integration test can prepare a corrupt checkpoint")
	if file == null:
		return
	file.store_string("{broken")
	file.close()

	_app.show_start_screen()
	await get_tree().process_frame
	var start = _app.get_current_screen()
	_expect(_app.get_current_route() == &"start", "corrupt checkpoint stays on start route")
	_expect(not start.is_continue_enabled(), "corrupt checkpoint disables continue")
	_expect(start.get_status_text().contains("无法读取"), "corrupt checkpoint is reported without overwrite")


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("APP_V04_INTEGRATION_OK checks=%d" % _checks)
		get_tree().quit(0)
		return
	for failure in _failures:
		printerr("APP_V04_INTEGRATION_FAIL %s" % failure)
	print("APP_V04_INTEGRATION_FAIL checks=%d failures=%d" % [_checks, _failures.size()])
	get_tree().quit(1)


func _remove_tree(path: String) -> void:
	var absolute_path := ProjectSettings.globalize_path(path)
	if not DirAccess.dir_exists_absolute(absolute_path):
		return
	var directory := DirAccess.open(absolute_path)
	if directory == null:
		return
	for file_name in directory.get_files():
		DirAccess.remove_absolute(absolute_path.path_join(file_name))
	for child_name in directory.get_directories():
		_remove_tree(path.path_join(child_name))
	DirAccess.remove_absolute(absolute_path)
