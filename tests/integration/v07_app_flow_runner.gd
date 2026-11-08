extends Node

const AppRootScene := preload("res://src/app/app_root.tscn")

const TEST_ROOT := "user://mask_whispers_app_integration_v07"
const IDENTITY_ID := "identity.reporter"
const UPGRADE_CARD_ID := "card.skill.ink_dart"
const FIRST_NODE := "route.v070.node.first_hunt"
const ELITE_NODE := "route.v070.node.mirror_pursuit"
const REST_NODE := "route.v070.node.old_house_rest"
const BOSS_NODE := "route.v070.node.mirror_baron"
const RITUAL_NODE := "route.v070.node.ascension"
const SECOND_FIRST_NODE := "route.v070.broken.node.first_hunt"
const SECOND_ELITE_NODE := "route.v070.broken.node.twin_pursuit"
const SECOND_REST_NODE := "route.v070.broken.node.old_house_rest"
const SECOND_BOSS_NODE := "route.v070.broken.node.mirror_baron"
const SECOND_RITUAL_NODE := "route.v070.broken.node.ascension"
const FIRST_CHALLENGE := "challenge.v060.mirror_echoes"
const SECOND_CHALLENGE := "challenge.v070.broken_procession"

var _checks := 0
var _failures: Array[String] = []
var _app: Control


func _ready() -> void:
	await get_tree().process_frame
	_remove_tree(TEST_ROOT)
	_app = AppRootScene.instantiate()
	_app.configure_for_testing(TEST_ROOT, "v07_flow", 424242)
	add_child(_app)
	await _wait_frames(2)

	await _test_start_state()
	await _test_identity_and_deck()
	await _test_unconfirmed_deck_resume()
	await _run_first_route()
	await _test_growth_and_upgrade()
	await _run_first_route_tail()
	await _test_first_challenge_and_second_unlock()
	await _run_first_challenge()
	await _run_second_challenge()
	await _test_corrupt_checkpoint_state()

	_remove_tree(TEST_ROOT)
	_finish()


func _test_start_state() -> void:
	_expect(_app.get_current_route() == &"start", "app starts on the v0.7 start route")
	var start = _app.get_current_screen()
	_expect(start != null, "start screen is mounted")
	_expect(not start.is_continue_enabled(), "continue is disabled without a checkpoint")
	_expect(not start.is_challenge_enabled(), "challenge is disabled before sequence eight")
	await _wait_frames(1)


func _test_identity_and_deck() -> void:
	_app.get_current_screen().new_game_requested.emit()
	await _wait_frames(3)
	_expect(
		_app.get_current_route() == &"route_select",
		"new game opens route selection"
	)
	_app.get_current_screen().choose_route("route.v070.first_case")
	await _wait_frames(3)
	_expect(_app.get_current_route() == &"identity", "route choice opens identity selection")
	_app.get_current_screen().choose_identity(IDENTITY_ID)
	await _wait_frames(3)
	_expect(_app.get_current_route() == &"deck", "identity selection opens the deck editor")
	var deck = _app.get_current_screen()
	_expect(deck.get_total_card_count() == 20, "deck editor exposes the twenty-card pool")
	_expect(deck.get_preset_count() == 3, "deck editor exposes three presets")
	_expect(deck.get_current_deck_count() == 8, "default deck contains eight unique cards")
	_expect(deck.is_confirm_enabled(), "default deck is immediately confirmable")
	var first_id := String(
		_app.get_deck_snapshot().data.get("current_card_ids", [])[0]
	)
	deck.request_remove_card(first_id)
	await _wait_frames(2)
	_expect(deck.get_current_deck_count() == 7, "removing a card produces a seven-card deck")
	_expect(not deck.is_confirm_enabled(), "incomplete deck disables confirmation")
	deck.request_add_card(first_id)
	await _wait_frames(2)
	_expect(deck.get_current_deck_count() == 8, "removed unique card can be added back")
	deck.request_confirm_deck()
	await _wait_frames(3)
	_expect(_app.get_current_route() == &"hub", "confirmed deck returns to the identity hub")
	_expect(bool(_app.get_deck_snapshot().data.get("confirmed", false)), "deck snapshot records confirmation")


