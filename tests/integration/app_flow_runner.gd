extends Node

const AppRootScene := preload("res://src/app/app_root.tscn")

const TEST_ROOT := "user://mask_whispers_app_integration_v05"
const IDENTITY_ID := "identity.reporter"
const UPGRADE_CARD_ID := "card.skill.ink_dart"
const FIRST_NODE := "route.v050.node.first_hunt"
const ELITE_NODE := "route.v050.node.mirror_pursuit"
const REST_NODE := "route.v050.node.old_house_rest"
const BOSS_NODE := "route.v050.node.mirror_baron"
const RITUAL_NODE := "route.v050.node.ascension"
const CHALLENGE_MODIFIER := "modifier.fractured_deck"

var _checks := 0
var _failures: Array[String] = []
var _app: Control


func _ready() -> void:
	await get_tree().process_frame
	_remove_tree(TEST_ROOT)
	_app = AppRootScene.instantiate()
	_app.configure_for_testing(TEST_ROOT, "flow_slot", 424242)
	add_child(_app)
	await _wait_frames(2)

	await _test_start_state()
	await _test_new_route_identity()
	await _advance_battle(FIRST_NODE, "first_hunt")
	await _claim_reward("reward.ink_dart_fragments")
	await _test_growth_between_nodes()
	await _advance_battle(ELITE_NODE, "mirror_pursuit")
	await _claim_reward("reward.divination_tickets")
	await _test_rest_boundary_restore()
	await _advance_battle(BOSS_NODE, "mirror_baron")
	await _claim_reward("reward.divination_tickets")
	await _test_ritual_and_sequence()
	await _test_completed_checkpoint_continue()
	await _test_challenge_flow()
	await _test_corrupt_checkpoint_state()

	_remove_tree(TEST_ROOT)
	_finish()


func _test_start_state() -> void:
	_expect(_app.get_current_route() == &"start", "app starts on start route")
	var start = _app.get_current_screen()
	_expect(start != null, "start screen is mounted")
	_expect(not start.is_continue_enabled(), "continue disabled without checkpoint")
	_expect(not start.is_challenge_enabled(), "challenge disabled before sequence eight")
	_expect(start.get_status_text().contains("尚未"), "start reports no local checkpoint")
	await _wait_frames(1)


func _test_new_route_identity() -> void:
	_app.get_current_screen().new_game_requested.emit()
	await _wait_frames(3)
	_expect(
		_app.get_current_route() == &"route_select",
		"new game routes to route selection"
	)
	_app.get_current_screen().choose_route("route.v070.first_case")
	await _wait_frames(3)
	_expect(_app.get_current_route() == &"identity", "route choice routes to identity selection")
	_expect(_app.get_session() != null, "route session is retained")
	var progression = _app.get_progression_snapshot()
	_expect(
		progression != null and progression.data.get("phase", "") == "identity_selection",
		"progression starts in identity selection"
	)
	_app.get_current_screen().choose_identity(IDENTITY_ID)
	await _wait_frames(3)
	_expect(_app.get_current_route() == &"map", "identity selection enters route map")
	var route = _app.get_route_snapshot()
	_expect(route != null and route.data.get("nodes", []).size() == 5, "route map exposes five fixed nodes")
	_expect(
		String(route.data.get("available_node_id", "")) == FIRST_NODE,
		"first hunt is the first available node"
	)


func _advance_battle(node_id: String, encounter_fragment: String) -> void:
	var route_screen = _app.get_current_screen()
	_expect(_app.get_current_route() == &"map", "route map is active before %s" % node_id)
	route_screen.request_node(node_id)
	await _wait_frames(3)
	_expect(_app.get_current_route() == &"battle", "node %s starts a real battle" % node_id)
	var battle = _app.get_current_screen()
	var battle_id := String(battle.get_snapshot_data().get("battle_id", ""))
	_expect(battle_id.contains(encounter_fragment), "battle uses encounter %s" % encounter_fragment)
	await _fight_until_finished()
	_expect(_app.get_current_route() == &"reward", "victory from %s enters reward phase" % node_id)


func _claim_reward(
	reward_id: String,
	expected_route: StringName = &"map"
) -> void:
	_expect(_app.get_current_route() == &"reward", "reward screen active before claim")
	var screen = _app.get_current_screen()
	_expect(screen.get_option_count() == 2, "reward screen exposes two choices")
	screen.claim_reward(reward_id)
	await _wait_frames(3)
	if not expected_route.is_empty():
		_expect(
			_app.get_current_route() == expected_route,
			"claimed reward returns to %s" % String(expected_route)
		)


