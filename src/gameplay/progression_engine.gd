class_name ProgressionEngine
extends RefCounted

const PHASE_IDENTITY: StringName = &"identity_selection"
const PHASE_HUB: StringName = &"hub"
const PHASE_REWARD: StringName = &"reward"
const PHASE_INIT_ERROR: StringName = &"init_error"

const OUTCOME_VICTORY: StringName = &"victory"
const OUTCOME_DEFEAT: StringName = &"defeat"

const BAL_STARTING_TICKETS: StringName = &"progression.starting_divination_tickets"
const BAL_SINGLE_COST: StringName = &"gacha.single_cost"
const BAL_TRIPLE_COST: StringName = &"gacha.triple_cost"
const BAL_RARITY_WEIGHTS: StringName = &"gacha.rarity_weights"
const BAL_RARE_PITY: StringName = &"gacha.rare_pity"
const BAL_DUPLICATE_FRAGMENTS: StringName = &"gacha.duplicate_fragments"
const BAL_UPGRADE_COSTS: StringName = &"upgrade.cost_by_next_level"
const BAL_REWARD_AMOUNTS: StringName = &"reward.amounts"
const SEQUENCE_FRAGMENT_REWARD_ID := "reward.sequence_fragments"

const RARITY_COMMON: StringName = &"common"
const RARITY_RARE: StringName = &"rare"

var _content: ProgressionContentPort
var _balance: BattleBalancePort
var _random: BattleRandomPort

var _revision: int = 0
var _state: Dictionary = {}
var _pending_events: Array[ProgressionEvent] = []
var _identities_by_id: Dictionary = {}
var _identity_order: Array[String] = []
var _starter_card_ids: Array[String] = []
var _gacha_pool_by_rarity: Dictionary = {}
var _reward_options: Array[Dictionary] = []
var _upgrade_definitions: Dictionary = {}
var _potion_definitions_by_id: Dictionary = {}
var _digestion_rules: Dictionary = {}
var _balance_error: StringName = &""


func _init(
	content: ProgressionContentPort,
	balance: BattleBalancePort,
	random: BattleRandomPort
) -> void:
	_content = content
	_balance = balance
	_random = random


func initialize(initial_state: Dictionary = {}) -> ProgressionCommandResult:
	_reset_runtime()
	if _content == null or _balance == null or _random == null:
		return _initialization_error(&"port_missing")
	if not _load_content():
		return _initialization_error(&"content_invalid")
	if not _load_required_balance():
		return _initialization_error(&"balance_missing")

	if initial_state.is_empty():
		_state = _new_state()
	else:
		var restored := _restore_state(initial_state)
		if not restored.accepted:
			return restored
	_state["phase"] = StringName(_state.get("phase", PHASE_IDENTITY))
	_state["identity_id"] = StringName(_state.get("identity_id", &""))
	_revision = maxi(1, int(_state.get("revision", 1)))
	_state["revision"] = _revision
	return ProgressionCommandResult.new(
		true,
		&"ok",
		[
			ProgressionEvent.new(&"ProgressionReady", {
				"phase": String(_state["phase"]),
			})
		],
		get_snapshot()
	)


func submit(command: ProgressionCommand) -> ProgressionCommandResult:
	if command == null:
		return _rejected(&"invalid_command")
	if StringName(_state.get("phase", PHASE_INIT_ERROR)) == PHASE_INIT_ERROR:
		return _rejected(&"not_initialized")
	_pending_events.clear()
	var result: ProgressionCommandResult
	match command.type:
		ProgressionCommand.SELECT_IDENTITY:
			result = _select_identity(command.identity_id)
		ProgressionCommand.RESOLVE_BATTLE:
			result = _resolve_battle(command.battle_outcome)
		ProgressionCommand.CLAIM_REWARD:
			result = _claim_reward(command.reward_id)
		ProgressionCommand.DRAW_GACHA:
			result = _draw_gacha(command.pull_count)
		ProgressionCommand.UPGRADE_CARD:
			result = _upgrade_card(command.definition_id)
		ProgressionCommand.RECORD_PERFORMANCE:
			result = _record_performance(command.definition_id)
		ProgressionCommand.CONSUME_POTION:
			result = _consume_potion(command.potion_id)
		_:
			return _rejected(&"invalid_command")
	if result.accepted:
		_revision += 1
		_state["revision"] = _revision
		result.snapshot = get_snapshot()
	return result


