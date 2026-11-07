extends Control

signal route_changed(route_name: StringName)

const AppBootstrapScript := preload("res://src/app/bootstrap.gd")
const ProgressionCommandScript := preload("res://src/core/progression_command.gd")
const UpgradedBattleContentPortScript := preload("res://src/gameplay/upgraded_battle_content_port.gd")
const StartScreenScene := preload("res://scenes/ui/start_screen.tscn")
const IdentityScreenScene := preload("res://scenes/ui/identity_screen.tscn")
const BattleScreenScene := preload("res://scenes/ui/battle_screen.tscn")
const RewardScreenScene := preload("res://scenes/ui/reward_screen.tscn")
const GachaScreenScene := preload("res://scenes/ui/gacha_screen.tscn")
const UpgradeScreenScene := preload("res://scenes/ui/upgrade_screen.tscn")
const ResultScreenScene := preload("res://scenes/ui/result_screen.tscn")

const ROUTE_START: StringName = &"start"
const ROUTE_IDENTITY: StringName = &"identity"
const ROUTE_HUB: StringName = &"hub"
const ROUTE_BATTLE: StringName = &"battle"
const ROUTE_REWARD: StringName = &"reward"
const ROUTE_GACHA: StringName = &"gacha"
const ROUTE_UPGRADE: StringName = &"upgrade"
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
	var resolved_seed := _resolve_seed(seed_value)
	var result = AppBootstrapScript.start_campaign(
		resolved_seed,
		encounter_id,
		{"save_directory": save_directory},
		checkpoint_slot,
		false
	)
	if not result.ok:
		_show_start_error(result)
		return result
	_session = result.data
	_last_encounter_id = _session.encounter_id
	_show_progression_home()
	return result


func continue_saved_checkpoint() -> InfrastructureResult:
	var inspected = AppBootstrapScript.inspect_checkpoint(
		checkpoint_slot,
		save_directory
	)
	if not inspected.ok or String(inspected.data.get("status", "")) != "loaded":
		var failed := InfrastructureResult.failure(
			&"checkpoint_not_available",
			"No loaded checkpoint is available to continue."
		)
		_show_start_error(failed)
		return failed
	_last_checkpoint_summary = inspected.data.get("checkpoint", {}).duplicate(true)
	var seed_value := int(_last_checkpoint_summary.get("rng_seed", _resolve_seed(-1)))
	var encounter_id := StringName(
		String(_last_checkpoint_summary.get("encounter_id", ""))
	)
	var result = AppBootstrapScript.start_campaign(
		seed_value,
		encounter_id,
		{"save_directory": save_directory},
		checkpoint_slot,
		true
	)
	if not result.ok:
		_show_start_error(result)
		return result
	_session = result.data
	_last_encounter_id = _session.encounter_id
	_show_progression_home()
	return result


func get_current_route() -> StringName:
	return _route


func get_current_screen() -> Control:
	return _screen


func get_session() -> RefCounted:
	return _session


func get_progression_snapshot() -> ProgressionSnapshot:
	if _session == null:
		return null
	return _session.get_progression_snapshot()


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


func _show_progression_home() -> void:
	if _session == null:
		_show_start_error(InfrastructureResult.failure(
			&"campaign_missing",
			"Campaign session was not created."
		))
		return
	var snapshot: ProgressionSnapshot = _session.get_progression_snapshot()
	var phase := String(snapshot.data.get("phase", "")) if snapshot != null else ""
	match phase:
		"identity_selection":
			_show_identity_selection()
		"hub":
			_show_hub()
		"reward":
			_show_reward()
		_:
			_show_start_error(InfrastructureResult.failure(
				&"progression_phase_invalid",
				"Campaign progression entered an unsupported phase.",
				{"phase": phase}
			))


func _show_identity_selection() -> void:
	var screen := _replace_screen(IdentityScreenScene)
	_connect_identity_screen(screen)
	screen.apply_snapshot(_session.get_progression_snapshot())
	_set_route(ROUTE_IDENTITY)


