class_name ChallengeContentAdapter
extends ChallengeContentPort

const SUPPORTED_EFFECTS: Array[String] = [
	"phase_round_delta",
	"starting_corruption_delta",
	"starting_attention_delta",
	"battle_corruption_delta",
	"starting_max_spirit_delta",
	"remove_definition_ids",
	"completion_reward",
]

var content_version: String = ""
var base_route_version: String = ""

var _default_challenge_id: StringName = &""
var _challenges_by_id: Dictionary = {}
var _challenge_order: Array[String] = []
var _errors: Array[String] = []


func _init(
	document: Dictionary,
	catalog: CampaignContentCatalog,
	route_content: RouteContentAdapter,
	progression_content: ProgressionContentPort
) -> void:
	content_version = String(document.get("content_version", ""))
	base_route_version = String(document.get("base_route_version", ""))
	_validate(
		document,
		catalog,
		route_content,
		progression_content
	)


func is_valid() -> bool:
	return (
		_errors.is_empty()
		and not content_version.is_empty()
		and not _default_challenge_id.is_empty()
		and _challenges_by_id.has(String(_default_challenge_id))
	)


func validation_errors() -> Array[String]:
	return _errors.duplicate()


func get_default_challenge_id() -> StringName:
	return _default_challenge_id


func get_challenge(challenge_id: StringName) -> Dictionary:
	var value: Variant = _challenges_by_id.get(String(challenge_id), {})
	return value.duplicate(true) if value is Dictionary else {}


func has_challenge(challenge_id: StringName) -> bool:
	return _challenges_by_id.has(String(challenge_id))


func get_challenge_ids() -> Array[String]:
	return _challenge_order.duplicate()


func _validate(
	document: Dictionary,
	catalog: CampaignContentCatalog,
	route_content: RouteContentAdapter,
	progression_content: ProgressionContentPort
) -> void:
	if int(document.get("schema_version", -1)) != 1:
		_errors.append("challenge schema_version must be 1")
	if content_version.is_empty():
		_errors.append("challenge content_version must not be empty")
	if base_route_version.is_empty():
		_errors.append("challenge base_route_version must not be empty")
	elif base_route_version != route_content.content_version:
		_errors.append(
			"challenge base_route_version must match the loaded route package"
		)

	var reward_ids := {}
	for reward_value in progression_content.get_reward_options():
		if reward_value is Dictionary:
			var reward_id := String(reward_value.get("id", ""))
			if not reward_id.is_empty():
				reward_ids[reward_id] = true

	var challenges_value: Variant = document.get("challenges")
	if not challenges_value is Array or challenges_value.is_empty():
		_errors.append("challenges must be a non-empty array")
		return

	var modifier_ids := {}
	for value in challenges_value:
		if not value is Dictionary:
			_errors.append("challenge entry must be an object")
			continue
		var challenge: Dictionary = value
		var challenge_id := String(challenge.get("id", ""))
		if challenge_id.is_empty() or _challenges_by_id.has(challenge_id):
			_errors.append("challenge ids must be non-empty and unique")
			continue

		var route_id := StringName(challenge.get("route_id", ""))
		var route := route_content.get_route(route_id)
		if route.is_empty():
			_errors.append(
				"challenge %s references a missing route %s"
				% [challenge_id, String(route_id)]
			)
			continue

		var required_sequence := int(challenge.get("required_sequence", 0))
		if required_sequence < 1 or required_sequence > 9:
			_errors.append(
				"challenge %s required_sequence is invalid" % challenge_id
			)

		var completion_reward: Variant = challenge.get("completion_reward", {})
		if not _validate_reward(
			completion_reward,
			reward_ids,
			"challenge %s completion_reward" % challenge_id
		):
			continue

		var encounter_card_ids := _collect_route_card_ids(route, catalog)
		var modifiers_value: Variant = challenge.get("modifiers")
		if not modifiers_value is Array or modifiers_value.size() < 3:
			_errors.append(
				"challenge %s must provide at least three modifiers"
				% challenge_id
			)
			continue
		var challenge_modifier_ids := {}
		for modifier_value in modifiers_value:
			if not modifier_value is Dictionary:
				_errors.append("challenge modifier must be an object")
				continue
			var modifier: Dictionary = modifier_value
			var modifier_id := String(modifier.get("id", ""))
			if modifier_id.is_empty() or modifier_ids.has(modifier_id):
				_errors.append(
					"challenge modifier ids must be non-empty and globally unique"
				)
				continue
			modifier_ids[modifier_id] = true
			challenge_modifier_ids[modifier_id] = true
			if String(modifier.get("display_name_zh", "")).is_empty():
				_errors.append(
					"challenge modifier %s display_name_zh is required"
					% modifier_id
				)
			var effects_value: Variant = modifier.get("effects")
			if not effects_value is Dictionary or effects_value.is_empty():
				_errors.append(
					"challenge modifier %s effects must not be empty"
					% modifier_id
				)
				continue
			_validate_effects(
				effects_value,
				encounter_card_ids,
				reward_ids,
				modifier_id
			)
		if challenge_modifier_ids.is_empty():
			continue

		_challenges_by_id[challenge_id] = challenge.duplicate(true)
		_challenge_order.append(challenge_id)

	var default_id := String(document.get("default_challenge_id", ""))
	if default_id.is_empty() or not _challenges_by_id.has(default_id):
		_errors.append(
			"default_challenge_id must reference an existing challenge"
		)
	else:
		_default_challenge_id = StringName(default_id)