func _test_unconfirmed_deck_resume() -> void:
	var hub = _app.get_current_screen()
	_expect(hub.get_deck_summary_text().contains("8 / 8"), "hub displays the confirmed deck size")
	hub.deck_requested.emit()
	await _wait_frames(2)
	_expect(_app.get_current_route() == &"deck", "hub opens the deck editor")
	var deck = _app.get_current_screen()
	var first_id := String(
		_app.get_deck_snapshot().data.get("current_card_ids", [])[0]
	)
	deck.request_remove_card(first_id)
	await _wait_frames(2)
	deck.request_back()
	await _wait_frames(2)
	_expect(_app.get_current_route() == &"hub", "back from deck editing returns to hub")
	_app.show_start_screen()
	await _wait_frames(2)
	var start = _app.get_current_screen()
	_expect(start.is_continue_enabled(), "unconfirmed deck checkpoint can be continued")
	_expect(not start.is_challenge_enabled(), "challenge entry is blocked until deck confirmation")
	start.continue_requested.emit()
	await _wait_frames(4)
	_expect(_app.get_current_route() == &"deck", "continue restores the unconfirmed deck phase")
	deck = _app.get_current_screen()
	deck.request_add_card(first_id)
	await _wait_frames(2)
	deck.request_confirm_deck()
	await _wait_frames(3)
	_expect(_app.get_current_route() == &"hub", "reconfirmed deck returns to the hub")
	_app.get_current_screen().battle_requested.emit()
	await _wait_frames(3)
	_expect(_app.get_current_route() == &"map", "hub enters the v0.7 route map")


func _run_first_route() -> void:
	await _advance_battle(FIRST_NODE, "first_hunt")
	await _claim_reward("reward.ink_dart_fragments")
	await _advance_battle(ELITE_NODE, "mirror_pursuit")
	await _claim_reward("reward.divination_tickets")


func _test_growth_and_upgrade() -> void:
	_app.get_current_screen().hub_requested.emit()
	await _wait_frames(3)
	_expect(_app.get_current_route() == &"hub", "route growth opens the hub")
	var hub = _app.get_current_screen()
	hub.gacha_requested.emit()
	await _wait_frames(3)
	_expect(_app.get_current_route() == &"gacha", "hub opens spirit-world draw")
	var tickets_before := int(_app.get_progression_snapshot().data.get("divination_tickets", 0))
	_app.get_current_screen().request_draw(1)
	await _wait_frames(3)
	_expect(
		int(_app.get_progression_snapshot().data.get("divination_tickets", 0))
		== tickets_before - 2,
		"single draw deducts two tickets"
	)
	_app.get_current_screen().back_requested.emit()
	await _wait_frames(2)
	_app.get_current_screen().upgrade_requested.emit()
	await _wait_frames(3)
	_app.get_current_screen().request_upgrade(UPGRADE_CARD_ID)
	await _wait_frames(3)
	_expect(_collection_level(UPGRADE_CARD_ID) >= 1, "ink dart upgrade is persisted")
	_app.get_current_screen().back_requested.emit()
	await _wait_frames(2)
	_app.get_current_screen().deck_requested.emit()
	await _wait_frames(2)
	_expect(_app.get_current_route() == &"deck", "deck editor remains available after growth")
	_expect(_app.get_current_screen().get_preset_count() == 3, "presets remain available after growth")
	_app.get_current_screen().request_confirm_deck()
	await _wait_frames(3)
	_expect(_app.get_current_route() == &"hub", "deck re-confirmation returns to hub")
	_app.get_current_screen().battle_requested.emit()
	await _wait_frames(3)
	_expect(_app.get_current_route() == &"map", "battle action returns to the active route")


func _run_first_route_tail() -> void:
	var route = _app.get_current_screen()
	route.request_node(REST_NODE)
	await _wait_frames(2)
	_expect(_app.get_current_route() == &"rest", "first route reaches the rest node")
	_app.get_current_screen().select_rest("rest.seal_echo")
	await _wait_frames(3)
	await _advance_battle(BOSS_NODE, "mirror_baron")
	await _claim_reward("reward.divination_tickets")
	_app.get_current_screen().request_node(RITUAL_NODE)
	await _wait_frames(2)
	await _submit_ritual(["name.elin_ward", "name.thomas_ward"])
	await _submit_ritual(["event.birth", "event.death", "event.burial"])
	await _submit_ritual(["seal.inverted_eye"])
	_expect(_app.get_current_route() == &"route_result", "first route opens route result")
	_expect(
		int(_app.get_session().get_sequence_state().data.get("current_sequence", 0)) == 8,
		"first route advances the character to sequence eight"
	)


