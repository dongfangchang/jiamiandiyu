class_name ChallengeCommand
extends RefCounted

const SELECT_MODIFIER: StringName = &"select_modifier"
const START_CHALLENGE: StringName = &"start_challenge"
const ROUTE: StringName = &"route"

var type: StringName = &""
var modifier_id: StringName = &""
var route_command: RouteCommand = null


func _init(command_type: StringName = &"") -> void:
	type = command_type


static func select_modifier(modifier_id_value: StringName) -> ChallengeCommand:
	var command := ChallengeCommand.new(SELECT_MODIFIER)
	command.modifier_id = modifier_id_value
	return command


static func start_challenge() -> ChallengeCommand:
	return ChallengeCommand.new(START_CHALLENGE)


static func forward_route(command: RouteCommand) -> ChallengeCommand:
	var challenge_command := ChallengeCommand.new(ROUTE)
	challenge_command.route_command = command
	return challenge_command
