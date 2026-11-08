class_name BattleEngine
extends RefCounted

const PHASE_ROUND_START: StringName = &"round_start"
const PHASE_PLAYER_ACTION: StringName = &"player_action"
const PHASE_ENEMY_ACTION: StringName = &"enemy_action"
const PHASE_BATTLE_ENDED: StringName = &"battle_ended"
const PHASE_INIT_ERROR: StringName = &"init_error"

const OUTCOME_NONE: StringName = &""
const OUTCOME_VICTORY: StringName = &"victory"
const OUTCOME_DEFEAT: StringName = &"defeat"

const ENEMY_PRESSURE_INTERVAL_ROUNDS: int = 2
const ENEMY_PRESSURE_TRIGGER_COUNT: int = 3

const SUPPORTED_EFFECTS: Array[StringName] = [
	&"damage",
	&"block",
	&"heal",
	&"draw",
	&"spirit",
	&"apply_status",
	&"remove_status",
	&"discard",
	&"reveal_intent",
	&"risk",
]

var _content: BattleContentPort
var _balance: BattleBalancePort
var _random: BattleRandomPort

var _battle_id: StringName = &""
var _revision: int = 0
var _round_number: int = 0
var _max_rounds: int = 0
var _phase: StringName = PHASE_INIT_ERROR
var _outcome: StringName = OUTCOME_NONE
var _outcome_reason: StringName = &""

var _player: Dictionary = {}
var _enemies: Array[Dictionary] = []
var _draw_pile: Array[Dictionary] = []
var _discard_pile: Array[Dictionary] = []
var _hand: Array[Dictionary] = []
var _pending_events: Array[BattleEvent] = []

var _starting_hand: int = 0
var _turn_draw_to_hand_size: int = 0
var _max_hand_size: int = 0
var _enemy_pressure_start_round: int = 0
var _chain_threshold: int = 0
var _chain_damage: int = 0
var _chain_draw: int = 0
var _chain_spirit: int = 0
var _chain_count: int = 0


func initialize(
	content: BattleContentPort,
	balance: BattleBalancePort,
	random: BattleRandomPort,
	battle_id: StringName,
	player_state: Dictionary,
	deck_definition_ids: Array,
	enemy_configs: Array
) -> BattleCommandResult:
	_reset_runtime()
	_content = content
	_balance = balance
	_random = random
	_battle_id = battle_id

	if _content == null or _balance == null or _random == null:
		return _initialization_error(&"port_missing")
	if battle_id.is_empty():
		return _initialization_error(&"battle_id_missing")
	if deck_definition_ids.is_empty():
		return _initialization_error(&"empty_deck")
	if enemy_configs.is_empty():
		return _initialization_error(&"empty_enemy_list")

	var max_rounds_value: Variant = _balance.get_value(&"battle.max_rounds")
	var starting_hand_value: Variant = _balance.get_value(&"player.starting_hand")
	var turn_draw_value: Variant = _balance.get_value(&"player.turn_draw_to_hand_size")
	var max_hand_value: Variant = _balance.get_value(&"player.max_hand_size")
	var pressure_value: Variant = _balance.get_value(&"battle.enemy_pressure_start_round")
	if (
		max_rounds_value == null
		or starting_hand_value == null
		or turn_draw_value == null
		or max_hand_value == null
		or pressure_value == null
	):
		return _initialization_error(&"balance_missing")

	_max_rounds = int(max_rounds_value)
	_starting_hand = int(starting_hand_value)
	_turn_draw_to_hand_size = int(turn_draw_value)
	_max_hand_size = int(max_hand_value)
	_enemy_pressure_start_round = int(pressure_value)
	var chain_value: Variant = _balance.get_value(&"battle.chain")
	if chain_value != null:
		if not chain_value is Dictionary:
			return _initialization_error(&"balance_invalid")
		var chain: Dictionary = chain_value
		_chain_threshold = int(chain.get("threshold", 0))
		_chain_damage = int(chain.get("damage", 0))
		_chain_draw = int(chain.get("draw", 0))
		_chain_spirit = int(chain.get("spirit", 0))

	if _max_rounds <= 0 or _starting_hand < 0 or _turn_draw_to_hand_size < 0:
		return _initialization_error(&"balance_invalid")
	if _max_hand_size < _starting_hand or _max_hand_size < _turn_draw_to_hand_size:
		return _initialization_error(&"balance_invalid")
	if _enemy_pressure_start_round <= 0:
		return _initialization_error(&"balance_invalid")
	if (
		_chain_threshold < 0
		or _chain_damage < 0
		or _chain_draw < 0
		or _chain_spirit < 0
	):
		return _initialization_error(&"balance_invalid")

	_player = player_state.duplicate(true)
	if not _validate_player_state(_player):
		return _initialization_error(&"player_state_invalid")

	var occupied_lanes: Dictionary = {}
	for enemy_source in enemy_configs:
		var enemy: Dictionary = enemy_source.duplicate(true)
		if not _validate_enemy_state(enemy):
			return _initialization_error(&"enemy_state_invalid")
		var lane_index: int = int(enemy["lane_index"])
		if occupied_lanes.has(lane_index):
			return _initialization_error(&"enemy_state_invalid")
		occupied_lanes[lane_index] = true
		enemy["pressure_bonus"] = int(enemy.get("pressure_bonus", 0))
		enemy["block"] = int(enemy.get("block", 0))
		enemy["statuses"] = []
		enemy["intent"] = {}
		enemy["defeated_announced"] = false
		var phase_source: Variant = enemy.get("phases", [])
		enemy["phases"] = (
			phase_source.duplicate(true)
			if phase_source is Array
			else phase_source
		)
		enemy["triggered_phases"] = []
		if not _validate_enemy_phases(enemy["phases"]):
			return _initialization_error(&"enemy_state_invalid")
		_enemies.append(enemy)
	_enemies.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a["lane_index"]) < int(b["lane_index"])
	)

	var instance_index: int = 0
	for source_definition_id in deck_definition_ids:
		var definition_id: StringName = StringName(source_definition_id)
		var definition: Dictionary = _content.get_card_definition(definition_id)
		if not _validate_card_definition(definition, definition_id):
			return _initialization_error(&"card_definition_invalid")
		instance_index += 1
		_draw_pile.append({
			"instance_id": StringName("%s.instance.%03d" % [String(battle_id), instance_index]),
			"definition_id": definition_id,
		})

	_shuffle_array(_draw_pile)
	_revision = 1
	_round_number = 1
	_chain_count = 0
	_pending_events.clear()
	_emit(&"BattleStarted", {
		"battle_id": String(_battle_id),
		"round_number": _round_number,
	})
	_begin_round(_starting_hand)
	return BattleCommandResult.new(true, &"ok", _pending_events.duplicate(), get_snapshot())