func get_snapshot() -> ProgressionSnapshot:
	var collection_views: Array[Dictionary] = []
	var collection: Dictionary = _state.get("collection", {})
	for definition_id in _all_card_ids():
		var card_state: Dictionary = _card_state(collection, definition_id)
		var upgrade: Dictionary = _upgrade_definitions.get(definition_id, {})
		var next_level: int = int(card_state["level"]) + 1
		collection_views.append({
			"definition_id": definition_id,
			"copies": int(card_state["copies"]),
			"level": int(card_state["level"]),
			"fragments": int(card_state["fragments"]),
			"max_level": int(upgrade.get("max_level", 0)),
			"next_upgrade_cost": _upgrade_cost(next_level),
		})

	var identity_views: Array[Dictionary] = []
	for identity_id in _identity_order:
		var identity: Dictionary = _identities_by_id.get(identity_id, {})
		identity_views.append({
			"id": identity_id,
			"display_name_zh": String(identity.get("display_name_zh", identity_id)),
			"description_zh": String(identity.get("description_zh", "")),
			"passive_text_zh": String(identity.get("passive_text_zh", "")),
			"battle_modifiers": identity.get("battle_modifiers", {}).duplicate(true),
			"selected": StringName(_state.get("identity_id", &"")) == StringName(identity_id),
		})

	var reward_views: Array[Dictionary] = []
	for reward in _reward_options:
		var reward_id := String(reward.get("id", ""))
		if reward_id in _state.get("reward_option_ids", []):
			var view: Dictionary = reward.duplicate(true)
			view["amount"] = _reward_amount(reward_id)
			reward_views.append(view)
	if SEQUENCE_FRAGMENT_REWARD_ID in _state.get("reward_option_ids", []):
		var target_id := String(_state.get("sequence_reward_target_id", ""))
		var target := _content.get_card_definition(StringName(target_id))
		reward_views.append({
			"id": SEQUENCE_FRAGMENT_REWARD_ID,
			"display_name_zh": "%s残页" % String(target.get("display_name_zh", "序列卡牌")),
			"kind": "card_fragments",
			"target_definition_id": target_id,
			"amount": _reward_amount("reward.ink_dart_fragments"),
		})

	var identity_id := StringName(_state.get("identity_id", &""))
	var identity: Dictionary = _identities_by_id.get(String(identity_id), {})
	var rarity_weights: Dictionary = _value_or(Dictionary(), BAL_RARITY_WEIGHTS)
	return ProgressionSnapshot.new({
		"revision": _revision,
		"phase": String(_state.get("phase", PHASE_INIT_ERROR)),
		"identity_id": String(identity_id),
		"sequence": int(_state.get("sequence", 9)),
		"identity_options": identity_views,
		"battle_modifiers": identity.get("battle_modifiers", {}).duplicate(true),
		"divination_tickets": int(_state.get("divination_tickets", 0)),
		"collection": collection_views,
		"pity_counter": int(_state.get("pity_counter", 0)),
		"rare_pity": int(_value_or(0, BAL_RARE_PITY)),
		"gacha_costs": {
			"single": int(_value_or(0, BAL_SINGLE_COST)),
			"triple": int(_value_or(0, BAL_TRIPLE_COST)),
		},
		"rarity_weights": rarity_weights.duplicate(true),
		"reward_options": reward_views,
		"last_battle_outcome": String(_state.get("last_battle_outcome", "")),
		"last_gacha_results": _state.get("last_gacha_results", []).duplicate(true),
		"gacha_history": _state.get("gacha_history", []).duplicate(true),
		"digestion": _digestion_snapshot(),
		"potion_inventory": _state.get("potion_inventory", []).duplicate(true),
	})


func export_persistent_state() -> Dictionary:
	return _state.duplicate(true)


func apply_reward_bundle(reward_amounts: Dictionary) -> ProgressionCommandResult:
	if StringName(_state.get("phase", PHASE_INIT_ERROR)) == PHASE_INIT_ERROR:
		return _rejected(&"not_initialized")
	if reward_amounts.is_empty():
		return _rejected(&"reward_bundle_empty")
	_pending_events.clear()

	# Validate the entire bundle before touching resources so an invalid entry
	# cannot leave a partially applied challenge reward.
	var planned: Array[Dictionary] = []
	for reward_id_value in reward_amounts:
		var reward_id := String(reward_id_value)
		var amount_value: Variant = _finite_integer(
			reward_amounts[reward_id_value]
		)
		if amount_value == null or int(amount_value) < 0:
			return _rejected(&"reward_amount_invalid")
		var reward := _reward_by_id(reward_id)
		if reward.is_empty():
			return _rejected(&"reward_not_supported")
		var kind := String(reward.get("kind", ""))
		var target_id := String(reward.get("target_definition_id", ""))
		if kind == "card_fragments":
			if (
				target_id.is_empty()
				or not _content.has_card_definition(StringName(target_id))
			):
				return _rejected(&"content_invalid")
		elif kind != "divination_tickets":
			return _rejected(&"reward_not_supported")
		planned.append({
			"reward_id": reward_id,
			"kind": kind,
			"target_definition_id": target_id,
			"amount": int(amount_value),
		})

	for entry in planned:
		var amount: int = int(entry["amount"])
		if amount <= 0:
			continue
		if String(entry["kind"]) == "divination_tickets":
			_state["divination_tickets"] = (
				int(_state.get("divination_tickets", 0)) + amount
			)
		else:
			_add_fragments(String(entry["target_definition_id"]), amount)
		_emit(&"RewardBundleApplied", {
			"reward_id": String(entry["reward_id"]),
			"kind": String(entry["kind"]),
			"target_definition_id": String(entry["target_definition_id"]),
			"amount": amount,
		})

	_revision += 1
	_state["revision"] = _revision
	return _success()


