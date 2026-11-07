extends Control

signal route_changed(route_name: StringName)

const AppBootstrapScript := preload("res://src/app/bootstrap.gd")
const StartScreenScene := preload("res://scenes/ui/start_screen.tscn")
const BattleScreenScene := preload("res://scenes/ui/battle_screen.tscn")
const ResultScreenScene := preload("res://scenes/ui/result_screen.tscn")

const ROUTE_START: StringName = &"start"
const ROUTE_BATTLE: StringName = &"battle"
const ROUTE_RESULT: StringName = &"result"

var save_directory: String = AtomicSaveService.DEFAULT_DIRECTORY
var checkpoint_slot: String = "checkpoint"

var _route: StringName = &""
var _screen: Control = null
var _session: RefCounted = null
var _last_checkpoint_summary: Dictionary = {}
var _last_encounter_id: StringName = &""
var _seed_override: int = -1


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	show_start_screen()


func configure_for_testing(
	save_directory_value: String,
	checkpoint_slot_value: String = "checkpoint",
	seed_override_value: int = -1
) -> void:
	save_directory = save_directory_value
	checkpoint_slot = checkpoint_slot_value
	_seed_override = seed_override_value


func show_start_screen() -> void:
	_clear_session()
	var screen := _replace_screen(StartScreenScene)
	screen.new_game_requested.connect(_on_new_game_requested)
	screen.continue_requested.connect(_on_continue_requested)
	screen.quit_requested.connect(_on_quit_requested)
	_set_route(ROUTE_START)
	_refresh_checkpoint_summary(screen)


func start_new_game(
	seed_value: int = -1,
	encounter_id: StringName = &""
) -> InfrastructureResult:
	var resolved_seed := seed_value
	if resolved_seed < 0:
		resolved_seed = _next_seed()
	var result = AppBootstrapScript.start_new_game(
		resolved_seed,
		encounter_id,
		{"save_directory": save_directory},
		checkpoint_slot
	)
	if not result.ok:
		_show_start_error(result)
		return result
	_session = result.data
	_last_encounter_id = _session.encounter_id
	_show_battle()
	return result


func continue_saved_checkpoint() -> InfrastructureResult:
	if _last_checkpoint_summary.is_empty():
		var inspected = AppBootstrapScript.inspect_checkpoint(
			checkpoint_slot,
			save_directory
		)
		if not inspected.ok or inspected.data.get("status", "") != "loaded":
			var failed := InfrastructureResult.failure(
				&"checkpoint_not_available",
				"No loaded checkpoint is available to continue."
			)
			_show_start_error(failed)
			return failed
		_last_checkpoint_summary = inspected.data.get("checkpoint", {})

	var seed_value := int(_last_checkpoint_summary.get("rng_seed", -1))
	var encounter_id := StringName(
		String(_last_checkpoint_summary.get("encounter_id", ""))
	)
	var result = AppBootstrapScript.start_new_game(
		seed_value,
		encounter_id,
		{"save_directory": save_directory},
		checkpoint_slot
	)
	if not result.ok:
		_show_start_error(result)
		return result
	_session = result.data
	_last_encounter_id = _session.encounter_id
	_show_battle()
	return result


func get_current_route() -> StringName:
	return _route


func get_current_screen() -> Control:
	return _screen


func get_session() -> RefCounted:
	return _session


func get_last_checkpoint_summary() -> Dictionary:
	return _last_checkpoint_summary.duplicate(true)


func _refresh_checkpoint_summary(start_screen: Control) -> void:
	var inspected = AppBootstrapScript.inspect_checkpoint(
		checkpoint_slot,
		save_directory
	)
	if not inspected.ok:
		_last_checkpoint_summary = {}
		start_screen.show_checkpoint_status(
			"corrupt",
			{},
			"%s: %s" % [String(inspected.code), inspected.message]
		)
		return

	var status := String(inspected.data.get("status", "none"))
	if status == "loaded":
		_last_checkpoint_summary = inspected.data.get("checkpoint", {}).duplicate(true)
		start_screen.show_checkpoint_status("loaded", _last_checkpoint_summary)
		return
	_last_checkpoint_summary = {}
	if status == "corrupt":
		start_screen.show_checkpoint_status(
			"corrupt",
			{},
			String(inspected.data.get("message", "Checkpoint could not be read."))
		)
		return
	start_screen.show_checkpoint_status("none")