func _test_growth_between_nodes() -> void:
	var route_screen = _app.get_current_screen()
	route_screen.hub_requested.emit()
	await _wait_frames(3)
	_expect(_app.get_current_route() == &"hub", "route hub opens the identity/growth hub")
	var hub = _app.get_current_screen()
	hub.gacha_requested.emit()
	await _wait_frames(3)
	_expect(_app.get_current_route() == &"gacha", "hub opens spirit-world gacha")
	var gacha = _app.get_current_screen()
	var tickets_before := int(_app.get_progression_snapshot().data.get("divination_tickets", 0))
	gacha.request_draw(1)
	await _wait_frames(3)
	_expect(gacha.get_result_count() == 1, "single draw displays one result")
	_expect(
		int(_app.get_progression_snapshot().data.get("divination_tickets", 0))
		== tickets_before - 2,
		"single draw deducts two tickets"
	)
	gacha.back_requested.emit()
	await _wait_frames(3)
	_expect(_app.get_current_route() == &"hub", "gacha returns to identity hub")
	_app.get_current_screen().upgrade_requested.emit()
	await _wait_frames(3)
	_expect(_app.get_current_route() == &"upgrade", "hub opens card upgrade")
	var upgrade = _app.get_current_screen()
	upgrade.request_upgrade(UPGRADE_CARD_ID)
	await _wait_frames(3)
	_expect(_collection_level(UPGRADE_CARD_ID) >= 1, "ink dart upgrade is persisted")
	upgrade.back_requested.emit()
	await _wait_frames(3)
	_expect(_app.get_current_route() == &"hub", "upgrade returns to hub")
	_app.get_current_screen().battle_requested.emit()
	await _wait_frames(3)
	_expect(_app.get_current_route() == &"map", "hub battle action returns to the active route")
	_expect(
		String(_app.get_route_snapshot().data.get("available_node_id", "")) == ELITE_NODE,
		"next route node is the mirror pursuit elite"
	)


func _test_rest_boundary_restore() -> void:
	var route_screen = _app.get_current_screen()
	route_screen.request_node(REST_NODE)
	await _wait_frames(3)
	_expect(_app.get_current_route() == &"rest", "rest node opens the rest screen")
	_expect(_app.get_current_screen().get_option_count() == 2, "rest exposes two choices")

	_app.show_start_screen()
	await _wait_frames(2)
	var start = _app.get_current_screen()
	_expect(start.is_continue_enabled(), "rest checkpoint enables continue")
	_expect(
		String(_app.get_last_checkpoint_summary().get("current_node_id", "")) == REST_NODE,
		"checkpoint summary records the rest node"
	)
	start.continue_requested.emit()
	await _wait_frames(4)
	_expect(_app.get_current_route() == &"rest", "continue restores the rest screen")
	_expect(_app.get_current_screen().get_option_count() == 2, "restored rest screen keeps choices")
	_app.get_current_screen().select_rest("rest.seal_echo")
	await _wait_frames(3)
	_expect(_app.get_current_route() == &"map", "rest selection advances to boss route map")
	_expect(
		String(_app.get_route_snapshot().data.get("available_node_id", "")) == BOSS_NODE,
		"boss becomes available after rest"
	)


func _test_ritual_and_sequence() -> void:
	var route_screen = _app.get_current_screen()
	route_screen.request_node(RITUAL_NODE)
	await _wait_frames(3)
	_expect(_app.get_current_route() == &"ritual", "boss completion unlocks ascension ritual")

	_app.get_current_screen().request_cancel()
	await _wait_frames(3)
	_expect(_app.get_current_route() == &"map", "cancelled ritual returns to route map")
	_app.get_current_screen().request_node(RITUAL_NODE)
	await _wait_frames(3)
	_expect(_app.get_current_route() == &"ritual", "ritual can be re-entered after cancel")

	var ritual = _app.get_current_screen()
	ritual.select_option("name.mira_finch")
	ritual.select_option("name.elin_ward")
	ritual.submit_step()
	await _wait_frames(3)
	_expect(_app.get_current_route() == &"ritual", "wrong ritual step keeps the ritual open")
	_expect(_app.get_ritual_snapshot().data.get("errors", 0) == 1, "wrong step records one error")
	_expect(_app.get_ritual_snapshot().data.get("corruption", 0) >= 2, "wrong step adds corruption")

	await _submit_ritual(["name.elin_ward", "name.thomas_ward"])
	await _submit_ritual(["event.birth", "event.death", "event.burial"])
	await _submit_ritual(["seal.inverted_eye"])
	_expect(_app.get_current_route() == &"route_result", "completed ritual opens route result")
	var route = _app.get_route_snapshot()
	_expect(route.data.get("route_outcome", "") == "completed", "route outcome is completed")
	var sequence = _app.get_session().get_sequence_state().data
	_expect(int(sequence.get("current_sequence", 0)) == 8, "sequence advances to eight")
	_expect(String(sequence.get("next_sequence_name_zh", "")) == "小丑", "sequence name is Clown")