func grant_potion(potion_id: StringName) -> ProgressionCommandResult:
	if StringName(_state.get("phase", PHASE_INIT_ERROR)) == PHASE_INIT_ERROR:
		return _rejected(&"not_initialized")
	var key := String(potion_id)
	if not _potion_definitions_by_id.has(key):
		return _rejected(&"potion_not_supported")
	var inventory: Array = _state.get("potion_inventory", [])
	if key in inventory:
		return _rejected(&"potion_already_owned")
	inventory.append(key)
	_state["potion_inventory"] = inventory
	_emit(&"PotionLooted", {
		"potion_id": key,
		"display_name_zh": String(_potion_definitions_by_id[key].get("display_name_zh", key)),
	})
	_revision += 1
	_state["revision"] = _revision
	return _success()


func record_card_performance(definition_id: StringName) -> ProgressionCommandResult:
	return _record_performance(definition_id)


func consume_potion(potion_id: StringName) -> ProgressionCommandResult:
	return _consume_potion(potion_id)


func get_card_levels() -> Dictionary:
	var levels: Dictionary = {}
	var collection: Dictionary = _state.get("collection", {})
	for definition_id in collection:
		var card_state: Dictionary = collection[definition_id]
		levels[String(definition_id)] = int(card_state.get("level", 0))
	return levels


func build_owned_battle_deck(source_deck_ids: Array) -> Array[String]:
	var deck: Array[String] = []
	var collection: Dictionary = _state.get("collection", {})
	for value in source_deck_ids:
		var definition_id := String(value)
		var card_state: Dictionary = collection.get(definition_id, {})
		if int(card_state.get("copies", 0)) > 0:
			deck.append(definition_id)
	return deck


func create_upgraded_content(base: BattleContentPort) -> BattleContentPort:
	return UpgradedBattleContentPort.new(
		base,
		_upgrade_definitions,
		get_card_levels()
	)


func apply_battle_modifiers(player_state: Dictionary) -> Dictionary:
	var modified: Dictionary = player_state.duplicate(true)
	var identity_id := String(_state.get("identity_id", ""))
	var identity: Dictionary = _identities_by_id.get(identity_id, {})
	var modifiers_value: Variant = identity.get("battle_modifiers", {})
	if not modifiers_value is Dictionary:
		return modified
	var modifiers: Dictionary = modifiers_value
	var max_hp_bonus: int = int(modifiers.get("max_hp_bonus", 0))
	if max_hp_bonus != 0:
		modified["max_hp"] = maxi(1, int(modified.get("max_hp", 1)) + max_hp_bonus)
		modified["hp"] = mini(
			int(modified["max_hp"]),
			maxi(0, int(modified.get("hp", 0)) + max_hp_bonus)
		)
	var max_attention_bonus: int = int(modifiers.get("max_attention_bonus", 0))
	if max_attention_bonus != 0:
		modified["max_attention"] = maxi(
			1,
			int(modified.get("max_attention", 1)) + max_attention_bonus
		)
	var starting_attention: int = int(modifiers.get("starting_attention", 0))
	if starting_attention != 0:
		modified["attention"] = clampi(
			int(modified.get("attention", 0)) + starting_attention,
			0,
			int(modified.get("max_attention", 10))
		)
	var max_spirit_bonus: int = int(modifiers.get("max_spirit_bonus", 0))
	if max_spirit_bonus != 0:
		modified["max_spirit"] = maxi(
			0,
			int(modified.get("max_spirit", 0)) + max_spirit_bonus
		)
		modified["spirit"] = mini(
			int(modified["max_spirit"]),
			maxi(0, int(modified.get("spirit", 0)) + max_spirit_bonus)
		)
	return modified


func _select_identity(identity_id: StringName) -> ProgressionCommandResult:
	if StringName(_state.get("phase", "")) != PHASE_IDENTITY:
		return _rejected(&"wrong_phase")
	if not _identities_by_id.has(String(identity_id)):
		return _rejected(&"unknown_identity")
	_state["identity_id"] = String(identity_id)
	_state["phase"] = String(PHASE_HUB)
	_emit(&"IdentitySelected", {
		"identity_id": String(identity_id),
	})
	return _success()


func _resolve_battle(outcome: StringName) -> ProgressionCommandResult:
	if StringName(_state.get("phase", "")) != PHASE_HUB:
		return _rejected(&"wrong_phase")
	if outcome != OUTCOME_VICTORY and outcome != OUTCOME_DEFEAT:
		return _rejected(&"invalid_battle_outcome")
	_state["last_battle_outcome"] = String(outcome)
	_emit(&"BattleResolved", {
		"outcome": String(outcome),
	})
	if outcome == OUTCOME_VICTORY:
		_apply_victory_resources()
		_state["sequence_reward_target_id"] = _pick_sequence_reward_target()
		_state["reward_option_ids"] = _all_reward_ids()
		_state["phase"] = String(PHASE_REWARD)
	else:
		_state["reward_option_ids"] = []
		_state["phase"] = String(PHASE_HUB)
	return _success()


