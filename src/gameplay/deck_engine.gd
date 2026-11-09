class_name DeckEngine
extends RefCounted

const PHASE_EDITING: StringName = &"editing"
const PHASE_READY: StringName = &"ready"
const PHASE_INIT_ERROR: StringName = &"init_error"

const REASON_PLAYABLE: StringName = &"playable"
const REASON_EMPTY_DECK: StringName = &"empty_deck"
const REASON_WRONG_DECK_SIZE: StringName = &"wrong_deck_size"
const REASON_DUPLICATE_CARD: StringName = &"duplicate_card"
const REASON_CARD_NOT_OWNED: StringName = &"card_not_owned"
const REASON_UNKNOWN_CARD: StringName = &"unknown_card"
const REASON_SEQUENCE_LOCKED: StringName = &"sequence_locked"

var _content: DeckContentPort
var _battle_content: BattleContentPort

var _required_size: int = 0
var _default_preset_id: StringName = &""
var _preset_order: Array[String] = []
var _preset_content: Dictionary = {}
var _catalog_ids: Array[String] = []
var _owned_ids: Dictionary = {}
var _current_sequence: int = 9

var _revision: int = 0
var _state: Dictionary = {}
var _pending_events: Array[DeckEvent] = []


func _init(content: DeckContentPort, battle_content: BattleContentPort) -> void:
	_content = content
	_battle_content = battle_content


func initialize(
	owned_card_ids: Array,
	initial_state: Dictionary = {},
	current_sequence: int = 9
) -> DeckCommandResult:
	_reset_runtime()
	_current_sequence = current_sequence
	if _content == null or _battle_content == null:
		return _initialization_error(&"port_missing")
	if not _load_content():
		return _initialization_error(&"content_invalid")
	for value in owned_card_ids:
		var definition_id := String(value)
		if _catalog_ids.has(definition_id):
			_owned_ids[definition_id] = true
	if initial_state.is_empty():
		_state = _new_state()
	else:
		var restored := _restore_state(initial_state)
		if not restored.accepted:
			return restored
	_revision = maxi(1, int(_state.get("revision", 1)))
	_state["revision"] = _revision
	return DeckCommandResult.new(
		true,
		&"ok",
		[DeckEvent.new(&"DeckReady", {
			"default_preset_id": String(_default_preset_id),
			"required_deck_size": _required_size,
		})],
		get_snapshot()
	)


func submit(command: DeckCommand) -> DeckCommandResult:
	if command == null:
		return _rejected(&"invalid_command")
	if StringName(_state.get("phase", PHASE_INIT_ERROR)) == PHASE_INIT_ERROR:
		return _rejected(&"not_initialized")
	_pending_events.clear()
	var result: DeckCommandResult
	match command.type:
		DeckCommand.SELECT_PRESET:
			result = _select_preset(command.preset_id)
		DeckCommand.ADD_CARD:
			result = _add_card(command.definition_id)
		DeckCommand.REMOVE_CARD:
			result = _remove_card(command.definition_id)
		DeckCommand.CLEAR_DECK:
			result = _clear_deck()
		DeckCommand.RESET_DEFAULT:
			result = _reset_default()
		DeckCommand.SAVE_PRESET:
			result = _save_preset(command.preset_id)
		DeckCommand.CONFIRM_DECK:
			result = _confirm_deck()
		_:
			result = _rejected(&"invalid_command")
	if result.accepted:
		_revision += 1
		_state["revision"] = _revision
		result.snapshot = get_snapshot()
	return result


func get_current_deck_ids() -> Array[String]:
	return _string_array(_state.get("current_card_ids", []))


func get_confirmed_deck_ids() -> Array[String]:
	if not bool(_state.get("confirmed", false)):
		return []
	var deck := get_current_deck_ids()
	if _validate_deck(deck) != REASON_PLAYABLE:
		return []
	return deck


func set_current_sequence(sequence: int) -> DeckSnapshot:
	_current_sequence = sequence
	return get_snapshot()