func _submit_ritual(selections: Array[String]) -> void:
	var ritual = _app.get_current_screen()
	for selection in selections:
		ritual.select_option(selection)
	ritual.submit_step()
	await _wait_frames(3)


func _test_completed_checkpoint_continue() -> void:
	_expect(_app.get_current_route() == &"route_result", "completed route result is visible")
	_expect(_app.get_current_screen().get_title_text() == "晋升完成", "result title reports ascension")
	_app.show_start_screen()
	await _wait_frames(2)
	var start = _app.get_current_screen()
	_expect(start.is_continue_enabled(), "completed route checkpoint enables continue")
	var summary = _app.get_last_checkpoint_summary()
	_expect(String(summary.get("checkpoint_kind", "")) == "route", "checkpoint kind is route")
	_expect(int(summary.get("sequence", 0)) == 8, "checkpoint summary stores sequence eight")
	start.continue_requested.emit()
	await _wait_frames(4)
	_expect(_app.get_current_route() == &"route_result", "continue restores completed route result")
	var sequence = _app.get_session().get_sequence_state().data
	_expect(int(sequence.get("current_sequence", 0)) == 8, "continued session keeps sequence eight")


func _test_challenge_flow() -> void:
	_app.show_start_screen()
	await _wait_frames(2)
	var start = _app.get_current_screen()
	_expect(start.is_challenge_enabled(), "sequence eight unlocks the challenge entry")
	_expect(start.get_challenge_hint_text().contains("已解锁"), "challenge entry reports unlocked")
	start.challenge_requested.emit()
	await _wait_frames(4)
	_expect(_app.get_current_route() == &"challenge_select", "challenge opens modifier selection")
	var challenge_screen = _app.get_current_screen()
	_expect(challenge_screen.get_modifier_count() == 3, "challenge exposes three modifiers")
	_expect(challenge_screen.get_requirement_text().contains("已解锁"), "challenge selection confirms unlock")
	challenge_screen.request_modifier(CHALLENGE_MODIFIER)
	await _wait_frames(3)
	_expect(
		challenge_screen.get_selected_modifier_id() == CHALLENGE_MODIFIER,
		"selected challenge modifier is retained"
	)
	var tickets_before := int(
		_app.get_progression_snapshot().data.get("divination_tickets", 0)
	)
	challenge_screen.request_start()
	await _wait_frames(4)
	_expect(_app.get_current_route() == &"map", "starting challenge enters its route map")
	_expect(
		_app.get_current_screen().get_challenge_context_text().contains("镜厅余响"),
		"challenge route displays challenge context"
	)
	_expect(
		String(_app.get_route_snapshot().data.get("available_node_id", ""))
		== FIRST_NODE,
		"challenge starts at the first route node"
	)

	await _advance_battle(FIRST_NODE, "first_hunt")
	await _claim_reward("reward.ink_dart_fragments")
	await _advance_battle(ELITE_NODE, "mirror_pursuit")
	await _claim_reward("reward.divination_tickets")
	var route_screen = _app.get_current_screen()
	route_screen.request_node(REST_NODE)
	await _wait_frames(3)
	_expect(_app.get_current_route() == &"rest", "challenge reaches rest node")
	_app.get_current_screen().select_rest("rest.bandage")
	await _wait_frames(3)
	await _advance_battle(BOSS_NODE, "mirror_baron")
	await _claim_reward("reward.divination_tickets")
	route_screen = _app.get_current_screen()
	route_screen.request_node(RITUAL_NODE)
	await _wait_frames(3)
	await _submit_ritual(["name.elin_ward", "name.thomas_ward"])
	await _submit_ritual(["event.birth", "event.death", "event.burial"])
	await _submit_ritual(["seal.inverted_eye"])
	_expect(_app.get_current_route() == &"challenge_result", "challenge completion opens challenge result")
	var challenge = _app.get_session().get_challenge_snapshot()
	_expect(
		challenge.data.get("challenge_outcome", "") == "completed",
		"challenge outcome is completed"
	)
	_expect(
		bool(challenge.data.get("unlocked", false)),
		"completed challenge remains unlocked"
	)
	_expect(
		int(_app.get_progression_snapshot().data.get("divination_tickets", 0))
		>= tickets_before + 2,
		"challenge completion reward is applied once"
	)
	_expect(
		_app.get_current_screen().get_title_text() == "挑战完成",
		"challenge result displays success"
	)

	_app.show_start_screen()
	await _wait_frames(2)
	start = _app.get_current_screen()
	_expect(start.is_continue_enabled(), "completed challenge checkpoint can continue")
	start.continue_requested.emit()
	await _wait_frames(4)
	_expect(_app.get_current_route() == &"challenge_result", "continue restores challenge result")
	_app.get_current_screen().retry_requested.emit()
	await _wait_frames(4)
	_expect(_app.get_current_route() == &"challenge_select", "retry starts fresh challenge selection")
	_expect(
		String(_app.get_session().get_challenge_snapshot().data.get("phase", ""))
		== "modifier_selection",
		"retry does not resume completed challenge"
	)
	challenge_screen = _app.get_current_screen()
	challenge_screen.request_modifier("modifier.tainted_margins")
	await _wait_frames(3)
	challenge_screen.request_start()
	await _wait_frames(4)
	await _advance_battle(FIRST_NODE, "first_hunt")
	await _claim_reward("reward.ink_dart_fragments")
	await _advance_battle(ELITE_NODE, "mirror_pursuit")
	await _claim_reward("reward.divination_tickets")
	route_screen = _app.get_current_screen()
	route_screen.request_node(REST_NODE)
	await _wait_frames(3)
	_app.get_current_screen().select_rest("rest.bandage")
	await _wait_frames(3)
	await _advance_battle(BOSS_NODE, "mirror_baron")
	await _claim_reward("reward.divination_tickets", &"challenge_result")
	_expect(
		_app.get_current_route() == &"challenge_result",
		"tainted challenge failure after reward routes to challenge result"
	)
	challenge = _app.get_session().get_challenge_snapshot()
	_expect(
		challenge.data.get("challenge_outcome", "") == "failed",
		"tainted challenge records failure"
	)
	_expect(
		_app.get_current_screen().get_title_text() == "挑战中断",
		"challenge result displays failure"
	)
	_app.get_current_screen().retry_requested.emit()
	await _wait_frames(4)
	_expect(_app.get_current_route() == &"challenge_select", "failed challenge can retry")
	_app.get_current_screen().exit_requested.emit()
	await _wait_frames(2)
	_expect(_app.get_current_route() == &"start", "challenge selection can return to start")


