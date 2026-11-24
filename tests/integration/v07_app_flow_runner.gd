extends Node
## Challenge entry through the app router: a completed main route unlocks the
## challenge hub; hub -> modifier selection -> challenge diary -> result ->
## back to the challenge hub, using the shared back-target table (NAV-05/07).

const AppDriver := preload("res://tests/integration/app_driver.gd")
const TEST_ROOT := "user://mask_whispers_app_flow_challenge"
const SLOT := "challenge_flow"
const SEED := 1
const FIRST_CHALLENGE := "challenge.v060.mirror_echoes"
const SECOND_CHALLENGE := "challenge.v070.broken_procession"
const CHALLENGE_PREFIX := "route.v070.node."

var _d: AppDriver


func _ready() -> void:
	_d = AppDriver.new(get_tree())
	await _d.mount(self, TEST_ROOT, SLOT, SEED)
	await _d.begin_campaign()
	await _d.play_full_route()
	await _return_to_title()
	await _test_challenge_hub_entry()
	await _test_challenge_select_backs_to_hub()
	await _test_start_challenge_without_deck_loop()
	await _test_challenge_run_and_result()
	_d.remove_tree(TEST_ROOT)
	_d.finish("APP_V07_CHALLENGE_FLOW")


func _return_to_title() -> void:
	_d.screen().hub_requested.emit()
	_d.expect(await _d.wait_route(&"hub"), "route result opens the hub")
	_d.screen().main_menu_requested.emit()
	_d.expect(await _d.wait_route(&"start"), "hub returns to the title")


func _test_challenge_hub_entry() -> void:
	var start := _d.screen()
	_d.expect(start.is_challenge_enabled(), "sequence eight unlocks the challenge entry")
	_d.expect(_d.press_title_item("挑战"), "title lists 挑战")
	_d.expect(await _d.wait_route(&"challenge_hub"), "challenge entry opens the challenge hub")
	var hub := _d.screen()
	_d.expect(hub.get_challenge_count() == 2, "challenge hub lists both challenges")
	_d.expect(hub.get_unlocked_count() == 1, "only the first challenge is open")
	_d.expect(not hub.is_challenge_enabled(SECOND_CHALLENGE), "second challenge stays locked")
	_d.expect(_d.app.is_challenge_hub_preview_cached(), "challenge previews are cached")
	_d.expect(_d.app.get_back_target(&"challenge_hub") == &"start", "challenge hub backs to the title")
	hub.request_exit()
	_d.expect(await _d.wait_route(&"start"), "challenge hub exit returns to the title")
	var started_msec := Time.get_ticks_msec()
	_d.expect(_d.press_title_item("挑战"), "title lists 挑战 again")
	_d.expect(await _d.wait_route(&"challenge_hub"), "challenge hub reopens")
	_d.expect(_d.screen().get_unlocked_count() == 1, "cached previews keep the unlock state")
	_d.expect(Time.get_ticks_msec() - started_msec < 2000, "cached hub reopens quickly")


func _test_challenge_select_backs_to_hub() -> void:
	_d.screen().request_challenge(FIRST_CHALLENGE)
	_d.expect(await _d.wait_route(&"challenge_select"), "first challenge opens modifier selection")
	_d.expect(_d.screen().get_modifier_count() == 3, "first challenge exposes three modifiers")
	_d.expect(
		_d.app.get_back_target(&"challenge_select") == &"challenge_hub",
		"challenge selection backs to the challenge hub"
	)
	_d.screen().request_exit()
	_d.expect(
		await _d.wait_route(&"challenge_hub"),
		"challenge selection exit returns to the challenge hub, not the title"
	)


func _test_start_challenge_without_deck_loop() -> void:
	_d.screen().request_challenge(FIRST_CHALLENGE)
	_d.expect(await _d.wait_route(&"challenge_select"), "challenge selection reopens")
	var challenge := _d.screen()
	challenge.request_modifier("modifier.rushed_reflection")
	await _d.settle()
	challenge.request_start()
	await _d.settle()
	if _d.route() == &"deck":
		_d.expect(
			_d.app.get_back_target(&"deck") == &"challenge_hub",
			"challenge deck backs to the challenge hub"
		)
		_d.screen().request_confirm_deck()
		await _d.settle()
	_d.expect(
		_d.route() == &"map",
		"starting a challenge reaches its diary without looping through the hub (route=%s)" % _d.route()
	)
	_d.expect(
		_d.available_node_id() == CHALLENGE_PREFIX + "first_hunt",
		"challenge uses the first-case route"
	)
	## BUG-0038: challenge nodes have no volume entry, so the diary shows
	## fallback spreads and the first one carries a pressable seal.
	var diary := _d.screen()
	var route_nodes: Array = _d.app.get_route_snapshot().data.get("nodes", [])
	_d.expect(
		diary.get_page_count() == route_nodes.size() and route_nodes.size() > 0,
		"challenge diary has one fallback spread per route node (%d)" % diary.get_page_count()
	)
	var first_clue: Dictionary = diary.get_clue(CHALLENGE_PREFIX + "first_hunt")
	_d.expect(
		int(first_clue.get("state", -1)) == 1,
		"first challenge seal is available on the diary desk"
	)


func _test_challenge_run_and_result() -> void:
	## The scripted player cannot clear the whole challenge, so this covers its
	## first node and the hub/back wiring; result routing is checked by table.
	## The node is entered by pressing its desk seal, as on the main path.
	await _d.clear_battle_node("first_hunt", CHALLENGE_PREFIX)
	_d.expect(_d.route() == &"map", "challenge reward returns to the challenge diary")
	_d.expect(_d.app.get_back_target(&"map") == &"hub", "challenge diary closes to the hub")
	_d.expect(
		_d.app.get_back_target(&"challenge_result") == &"challenge_hub",
		"challenge result backs to the challenge hub, not the campaign hub"
	)
	_d.expect(
		_d.app.get_back_target(&"route_result") == &"hub",
		"campaign result still backs to the identity hub"
	)
	_d.screen().request_close()
	_d.expect(await _d.wait_route(&"hub"), "challenge diary closes to the hub")
	_d.screen().battle_requested.emit()
	_d.expect(await _d.wait_route(&"map"), "hub reopens the challenge diary")
	_d.expect(
		_d.available_node_id() == CHALLENGE_PREFIX + "mirror_pursuit",
		"challenge progress is kept across the hub round trip"
	)
	_d.screen().request_close()
	_d.expect(await _d.wait_route(&"hub"), "challenge diary closes again")
	_d.screen().main_menu_requested.emit()
	_d.expect(await _d.wait_route(&"start"), "hub returns to the title")
	_d.expect(_d.press_title_item("继续"), "title lists 继续")
	_d.expect(await _d.wait_route(&"map"), "continue restores the challenge diary")
	_d.expect(
		_d.app.get_challenge_snapshot() != null
		and String(_d.app.get_challenge_snapshot().data.get("challenge_id", "")) == FIRST_CHALLENGE,
		"continued session is the first challenge"
	)