func _show_battle() -> void:
	if _session == null:
		return
	var screen := _replace_screen(BattleScreenScene)
	var labels := _build_display_labels()
	screen.configure(
		String(_session.encounter_name),
		labels.cards,
		labels.enemies,
		Callable(_session, "query_card_play")
	)
	screen.command_requested.connect(_on_battle_command_requested)
	screen.battle_finished.connect(_on_battle_finished)
	screen.apply_snapshot(_session.get_snapshot())
	_set_route(ROUTE_BATTLE)


func _build_display_labels() -> Dictionary:
	var card_labels: Dictionary = {}
	var enemy_labels: Dictionary = {}
	var resolved = _session.catalog.resolve_encounter(_session.encounter_id)
	if not resolved.ok:
		return {"cards": card_labels, "enemies": enemy_labels}
	for definition_value in resolved.data.get("deck_definition_ids", []):
		var definition_id := StringName(definition_value)
		card_labels[definition_id] = _session.card_display_name(definition_id)
	for enemy_value in resolved.data.get("enemy_configs", []):
		var definition_id := StringName(enemy_value.get("definition_id", ""))
		enemy_labels[definition_id] = _session.enemy_display_name(definition_id)
	return {"cards": card_labels, "enemies": enemy_labels}


func _on_battle_command_requested(command: BattleCommand) -> void:
	if _session == null or _screen == null or _route != ROUTE_BATTLE:
		return
	var result = _session.submit(command)
	_screen.apply_command_result(result)


func _on_battle_finished(snapshot: BattleSnapshot) -> void:
	call_deferred("_show_battle_result", snapshot)


func _show_battle_result(snapshot: BattleSnapshot) -> void:
	if snapshot == null or _route != ROUTE_BATTLE:
		return
	var save_status := "failed"
	var save_message := "Post-battle checkpoint result was not produced."
	if _session != null and _session.last_checkpoint_result != null:
		var save_result: InfrastructureResult = _session.last_checkpoint_result
		if save_result.ok:
			save_status = (
				"already_saved"
				if bool(save_result.details.get("already_saved", false))
				else "saved"
			)
			save_message = ""
		else:
			save_message = save_result.message

	var screen := _replace_screen(ResultScreenScene)
	screen.show_result(
		snapshot,
		String(_session.encounter_name) if _session != null else "首场战斗",
		save_status,
		save_message
	)
	screen.return_to_title_requested.connect(show_start_screen)
	screen.retry_requested.connect(_on_retry_requested)
	_set_route(ROUTE_RESULT)


func _on_retry_requested() -> void:
	start_new_game(_next_seed(), _last_encounter_id)


func _on_new_game_requested() -> void:
	start_new_game(_next_seed())


func _on_continue_requested() -> void:
	continue_saved_checkpoint()


func _on_quit_requested() -> void:
	get_tree().quit(0)


func _show_start_error(result: InfrastructureResult) -> void:
	show_start_screen()
	if _screen != null:
		_screen.show_checkpoint_status(
			"corrupt",
			{},
			"%s: %s" % [String(result.code), result.message]
		)


func _next_seed() -> int:
	if _seed_override >= 0:
		return _seed_override
	return int(Time.get_unix_time_from_system()) ^ Time.get_ticks_msec()


func _replace_screen(scene: PackedScene) -> Control:
	if _screen != null:
		remove_child(_screen)
		_screen.queue_free()
		_screen = null
	var next := scene.instantiate() as Control
	next.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(next)
	_screen = next
	return next


func _set_route(next_route: StringName) -> void:
	_route = next_route
	route_changed.emit(_route)


func _clear_session() -> void:
	_session = null
	_last_encounter_id = &""