func submit(command: BattleCommand) -> BattleCommandResult:
	if command == null:
		return _rejected_result(&"invalid_command")
	if _outcome != OUTCOME_NONE:
		return _rejected_result(&"battle_ended")
	if command.type == BattleCommand.PLAY_CARD:
		return _play_card(command)
	if command.type == BattleCommand.END_TURN:
		return _end_turn()
	return _rejected_result(&"invalid_command")


func query_card_play(
	card_instance_id: StringName,
	target_id: StringName = &""
) -> BattlePlayability:
	if _phase != PHASE_PLAYER_ACTION:
		return BattlePlayability.new(false, BattlePlayability.WRONG_PHASE)
	var card_index: int = _find_hand_index(card_instance_id)
	if card_index < 0:
		return BattlePlayability.new(false, BattlePlayability.CARD_NOT_IN_HAND)
	var card: Dictionary = _hand[card_index]
	var definition: Dictionary = _get_card_definition(card)
	if int(definition.get("cost_spirit", -1)) < 0:
		return BattlePlayability.new(false, &"definition_error")
	if int(_player["spirit"]) < int(definition["cost_spirit"]):
		return BattlePlayability.new(false, BattlePlayability.INSUFFICIENT_SPIRIT)
	if not _is_target_valid(definition, target_id):
		return BattlePlayability.new(false, BattlePlayability.INVALID_TARGET)
	return BattlePlayability.new(true, BattlePlayability.PLAYABLE)


func get_snapshot() -> BattleSnapshot:
	var hand_views: Array[Dictionary] = []
	for card in _hand:
		var definition: Dictionary = _get_card_definition(card)
		hand_views.append({
			"instance_id": String(card["instance_id"]),
			"definition_id": String(card["definition_id"]),
			"category": String(definition.get("category", "")),
			"cost_spirit": int(definition.get("cost_spirit", 0)),
			"target_type": String(definition.get("target_type", "none")),
		})

	var enemy_views: Array[Dictionary] = []
	var max_pressure: int = 0
	for enemy in _enemies:
		if _is_alive(enemy):
			max_pressure = maxi(max_pressure, int(enemy.get("pressure_bonus", 0)))
		enemy_views.append({
			"actor_id": String(enemy["id"]),
			"definition_id": String(enemy["definition_id"]),
			"lane_index": int(enemy["lane_index"]),
			"hp": int(enemy["hp"]),
			"max_hp": int(enemy["max_hp"]),
			"block": int(enemy["block"]),
			"statuses": enemy["statuses"].duplicate(true),
			"intent": enemy["intent"].duplicate(true),
			"phases": enemy.get("phases", []).duplicate(true),
			"triggered_phase_count": enemy.get("triggered_phases", []).size(),
		})

	var revision_value: int = _revision
	var round_value: int = _round_number
	var max_rounds_value: int = _max_rounds
	var phase_value: StringName = _phase
	var outcome_value: StringName = _outcome
	var outcome_reason_value: StringName = _outcome_reason
	var battle_id_value: StringName = _battle_id
	return BattleSnapshot.new({
		"revision": revision_value,
		"battle_id": String(battle_id_value),
		"phase": String(phase_value),
		"round_number": round_value,
		"max_rounds": max_rounds_value,
		"enemy_pressure_bonus": max_pressure,
		"chain": {
			"count": _chain_count,
			"threshold": _chain_threshold,
			"damage": _chain_damage,
			"draw": _chain_draw,
			"spirit": _chain_spirit,
		},
		"player": _player.duplicate(true),
		"hand": hand_views,
		"draw_pile_count": _draw_pile.size(),
		"discard_pile_count": _discard_pile.size(),
		"enemies": enemy_views,
		"outcome": String(outcome_value),
		"outcome_reason": String(outcome_reason_value),
	})