func _fight_until_finished() -> void:
	var commands_sent := 0
	for _round_index in 15:
		if _app.get_current_route() != &"battle":
			break
		var battle = _app.get_current_screen()
		var data: Dictionary = battle.get_snapshot_data()
		var hand: Array = data.get("hand", []).duplicate()
		for card_value in hand:
			if _app.get_current_route() != &"battle" or not card_value is Dictionary:
				break
			var card: Dictionary = card_value
			var instance_id := StringName(card.get("instance_id", ""))
			if instance_id.is_empty():
				continue
			var target_id: StringName = &""
			if String(card.get("target_type", "")) == "enemy":
				target_id = _lowest_health_enemy(battle.get_snapshot_data())
				if target_id.is_empty():
					continue
			var playability = _app.get_session().query_card_play(instance_id, target_id)
			if playability == null or not playability.playable:
				continue
			battle.select_card_instance(instance_id)
			if not target_id.is_empty():
				battle.select_target(target_id)
			battle.play_selected()
			commands_sent += 1
			await get_tree().process_frame
		if _app.get_current_route() != &"battle":
			break
		battle.end_turn()
		commands_sent += 1
		await _wait_frames(3)
	_expect(commands_sent > 0, "battle automation sent real UI commands")


func _lowest_health_enemy(snapshot: Dictionary) -> StringName:
	var selected_id: StringName = &""
	var selected_hp := 2147483647
	for enemy_value in snapshot.get("enemies", []):
		if not enemy_value is Dictionary:
			continue
		var enemy: Dictionary = enemy_value
		var hp := int(enemy.get("hp", 0))
		if hp > 0 and hp < selected_hp:
			selected_hp = hp
			selected_id = StringName(enemy.get("actor_id", ""))
	return selected_id


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
	await _wait_frames(2)
	var start = _app.get_current_screen()
	_expect(_app.get_current_route() == &"start", "corrupt checkpoint stays on start route")
	_expect(not start.is_continue_enabled(), "corrupt checkpoint disables continue")
	_expect(start.get_status_text().contains("无法读取"), "corrupt checkpoint is reported without overwrite")


func _wait_frames(count: int) -> void:
	for _index in count:
		await get_tree().process_frame


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("APP_V06_INTEGRATION_OK checks=%d" % _checks)
		get_tree().quit(0)
		return
	for failure in _failures:
		printerr("APP_V05_INTEGRATION_FAIL %s" % failure)
	print("APP_V06_INTEGRATION_FAIL checks=%d failures=%d" % [_checks, _failures.size()])
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