func _test_first_challenge_and_second_unlock() -> void:
	_app.show_start_screen()
	await _wait_frames(2)
	var start = _app.get_current_screen()
	_expect(start.is_challenge_enabled(), "sequence eight unlocks challenge entry")
	start.challenge_requested.emit()
	await _wait_frames(4)
	_expect(_app.get_current_route() == &"challenge_hub", "challenge entry opens the challenge hub")
	var hub = _app.get_current_screen()
	_expect(hub.get_challenge_count() == 2, "challenge hub lists both v0.7 challenges")
	_expect(hub.get_unlocked_count() == 1, "only the first challenge is initially available")
	_expect(not hub.is_challenge_enabled(SECOND_CHALLENGE), "second challenge stays locked")
	hub.request_challenge(FIRST_CHALLENGE)
	await _wait_frames(4)
	_expect(_app.get_current_route() == &"challenge_select", "first challenge opens modifier selection")
	var challenge = _app.get_current_screen()
	_expect(challenge.get_modifier_count() == 3, "first challenge exposes three modifiers")
	challenge.request_modifier("modifier.rushed_reflection")
	await _wait_frames(2)
	challenge.request_start()
	await _wait_frames(4)
	_expect(_app.get_current_route() == &"map", "first challenge starts at its route map")
	_expect(
		String(_app.get_route_snapshot().data.get("available_node_id", "")) == FIRST_NODE,
		"first challenge uses the first-case route"
	)


func _run_first_challenge() -> void:
	await _advance_battle(FIRST_NODE, "first_hunt")
	await _claim_reward("reward.ink_dart_fragments")
	await _advance_battle(ELITE_NODE, "mirror_pursuit")
	await _claim_reward("reward.divination_tickets")
	_app.get_current_screen().request_node(REST_NODE)
	await _wait_frames(2)
	_app.get_current_screen().select_rest("rest.seal_echo")
	await _wait_frames(3)
	await _advance_battle(BOSS_NODE, "mirror_baron")
	await _claim_reward("reward.divination_tickets")
	_app.get_current_screen().request_node(RITUAL_NODE)
	await _wait_frames(2)
	await _submit_ritual(["name.elin_ward", "name.thomas_ward"])
	await _submit_ritual(["event.birth", "event.death", "event.burial"])
	await _submit_ritual(["seal.inverted_eye"])
	_expect(_app.get_current_route() == &"challenge_result", "first challenge reaches result")
	_expect(
		String(_app.get_challenge_snapshot().data.get("challenge_outcome", "")) == "completed",
		"first challenge records completion"
	)


func _run_second_challenge() -> void:
	_app.show_start_screen()
	await _wait_frames(2)
	_app.get_current_screen().challenge_requested.emit()
	await _wait_frames(4)
	var hub = _app.get_current_screen()
	_expect(hub.get_unlocked_count() == 2, "completed first challenge unlocks the second")
	_expect(hub.is_challenge_enabled(SECOND_CHALLENGE), "second challenge button becomes enabled")
	hub.request_challenge(SECOND_CHALLENGE)
	await _wait_frames(4)
	var challenge = _app.get_current_screen()
	_expect(
		String(_app.get_challenge_snapshot().data.get("challenge_id", "")) == SECOND_CHALLENGE,
		"selected second challenge is retained"
	)
	challenge.request_modifier("modifier.ritual_vigil")
	await _wait_frames(2)
	challenge.request_start()
	await _wait_frames(4)
	_expect(_app.get_current_route() == &"map", "second challenge starts on its route map")
	_expect(
		String(_app.get_route_snapshot().data.get("available_node_id", "")) == SECOND_FIRST_NODE,
		"second challenge uses its route variant"
	)
	await _advance_battle(SECOND_FIRST_NODE, "first_hunt")
	await _claim_reward("reward.ink_dart_fragments")
	await _advance_battle(SECOND_ELITE_NODE, "twin_pursuit")
	await _claim_reward("reward.divination_tickets")
	_app.get_current_screen().request_node(SECOND_REST_NODE)
	await _wait_frames(2)
	_app.get_current_screen().select_rest("rest.seal_echo")
	await _wait_frames(3)
	await _advance_battle(SECOND_BOSS_NODE, "broken_baron")
	await _claim_reward("reward.divination_tickets")
	_app.get_current_screen().request_node(SECOND_RITUAL_NODE)
	await _wait_frames(2)
	await _submit_ritual(["name.elin_ward", "name.thomas_ward"])
	await _submit_ritual(["event.birth", "event.death", "event.burial"])
	await _submit_ritual(["seal.inverted_eye"])
	_expect(_app.get_current_route() == &"challenge_result", "second challenge reaches result")
	_expect(
		String(_app.get_challenge_snapshot().data.get("challenge_outcome", "")) == "completed",
		"second challenge records completion"
	)
	_expect(
		_app.get_challenge_snapshot().data.get("completed_challenge_ids", []).size() >= 2,
		"both challenge completion IDs are retained"
	)
	_app.show_start_screen()
	await _wait_frames(2)
	var start = _app.get_current_screen()
	_expect(start.is_continue_enabled(), "completed second challenge has a checkpoint")
	start.continue_requested.emit()
	await _wait_frames(4)
	_expect(
		_app.get_current_route() == &"challenge_result",
		"continue restores the second challenge result (actual=%s)" % String(
			_app.get_current_route()
		)
	)