func _claim_reward(reward_id: StringName) -> ProgressionCommandResult:
	if StringName(_state.get("phase", "")) != PHASE_REWARD:
		return _rejected(&"wrong_phase")
	var offered: Array = _state.get("reward_option_ids", [])
	if not String(reward_id) in offered:
		return _rejected(&"reward_not_available")
	var reward: Dictionary = _reward_by_id(String(reward_id))
	if reward.is_empty():
		return _rejected(&"reward_not_available")
	var amount: int = _reward_amount(String(reward_id))
	if String(reward_id) == SEQUENCE_FRAGMENT_REWARD_ID:
		amount = _reward_amount("reward.ink_dart_fragments")
	if amount <= 0:
		return _rejected(&"balance_missing")
	var kind := String(reward.get("kind", ""))
	if kind == "divination_tickets":
		_state["divination_tickets"] = int(_state.get("divination_tickets", 0)) + amount
	elif kind == "card_fragments":
		var target_id := String(reward.get("target_definition_id", ""))
		if String(reward_id) == SEQUENCE_FRAGMENT_REWARD_ID:
			target_id = String(_state.get("sequence_reward_target_id", target_id))
		if target_id.is_empty() or not _content.has_card_definition(StringName(target_id)):
			return _rejected(&"content_invalid")
		_add_fragments(target_id, amount)
	else:
		return _rejected(&"reward_not_supported")
	_state["reward_option_ids"] = []
	_state["phase"] = String(PHASE_HUB)
	_emit(&"RewardClaimed", {
		"reward_id": String(reward_id),
		"kind": kind,
		"amount": amount,
	})
	return _success()


func _draw_gacha(pull_count: int) -> ProgressionCommandResult:
	if StringName(_state.get("phase", "")) != PHASE_HUB:
		return _rejected(&"wrong_phase")
	if pull_count != 1 and pull_count != 3:
		return _rejected(&"invalid_pull_count")
	var cost: int = int(_value_or(0, BAL_SINGLE_COST if pull_count == 1 else BAL_TRIPLE_COST))
	if cost <= 0:
		return _rejected(&"balance_missing")
	var tickets: int = int(_state.get("divination_tickets", 0))
	if tickets < cost:
		return _rejected(&"insufficient_divination_tickets")
	_state["divination_tickets"] = tickets - cost
	var pull_results: Array[Dictionary] = []
	for _pull_index in range(pull_count):
		var entry := _draw_one_entry()
		if entry.is_empty():
			return _rejected(&"content_invalid")
		var definition_id := String(entry.get("definition_id", ""))
		var rarity := String(entry.get("rarity", "common"))
		var collection: Dictionary = _state["collection"]
		var card_state: Dictionary = _card_state(collection, definition_id)
		var duplicate := int(card_state["copies"]) > 0
		var fragments: int = 0
		if duplicate:
			fragments = _duplicate_fragments()
			card_state["fragments"] = int(card_state["fragments"]) + fragments
			card_state["copies"] = int(card_state["copies"]) + 1
		else:
			card_state["copies"] = 1
		collection[definition_id] = card_state
		_state["collection"] = collection
		_update_pity(rarity)
		var pull_result := {
			"definition_id": definition_id,
			"rarity": rarity,
			"duplicate": duplicate,
			"fragments": fragments,
		}
		pull_results.append(pull_result)
		_emit(&"GachaCardDrawn", pull_result.duplicate(true))
	_state["last_gacha_results"] = pull_results
	var gacha_history: Array = _state.get("gacha_history", [])
	gacha_history.append({
		"draw_index": gacha_history.size() + 1,
		"pull_count": pull_count,
		"results": pull_results.duplicate(true),
	})
	_state["gacha_history"] = gacha_history
	_emit(&"GachaCompleted", {
		"pull_count": pull_count,
		"cost": cost,
	})
	return _success()


func _upgrade_card(definition_id: StringName) -> ProgressionCommandResult:
	if StringName(_state.get("phase", "")) != PHASE_HUB:
		return _rejected(&"wrong_phase")
	var definition_key := String(definition_id)
	var upgrade_value: Variant = _upgrade_definitions.get(definition_key, {})
	if not upgrade_value is Dictionary or upgrade_value.is_empty():
		return _rejected(&"upgrade_not_supported")
	var upgrade: Dictionary = upgrade_value
	var collection: Dictionary = _state["collection"]
	var card_state: Dictionary = _card_state(collection, definition_key)
	if int(card_state["copies"]) <= 0:
		return _rejected(&"card_not_owned")
	var current_level: int = int(card_state["level"])
	var max_level: int = int(upgrade.get("max_level", 0))
	if current_level >= max_level:
		return _rejected(&"card_level_max")
	var next_level: int = current_level + 1
	var cost: int = _upgrade_cost(next_level)
	if cost <= 0:
		return _rejected(&"balance_missing")
	if int(card_state["fragments"]) < cost:
		return _rejected(&"insufficient_fragments")
	card_state["fragments"] = int(card_state["fragments"]) - cost
	card_state["level"] = next_level
	collection[definition_key] = card_state
	_state["collection"] = collection
	_emit(&"CardUpgraded", {
		"definition_id": definition_key,
		"from_level": current_level,
		"to_level": next_level,
		"cost": cost,
	})
	return _success()


