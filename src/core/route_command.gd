class_name RouteCommand
extends RefCounted

const SELECT_NODE: StringName = &"select_node"
const RESOLVE_NODE: StringName = &"resolve_node"
const USE_REST: StringName = &"use_rest"
const BEGIN_ASCENSION: StringName = &"begin_ascension"
const SUBMIT_RITUAL_STEP: StringName = &"submit_ritual_step"
const REQUEST_RITUAL_HINT: StringName = &"request_ritual_hint"
const CANCEL_RITUAL: StringName = &"cancel_ritual"

var type: StringName = &""
var node_id: StringName = &""
var battle_outcome: StringName = &""
var battle_player_state: Dictionary = {}
var rest_id: StringName = &""
var ritual_selections: Array[String] = []


func _init(command_type: StringName = &"") -> void:
	type = command_type


static func select_node(node_id_value: StringName) -> RouteCommand:
	var command := RouteCommand.new(SELECT_NODE)
	command.node_id = node_id_value
	return command


static func resolve_node(
	node_id_value: StringName,
	outcome: StringName,
	player_state: Dictionary = {}
) -> RouteCommand:
	var command := RouteCommand.new(RESOLVE_NODE)
	command.node_id = node_id_value
	command.battle_outcome = outcome
	command.battle_player_state = player_state.duplicate(true)
	return command


static func use_rest(rest_id_value: StringName) -> RouteCommand:
	var command := RouteCommand.new(USE_REST)
	command.rest_id = rest_id_value
	return command


static func begin_ascension() -> RouteCommand:
	return RouteCommand.new(BEGIN_ASCENSION)


static func submit_ritual_step(selections: Array[String]) -> RouteCommand:
	var command := RouteCommand.new(SUBMIT_RITUAL_STEP)
	command.ritual_selections = selections.duplicate()
	return command


static func request_ritual_hint() -> RouteCommand:
	return RouteCommand.new(REQUEST_RITUAL_HINT)


static func cancel_ritual() -> RouteCommand:
	return RouteCommand.new(CANCEL_RITUAL)
