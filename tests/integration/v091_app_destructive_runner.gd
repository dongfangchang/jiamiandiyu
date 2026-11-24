extends Node
## Destructive navigation with real router transitions (fades and exit
## hooks on): double clicks, input during a swap, back while a battle exit is
## pending, in-play errors as toasts, and a corrupt checkpoint on continue.

const AppDriver := preload("res://tests/integration/app_driver.gd")
const TEST_ROOT := "user://mask_whispers_app_destructive_nav"
const SLOT := "destructive_slot"
const SEED := 1

var _d: AppDriver
var _route_log: Array[StringName] = []


func _ready() -> void:
	_d = AppDriver.new(get_tree())
	await _d.mount(self, TEST_ROOT, SLOT, SEED)
	_d.app.set_transitions_instant(false)
	_d.app.route_changed.connect(func(route_name: StringName) -> void:
		_route_log.append(route_name)
	)
	await _test_double_new_game_swaps_once()
	await _d.begin_campaign()
	await _test_double_seal_enters_one_battle()
	await _test_battle_exit_pending_back_lands_on_diary()
	await _test_finish_awaits_battle_exit_beat()
	await _test_double_claim_and_double_close()
	await _test_in_play_error_is_a_toast()
	await _test_corrupt_checkpoint_on_continue()
	_d.remove_tree(TEST_ROOT)
	_d.finish("V091_APP_DESTRUCTIVE")


func _count(route_name: StringName) -> int:
	return _route_log.count(route_name)


func _test_double_new_game_swaps_once() -> void:
	var start := _d.screen()
	var router: Control = _d.app.get_router()
	start.new_game_requested.emit()
	start.new_game_requested.emit()
	_d.expect(_d.app.is_transitioning(), "new game starts a real transition")
	_d.expect(
		router.get_overlay().mouse_filter == Control.MOUSE_FILTER_STOP,
		"overlay blocks input while the title fades out"
	)
	start.continue_requested.emit()
	start.challenge_requested.emit()
	_d.expect(await _d.wait_route(&"route_select"), "double new game lands on route selection")
	_d.expect(_count(&"route_select") == 1, "double new game swaps exactly once")
	_d.expect(_count(&"challenge_hub") == 0, "clicks during the swap are dropped")
	_d.expect(
		router.get_overlay().mouse_filter == Control.MOUSE_FILTER_IGNORE,
		"overlay releases input after the swap"
	)
	_d.expect(_d.app.get_back_target(&"route_select") == &"start", "route select backs to the title")
	_d.screen().request_back()
	_d.expect(await _d.wait_route(&"start"), "route select back returns to the title")
	_route_log.clear()


func _test_double_seal_enters_one_battle() -> void:
	var diary := _d.screen()
	var target := _d.node_id("first_hunt")
	_d.expect(_d.press_seal(target), "first seal press is accepted")
	_d.press_seal(target)
	_d.expect(_d.app.is_transitioning(), "seal starts a real transition")
	_d.expect(diary.is_inside_tree(), "diary stays on screen while its exit beat plays")
	_d.expect(
		diary.get_status_text().contains("调查开始"),
		"clue status line is still on screen while the diary exits"
	)
	_d.expect(await _d.wait_route(&"battle"), "seal enters battle")
	_d.expect(_count(&"battle") == 1, "double seal press starts one battle")
	_d.expect(_d.app.get_router().last_exit_was_awaited(), "diary on_exit beat was awaited")


func _test_battle_exit_pending_back_lands_on_diary() -> void:
	var battle := _d.screen()
	_route_log.clear()
	_d.expect(_d.app.get_back_target(&"battle") == &"map", "battle backs to the diary")
	battle.request_exit()
	_d.expect(battle.is_exit_confirmation_visible(), "battle exit asks for confirmation")
	battle.confirm_exit()
	battle.confirm_exit()
	battle.end_turn()
	_d.expect(await _d.wait_route(&"map"), "confirmed battle exit returns to the diary checkpoint")
	_d.expect(_count(&"start") == 0, "battle exit no longer drops to the title")
	_d.expect(_count(&"map") == 1, "repeated exit confirmation swaps once")
	_d.expect(
		_d.available_node_id() == _d.node_id("first_hunt"),
		"abandoned battle leaves its clue available"
	)


func _test_finish_awaits_battle_exit_beat() -> void:
	_d.expect(_d.press_seal(_d.node_id("first_hunt")), "seal again after exit")
	_d.expect(await _d.wait_route(&"battle"), "battle reopens")
	_d.expect(await _d.fight_until_finished(), "battle finishes")
	_d.expect(_d.route() == &"reward", "victory opens the reward")
	_d.expect(_d.app.get_router().last_exit_was_awaited(), "battle on_exit beat was awaited")


func _test_double_claim_and_double_close() -> void:
	var reward := _d.screen()
	var options: Array = _d.app.get_progression_snapshot().data.get("reward_options", [])
	var reward_id := String(options[0].get("id", "")) if not options.is_empty() else ""
	var revision_before := int(_d.app.get_progression_snapshot().data.get("revision", 0))
	reward.claim_reward(reward_id)
	reward.claim_reward(reward_id)
	_d.expect(await _d.wait_route(&"map"), "claimed reward returns to the diary")
	_d.expect(
		int(_d.app.get_progression_snapshot().data.get("revision", 0)) == revision_before + 1,
		"double claim is applied once"
	)
	_route_log.clear()
	var diary := _d.screen()
	diary.request_close()
	diary.request_close()
	_d.expect(await _d.wait_route(&"hub"), "closing the diary opens the hub")
	_d.expect(_count(&"hub") == 1, "double close swaps once")


func _test_in_play_error_is_a_toast() -> void:
	_d.screen().battle_requested.emit()
	_d.expect(await _d.wait_route(&"map"), "hub reopens the diary")
	var session_before = _d.app.get_session()
	var failed = _d.app.start_new_challenge(SEED, &"challenge.does_not_exist")
	await _d.settle()
	_d.expect(not failed.ok, "unknown challenge fails to start")
	_d.expect(_d.route() == &"map", "in-play error keeps the player on the diary")
	_d.expect(_d.app.get_session() == session_before, "in-play error keeps the session")
	_d.expect(not _d.app.get_toast_text().is_empty(), "in-play error is shown as a toast")


func _test_corrupt_checkpoint_on_continue() -> void:
	_d.screen().request_close()
	_d.expect(await _d.wait_route(&"hub"), "diary closes to the hub")
	_d.screen().main_menu_requested.emit()
	_d.expect(await _d.wait_route(&"start"), "hub returns to the title")
	var saves = AtomicSaveService.new(TEST_ROOT)
	var path: String = saves.get_slot_path(SLOT)
	_d.write_text(path, "{broken")
	_d.expect(_d.app.continue_saved_checkpoint().ok == false, "continue refuses a corrupt checkpoint")
	_d.expect(await _d.wait_route(&"start"), "corrupt checkpoint load returns to the title")
	var start := _d.screen()
	_d.expect(not start.is_continue_enabled(), "corrupt checkpoint disables continue")
	_d.expect(_d.read_text(path) == "{broken", "corrupt checkpoint is not overwritten")
