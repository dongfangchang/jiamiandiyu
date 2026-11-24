class_name GameSession
extends RefCounted

const BattleEngineScript := preload("res://src/gameplay/battle_engine.gd")

var catalog: RefCounted
var battle_id: StringName
var encounter_id: StringName
var root_seed: int

var _engine: RefCounted
var _deck_definition_ids: Array[String] = []
var _progression: RefCounted
var _challenge_engine: RefCounted


func _init(
	content_catalog: RefCounted,
	content: BattleContentPort,
	balance: BattleBalancePort,
	random: BattleRandomPort,
	run_seed: int,
	selected_encounter_id: StringName,
	progression: RefCounted = null,
	player_state_override: Dictionary = {},
	apply_progression_modifiers: bool = true,
	challenge_engine: RefCounted = null,
	deck_override_ids: Array = []
) -> void:
	catalog = content_catalog
	_progression = progression
	_challenge_engine = challenge_engine
	root_seed = run_seed
	encounter_id = selected_encounter_id
	_engine = BattleEngineScript.new()
	var resolved = catalog.resolve_encounter(encounter_id)
	if not resolved.ok:
		return
	_deck_definition_ids.assign(
		deck_override_ids
		if not deck_override_ids.is_empty()
		else resolved.data.get("deck_definition_ids", [])
	)
	if _progression != null:
		_deck_definition_ids.assign(
			_progression.build_owned_battle_deck(_deck_definition_ids)
		)
		content = _progression.create_upgraded_content(content)
	if _challenge_engine != null:
		_deck_definition_ids.assign(
			_challenge_engine.build_battle_deck(_deck_definition_ids)
		)
	battle_id = StringName("%s.%d" % [String(encounter_id), run_seed])
	var player_state: Dictionary = (
		player_state_override.duplicate(true)
		if not player_state_override.is_empty()
		else _build_player_state(balance)
	)
	if _progression != null and apply_progression_modifiers:
		player_state = _progression.apply_battle_modifiers(player_state)
	var enemy_configs: Array = resolved.data.get("enemy_configs", [])
	if _challenge_engine != null:
		enemy_configs = _challenge_engine.prepare_enemy_configs(enemy_configs)
	_engine.initialize(
		content,
		balance,
		random,
		battle_id,
		player_state,
		_deck_definition_ids,
		enemy_configs
	)


func is_ready() -> bool:
	var snapshot := get_snapshot()
	return not snapshot.data.is_empty() and String(snapshot.data.get("phase", "")) != "init_error"


func get_snapshot() -> BattleSnapshot:
	return _engine.get_snapshot()


func query_card_play(
	card_instance_id: StringName,
	target_id: StringName = &"",
	discard_ids: Array = []
) -> BattlePlayability:
	return _engine.query_card_play(card_instance_id, target_id, discard_ids)


func auto_discard_ids_for(card_instance_id: StringName) -> Array[StringName]:
	return _engine.auto_discard_ids_for(card_instance_id)


func submit(command: BattleCommand) -> BattleCommandResult:
	return _engine.submit(command)


func get_deck_definition_ids() -> Array[String]:
	return _deck_definition_ids.duplicate()


func _build_player_state(balance: BattleBalancePort) -> Dictionary:
	var max_corruption: Variant = balance.get_value(&"player.max_corruption")
	var max_attention: Variant = balance.get_value(&"player.max_attention")
	return {
		"actor_id": "player",
		"hp": int(balance.get_value(&"player.starting_health")),
		"max_hp": int(balance.get_value(&"player.base_max_hp")),
		"block": 0,
		"spirit": 0,
		"max_spirit": int(balance.get_value(&"player.base_max_spirit")),
		"corruption": 0,
		"max_corruption": int(max_corruption) if max_corruption != null else 0,
		"attention": 0,
		"max_attention": int(max_attention) if max_attention != null else 0,
		"statuses": [],
	}