func _record_performance(definition_id: StringName) -> ProgressionCommandResult:
	if StringName(_state.get("phase", PHASE_INIT_ERROR)) == PHASE_INIT_ERROR:
		return _rejected(&"not_initialized")
	var digestion: Dictionary = _state.get("digestion", {}).duplicate(true)
	if bool(digestion.get("consumed", false)):
		return _success()
	var definition: Dictionary = _content.get_card_definition(definition_id)
	if definition.is_empty():
		return _rejected(&"unknown_card")
	var card_tags: Array = definition.get("mechanic_tags", [])
	var eligible_tags: Array = _digestion_rules.get("eligible_mechanic_tags", [])
	var matched := false
	for tag in card_tags:
		if String(tag) in eligible_tags:
			matched = true
			break
	if not matched:
		return _success()
	var before := int(digestion.get("progress", 0))
	var gain := maxi(1, int(definition.get("acting_value", 1)))
	digestion["progress"] = mini(
		int(digestion.get("required", 1)),
		before + gain
	)
	_state["digestion"] = digestion
	_emit(&"PotionDigestionAdvanced", {
		"definition_id": String(definition_id),
		"before": before,
		"after": int(digestion["progress"]),
		"gain": int(digestion["progress"]) - before,
		"potion_id": String(digestion.get("potion_id", "")),
	})
	return _success()


func _consume_potion(potion_id: StringName) -> ProgressionCommandResult:
	if StringName(_state.get("phase", PHASE_INIT_ERROR)) != PHASE_HUB:
		return _rejected(&"wrong_phase")
	var key := String(potion_id)
	var inventory: Array = _state.get("potion_inventory", [])
	if not key in inventory:
		return _rejected(&"potion_not_owned")
	var digestion: Dictionary = _state.get("digestion", {})
	if bool(digestion.get("consumed", false)) or String(digestion.get("potion_id", "")) != key:
		return _rejected(&"potion_not_ready")
	if int(digestion.get("progress", 0)) < int(digestion.get("required", 1)):
		return _rejected(&"digestion_insufficient")
	inventory.erase(key)
	_state["potion_inventory"] = inventory
	digestion["consumed"] = true
	digestion["progress"] = 0
	_state["digestion"] = digestion
	_state["sequence"] = int(digestion.get("to_sequence", 8))
	_emit(&"PotionConsumed", {
		"potion_id": key,
		"from_sequence": int(digestion.get("from_sequence", 9)),
		"to_sequence": int(digestion.get("to_sequence", 8)),
		"sequence_name_zh": String(digestion.get("to_sequence_name_zh", "小丑")),
	})
	return _success()


func _apply_victory_resources() -> void:
	var identity_id := String(_state.get("identity_id", ""))
	var identity: Dictionary = _identities_by_id.get(identity_id, {})
	var rewards: Variant = identity.get("victory_resources", {})
	if not rewards is Dictionary:
		return
	for resource_id in rewards:
		var amount: int = int(rewards[resource_id])
		if resource_id == "divination_tickets":
			_state["divination_tickets"] = int(_state.get("divination_tickets", 0)) + amount
			_emit(&"ResourceGained", {
				"resource_id": "divination_tickets",
				"amount": amount,
				"source": "identity",
			})


func _draw_one_entry() -> Dictionary:
	var rare_pity: int = int(_value_or(0, BAL_RARE_PITY))
	var rarity: StringName
	if rare_pity > 0 and int(_state.get("pity_counter", 0)) + 1 >= rare_pity:
		rarity = RARITY_RARE
	else:
		rarity = _roll_rarity()
	var entries: Array = _unlocked_gacha_entries(
		_gacha_pool_by_rarity.get(String(rarity), [])
	)
	if entries.is_empty():
		return {}
	return entries[_random.next_int(entries.size())].duplicate(true)


func _unlocked_gacha_entries(entries: Array) -> Array:
	var result: Array = []
	var current_sequence := int(_state.get("sequence", 9))
	for entry_value in entries:
		if not entry_value is Dictionary:
			continue
		var definition_id := String(entry_value.get("definition_id", ""))
		var definition := _content.get_card_definition(StringName(definition_id))
		var band := String(definition.get("sequence_band", "序列9"))
		if _is_sequence_locked(band, current_sequence):
			continue
		result.append(entry_value.duplicate(true))
	return result


func _is_sequence_locked(sequence_band: String, current_sequence: int) -> bool:
	if current_sequence <= 8:
		return false
	return sequence_band.contains("序列8") or sequence_band.contains("→8")


func _roll_rarity() -> StringName:
	var weights: Dictionary = _value_or(Dictionary(), BAL_RARITY_WEIGHTS)
	var total: int = 0
	for value in weights.values():
		total += maxi(0, int(value))
	if total <= 0:
		return RARITY_COMMON
	var roll: int = _random.next_int(total)
	var cursor: int = 0
	for rarity in [RARITY_COMMON, RARITY_RARE]:
		cursor += maxi(0, int(weights.get(String(rarity), 0)))
		if roll < cursor:
			return rarity
	return RARITY_COMMON


func _update_pity(rarity: String) -> void:
	if StringName(rarity) == RARITY_RARE:
		_state["pity_counter"] = 0
	else:
		_state["pity_counter"] = int(_state.get("pity_counter", 0)) + 1


func _duplicate_fragments() -> int:
	var amount: int = int(_value_or(0, BAL_DUPLICATE_FRAGMENTS))
	var identity_id := String(_state.get("identity_id", ""))
	var identity: Dictionary = _identities_by_id.get(identity_id, {})
	amount += int(identity.get("duplicate_fragment_bonus", 0))
	return maxi(0, amount)


