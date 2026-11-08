class_name DeckCommand
extends RefCounted

const SELECT_PRESET: StringName = &"select_preset"
const ADD_CARD: StringName = &"add_card"
const REMOVE_CARD: StringName = &"remove_card"
const CLEAR_DECK: StringName = &"clear_deck"
const RESET_DEFAULT: StringName = &"reset_default"
const SAVE_PRESET: StringName = &"save_preset"
const CONFIRM_DECK: StringName = &"confirm_deck"

var type: StringName = &""
var preset_id: StringName = &""
var definition_id: StringName = &""


func _init(
	command_type: StringName = &"",
	preset_id_value: StringName = &"",
	definition_id_value: StringName = &""
) -> void:
	type = command_type
	preset_id = preset_id_value
	definition_id = definition_id_value


static func select_preset(preset_id_value: StringName) -> DeckCommand:
	return DeckCommand.new(SELECT_PRESET, preset_id_value)


static func add_card(definition_id_value: StringName) -> DeckCommand:
	return DeckCommand.new(ADD_CARD, &"", definition_id_value)


static func remove_card(definition_id_value: StringName) -> DeckCommand:
	return DeckCommand.new(REMOVE_CARD, &"", definition_id_value)


static func clear_deck() -> DeckCommand:
	return DeckCommand.new(CLEAR_DECK)


static func reset_default() -> DeckCommand:
	return DeckCommand.new(RESET_DEFAULT)


static func save_preset(preset_id_value: StringName) -> DeckCommand:
	return DeckCommand.new(SAVE_PRESET, preset_id_value)


static func confirm_deck() -> DeckCommand:
	return DeckCommand.new(CONFIRM_DECK)