func _validate_effects(
	effects: Dictionary,
	encounter_card_ids: Dictionary,
	reward_ids: Dictionary,
	modifier_id: String
) -> void:
	for effect_id_value in effects:
		var effect_id := String(effect_id_value)
		if effect_id not in SUPPORTED_EFFECTS:
			_errors.append(
				"modifier %s uses unsupported effect %s"
				% [modifier_id, effect_id]
			)
	if effects.has("phase_round_delta"):
		if not _is_integer(effects["phase_round_delta"]):
			_errors.append(
				"modifier %s phase_round_delta must be an integer"
				% modifier_id
			)
	for key in [
		"starting_corruption_delta",
		"starting_attention_delta",
		"battle_corruption_delta",
		"starting_max_spirit_delta",
	]:
		if effects.has(key) and not _is_integer(effects[key]):
			_errors.append(
				"modifier %s %s must be an integer" % [modifier_id, key]
			)
	if effects.has("remove_definition_ids"):
		var values: Variant = effects["remove_definition_ids"]
		if not values is Array:
			_errors.append(
				"modifier %s remove_definition_ids must be an array"
				% modifier_id
			)
		else:
			var seen := {}
			for value in values:
				var definition_id := String(value)
				if definition_id.is_empty() or seen.has(definition_id):
					_errors.append(
						"modifier %s remove_definition_ids must be unique and non-empty"
						% modifier_id
					)
				elif not encounter_card_ids.has(definition_id):
					_errors.append(
						"modifier %s removes card not present in the route: %s"
						% [modifier_id, definition_id]
					)
				seen[definition_id] = true
	if effects.has("completion_reward"):
		_validate_reward(
			effects["completion_reward"],
			reward_ids,
			"modifier %s completion_reward" % modifier_id
		)


func _validate_reward(
	value: Variant,
	reward_ids: Dictionary,
	label: String
) -> bool:
	if not value is Dictionary or value.is_empty():
		_errors.append("%s must be a non-empty object" % label)
		return false
	var valid := true
	for reward_id_value in value:
		var reward_id := String(reward_id_value)
		if not reward_ids.has(reward_id):
			_errors.append("%s references unknown reward %s" % [label, reward_id])
			valid = false
		if not _is_integer(value[reward_id_value]) or int(value[reward_id_value]) < 0:
			_errors.append("%s amount must be a non-negative integer" % reward_id)
			valid = false
	return valid


func _collect_route_card_ids(
	route: Dictionary,
	catalog: CampaignContentCatalog
) -> Dictionary:
	var result := {}
	for node_value in route.get("nodes", []):
		if not node_value is Dictionary:
			continue
		var encounter_id := StringName(node_value.get("encounter_id", ""))
		if encounter_id.is_empty():
			continue
		var encounter := catalog.resolve_encounter(encounter_id)
		if not encounter.ok:
			continue
		for definition_id in encounter.data.get("deck_definition_ids", []):
			result[String(definition_id)] = true
	return result


func _is_integer(value: Variant) -> bool:
	if value is int:
		return true
	if value is float:
		return is_finite(value) and is_equal_approx(value, round(value))
	return false