func _add_fragments(definition_id: String, amount: int) -> void:
	var collection: Dictionary = _state["collection"]
	var card_state: Dictionary = _card_state(collection, definition_id)
	card_state["fragments"] = int(card_state["fragments"]) + amount
	collection[definition_id] = card_state
	_state["collection"] = collection


func _upgrade_cost(next_level: int) -> int:
	var costs: Dictionary = _value_or(Dictionary(), BAL_UPGRADE_COSTS)
	var value: Variant = costs.get(str(next_level), costs.get(next_level, 0))
	return maxi(0, int(value))


func _reward_amount(reward_id: String) -> int:
	var amounts: Dictionary = _value_or(Dictionary(), BAL_REWARD_AMOUNTS)
	return maxi(0, int(amounts.get(reward_id, 0)))


func _reward_by_id(reward_id: String) -> Dictionary:
	if reward_id == SEQUENCE_FRAGMENT_REWARD_ID:
		return {
			"id": SEQUENCE_FRAGMENT_REWARD_ID,
			"display_name_zh": "序列 %d 残页" % int(_state.get("sequence", 9)),
			"kind": "card_fragments",
			"target_definition_id": String(_state.get("sequence_reward_target_id", "")),
		}
	for reward in _reward_options:
		if String(reward.get("id", "")) == reward_id:
			return reward.duplicate(true)
	return {}


func _all_reward_ids() -> Array[String]:
	var result: Array[String] = []
	for reward in _reward_options:
		result.append(String(reward.get("id", "")))
	if not String(_state.get("sequence_reward_target_id", "")).is_empty():
		result.append(SEQUENCE_FRAGMENT_REWARD_ID)
	return result


func _pick_sequence_reward_target() -> String:
	var candidates: Array[String] = []
	var sequence := int(_state.get("sequence", 9))
	for definition_id in _all_card_ids():
		var definition := _content.get_card_definition(StringName(definition_id))
		var band := String(definition.get("sequence_band", "序列9"))
		if sequence == 9 and (band.contains("序列9") or band.contains("→8")):
			candidates.append(definition_id)
		elif sequence == 8 and band.contains("序列8"):
			candidates.append(definition_id)
	if candidates.is_empty():
		return "card.skill.ink_dart"
	return candidates[_random.next_int(candidates.size())]


func _all_card_ids() -> Array[String]:
	var result: Array[String] = []
	for definition_id in _starter_card_ids:
		if not definition_id in result:
			result.append(definition_id)
	for entries_value in _gacha_pool_by_rarity.values():
		for entry in entries_value:
			var definition_id := String(entry.get("definition_id", ""))
			if not definition_id in result:
				result.append(definition_id)
	result.sort()
	return result


func _card_state(collection: Dictionary, definition_id: String) -> Dictionary:
	var value: Variant = collection.get(definition_id, {})
	var state: Dictionary = value.duplicate(true) if value is Dictionary else {}
	state["copies"] = maxi(0, int(state.get("copies", 0)))
	state["level"] = maxi(0, int(state.get("level", 0)))
	state["fragments"] = maxi(0, int(state.get("fragments", 0)))
	return state