func get_snapshot() -> DeckSnapshot:
	var current_ids := get_current_deck_ids()
	var reason := _validate_deck(current_ids)
	var card_views: Array[Dictionary] = []
	var all_ids: Array[String] = _catalog_ids.duplicate()
	for definition_id in current_ids:
		if not definition_id in all_ids:
			all_ids.append(definition_id)
	for definition_id in all_ids:
		var definition: Dictionary = _battle_content.get_card_definition(
			StringName(definition_id)
		)
		card_views.append({
			"definition_id": definition_id,
			"display_name_zh": String(
				definition.get("display_name_zh", definition_id)
			),
			"description_zh": String(definition.get("description_zh", "")),
			"category": String(definition.get("category", "")),
			"cost_spirit": int(definition.get("cost_spirit", 0)),
			"target_type": String(definition.get("target_type", "")),
			"owned": _owned_ids.has(definition_id),
			"in_deck": definition_id in current_ids,
		})

	var preset_views: Array[Dictionary] = []
	var presets: Dictionary = _state.get("presets", {})
	for preset_id in _preset_order:
		var preset_ids := _string_array(presets.get(preset_id, []))
		var preset_content: Dictionary = _preset_content.get(preset_id, {})
		var preset_reason := _validate_deck(preset_ids)
		preset_views.append({
			"id": preset_id,
			"display_name_zh": String(
				preset_content.get("display_name_zh", preset_id)
			),
			"description_zh": String(
				preset_content.get("description_zh", "")
			),
			"card_definition_ids": preset_ids,
			"legal": preset_reason == REASON_PLAYABLE,
			"reason_code": String(preset_reason),
			"selected": preset_id == String(
				_state.get("selected_preset_id", "")
			),
		})

	return DeckSnapshot.new({
		"revision": _revision,
		"phase": String(_state.get("phase", PHASE_INIT_ERROR)),
		"required_deck_size": _required_size,
		"current_card_ids": current_ids,
		"current_deck_size": current_ids.size(),
		"legal": reason == REASON_PLAYABLE,
		"reason_code": String(reason),
		"selected_preset_id": String(
			_state.get("selected_preset_id", "")
		),
		"default_preset_id": String(_default_preset_id),
		"confirmed": bool(_state.get("confirmed", false)),
		"cards": card_views,
		"presets": preset_views,
		"available_commands": _available_commands(),
	})


func export_persistent_state() -> Dictionary:
	return _state.duplicate(true)


func _select_preset(preset_id: StringName) -> DeckCommandResult:
	var preset_key := String(preset_id)
	if not _preset_content.has(preset_key):
		return _rejected(&"unknown_preset")
	_state["current_card_ids"] = _string_array(
		_state.get("presets", {}).get(preset_key, [])
	)
	_state["selected_preset_id"] = preset_key
	_set_editing()
	_emit(&"DeckPresetSelected", {"preset_id": preset_key})
	return _success()


func _add_card(definition_id: StringName) -> DeckCommandResult:
	var definition_key := String(definition_id)
	if not _catalog_ids.has(definition_key):
		return _rejected(REASON_UNKNOWN_CARD)
	if not _owned_ids.has(definition_key):
		return _rejected(REASON_CARD_NOT_OWNED)
	var definition := _battle_content.get_card_definition(definition_id)
	var sequence_band := String(definition.get("sequence_band", "序列9"))
	if _current_sequence > 8 and (sequence_band.contains("序列8") or sequence_band.contains("→8")):
		return _rejected(REASON_SEQUENCE_LOCKED)
	var current := get_current_deck_ids()
	if definition_key in current:
		return _rejected(REASON_DUPLICATE_CARD)
	current.append(definition_key)
	_state["current_card_ids"] = current
	_state["selected_preset_id"] = ""
	_set_editing()
	_emit(&"DeckCardAdded", {"definition_id": definition_key})
	return _success()


func _remove_card(definition_id: StringName) -> DeckCommandResult:
	var definition_key := String(definition_id)
	var current := get_current_deck_ids()
	if not definition_key in current:
		return _rejected(&"card_not_in_deck")
	current.erase(definition_key)
	_state["current_card_ids"] = current
	_state["selected_preset_id"] = ""
	_set_editing()
	_emit(&"DeckCardRemoved", {"definition_id": definition_key})
	return _success()


func _clear_deck() -> DeckCommandResult:
	_state["current_card_ids"] = []
	_state["selected_preset_id"] = ""
	_set_editing()
	_emit(&"DeckCleared", {})
	return _success()


