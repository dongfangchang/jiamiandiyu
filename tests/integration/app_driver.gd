extends RefCounted
## Drives AppRoot along the current main path (title, route select, diary,
## battle, reward, hub) through the screens' public APIs only. Waits are
## time-bounded so the same helpers work with instant and real transitions.

const AppRootScene := preload("res://src/app/app_root.tscn")

const MAIN_ROUTE := "route.v028.first_stage"
const IDENTITY_ID := "identity.reporter"
const NODE_PREFIX := "route.v028.first_stage.node."
const RITUAL_STEPS := {
	"ritual.v070.tampered_obituary": [
		["rule.guide_others", "rule.not_rely"],
		["event.birth", "event.death", "event.burial"],
		["seal.inverted_eye"],
	],
	"ritual.v070.fractured_obituary": [
		["name.elin_ward", "name.thomas_ward"],
		["event.birth", "event.death", "event.burial"],
		["seal.inverted_eye"],
	],
}

var app: Control
var tree: SceneTree
var checks := 0
var failures: Array[String] = []


func _init(scene_tree: SceneTree) -> void:
	tree = scene_tree


func mount(host: Node, save_root: String, slot: String, seed_value: int) -> Control:
	remove_tree(save_root)
	app = AppRootScene.instantiate()
	app.configure_for_testing(save_root, slot, seed_value)
	host.add_child(app)
	await frames(2)
	return app


func route() -> StringName:
	return app.get_current_route()


func screen() -> Control:
	return app.get_current_screen()


func frames(count: int) -> void:
	for _index in count:
		await tree.process_frame


func seconds(value: float) -> void:
	await tree.create_timer(value).timeout


## Waits for the router to go idle (bounded) and returns whether it did.
func settle(timeout_sec: float = 4.0) -> bool:
	var deadline := Time.get_ticks_msec() + int(timeout_sec * 1000.0)
	await tree.process_frame
	while app.is_transitioning() and Time.get_ticks_msec() < deadline:
		await tree.process_frame
	await tree.process_frame
	return not app.is_transitioning()


func wait_route(expected: StringName, timeout_sec: float = 4.0) -> bool:
	var deadline := Time.get_ticks_msec() + int(timeout_sec * 1000.0)
	while Time.get_ticks_msec() < deadline:
		if route() == expected and not app.is_transitioning():
			return true
		await tree.process_frame
	return route() == expected and not app.is_transitioning()


func expect(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)


func node_id(short_name: String) -> String:
	return NODE_PREFIX + short_name


## Title -> new game -> route select -> identity -> deck -> hub -> diary.
func begin_campaign() -> void:
	screen().new_game_requested.emit()
	expect(await wait_route(&"route_select"), "new game opens route selection")
	screen().choose_route(MAIN_ROUTE)
	expect(await wait_route(&"identity"), "route choice opens identity selection")
	screen().choose_identity(IDENTITY_ID)
	expect(await wait_route(&"deck"), "identity choice opens the deck editor")
	expect(screen().is_confirm_enabled(), "default deck is confirmable")
	screen().request_confirm_deck()
	expect(await wait_route(&"hub"), "deck confirmation returns to the hub")
	screen().battle_requested.emit()
	expect(await wait_route(&"map"), "hub opens the diary")


## Presses the desk wax seal for a clue, exactly as a click on the 3D seal does.
func press_seal(target_node_id: String) -> bool:
	var diary := screen()
	if not diary.has_method("get_desk_stage") or diary.get_desk_stage() == null:
		return false
	var clue: Dictionary = diary.get_clue(target_node_id)
	if clue.is_empty():
		return false
	diary.get_desk_stage().seal_activated.emit(clue)
	return true


## Challenge routes have no diary clues yet (see UI report v0.86.0), so their
## nodes are entered through the diary's own command signal, which is what a
## seal press emits.
func enter_node(target_node_id: String, ritual: bool = false) -> bool:
	if press_seal(target_node_id):
		return true
	var diary := screen()
	if not diary.has_signal("route_command_requested"):
		return false
	diary.route_command_requested.emit(
		RouteCommand.begin_ascension()
		if ritual
		else RouteCommand.select_node(StringName(target_node_id))
	)
	return true


func available_node_id() -> String:
	return String(app.get_route_snapshot().data.get("available_node_id", ""))


