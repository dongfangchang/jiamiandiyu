extends Node
## Campaign main path through the app router: title -> new game -> route
## select -> diary -> seal into battle -> victory -> reward -> diary -> close
## to hub -> title, plus the shared back-target table (NAV-03/05/08).

const AppDriver := preload("res://tests/integration/app_driver.gd")
const TEST_ROOT := "user://mask_whispers_app_flow_main_path"
const SLOT := "flow_slot"
## Auto-play wins every main-route battle with this seed.
const SEED := 1

var _d: AppDriver


func _ready() -> void:
	_d = AppDriver.new(get_tree())
	await _d.mount(self, TEST_ROOT, SLOT, SEED)
	await _test_start_state()
	await _d.begin_campaign()
	await _test_diary_reused_across_battle()
	await _test_close_diary_and_hub_round_trips()
	await _test_reward_cannot_be_skipped_via_hub()
	await _test_rest_back_entry()
	await _finish_route()
	await _test_result_back_and_title_reset()
	await _test_restart_route_select_backs_to_hub()
	await _test_corrupt_checkpoint_state()
	_d.remove_tree(TEST_ROOT)
	_d.finish("APP_FLOW")


func _test_start_state() -> void:
	_d.expect(_d.route() == &"start", "app starts on the title")
	var start := _d.screen()
	_d.expect(not start.is_continue_enabled(), "continue disabled without checkpoint")
	_d.expect(not start.is_challenge_enabled(), "challenge disabled before sequence eight")
	_d.expect(_d.app.get_back_target(&"route_select") == &"start", "route select backs to title without a session")


func _test_diary_reused_across_battle() -> void:
	var diary := _d.screen()
	var diary_id := diary.get_instance_id()
	var desk_id: int = diary.get_desk_stage().get_instance_id()
	_d.expect(diary.desk_world_ready(), "diary desk world is built")
	await _d.clear_battle_node("first_hunt")
	var back := _d.screen()
	_d.expect(back.get_instance_id() == diary_id, "diary instance is reused after battle and reward")
	_d.expect(
		back.get_desk_stage() != null and back.get_desk_stage().get_instance_id() == desk_id,
		"diary desk stage is not rebuilt on return"
	)
	_d.expect(
		_d.available_node_id() == _d.node_id("tenant_trace"),
		"next clue becomes available after the first hunt"
	)
	_d.expect(
		not back.get_clue(_d.node_id("tenant_trace")).is_empty()
		and int(back.get_clue(_d.node_id("tenant_trace")).get("state", 0)) == 1,
		"reused diary re-renders the new clue state"
	)


func _test_close_diary_and_hub_round_trips() -> void:
	var diary_id := _d.screen().get_instance_id()
	_d.expect(_d.app.get_back_target(&"map") == &"hub", "diary closes to the hub")
	_d.screen().request_close()
	_d.expect(await _d.wait_route(&"hub"), "closing the diary opens the hub")
	var hub := _d.screen()
	hub.gacha_requested.emit()
	_d.expect(await _d.wait_route(&"gacha"), "hub opens gacha")
	_d.screen().back_requested.emit()
	_d.expect(await _d.wait_route(&"hub"), "gacha backs to hub")
	_d.screen().upgrade_requested.emit()
	_d.expect(await _d.wait_route(&"upgrade"), "hub opens upgrade")
	_d.screen().back_requested.emit()
	_d.expect(await _d.wait_route(&"hub"), "upgrade backs to hub")
	_d.screen().deck_requested.emit()
	_d.expect(await _d.wait_route(&"deck"), "hub opens deck")
	_d.expect(_d.app.get_back_target(&"deck") == &"hub", "deck from hub backs to hub")
	_d.screen().request_back()
	_d.expect(await _d.wait_route(&"hub"), "deck backs to hub")
	_d.screen().battle_requested.emit()
	_d.expect(await _d.wait_route(&"map"), "hub reopens the diary")
	_d.expect(_d.screen().get_instance_id() == diary_id, "hub round trip reuses the cached diary")