func _reset_default() -> DeckCommandResult:
	var preset := _string_array(
		_state.get("presets", {}).get(
			String(_default_preset_id),
			[]
		)
	)
	_state["current_card_ids"] = preset
	_state["selected_preset_id"] = String(_default_preset_id)
	_set_editing()
	_emit(&"DeckDefaultRestored", {
		"preset_id": String(_default_preset_id),
	})
	return _success()


func _save_preset(preset_id: StringName) -> DeckCommandResult:
	var preset_key := String(preset_id)
	if not _preset_content.has(preset_key):
		return _rejected(&"unknown_preset")
	var current := get_current_deck_ids()
	var reason := _validate_deck(current)
	if reason != REASON_PLAYABLE:
		return _rejected(reason)
	var presets: Dictionary = _state.get("presets", {}).duplicate(true)
	presets[preset_key] = current.duplicate()
	_state["presets"] = presets
	_state["selected_preset_id"] = preset_key
	_set_editing()
	_emit(&"DeckPresetSaved", {
		"preset_id": preset_key,
		"card_definition_ids": current.duplicate(),
	})
	return _success()


func _confirm_deck() -> DeckCommandResult:
	var current := get_current_deck_ids()
	var reason := _validate_deck(current)
	if reason != REASON_PLAYABLE:
		return _rejected(reason)
	_state["confirmed"] = true
	_state["confirmed_card_ids"] = current.duplicate()
	_state["phase"] = String(PHASE_READY)
	_emit(&"DeckConfirmed", {
		"card_definition_ids": current.duplicate(),
		"selected_preset_id": String(
			_state.get("selected_preset_id", "")
		),
	})
	return _success()


func _validate_deck(deck_ids: Array[String]) -> StringName:
	if deck_ids.is_empty():
		return REASON_EMPTY_DECK
	if deck_ids.size() != _required_size:
		return REASON_WRONG_DECK_SIZE
	var seen := {}
	for definition_id in deck_ids:
		if seen.has(definition_id):
			return REASON_DUPLICATE_CARD
		seen[definition_id] = true
		if not _catalog_ids.has(definition_id):
			return REASON_UNKNOWN_CARD
		if not _owned_ids.has(definition_id):
			return REASON_CARD_NOT_OWNED
		var definition := _battle_content.get_card_definition(StringName(definition_id))
		var sequence_band := String(definition.get("sequence_band", "序列9"))
		if _current_sequence > 8 and (sequence_band.contains("序列8") or sequence_band.contains("→8")):
			return REASON_SEQUENCE_LOCKED
	return REASON_PLAYABLE


func _load_content() -> bool:
	_required_size = _content.get_required_deck_size()
	if _required_size <= 0:
		return false
	_default_preset_id = _content.get_default_preset_id()
	if _default_preset_id.is_empty():
		return false
	var presets_value: Variant = _content.get_preset_definitions()
	if not presets_value is Array or presets_value.is_empty():
		return false
	for value in presets_value:
		if not value is Dictionary:
			return false
		var preset: Dictionary = value
		var preset_id := String(preset.get("id", ""))
		if preset_id.is_empty() or _preset_content.has(preset_id):
			return false
		var ids_value: Variant = preset.get("card_definition_ids")
		if not ids_value is Array or ids_value.is_empty():
			return false
		var ids := _normalize_ids(ids_value)
		if ids.is_empty() or not _unique(ids):
			return false
		var normalized := preset.duplicate(true)
		normalized["card_definition_ids"] = ids
		_preset_content[preset_id] = normalized
		_preset_order.append(preset_id)
	if not _preset_content.has(String(_default_preset_id)):
		return false

	var catalog_value: Variant = _content.get_card_catalog_ids()
	if not catalog_value is Array or catalog_value.is_empty():
		return false
	for value in catalog_value:
		var definition_id := String(value)
		if (
			definition_id.is_empty()
			or definition_id in _catalog_ids
			or _battle_content.get_card_definition(
				StringName(definition_id)
			).is_empty()
		):
			return false
		_catalog_ids.append(definition_id)
	for preset_id in _preset_order:
		for definition_id in _preset_content[preset_id]["card_definition_ids"]:
			if not definition_id in _catalog_ids:
				return false
	return _preset_order.size() >= 3