func fight_until_finished() -> bool:
	var commands_sent := 0
	for _round_index in 24:
		if route() != &"battle":
			break
		var battle := screen()
		var snapshot: Dictionary = battle.get_snapshot_data()
		for card_value in snapshot.get("hand", []).duplicate():
			if route() != &"battle" or not card_value is Dictionary:
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
			var discards: Array = app.get_session().auto_discard_ids_for(instance_id)
			var playability = app.get_session().query_card_play(instance_id, target_id, discards)
			if playability == null or not playability.playable:
				continue
			battle.select_card_instance(instance_id)
			if not target_id.is_empty():
				battle.select_target(target_id)
			for discard_id in discards:
				battle.toggle_discard_choice(StringName(discard_id))
			battle.play_selected()
			commands_sent += 1
			await tree.process_frame
		if route() != &"battle":
			break
		battle.end_turn()
		commands_sent += 1
		await frames(2)
	await settle()
	return commands_sent > 0 and route() != &"battle"


## Seal -> battle -> victory -> reward claim -> back on the diary.
func clear_battle_node(short_name: String, prefix: String = NODE_PREFIX) -> void:
	var target := prefix + short_name
	expect(route() == &"map", "diary is open before %s" % short_name)
	expect(enter_node(target), "seal for %s is pressable" % short_name)
	expect(await wait_route(&"battle"), "seal %s enters battle" % short_name)
	expect(await fight_until_finished(), "battle %s finishes" % short_name)
	expect(route() == &"reward", "victory at %s opens the reward (route=%s hp=%s)" % [
		short_name,
		route(),
		str(app.get_progression_snapshot().data.get("last_battle_outcome", "?")) + " completed=" + str(app.get_route_snapshot().data.get("completed_node_ids", [])),
	])
	if route() != &"reward":
		return
	var options: Array = app.get_progression_snapshot().data.get("reward_options", [])
	var reward_id := ""
	for option in options:
		if option is Dictionary:
			reward_id = String(option.get("id", ""))
			break
	screen().claim_reward(reward_id)
	expect(await wait_route(&"map"), "claimed reward at %s returns to the diary" % short_name)


func clear_rest_node(short_name: String, rest_id: String, prefix: String = NODE_PREFIX) -> void:
	expect(enter_node(prefix + short_name), "rest seal %s is pressable" % short_name)
	expect(await wait_route(&"rest"), "rest seal opens the rest screen")
	screen().select_rest(rest_id)
	expect(await wait_route(&"map"), "rest choice returns to the diary")


func complete_ritual(full_node_id: String, result_route: StringName) -> void:
	expect(enter_node(full_node_id, true), "ritual seal is pressable")
	expect(await wait_route(&"ritual"), "ritual seal opens the ritual")
	var ritual_id := String(app.get_ritual_snapshot().data.get("ritual_id", ""))
	expect(RITUAL_STEPS.has(ritual_id), "ritual %s has known answers" % ritual_id)
	for step in RITUAL_STEPS.get(ritual_id, []):
		var ritual := screen()
		for selection in step:
			ritual.select_option(selection)
		ritual.submit_step()
		await settle()
	expect(await wait_route(result_route), "completed ritual opens %s" % result_route)


func play_full_route(result_route: StringName = &"route_result") -> void:
	for short_name in ["first_hunt", "tenant_trace", "mirror_pursuit", "boundary"]:
		await clear_battle_node(short_name)
	await clear_rest_node("rest", "rest.seal_echo")
	for short_name in ["lamud", "baron"]:
		await clear_battle_node(short_name)
	await complete_ritual(node_id("ascension"), result_route)


func write_text(path: String, text_value: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(text_value)
	file.close()


func read_text(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var text_value := file.get_as_text()
	file.close()
	return text_value


func finish(tag: String) -> void:
	if failures.is_empty():
		print("%s_OK checks=%d" % [tag, checks])
		tree.quit(0)
		return
	for failure in failures:
		printerr("%s_FAIL %s" % [tag, failure])
	print("%s_FAIL checks=%d failures=%d" % [tag, checks, failures.size()])
	tree.quit(1)


func remove_tree(path: String) -> void:
	var absolute_path := ProjectSettings.globalize_path(path)
	if not DirAccess.dir_exists_absolute(absolute_path):
		return
	var directory := DirAccess.open(absolute_path)
	if directory == null:
		return
	for file_name in directory.get_files():
		DirAccess.remove_absolute(absolute_path.path_join(file_name))
	for child_name in directory.get_directories():
		remove_tree(path.path_join(child_name))
	DirAccess.remove_absolute(absolute_path)


func _lowest_health_enemy(snapshot: Dictionary) -> StringName:
	var selected_id: StringName = &""
	var selected_hp := 2147483647
	for enemy_value in snapshot.get("enemies", []):
		if not enemy_value is Dictionary:
			continue
		var hp := int(enemy_value.get("hp", 0))
		if hp > 0 and hp < selected_hp:
			selected_hp = hp
			selected_id = StringName(enemy_value.get("actor_id", ""))
	return selected_id