func _load_content() -> bool:
	var identities_value: Variant = _content.get_identity_options()
	if not identities_value is Array or identities_value.is_empty():
		return false
	for value in identities_value:
		if not value is Dictionary:
			return false
		var identity: Dictionary = value
		var identity_id := String(identity.get("id", ""))
		if identity_id.is_empty() or _identities_by_id.has(identity_id):
			return false
		_identities_by_id[identity_id] = identity.duplicate(true)
		_identity_order.append(identity_id)

	for value in _content.get_starter_card_ids():
		var definition_id := String(value)
		if not _content.has_card_definition(StringName(definition_id)):
			return false
		_starter_card_ids.append(definition_id)
	if _starter_card_ids.is_empty():
		return false

	var seen_pool_ids: Dictionary = {}
	var pool_value: Variant = _content.get_gacha_pool()
	if not pool_value is Array or pool_value.is_empty():
		return false
	for value in pool_value:
		if not value is Dictionary:
			return false
		var entry: Dictionary = value
		var definition_id := String(entry.get("definition_id", ""))
		var rarity := String(entry.get("rarity", ""))
		if (
			definition_id.is_empty()
			or seen_pool_ids.has(definition_id)
			or not rarity in ["common", "rare"]
			or not _content.has_card_definition(StringName(definition_id))
		):
			return false
		seen_pool_ids[definition_id] = true
		var bucket: Array = _gacha_pool_by_rarity.get(rarity, [])
		bucket.append(entry.duplicate(true))
		_gacha_pool_by_rarity[rarity] = bucket
	if _gacha_pool_by_rarity.is_empty():
		return false

	var rewards_value: Variant = _content.get_reward_options()
	if not rewards_value is Array or rewards_value.is_empty():
		return false
	var seen_reward_ids: Dictionary = {}
	for value in rewards_value:
		if not value is Dictionary:
			return false
		var reward: Dictionary = value
		var reward_id := String(reward.get("id", ""))
		if reward_id.is_empty() or seen_reward_ids.has(reward_id):
			return false
		var kind := String(reward.get("kind", ""))
		if kind == "card_fragments":
			var target_id := String(reward.get("target_definition_id", ""))
			if target_id.is_empty() or not _content.has_card_definition(StringName(target_id)):
				return false
		elif kind != "divination_tickets":
			return false
		seen_reward_ids[reward_id] = true
		_reward_options.append(reward.duplicate(true))

	for definition_id in _all_card_ids():
		var upgrade: Dictionary = _content.get_upgrade_definition(StringName(definition_id))
		if not upgrade.is_empty():
			if int(upgrade.get("max_level", 0)) <= 0:
				return false
			var bonuses: Variant = upgrade.get("bonuses", [])
			if not bonuses is Array or bonuses.is_empty():
				return false
			_upgrade_definitions[definition_id] = upgrade.duplicate(true)
	var potion_values: Variant = _content.get_potion_definitions()
	if not potion_values is Array or potion_values.is_empty():
		potion_values = [{
			"id": "potion.seer_to_clown",
			"display_name_zh": "小丑魔药",
			"sequence_from": 9,
			"sequence_to": 8,
		}]
	for potion_value in potion_values:
		if not potion_value is Dictionary:
			return false
		var potion: Dictionary = potion_value
		var potion_id := String(potion.get("id", ""))
		if potion_id.is_empty() or _potion_definitions_by_id.has(potion_id):
			return false
		_potion_definitions_by_id[potion_id] = potion.duplicate(true)
	_digestion_rules = _content.get_digestion_rules().duplicate(true)
	if _digestion_rules.is_empty():
		_digestion_rules = {
			"potion_id": "potion.seer_to_clown",
			"from_sequence": 9,
			"to_sequence": 8,
			"to_sequence_name_zh": "小丑",
			"required": 8,
			"eligible_mechanic_tags": ["占卜", "预感", "意图揭示", "标记"],
		}

	# Every gacha entry must have a meaningful upgrade path. Otherwise duplicates
	# can produce fragments that the player can never spend.
	for entries_value in _gacha_pool_by_rarity.values():
		for entry_value in entries_value:
			var definition_id := String(entry_value.get("definition_id", ""))
			if not _upgrade_definitions.has(definition_id):
				return false
	return true


func _load_required_balance() -> bool:
	var required: Array[StringName] = [
		BAL_STARTING_TICKETS,
		BAL_SINGLE_COST,
		BAL_TRIPLE_COST,
		BAL_RARITY_WEIGHTS,
		BAL_RARE_PITY,
		BAL_DUPLICATE_FRAGMENTS,
		BAL_UPGRADE_COSTS,
		BAL_REWARD_AMOUNTS,
	]
	for parameter_id in required:
		if _balance.get_value(parameter_id) == null:
			_balance_error = parameter_id
			return false
	if not _balance.get_value(BAL_RARITY_WEIGHTS) is Dictionary:
		_balance_error = BAL_RARITY_WEIGHTS
		return false
	if not _balance.get_value(BAL_UPGRADE_COSTS) is Dictionary:
		_balance_error = BAL_UPGRADE_COSTS
		return false
	if not _balance.get_value(BAL_REWARD_AMOUNTS) is Dictionary:
		_balance_error = BAL_REWARD_AMOUNTS
		return false
	if int(_balance.get_value(BAL_STARTING_TICKETS)) < 0:
		_balance_error = BAL_STARTING_TICKETS
		return false
	if int(_balance.get_value(BAL_SINGLE_COST)) <= 0:
		_balance_error = BAL_SINGLE_COST
		return false
	if int(_balance.get_value(BAL_TRIPLE_COST)) <= 0:
		_balance_error = BAL_TRIPLE_COST
		return false
	if int(_balance.get_value(BAL_RARE_PITY)) < 0:
		_balance_error = BAL_RARE_PITY
		return false
	if int(_balance.get_value(BAL_DUPLICATE_FRAGMENTS)) < 0:
		_balance_error = BAL_DUPLICATE_FRAGMENTS
		return false
	var weights: Dictionary = _balance.get_value(BAL_RARITY_WEIGHTS)
	for value in weights.values():
		if int(value) < 0:
			_balance_error = BAL_RARITY_WEIGHTS
			return false
	return true


func _new_state() -> Dictionary:
	var collection: Dictionary = {}
	for definition_id in _starter_card_ids:
		collection[definition_id] = {
			"copies": 1,
			"level": 0,
			"fragments": 0,
		}
	return {
		"phase": String(PHASE_IDENTITY),
		"identity_id": "",
		"divination_tickets": int(_value_or(0, BAL_STARTING_TICKETS)),
		"collection": collection,
		"pity_counter": 0,
		"reward_option_ids": [],
		"last_battle_outcome": "",
		"last_gacha_results": [],
		"gacha_history": [],
		"sequence_reward_target_id": "",
		"potion_inventory": [],
		"sequence": 9,
		"digestion": _new_digestion_state(),
		"revision": 1,
	}