func _play_card(command: BattleCommand) -> BattleCommandResult:
	var playability: BattlePlayability = query_card_play(
		command.card_instance_id,
		command.target_id
	)
	if not playability.playable:
		return _rejected_result(playability.reason_code)

	_pending_events.clear()
	var card_index: int = _find_hand_index(command.card_instance_id)
	var card: Dictionary = _hand[card_index]
	var definition: Dictionary = _get_card_definition(card)
	var spirit_before: int = int(_player["spirit"])
	_player["spirit"] = spirit_before - int(definition["cost_spirit"])
	_emit(&"SpiritChanged", {
		"before": spirit_before,
		"after": int(_player["spirit"]),
		"reason_code": "play_card",
	})
	_emit(&"CardPlayed", {
		"card_instance_id": String(command.card_instance_id),
		"definition_id": String(card["definition_id"]),
		"target_id": String(command.target_id),
	})

	# The card leaves the hand before effects resolve, preventing draw effects
	# from exposing the same instance twice.
	_hand.remove_at(card_index)
	for effect_source in definition["effects"]:
		if _outcome != OUTCOME_NONE:
			break
		var effect: Dictionary = effect_source
		_apply_effect(effect, definition, command.target_id)

	_discard_pile.append(card)
	_emit(&"CardDiscarded", {
		"card_instance_id": String(card["instance_id"]),
		"reason_code": "played",
	})
	if _outcome == OUTCOME_NONE:
		_advance_chain(int(definition.get("cost_spirit", 0)))
	_check_outcome_after_player_action()
	_revision += 1
	return BattleCommandResult.new(true, &"ok", _pending_events.duplicate(), get_snapshot())


func _end_turn() -> BattleCommandResult:
	if _phase != PHASE_PLAYER_ACTION:
		return _rejected_result(BattlePlayability.WRONG_PHASE)
	_pending_events.clear()
	_reset_chain(&"turn_end")
	_phase = PHASE_ENEMY_ACTION

	for enemy in _enemies:
		if not _is_alive(enemy):
			continue
		enemy["block"] = 0
		var intent: Dictionary = enemy["intent"]
		var pressure: int = int(enemy.get("pressure_bonus", 0))
		var raw_damage: int = int(enemy["base_attack"]) + pressure
		var weaken_index: int = _find_status_index(enemy["statuses"], &"weaken")
		if weaken_index >= 0:
			raw_damage = maxi(0, raw_damage - int(enemy["statuses"][weaken_index]["stacks"]))
		_emit(&"EnemyActed", {
			"enemy_id": String(enemy["id"]),
			"intent_id": String(intent.get("intent_id", "attack")),
			"damage": raw_damage,
		})
		_apply_damage_to_player(raw_damage, String(enemy["id"]))
		if not _is_alive(_player):
			break

	_tick_enemy_statuses()
	if not _is_alive(_player):
		_finish_battle(OUTCOME_DEFEAT, &"player_died")
		_revision += 1
		return BattleCommandResult.new(true, &"ok", _pending_events.duplicate(), get_snapshot())

	if _all_enemies_defeated():
		_finish_battle(OUTCOME_VICTORY, &"enemies_defeated")
		_revision += 1
		return BattleCommandResult.new(true, &"ok", _pending_events.duplicate(), get_snapshot())

	_round_number += 1
	if _round_number > _max_rounds:
		_finish_battle(OUTCOME_DEFEAT, &"round_limit")
		_revision += 1
		return BattleCommandResult.new(true, &"ok", _pending_events.duplicate(), get_snapshot())

	_begin_round(_turn_draw_to_hand_size)
	_revision += 1
	return BattleCommandResult.new(true, &"ok", _pending_events.duplicate(), get_snapshot())


