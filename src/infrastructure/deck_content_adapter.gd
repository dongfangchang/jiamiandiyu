class_name DeckContentAdapter
extends DeckContentPort

var content_version: String = ""

var _required_deck_size: int = 0
var _default_preset_id: StringName = &""
var _catalog_ids: Array[String] = []
var _presets: Array[Dictionary] = []
var _presets_by_id: Dictionary = {}
var _errors: Array[String] = []


func _init(document: Dictionary, battle_content: BattleContentPort) -> void:
	content_version = String(document.get("content_version", ""))
	_required_deck_size = int(document.get("required_deck_size", 0))
	_default_preset_id = StringName(
		document.get("default_preset_id", "")
	)
	_validate(document, battle_content)


func is_valid() -> bool:
	return _errors.is_empty()


func validation_errors() -> Array[String]:
	return _errors.duplicate()


func get_default_preset_id() -> StringName:
	return _default_preset_id


func get_required_deck_size() -> int:
	return _required_deck_size


func get_preset_definitions() -> Array:
	return _presets.duplicate(true)


func get_preset(preset_id: StringName) -> Dictionary:
	var value: Variant = _presets_by_id.get(String(preset_id), {})
	return value.duplicate(true) if value is Dictionary else {}


func get_card_catalog_ids() -> Array:
	return _catalog_ids.duplicate()


func _validate(document: Dictionary, battle_content: BattleContentPort) -> void:
	if int(document.get("schema_version", -1)) != 1:
		_errors.append("deck schema_version must be 1")
	if content_version.is_empty():
		_errors.append("deck content_version must not be empty")
	if _required_deck_size <= 0 or _required_deck_size > 12:
		_errors.append("required_deck_size must be between 1 and 12")
	if battle_content == null:
		_errors.append("battle content is required")
		return

	var catalog_value: Variant = document.get(
		"card_catalog_definition_ids",
		[]
	)
	if not catalog_value is Array or catalog_value.is_empty():
		_errors.append("card_catalog_definition_ids must not be empty")
		return
	var seen_cards := {}
	for value in catalog_value:
		var definition_id := String(value)
		if definition_id.is_empty() or seen_cards.has(definition_id):
			_errors.append("catalog card IDs must be non-empty and unique")
			continue
		if battle_content.get_card_definition(
			StringName(definition_id)
		).is_empty():
			_errors.append(
				"catalog references missing card %s" % definition_id
			)
		seen_cards[definition_id] = true
		_catalog_ids.append(definition_id)

	var presets_value: Variant = document.get("presets", [])
	if not presets_value is Array or presets_value.size() < 3:
		_errors.append("at least three deck presets are required")
		return
	for value in presets_value:
		if not value is Dictionary:
			_errors.append("deck preset must be an object")
			continue
		var preset: Dictionary = value.duplicate(true)
		var preset_id := String(preset.get("id", ""))
		if preset_id.is_empty() or _presets_by_id.has(preset_id):
			_errors.append("deck preset IDs must be non-empty and unique")
			continue
		if String(preset.get("display_name_zh", "")).is_empty():
			_errors.append("deck preset display_name_zh is required")
		var cards_value: Variant = preset.get("card_definition_ids")
		if not cards_value is Array or cards_value.size() != _required_deck_size:
			_errors.append(
				"deck preset %s must contain exactly %d cards"
				% [preset_id, _required_deck_size]
			)
			continue
		var seen_cards_in_preset := {}
		var valid_cards := true
		for card_value in cards_value:
			var definition_id := String(card_value)
			if (
				definition_id.is_empty()
				or seen_cards_in_preset.has(definition_id)
			):
				_errors.append(
					"deck preset %s card IDs must be unique" % preset_id
				)
				valid_cards = false
			elif not seen_cards.has(definition_id):
				_errors.append(
					"deck preset %s references card outside catalog: %s"
					% [preset_id, definition_id]
				)
				valid_cards = false
			seen_cards_in_preset[definition_id] = true
		if valid_cards:
			_presets.append(preset)
			_presets_by_id[preset_id] = preset

	if (
		_default_preset_id.is_empty()
		or not _presets_by_id.has(String(_default_preset_id))
	):
		_errors.append("default_preset_id must reference a valid preset")