func _test_reward_cannot_be_skipped_via_hub() -> void:
	var target := _d.node_id("tenant_trace")
	_d.expect(_d.press_seal(target), "tenant trace seal is pressable")
	_d.expect(await _d.wait_route(&"battle"), "tenant trace enters battle")
	_d.expect(await _d.fight_until_finished(), "tenant trace battle finishes")
	_d.expect(_d.route() == &"reward", "tenant trace victory opens reward")
	_d.expect(_d.app.get_back_target(&"reward") == &"hub", "reward backs to hub")
	_d.screen().hub_requested.emit()
	_d.expect(await _d.wait_route(&"hub"), "reward hub button opens the hub")
	_d.screen().battle_requested.emit()
	_d.expect(
		await _d.wait_route(&"reward"),
		"opening the diary from the hub returns to the unclaimed reward"
	)
	var options: Array = _d.app.get_progression_snapshot().data.get("reward_options", [])
	_d.screen().claim_reward(String(options[0].get("id", "")) if not options.is_empty() else "")
	_d.expect(await _d.wait_route(&"map"), "claimed reward returns to the diary")
	await _d.clear_battle_node("mirror_pursuit")
	await _d.clear_battle_node("boundary")


func _test_rest_back_entry() -> void:
	var rest_node := _d.node_id("rest")
	_d.expect(_d.press_seal(rest_node), "rest seal is pressable")
	_d.expect(await _d.wait_route(&"rest"), "rest seal opens the rest screen")
	_d.expect(_d.app.get_back_target(&"rest") == &"map", "rest backs to the diary")
	_d.screen().request_back()
	_d.expect(await _d.wait_route(&"map"), "rest back entry returns to the diary")
	_d.expect(_d.press_seal(rest_node), "pending rest clue stays pressable")
	_d.expect(await _d.wait_route(&"rest"), "pending rest clue reopens the rest screen")
	_d.expect(_d.screen().get_option_count() == 2, "reopened rest keeps both choices")
	_d.screen().select_rest("rest.seal_echo")
	_d.expect(await _d.wait_route(&"map"), "rest choice returns to the diary")


func _finish_route() -> void:
	await _d.clear_battle_node("lamud")
	await _d.clear_battle_node("baron")
	await _d.complete_ritual(_d.node_id("ascension"), &"route_result")
	var sequence = _d.app.get_session().get_sequence_state().data
	_d.expect(int(sequence.get("current_sequence", 0)) == 8, "ritual advances to sequence eight")


func _test_result_back_and_title_reset() -> void:
	_d.expect(_d.app.get_back_target(&"route_result") == &"hub", "route result backs to hub")
	_d.screen().hub_requested.emit()
	_d.expect(await _d.wait_route(&"hub"), "route result opens the hub")
	_d.expect(_d.app.get_back_target(&"hub") == &"start", "hub backs to the title")
	_d.screen().main_menu_requested.emit()
	_d.expect(await _d.wait_route(&"start"), "hub main menu returns to the title")
	_d.expect(_d.app.get_session() == null, "title clears the session")
	_d.expect(_d.app.checkpoint_slot == SLOT, "title keeps the configured checkpoint slot")
	var start := _d.screen()
	_d.expect(start.is_continue_enabled(), "completed route can be continued")
	_d.expect(start.is_challenge_enabled(), "sequence eight unlocks the challenge entry")
	start.continue_requested.emit()
	_d.expect(await _d.wait_route(&"route_result"), "continue restores the route result")


func _test_restart_route_select_backs_to_hub() -> void:
	_d.screen().hub_requested.emit()
	_d.expect(await _d.wait_route(&"hub"), "result opens the hub again")
	_d.screen().restart_requested.emit()
	_d.expect(await _d.wait_route(&"route_select"), "hub restart opens route selection")
	_d.expect(_d.app.get_back_target(&"route_select") == &"hub", "route select backs to hub with a session")
	_d.screen().request_back()
	_d.expect(await _d.wait_route(&"hub"), "route select back returns to the hub, not the title")


func _test_corrupt_checkpoint_state() -> void:
	var saves = AtomicSaveService.new(TEST_ROOT)
	_d.write_text(saves.get_slot_path(SLOT), "{broken")
	_d.app.show_start_screen()
	_d.expect(await _d.wait_route(&"start"), "corrupt checkpoint stays on the title")
	var start := _d.screen()
	_d.expect(not start.is_continue_enabled(), "corrupt checkpoint disables continue")
	_d.expect(start.get_status_text().contains("无法读取"), "corrupt checkpoint is reported")