func _begin_round(draw_target: int) -> void:
	_phase = PHASE_ROUND_START
	_player["block"] = 0
	_player["spirit"] = int(_player["max_spirit"])
	_emit(&"RoundStarted", {"round_number": _round_number})
	_apply_enemy_pressure_if_due()
	_trigger_due_enemy_phases()
	_generate_enemy_intents()
	_draw_to_hand(draw_target)
	_phase = PHASE_PLAYER_ACTION


func _advance_chain(spirit_cost: int) -> void:
	if _chain_threshold <= 0 or spirit_cost <= 0:
		return
	var before := _chain_count
	_chain_count += 1
	_emit(&"ChainChanged", {
		"before": before,
		"after": _chain_count,
		"threshold": _chain_threshold,
		"reason_code": "card_played",
	})
	if _chain_count < _chain_threshold:
		return
	_emit(&"ChainTriggered", {
		"count": _chain_threshold,
		"damage": _chain_damage,
		"draw": _chain_draw,
		"spirit": _chain_spirit,
	})
	if _chain_damage > 0:
		for enemy in _enemies:
			if _is_alive(enemy):
				_apply_damage(enemy, _chain_damage, "chain.echo")
	if _all_enemies_defeated():
		_chain_count = 0
		_emit(&"ChainChanged", {
			"before": _chain_threshold,
			"after": 0,
			"threshold": _chain_threshold,
			"reason_code": "triggered",
		})
		return
	if _chain_spirit > 0:
		var spirit_before := int(_player["spirit"])
		_player["spirit"] = mini(
			int(_player["max_spirit"]),
			spirit_before + _chain_spirit
		)
		_emit(&"SpiritChanged", {
			"before": spirit_before,
			"after": int(_player["spirit"]),
			"reason_code": "chain_echo",
		})
	for _draw_index in range(_chain_draw):
		_draw_one()
	_chain_count = 0
	_emit(&"ChainChanged", {
		"before": _chain_threshold,
		"after": 0,
		"threshold": _chain_threshold,
		"reason_code": "triggered",
	})


func _reset_chain(reason_code: StringName) -> void:
	if _chain_count <= 0:
		return
	var before := _chain_count
	_chain_count = 0
	_emit(&"ChainChanged", {
		"before": before,
		"after": 0,
		"threshold": _chain_threshold,
		"reason_code": String(reason_code),
	})


func _trigger_due_enemy_phases() -> void:
	for enemy in _enemies:
		if not _is_alive(enemy):
			continue
		var phases: Array = enemy.get("phases", [])
		var triggered: Array = enemy.get("triggered_phases", [])
		for phase_index in range(phases.size()):
			if phase_index in triggered:
				continue
			var phase: Dictionary = phases[phase_index]
			if int(phase.get("at_round", -1)) != _round_number:
				continue
			var attack_bonus: int = int(phase.get("base_attack_bonus", 0))
			var block_bonus: int = int(phase.get("block_bonus", 0))
			var heal_amount: int = int(phase.get("heal", 0))
			enemy["base_attack"] = int(enemy["base_attack"]) + attack_bonus
			enemy["block"] = int(enemy["block"]) + block_bonus
			if heal_amount > 0:
				enemy["hp"] = mini(
					int(enemy["max_hp"]),
					int(enemy["hp"]) + heal_amount
				)
			triggered.append(phase_index)
			enemy["triggered_phases"] = triggered
			_emit(&"EnemyPhaseTriggered", {
				"enemy_id": String(enemy["id"]),
				"phase_index": phase_index,
				"phase_id": String(phase.get("id", "")),
				"display_name_zh": String(
					phase.get("display_name_zh", phase.get("id", ""))
				),
				"round_number": _round_number,
				"base_attack_bonus": attack_bonus,
				"block_bonus": block_bonus,
				"heal": heal_amount,
			})


func _generate_enemy_intents() -> void:
	for enemy in _enemies:
		if not _is_alive(enemy):
			continue
		var damage: int = int(enemy["base_attack"]) + int(enemy.get("pressure_bonus", 0))
		enemy["intent"] = {
			"intent_id": "attack",
			"revealed": false,
			"visible_fields": {},
			"damage": damage,
		}
		_emit(&"IntentGenerated", {
			"enemy_id": String(enemy["id"]),
			"intent_id": "attack",
			"visible_fields": {},
		})


func _apply_enemy_pressure_if_due() -> bool:
	var offset: int = _round_number - _enemy_pressure_start_round
	var last_offset: int = (
		ENEMY_PRESSURE_INTERVAL_ROUNDS * (ENEMY_PRESSURE_TRIGGER_COUNT - 1)
	)
	if (
		offset < 0
		or offset > last_offset
		or offset % ENEMY_PRESSURE_INTERVAL_ROUNDS != 0
	):
		return false

	var living_count: int = 0
	var current_bonus: int = 0
	for enemy in _enemies:
		if _is_alive(enemy):
			enemy["pressure_bonus"] = int(enemy.get("pressure_bonus", 0)) + 1
			current_bonus = maxi(current_bonus, int(enemy["pressure_bonus"]))
			living_count += 1
	if living_count > 0:
		_emit(&"EnemyPressureChanged", {
			"bonus": current_bonus,
			"living_enemy_count": living_count,
			"round_number": _round_number,
		})
		return true
	return false