func _show_hub() -> void:
	var screen := _replace_screen(IdentityScreenScene)
	_connect_identity_screen(screen)
	screen.apply_snapshot(_session.get_progression_snapshot())
	_set_route(ROUTE_HUB)


func _connect_identity_screen(screen: Control) -> void:
	screen.identity_selected.connect(_on_identity_selected)
	screen.battle_requested.connect(_on_battle_requested)
	screen.gacha_requested.connect(_on_gacha_requested)
	screen.upgrade_requested.connect(_on_upgrade_requested)


func _on_identity_selected(identity_id: StringName) -> void:
	if _session == null or _route != ROUTE_IDENTITY:
		return
	var result: ProgressionCommandResult = _session.submit_progression(
		ProgressionCommandScript.select_identity(identity_id)
	)
	if _screen != null:
		_screen.apply_command_result(result)
	if result.accepted:
		_show_hub()


func _on_battle_requested() -> void:
	if _session == null or _route != ROUTE_HUB:
		return
	var result: InfrastructureResult = _session.begin_battle()
	if not result.ok:
		_show_hub()
		push_error(
			"Unable to begin battle: %s: %s" % [
				String(result.code),
				result.message,
			]
		)
		return
	_show_battle()


func _show_battle() -> void:
	if _session == null:
		return
	var snapshot: BattleSnapshot = _session.get_battle_snapshot()
	if snapshot == null:
		_show_hub()
		push_error("Campaign battle snapshot is unavailable.")
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
	screen.apply_snapshot(snapshot)
	_set_route(ROUTE_BATTLE)


func _on_battle_command_requested(command: BattleCommand) -> void:
	if _session == null or _screen == null or _route != ROUTE_BATTLE:
		return
	var result: BattleCommandResult = _session.submit_battle(command)
	_screen.apply_command_result(result)


func _on_battle_finished(snapshot: BattleSnapshot) -> void:
	call_deferred("_route_after_battle", snapshot)


func _route_after_battle(snapshot: BattleSnapshot) -> void:
	if snapshot == null or _route != ROUTE_BATTLE or _session == null:
		return
	var progression: ProgressionSnapshot = _session.get_progression_snapshot()
	var phase := String(progression.data.get("phase", ""))
	var outcome := String(snapshot.data.get("outcome", ""))
	if outcome == "victory" and phase == "reward":
		_show_reward()
		return
	_show_result(snapshot)


func _show_reward() -> void:
	var screen := _replace_screen(RewardScreenScene)
	screen.reward_claimed.connect(_on_reward_claimed)
	screen.hub_requested.connect(_show_hub)
	screen.apply_snapshot(_session.get_progression_snapshot())
	_set_route(ROUTE_REWARD)


func _on_reward_claimed(reward_id: StringName) -> void:
	if _session == null or _screen == null or _route != ROUTE_REWARD:
		return
	var result: ProgressionCommandResult = _session.submit_progression(
		ProgressionCommandScript.claim_reward(reward_id)
	)
	_screen.apply_command_result(result)
	if result.accepted:
		_show_hub()


func _on_gacha_requested() -> void:
	if _session == null or _route != ROUTE_HUB:
		return
	_show_gacha()


func _show_gacha() -> void:
	var screen := _replace_screen(GachaScreenScene)
	screen.configure(_build_card_names())
	screen.draw_requested.connect(_on_draw_requested)
	screen.back_requested.connect(_show_hub)
	screen.apply_snapshot(_session.get_progression_snapshot())
	_set_route(ROUTE_GACHA)


func _on_draw_requested(pull_count: int) -> void:
	if _session == null or _screen == null or _route != ROUTE_GACHA:
		return
	var result: ProgressionCommandResult = _session.submit_progression(
		ProgressionCommandScript.draw_gacha(pull_count)
	)
	_screen.apply_command_result(result)


func _on_upgrade_requested() -> void:
	if _session == null or _route != ROUTE_HUB:
		return
	_show_upgrade()


func _show_upgrade() -> void:
	var screen := _replace_screen(UpgradeScreenScene)
	screen.configure(_build_card_names(), _build_effect_previews())
	screen.upgrade_requested.connect(_on_upgrade_command_requested)
	screen.back_requested.connect(_show_hub)
	screen.apply_snapshot(_session.get_progression_snapshot())
	_set_route(ROUTE_UPGRADE)