func _restore_state(value: Dictionary) -> ProgressionCommandResult:
	if not value.get("collection") is Dictionary:
		return _restore_error(&"collection_missing")
	var restored := value.duplicate(true)
	var collection: Dictionary = restored["collection"]
	var normalized: Dictionary = {}
	for definition_id in collection:
		if not _content.has_card_definition(StringName(definition_id)):
			return _restore_error(&"unknown_card")
		var source: Variant = collection[definition_id]
		if not source is Dictionary:
			return _restore_error(&"card_state_invalid")
		var source_state: Dictionary = source
		normalized[String(definition_id)] = {
			"copies": int(source_state.get("copies", 0)),
			"level": int(source_state.get("level", 0)),
			"fragments": int(source_state.get("fragments", 0)),
		}
	var phase := StringName(restored.get("phase", PHASE_IDENTITY))
	if phase not in [PHASE_IDENTITY, PHASE_HUB, PHASE_REWARD]:
		return _restore_error(&"phase_invalid")
	var identity_id := String(restored.get("identity_id", ""))
	if not identity_id.is_empty() and not _identities_by_id.has(identity_id):
		return _restore_error(&"identity_invalid")
	if phase == PHASE_IDENTITY and not identity_id.is_empty():
		return _restore_error(&"identity_phase_invalid")
	if phase != PHASE_IDENTITY and identity_id.is_empty():
		return _restore_error(&"identity_phase_invalid")
	for definition_id in normalized:
		var upgrade_value: Variant = _upgrade_definitions.get(definition_id, {})
		var max_level := 0
		if upgrade_value is Dictionary:
			max_level = int(upgrade_value.get("max_level", 0))
		if int(normalized[definition_id]["level"]) > max_level:
			return _restore_error(&"card_level_invalid")
	var digestion: Variant = restored.get("digestion", _new_digestion_state())
	if not digestion is Dictionary:
		return _restore_error(&"digestion_invalid")
	var potion_inventory: Variant = restored.get("potion_inventory", [])
	if not potion_inventory is Array:
		return _restore_error(&"potion_inventory_invalid")
	for potion_id in potion_inventory:
		if not _potion_definitions_by_id.has(String(potion_id)):
			return _restore_error(&"potion_invalid")
	var gacha_history: Variant = restored.get("gacha_history", [])
	if not gacha_history is Array:
		return _restore_error(&"gacha_history_invalid")
	var sequence_reward_target_id := String(restored.get("sequence_reward_target_id", ""))
	if not sequence_reward_target_id.is_empty() and not _content.has_card_definition(StringName(sequence_reward_target_id)):
		return _restore_error(&"sequence_reward_target_invalid")
	restored["phase"] = String(phase)
	restored["collection"] = normalized
	restored["digestion"] = digestion.duplicate(true)
	restored["potion_inventory"] = potion_inventory.duplicate()
	restored["gacha_history"] = gacha_history.duplicate(true)
	restored["sequence_reward_target_id"] = sequence_reward_target_id
	restored["sequence"] = int(restored.get("sequence", 9))
	_state = restored
	return ProgressionCommandResult.new(true, &"ok", [], get_snapshot())


func _restore_error(reason: StringName) -> ProgressionCommandResult:
	_state = {}
	_revision = 0
	return ProgressionCommandResult.new(false, reason, [], get_snapshot())


func _value_or(fallback: Variant, parameter_id: StringName) -> Variant:
	var value: Variant = _balance.get_value(parameter_id)
	return fallback if value == null else value


func _finite_integer(value: Variant) -> Variant:
	if value is int:
		return value
	if value is float and is_finite(value) and is_equal_approx(value, round(value)):
		return int(value)
	return null


func _emit(event_type: StringName, event_data: Dictionary) -> void:
	_pending_events.append(ProgressionEvent.new(event_type, event_data))


func _success() -> ProgressionCommandResult:
	return ProgressionCommandResult.new(
		true,
		&"ok",
		_pending_events.duplicate(),
		get_snapshot()
	)


func _rejected(reason: StringName) -> ProgressionCommandResult:
	return ProgressionCommandResult.new(
		false,
		reason,
		[],
		get_snapshot()
	)


func _initialization_error(reason: StringName) -> ProgressionCommandResult:
	_state = {"phase": String(PHASE_INIT_ERROR)}
	_revision = 0
	return ProgressionCommandResult.new(false, reason, [], get_snapshot())


func _reset_runtime() -> void:
	_revision = 0
	_state = {}
	_pending_events.clear()
	_identities_by_id.clear()
	_identity_order.clear()
	_starter_card_ids.clear()
	_gacha_pool_by_rarity.clear()
	_reward_options.clear()
	_upgrade_definitions.clear()
	_potion_definitions_by_id.clear()
	_digestion_rules.clear()
	_balance_error = &""


func _new_digestion_state() -> Dictionary:
	var rule := _digestion_rules
	return {
		"potion_id": String(rule.get("potion_id", "potion.seer_to_clown")),
		"from_sequence": int(rule.get("from_sequence", 9)),
		"to_sequence": int(rule.get("to_sequence", 8)),
		"to_sequence_name_zh": String(rule.get("to_sequence_name_zh", "小丑")),
		"progress": 0,
		"required": int(rule.get("required", 8)),
		"consumed": false,
	}


func _digestion_snapshot() -> Dictionary:
	var value: Dictionary = _state.get("digestion", _new_digestion_state())
	var result := value.duplicate(true)
	result["ready"] = int(result.get("progress", 0)) >= int(result.get("required", 1))
	return result