func _apply_effect(
	effect: Dictionary,
	card_definition: Dictionary,
	command_target_id: StringName
) -> void:
	var effect_id: StringName = StringName(effect.get("effect_id", ""))
	var effect_target: StringName = _resolve_effect_target(effect, card_definition, command_target_id)

	match effect_id:
		&"damage":
			var target: Dictionary = _resolve_actor(effect_target)
			if target.is_empty():
				_emit(&"EffectSkipped", {"effect_id": "damage", "reason_code": "target_missing"})
				return
			_apply_damage(target, int(effect["amount"]), String(card_definition["id"]))
		&"block":
			var before_block: int = int(_player["block"])
			_player["block"] = before_block + int(effect["amount"])
			_emit(&"BlockChanged", {
				"target_id": String(_player["actor_id"]),
				"before": before_block,
				"after": int(_player["block"]),
			})
		&"heal":
			var hp_before_heal: int = int(_player["hp"])
			_player["hp"] = mini(int(_player["max_hp"]), hp_before_heal + int(effect["amount"]))
			_emit(&"Healed", {
				"target_id": String(_player["actor_id"]),
				"amount": int(_player["hp"]) - hp_before_heal,
				"hp_before": hp_before_heal,
				"hp_after": int(_player["hp"]),
			})
		&"draw":
			for _draw_index in range(int(effect["count"])):
				_draw_one()
		&"spirit":
			var spirit_before_effect: int = int(_player["spirit"])
			_player["spirit"] = spirit_before_effect + int(effect["amount"])
			_emit(&"SpiritChanged", {
				"before": spirit_before_effect,
				"after": int(_player["spirit"]),
				"reason_code": "card_effect",
			})
		&"apply_status":
			var status_target: Dictionary = _resolve_actor(effect_target)
			if status_target.is_empty():
				_emit(&"EffectSkipped", {
					"effect_id": "apply_status",
					"reason_code": "target_missing",
				})
				return
			_apply_status(
				status_target,
				StringName(effect["status_id"]),
				int(effect["stacks"]),
				int(effect.get("duration", 1)),
				int(effect.get("max_stacks", 999))
			)
		&"remove_status":
			var remove_target: Dictionary = _resolve_actor(effect_target)
			if remove_target.is_empty():
				_emit(&"EffectSkipped", {
					"effect_id": "remove_status",
					"reason_code": "target_missing",
				})
				return
			_remove_status(remove_target, StringName(effect["status_id"]), int(effect.get("stacks", -1)))
		&"discard":
			var discard_count: int = mini(int(effect["count"]), _hand.size())
			for _discard_index in range(discard_count):
				if _hand.is_empty():
					break
				var discarded: Dictionary = _hand.pop_back()
				_discard_pile.append(discarded)
				_emit(&"CardDiscarded", {
					"card_instance_id": String(discarded["instance_id"]),
					"reason_code": "effect",
				})
		&"reveal_intent":
			var reveal_target: Dictionary = _resolve_actor(effect_target)
			if reveal_target.is_empty() or not _is_alive(reveal_target):
				_emit(&"EffectSkipped", {
					"effect_id": "reveal_intent",
					"reason_code": "target_missing",
				})
				return
			reveal_target["intent"]["revealed"] = true
			reveal_target["intent"]["visible_fields"] = {
				"damage": int(reveal_target["intent"].get("damage", 0)),
			}
			_emit(&"IntentRevealed", {
				"enemy_id": String(reveal_target["id"]),
				"revealed_fields": reveal_target["intent"]["visible_fields"].duplicate(true),
			})
		&"risk":
			_apply_risk(StringName(effect["risk_id"]), int(effect["amount"]))
		_:
			_emit(&"EffectSkipped", {
				"effect_id": String(effect_id),
				"reason_code": "effect_not_registered",
			})


func _resolve_effect_target(
	effect: Dictionary,
	card_definition: Dictionary,
	command_target_id: StringName
) -> StringName:
	var raw_target: String = String(effect.get("target", ""))
	if raw_target.is_empty():
		raw_target = String(card_definition.get("target_type", "none"))
	match StringName(raw_target):
		&"enemy":
			return command_target_id
		&"self":
			return StringName(_player["actor_id"])
		&"run":
			return &"run"
		_:
			return &""


func _resolve_actor(actor_id: StringName) -> Dictionary:
	if actor_id == StringName(_player["actor_id"]):
		return _player
	for enemy in _enemies:
		if StringName(enemy["id"]) == actor_id and _is_alive(enemy):
			return enemy
	return {}