func _on_upgrade_command_requested(definition_id: StringName) -> void:
	if _session == null or _screen == null or _route != ROUTE_UPGRADE:
		return
	var result: ProgressionCommandResult = _session.submit_progression(
		ProgressionCommandScript.upgrade_card(definition_id)
	)
	_screen.apply_command_result(result)


func _show_result(snapshot: BattleSnapshot) -> void:
	if _session == null:
		show_start_screen()
		return
	var save_status := "failed"
	var save_message := "Post-battle checkpoint result was not produced."
	if _session.last_checkpoint_result != null:
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
		String(_session.encounter_name),
		save_status,
		save_message
	)
	screen.return_to_title_requested.connect(show_start_screen)
	screen.retry_requested.connect(_show_hub)
	_set_route(ROUTE_RESULT)


func _build_display_labels() -> Dictionary:
	var card_labels: Dictionary = {}
	var enemy_labels: Dictionary = {}
	if _session == null:
		return {"cards": card_labels, "enemies": enemy_labels}
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


func _build_card_names() -> Dictionary:
	var names: Dictionary = {}
	if _session == null:
		return names
	var snapshot: ProgressionSnapshot = _session.get_progression_snapshot()
	for card_value in snapshot.data.get("collection", []):
		if not card_value is Dictionary:
			continue
		var definition_id := StringName(card_value.get("definition_id", ""))
		names[definition_id] = _session.card_display_name(definition_id)
	return names


func _build_effect_previews() -> Dictionary:
	var previews: Dictionary = {}
	if _session == null:
		return previews
	var snapshot: ProgressionSnapshot = _session.get_progression_snapshot()
	var upgrades: Dictionary = {}
	for card_value in snapshot.data.get("collection", []):
		if not card_value is Dictionary:
			continue
		var definition_id := StringName(card_value.get("definition_id", ""))
		var upgrade: Dictionary = (
			_session.progression_content.get_upgrade_definition(definition_id)
		)
		if not upgrade.is_empty():
			upgrades[String(definition_id)] = upgrade
	for definition_key in upgrades:
		var upgrade: Dictionary = upgrades[definition_key]
		var max_level := int(upgrade.get("max_level", 0))
		var levels: Array[String] = []
		for level in range(max_level + 1):
			var content: BattleContentPort = UpgradedBattleContentPortScript.new(
				_session.base_content,
				upgrades,
				{definition_key: level}
			)
			var definition: Dictionary = content.get_card_definition(
				StringName(definition_key)
			)
			levels.append(_format_card_effects(definition))
		previews[definition_key] = levels
	return previews


func _format_card_effects(definition: Dictionary) -> String:
	var parts: Array[String] = []
	for effect_value in definition.get("effects", []):
		if not effect_value is Dictionary:
			continue
		var effect: Dictionary = effect_value
		var effect_id := String(effect.get("effect_id", ""))
		match effect_id:
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
				parts.append("施加 %d 层 %s" % [
					int(effect.get("stacks", 0)),
					_status_label(StringName(effect.get("status_id", ""))),
				])
			"remove_status":
				parts.append("移除 %s" % _status_label(
					StringName(effect.get("status_id", ""))
				))
			"reveal_intent":
				parts.append("揭示敌人意图")
			"risk":
				parts.append("污染 %+d" % int(effect.get("amount", 0)))
			"discard":
				parts.append("弃置 %d 张牌" % int(effect.get("count", 0)))
			_:
				parts.append(String(effect_id))
	return "；".join(parts) if not parts.is_empty() else "无直接数值效果"


func _status_label(status_id: StringName) -> String:
	match status_id:
		&"mark":
			return "标记"
		&"weaken":
			return "削弱"
		_:
			return String(status_id)


func _on_new_game_requested() -> void:
	start_new_game(_resolve_seed(-1))


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


func _resolve_seed(seed_value: int) -> int:
	if seed_value >= 0:
		return seed_value
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