func _advance_battle(node_id: String, encounter_fragment: String) -> void:
	_expect(_app.get_current_route() == &"map", "route map is active before %s" % node_id)
	_app.get_current_screen().request_node(node_id)
	await _wait_frames(3)
	_expect(_app.get_current_route() == &"battle", "node %s starts a real battle" % node_id)
	var battle = _app.get_current_screen()
	_expect(
		String(battle.get_snapshot_data().get("battle_id", "")).contains(encounter_fragment),
		"battle uses encounter %s" % encounter_fragment
	)
	_expect(
		_app.get_session().get_battle_session().get_deck_definition_ids().size() == 8,
		"battle receives the confirmed eight-card deck"
	)
	await _fight_until_finished()
	_expect(_app.get_current_route() == &"reward", "victory from %s enters reward" % node_id)


func _claim_reward(
	reward_id: String,
	expected_route: StringName = &"map"
) -> void:
	_expect(_app.get_current_route() == &"reward", "reward screen is active")
	var screen = _app.get_current_screen()
	_expect(screen.get_option_count() == 2, "reward offers two choices")
	screen.claim_reward(reward_id)
	await _wait_frames(3)
	if not expected_route.is_empty():
		_expect(_app.get_current_route() == expected_route, "claimed reward returns to expected route")


func _submit_ritual(selections: Array[String]) -> void:
	var ritual = _app.get_current_screen()
	for selection in selections:
		ritual.select_option(selection)
	ritual.submit_step()
	await _wait_frames(3)


func _fight_until_finished() -> void:
	for _round_index in 18:
		if _app.get_current_route() != &"battle":
			break
		var battle = _app.get_current_screen()
		var snapshot: Dictionary = battle.get_snapshot_data()
		for card_value in snapshot.get("hand", []).duplicate():
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
			await get_tree().process_frame
		if _app.get_current_route() != &"battle":
			break
		battle.end_turn()
		await _wait_frames(3)


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
		if card_value is Dictionary and String(card_value.get("definition_id", "")) == definition_id:
			return int(card_value.get("level", 0))
	return -1


func _test_corrupt_checkpoint_state() -> void:
	var saves = AtomicSaveService.new(TEST_ROOT)
	var checkpoint_path: String = saves.get_slot_path("v07_flow")
	var file := FileAccess.open(checkpoint_path, FileAccess.WRITE)
	_expect(file != null, "integration test can prepare a corrupt checkpoint")
	if file == null:
		return
	file.store_string("{broken")
	file.close()
	_app.show_start_screen()
	await _wait_frames(2)
	var start = _app.get_current_screen()
	_expect(_app.get_current_route() == &"start", "corrupt checkpoint stays on start")
	_expect(not start.is_continue_enabled(), "corrupt checkpoint disables continue")
	_expect(start.get_status_text().contains("无法读取"), "corrupt checkpoint is reported")


func _wait_frames(count: int) -> void:
	for _index in count:
		await get_tree().process_frame


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("APP_V07_INTEGRATION_OK checks=%d" % _checks)
		get_tree().quit(0)
		return
	for failure in _failures:
		printerr("APP_V07_INTEGRATION_FAIL %s" % failure)
	print("APP_V07_INTEGRATION_FAIL checks=%d failures=%d" % [_checks, _failures.size()])
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