func _apply_damage(target: Dictionary, base_amount: int, source_id: String) -> void:
	var amount: int = maxi(0, base_amount)
	if StringName(target.get("actor_id", target.get("id", ""))) == StringName(_player["actor_id"]):
		_apply_damage_to_player(amount, source_id)
		return

	var mark_index: int = _find_status_index(target["statuses"], &"mark")
	if mark_index >= 0:
		amount += int(target["statuses"][mark_index]["stacks"])
		var removed_stacks: int = int(target["statuses"][mark_index]["stacks"])
		target["statuses"].remove_at(mark_index)
		_emit(&"StatusChanged", {
			"target_id": String(target["id"]),
			"status_id": "mark",
			"stacks": 0,
			"removed_stacks": removed_stacks,
		})

	var block_before: int = int(target["block"])
	var absorbed: int = mini(block_before, amount)
	target["block"] = block_before - absorbed
	if absorbed > 0:
		_emit(&"BlockChanged", {
			"target_id": String(target["id"]),
			"before": block_before,
			"after": int(target["block"]),
		})
	var hp_before: int = int(target["hp"])
	target["hp"] = maxi(0, hp_before - (amount - absorbed))
	_emit(&"DamageApplied", {
		"source_id": source_id,
		"target_id": String(target["id"]),
		"amount": amount - absorbed,
		"raw_amount": amount,
		"hp_before": hp_before,
		"hp_after": int(target["hp"]),
	})
	if int(target["hp"]) <= 0 and not bool(target.get("defeated_announced", false)):
		target["defeated_announced"] = true
		_emit(&"EnemyDefeated", {"enemy_id": String(target["id"])})


func _apply_damage_to_player(amount: int, source_id: String) -> void:
	var block_before: int = int(_player["block"])
	var absorbed: int = mini(block_before, maxi(0, amount))
	_player["block"] = block_before - absorbed
	if absorbed > 0:
		_emit(&"BlockChanged", {
			"target_id": String(_player["actor_id"]),
			"before": block_before,
			"after": int(_player["block"]),
		})
	var hp_before: int = int(_player["hp"])
	_player["hp"] = maxi(0, hp_before - (maxi(0, amount) - absorbed))
	_emit(&"DamageApplied", {
		"source_id": source_id,
		"target_id": String(_player["actor_id"]),
		"amount": maxi(0, amount) - absorbed,
		"raw_amount": maxi(0, amount),
		"hp_before": hp_before,
		"hp_after": int(_player["hp"]),
	})


func _apply_status(
	target: Dictionary,
	status_id: StringName,
	stacks: int,
	duration: int,
	max_stacks: int
) -> void:
	var statuses: Array = target["statuses"]
	var index: int = _find_status_index(statuses, status_id)
	if status_id == &"weaken":
		if index >= 0:
			statuses[index]["duration"] = maxi(int(statuses[index]["duration"]), duration)
			statuses[index]["stacks"] = stacks
		else:
			statuses.append({
				"status_id": String(status_id),
				"stacks": stacks,
				"duration": duration,
			})
	else:
		if index >= 0:
			statuses[index]["stacks"] = mini(
				max_stacks,
				int(statuses[index]["stacks"]) + stacks
			)
			statuses[index]["duration"] = maxi(int(statuses[index]["duration"]), duration)
		else:
			statuses.append({
				"status_id": String(status_id),
				"stacks": mini(max_stacks, stacks),
				"duration": duration,
			})
	var target_id: String = _actor_id(target)
	var event_stacks: int = stacks
	if index >= 0:
		event_stacks = int(statuses[index]["stacks"])
	else:
		event_stacks = int(statuses[statuses.size() - 1]["stacks"])
	_emit(&"StatusChanged", {
		"target_id": target_id,
		"status_id": String(status_id),
		"stacks": event_stacks,
		"duration": duration,
	})


func _remove_status(target: Dictionary, status_id: StringName, requested_stacks: int) -> void:
	var index: int = _find_status_index(target["statuses"], status_id)
	if index < 0:
		return
	var status: Dictionary = target["statuses"][index]
	if requested_stacks < 0 or requested_stacks >= int(status["stacks"]):
		target["statuses"].remove_at(index)
		_emit(&"StatusChanged", {
			"target_id": _actor_id(target),
			"status_id": String(status_id),
			"stacks": 0,
		})
	else:
		status["stacks"] = int(status["stacks"]) - requested_stacks
		_emit(&"StatusChanged", {
			"target_id": _actor_id(target),
			"status_id": String(status_id),
			"stacks": int(status["stacks"]),
		})


func _tick_enemy_statuses() -> void:
	for enemy in _enemies:
		if not _is_alive(enemy):
			continue
		var statuses: Array = enemy["statuses"]
		var index: int = statuses.size() - 1
		while index >= 0:
			_tick_single_status(statuses, index)
			index -= 1