func _new_state() -> Dictionary:
	var presets: Dictionary = {}
	for preset_id in _preset_order:
		presets[preset_id] = _string_array(
			_preset_content[preset_id]["card_definition_ids"]
		)
	var default_ids := _string_array(
		presets.get(String(_default_preset_id), [])
	)
	return {
		"phase": String(PHASE_EDITING),
		"current_card_ids": default_ids,
		"selected_preset_id": String(_default_preset_id),
		"presets": presets,
		"confirmed": false,
		"confirmed_card_ids": [],
		"revision": 1,
	}


func _restore_state(value: Dictionary) -> DeckCommandResult:
	var presets_value: Variant = value.get("presets", {})
	if not presets_value is Dictionary:
		return _restore_error(&"presets_invalid")
	var restored_presets: Dictionary = {}
	for preset_id in _preset_order:
		var ids_value: Variant = presets_value.get(preset_id, null)
		if not ids_value is Array:
			return _restore_error(&"preset_missing")
		var ids := _normalize_ids(ids_value)
		if ids.size() != ids_value.size() or not _unique(ids):
			return _restore_error(&"preset_invalid")
		restored_presets[preset_id] = ids
	var current := _normalize_ids(value.get("current_card_ids", []))
	if not _unique(current):
		return _restore_error(&"deck_duplicate")
	var selected_preset_id := String(
		value.get("selected_preset_id", "")
	)
	if (
		not selected_preset_id.is_empty()
		and not restored_presets.has(selected_preset_id)
	):
		return _restore_error(&"preset_unknown")
	var confirmed := bool(value.get("confirmed", false))
	var phase := StringName(value.get("phase", PHASE_EDITING))
	if phase not in [PHASE_EDITING, PHASE_READY]:
		return _restore_error(&"phase_invalid")
	if phase == PHASE_READY and not confirmed:
		return _restore_error(&"phase_invalid")
	_state = {
		"phase": String(phase),
		"current_card_ids": current,
		"selected_preset_id": selected_preset_id,
		"presets": restored_presets,
		"confirmed": confirmed,
		"confirmed_card_ids": _normalize_ids(
			value.get("confirmed_card_ids", [])
		),
		"revision": maxi(1, int(value.get("revision", 1))),
	}
	return DeckCommandResult.new(
		true,
		&"ok",
		[],
		get_snapshot()
	)


func _set_editing() -> void:
	_state["confirmed"] = false
	_state["confirmed_card_ids"] = []
	_state["phase"] = String(PHASE_EDITING)


func _available_commands() -> Array[String]:
	var result: Array[String] = [
		"select_preset",
		"add_card",
		"remove_card",
		"clear_deck",
		"reset_default",
		"save_preset",
	]
	if _validate_deck(get_current_deck_ids()) == REASON_PLAYABLE:
		result.append("confirm_deck")
	return result


func _normalize_ids(value: Variant) -> Array[String]:
	var result: Array[String] = []
	if not value is Array:
		return result
	for item in value:
		if item is String:
			result.append(item)
	return result


func _string_array(value: Variant) -> Array[String]:
	return _normalize_ids(value)


func _unique(values: Array[String]) -> bool:
	var seen := {}
	for value in values:
		if seen.has(value):
			return false
		seen[value] = true
	return true


func _emit(event_type: StringName, event_data: Dictionary) -> void:
	_pending_events.append(DeckEvent.new(event_type, event_data))


func _success() -> DeckCommandResult:
	return DeckCommandResult.new(
		true,
		&"ok",
		_pending_events.duplicate(),
		get_snapshot()
	)


func _rejected(reason: StringName) -> DeckCommandResult:
	return DeckCommandResult.new(false, reason, [], get_snapshot())


func _restore_error(reason: StringName) -> DeckCommandResult:
	_state = {"phase": String(PHASE_INIT_ERROR)}
	_revision = 0
	return DeckCommandResult.new(false, reason, [], get_snapshot())


func _initialization_error(reason: StringName) -> DeckCommandResult:
	_state = {"phase": String(PHASE_INIT_ERROR)}
	_revision = 0
	return DeckCommandResult.new(false, reason, [], get_snapshot())


func _reset_runtime() -> void:
	_current_sequence = 9
	_required_size = 0
	_default_preset_id = &""
	_preset_order.clear()
	_preset_content.clear()
	_catalog_ids.clear()
	_owned_ids.clear()
	_revision = 0
	_state = {}
	_pending_events.clear()