func _tick_single_status(statuses: Array, index: int) -> void:
	if index < 0 or index >= statuses.size():
		return
	var status: Dictionary = statuses[index]
	status["duration"] = int(status["duration"]) - 1
	if int(status["duration"]) <= 0:
		statuses.remove_at(index)


func _apply_risk(risk_id: StringName, amount: int) -> void:
	var current_key: String
	var max_key: String
	match risk_id:
		&"corruption":
			current_key = "corruption"
			max_key = "max_corruption"
		&"attention":
			current_key = "attention"
			max_key = "max_attention"
		_:
			_emit(&"EffectSkipped", {
				"effect_id": "risk",
				"reason_code": "risk_not_registered",
			})
			return
	var before: int = int(_player[current_key])
	_player[current_key] = clampi(
		before + amount,
		0,
		int(_player[max_key])
	)
	_emit(&"RiskChanged", {
		"risk_id": String(risk_id),
		"before": before,
		"after": int(_player[current_key]),
		"reason_code": "card_effect",
	})


func _draw_to_hand(target_size: int) -> void:
	while _hand.size() < target_size:
		if not _draw_one():
			break


func _draw_one() -> bool:
	if _draw_pile.is_empty():
		if _discard_pile.is_empty():
			return false
		var reshuffled_count: int = _discard_pile.size()
		_draw_pile = _discard_pile.duplicate(true)
		_discard_pile.clear()
		_shuffle_array(_draw_pile)
		_emit(&"DeckReshuffled", {"discard_count": reshuffled_count})
	if _draw_pile.is_empty():
		return false
	var card: Dictionary = _draw_pile.pop_front()
	if _hand.size() >= _max_hand_size:
		_discard_pile.append(card)
		_emit(&"CardDiscarded", {
			"card_instance_id": String(card["instance_id"]),
			"reason_code": "hand_limit",
		})
		return true
	_hand.append(card)
	_emit(&"CardDrawn", {
		"card_instance_id": String(card["instance_id"]),
		"definition_id": String(card["definition_id"]),
	})
	return true


func _shuffle_array(values: Array) -> void:
	for index in range(values.size() - 1, 0, -1):
		var swap_index: int = _random.next_int(index + 1)
		if swap_index < 0 or swap_index > index:
			swap_index = index
		var temporary: Variant = values[index]
		values[index] = values[swap_index]
		values[swap_index] = temporary


func _check_outcome_after_player_action() -> void:
	if _all_enemies_defeated():
		_finish_battle(OUTCOME_VICTORY, &"enemies_defeated")
	elif not _is_alive(_player):
		_finish_battle(OUTCOME_DEFEAT, &"player_died")


func _finish_battle(outcome: StringName, reason: StringName) -> void:
	if _outcome != OUTCOME_NONE:
		return
	_outcome = outcome
	_outcome_reason = reason
	_phase = PHASE_BATTLE_ENDED
	_emit(&"BattleEnded", {
		"outcome": String(outcome),
		"reason_code": String(reason),
	})


func _all_enemies_defeated() -> bool:
	for enemy in _enemies:
		if _is_alive(enemy):
			return false
	return true


func _is_target_valid(card_definition: Dictionary, target_id: StringName) -> bool:
	var target_type: StringName = StringName(card_definition["target_type"])
	if target_type == &"none" or target_type == &"self":
		return target_id.is_empty()
	if target_type != &"enemy":
		return false
	if target_id.is_empty():
		return false
	var target: Dictionary = _resolve_actor(target_id)
	return not target.is_empty() and target != _player


func _validate_player_state(player: Dictionary) -> bool:
	var required: Array[StringName] = [
		&"actor_id",
		&"hp",
		&"max_hp",
		&"block",
		&"spirit",
		&"max_spirit",
		&"corruption",
		&"max_corruption",
		&"attention",
		&"max_attention",
		&"statuses",
	]
	for key in required:
		if not player.has(String(key)):
			return false
	if int(player["max_hp"]) <= 0 or int(player["hp"]) < 0:
		return false
	if int(player["hp"]) > int(player["max_hp"]):
		return false
	if int(player["max_spirit"]) < 0 or int(player["spirit"]) < 0:
		return false
	return player["statuses"] is Array


func _validate_enemy_state(enemy: Dictionary) -> bool:
	var required: Array[StringName] = [
		&"id",
		&"definition_id",
		&"lane_index",
		&"hp",
		&"max_hp",
		&"base_attack",
	]
	for key in required:
		if not enemy.has(String(key)):
			return false
	if int(enemy["hp"]) <= 0 or int(enemy["max_hp"]) <= 0:
		return false
	if int(enemy["lane_index"]) < 0 or int(enemy["lane_index"]) >= 3:
		return false
	return true


func _validate_enemy_phases(phases_value: Variant) -> bool:
	if not phases_value is Array:
		return false
	var seen_rounds: Dictionary = {}
	for value in phases_value:
		if not value is Dictionary:
			return false
		var phase: Dictionary = value
		if not _is_positive_integer(phase.get("at_round")):
			return false
		var at_round: int = int(phase["at_round"])
		if seen_rounds.has(at_round):
			return false
		seen_rounds[at_round] = true
		if not _is_non_negative_integer(phase.get("base_attack_bonus", 0)):
			return false
		if not _is_non_negative_integer(phase.get("block_bonus", 0)):
			return false
		if not _is_non_negative_integer(phase.get("heal", 0)):
			return false
	return true


func _validate_card_definition(definition: Dictionary, expected_id: StringName) -> bool:
	if definition.is_empty():
		return false
	if StringName(definition.get("id", "")) != expected_id:
		return false
	if int(definition.get("cost_spirit", -1)) < 0:
		return false
	var target_type: StringName = StringName(definition.get("target_type", ""))
	if target_type not in [&"none", &"self", &"enemy"]:
		return false
	var effects: Variant = definition.get("effects", null)
	if not (effects is Array) or effects.is_empty():
		return false
	for effect in effects:
		if not (effect is Dictionary):
			return false
		if not _validate_effect_definition(effect):
			return false
	return true


func _validate_effect_definition(effect: Dictionary) -> bool:
	var effect_id: StringName = StringName(effect.get("effect_id", ""))
	if effect_id not in SUPPORTED_EFFECTS:
		return false
	var effect_target: StringName = StringName(effect.get("target", ""))
	if (
		not effect_target.is_empty()
		and effect_target not in [&"self", &"enemy", &"run", &"none"]
	):
		return false
	match effect_id:
		&"damage", &"block", &"heal", &"spirit":
			return _is_non_negative_integer(effect.get("amount"))
		&"draw", &"discard":
			return _is_non_negative_integer(effect.get("count"))
		&"apply_status":
			if not (effect.get("status_id") is String):
				return false
			if String(effect["status_id"]) not in ["mark", "weaken"]:
				return false
			if not _is_positive_integer(effect.get("stacks")):
				return false
			if not _is_positive_integer(effect.get("duration")):
				return false
			return _is_positive_integer(effect.get("max_stacks", 999))
		&"remove_status":
			return (
				effect.get("status_id") is String
				and String(effect["status_id"]) in ["mark", "weaken"]
			)
		&"reveal_intent":
			return true
		&"risk":
			return (
				effect.get("risk_id") is String
				and String(effect["risk_id"]) in ["corruption", "attention"]
				and _is_integer_number(effect.get("amount"))
			)
	return false


func _is_integer_number(value: Variant) -> bool:
	if value is int:
		return true
	if value is float:
		return is_finite(value) and is_equal_approx(value, round(value))
	return false


func _is_non_negative_integer(value: Variant) -> bool:
	return _is_integer_number(value) and int(value) >= 0


func _is_positive_integer(value: Variant) -> bool:
	return _is_integer_number(value) and int(value) > 0


func _get_card_definition(card: Dictionary) -> Dictionary:
	return _content.get_card_definition(StringName(card["definition_id"]))


func _find_hand_index(card_instance_id: StringName) -> int:
	for index in range(_hand.size()):
		if StringName(_hand[index]["instance_id"]) == card_instance_id:
			return index
	return -1


func _find_status_index(statuses: Array, status_id: StringName) -> int:
	for index in range(statuses.size()):
		if StringName(statuses[index].get("status_id", "")) == status_id:
			return index
	return -1


func _is_alive(actor: Dictionary) -> bool:
	return int(actor.get("hp", 0)) > 0


func _actor_id(actor: Dictionary) -> String:
	return String(actor.get("actor_id", actor.get("id", "")))


func _emit(event_type: StringName, event_data: Dictionary) -> void:
	_pending_events.append(BattleEvent.new(event_type, event_data))


func _rejected_result(reason: StringName) -> BattleCommandResult:
	return BattleCommandResult.new(false, reason, [], get_snapshot())


func _initialization_error(reason: StringName) -> BattleCommandResult:
	_phase = PHASE_INIT_ERROR
	_outcome_reason = reason
	_revision = maxi(_revision, 1)
	return BattleCommandResult.new(false, reason, [], get_snapshot())


func _reset_runtime() -> void:
	_content = null
	_balance = null
	_random = null
	_battle_id = &""
	_revision = 0
	_round_number = 0
	_max_rounds = 0
	_phase = PHASE_INIT_ERROR
	_outcome = OUTCOME_NONE
	_outcome_reason = &""
	_chain_threshold = 0
	_chain_damage = 0
	_chain_draw = 0
	_chain_spirit = 0
	_chain_count = 0
	_player = {}
	_enemies.clear()
	_draw_pile.clear()
	_discard_pile.clear()
	_hand.clear()
	_pending_events.clear()
