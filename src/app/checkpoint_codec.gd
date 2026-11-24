class_name CheckpointCodec
extends RefCounted

## Explicit mapping between engine persistent state and the save v6 DTO
## (ADR-0033 §3). Engines keep their internal dictionaries; only fields listed
## here reach the save file, and only listed fields are handed back on load.
## A field an engine adds without being listed here is reported by audit().

const SaveMigrationsScript := preload("res://src/infrastructure/save_migrations.gd")

const SAVE_VERSION := SaveMigrationsScript.CURRENT_SAVE_VERSION

const RUN_STATE := {
	"hp": "i", "max_hp": "i", "spirit": "i", "max_spirit": "i",
	"corruption": "i", "max_corruption": "i", "attention": "i", "max_attention": "i",
}
const RITUAL_STATE := {
	"ritual_id": "s", "step_index": "i", "hints_used": "i", "hinted_steps": "ints",
	"errors": "i", "hint_text": "s", "status": "s", "result": "s",
}
const CLUE_OVERLAY := {
	"annotation_id": "s", "source": "s", "margin_note_id": "s",
	"legacy_text_zh": "s", "legacy_margin_note_zh": "s",
}
const ROUTE_STATE := {
	"route_id": "s",
	"phase": "s",
	"available_node_id": "s",
	"selected_node_id": "s",
	"completed_node_ids": "ids",
	"unlocked_node_ids": "ids",
	"clue_annotations": "smap",
	"legacy_clue_annotations_zh": "smap",
	"clue_overlays": {"map": {"object": CLUE_OVERLAY}},
	"run_state": {"object": RUN_STATE},
	"ritual_state": {"object": RITUAL_STATE},
	"sequence_state": "s",
	"route_outcome": "s",
	"end_reason": "s",
	"revision": "i",
}
const CARD_STATE := {"copies": "i", "level": "i", "fragments": "i"}
const GACHA_RESULT := {"definition_id": "s", "rarity": "s", "duplicate": "b", "fragments": "i"}
const GACHA_DRAW := {"draw_index": "i", "pull_count": "i", "results": {"list": {"object": GACHA_RESULT}}}
const DIGESTION := {
	"potion_id": "s", "from_sequence": "i", "to_sequence": "i", "to_sequence_name_zh": "s",
	"progress": "i", "required": "i", "consumed": "b",
}
const PROGRESSION_STATE := {
	"phase": "s",
	"identity_id": "s",
	"divination_tickets": "i",
	"collection": {"map": {"object": CARD_STATE}},
	"pity_counter": "i",
	"reward_option_ids": "ids",
	"last_battle_outcome": "s",
	"last_gacha_results": {"list": {"object": GACHA_RESULT}},
	"gacha_history": {"list": {"object": GACHA_DRAW}},
	"sequence_reward_target_id": "s",
	"potion_inventory": "ids",
	"sequence": "i",
	"digestion": {"object": DIGESTION},
	"revision": "i",
	"migrated_from_v1": "b",
}
const DECK_STATE := {
	"phase": "s", "current_card_ids": "ids", "selected_preset_id": "s",
	"presets": {"map": "ids"}, "confirmed": "b", "confirmed_card_ids": "ids", "revision": "i",
}
const CHALLENGE_STATE := {
	"challenge_id": "s",
	"phase": "s",
	"selected_modifier_id": "s",
	"challenge_outcome": "s",
	"route_state": {"object": ROUTE_STATE},
	"sequence_state": "open",
	"reward_applied": "b",
	"revision": "i",
}
const LAST_BATTLE := {
	"battle_id": "s", "node_id": "s", "outcome": "s", "reason_code": "s",
	"round_number": "i", "revision": "i",
}


static func build(
	progression_state: Dictionary,
	progression_snapshot: ProgressionSnapshot,
	route_state: Dictionary,
	sequence_state: Dictionary,
	root_seed: int,
	content_revision: int,
	save_version: int,
	checkpoint_kind: String,
	last_battle: Dictionary,
	encounter_id: String,
	current_node_id: String,
	deck_summary: Dictionary,
	challenge_state: Dictionary = {},
	deck_state: Dictionary = {}
) -> Dictionary:
	_report_unknown("route", route_state, ROUTE_STATE)
	_report_unknown("progression", progression_state, PROGRESSION_STATE)
	_report_unknown("deck", deck_state, DECK_STATE)
	_report_unknown("challenge", challenge_state, CHALLENGE_STATE)
	var collection: Dictionary = {}
	for item in progression_snapshot.data.get("collection", []):
		if int(item.get("copies", 0)) > 0 or int(item.get("fragments", 0)) > 0:
			collection[String(item.get("definition_id", ""))] = {
				"copies": int(item.get("copies", 0)),
				"level": int(item.get("level", 0)),
				"fragments": int(item.get("fragments", 0)),
			}
	var challenge := {
		"challenge_id": "",
		"phase": "inactive",
		"selected_modifier_id": "",
		"challenge_outcome": "",
		"reward_applied": false,
		"state": {},
	}
	if not challenge_state.is_empty():
		challenge = {
			"challenge_id": String(challenge_state.get("challenge_id", "")),
			"phase": String(challenge_state.get("phase", "inactive")),
			"selected_modifier_id": String(challenge_state.get("selected_modifier_id", "")),
			"challenge_outcome": String(challenge_state.get("challenge_outcome", "")),
			"reward_applied": bool(challenge_state.get("reward_applied", false)),
			"sequence_state": _convert(challenge_state.get("sequence_state", {}), "open"),
			"state": encode_challenge_state(challenge_state),
		}
	var route_dto := encode_route_state(route_state)
	var deck_counts: Dictionary = {}
	for definition_id in deck_summary:
		deck_counts[String(definition_id)] = int(deck_summary[definition_id])
	return {
		"save_version": save_version,
		"content_revision": content_revision,
		"created_at": Time.get_datetime_string_from_system(true, false) + "Z",
		"rng_seed": root_seed,
		"profile": {
			"pathway": String(sequence_state.get("pathway_id", "seer")),
			"sequence": int(sequence_state.get("current_sequence", 9)),
			"identity_id": String(progression_state.get("identity_id", "")),
		},
		"run": {
			"checkpoint_kind": checkpoint_kind,
			"encounter_id": encounter_id,
			"current_node_id": current_node_id,
			"deck_summary": deck_counts,
			"last_battle": _convert(last_battle, {"object": LAST_BATTLE}),
		},
		"collection": collection,
		"progression": encode_progression(progression_state),
		"route": {
			"initialized": not route_state.is_empty(),
			"route_id": String(route_state.get("route_id", "")),
			"phase": String(route_state.get("phase", "")),
			"run_state": route_dto.get("run_state", {}).duplicate(true),
			"completed_node_ids": route_dto.get("completed_node_ids", []).duplicate(),
			"sequence_state": String(
				route_state.get("sequence_state", sequence_state.get("advancement_state", "locked"))
			),
			"state": route_dto,
		},
		"challenge": challenge,
		"deck": {
			"initialized": not deck_state.is_empty(),
			"state": encode_deck_state(deck_state),
		},
	}


static func encode_route_state(state: Dictionary) -> Dictionary:
	return _convert(state, {"object": ROUTE_STATE})


static func decode_route_state(dto: Dictionary) -> Dictionary:
	return _convert(dto, {"object": ROUTE_STATE})


static func encode_progression(state: Dictionary) -> Dictionary:
	return _convert(state, {"object": PROGRESSION_STATE})


static func decode_progression(dto: Dictionary) -> Dictionary:
	return _convert(dto, {"object": PROGRESSION_STATE})


static func encode_deck_state(state: Dictionary) -> Dictionary:
	return _convert(state, {"object": DECK_STATE})


static func decode_deck_state(dto: Dictionary) -> Dictionary:
	return _convert(dto, {"object": DECK_STATE})


static func encode_challenge_state(state: Dictionary) -> Dictionary:
	return _convert(state, {"object": CHALLENGE_STATE})


static func decode_challenge_state(dto: Dictionary) -> Dictionary:
	return _convert(dto, {"object": CHALLENGE_STATE})


## Field paths present in `state` that the codec does not map (would be lost on save).
static func audit(kind: String, state: Dictionary) -> Array[String]:
	var spec: Dictionary = {
		"route": ROUTE_STATE,
		"progression": PROGRESSION_STATE,
		"deck": DECK_STATE,
		"challenge": CHALLENGE_STATE,
	}.get(kind, {})
	var found: Array[String] = []
	_collect_unknown(state, {"object": spec}, kind, found)
	return found


static func _report_unknown(kind: String, state: Dictionary, spec: Dictionary) -> void:
	var unknown: Array[String] = []
	_collect_unknown(state, {"object": spec}, kind, unknown)
	if not unknown.is_empty():
		push_error("CheckpointCodec: unmapped fields dropped from save: %s" % ", ".join(unknown))


static func _collect_unknown(value: Variant, type: Variant, path: String, out: Array[String]) -> void:
	if not type is Dictionary:
		return
	if type.has("object") and value is Dictionary:
		var spec: Dictionary = type["object"]
		for key in value:
			if not spec.has(key):
				out.append("%s.%s" % [path, key])
			else:
				_collect_unknown(value[key], spec[key], "%s.%s" % [path, key], out)
	elif type.has("map") and value is Dictionary:
		for key in value:
			_collect_unknown(value[key], type["map"], "%s.%s" % [path, key], out)
	elif type.has("list") and value is Array:
		for index in value.size():
			_collect_unknown(value[index], type["list"], "%s[%d]" % [path, index], out)


static func _convert(value: Variant, type: Variant) -> Variant:
	if type is Dictionary:
		if type.has("object"):
			var spec: Dictionary = type["object"]
			var out := {}
			if value is Dictionary:
				for key in spec:
					if value.has(key):
						out[key] = _convert(value[key], spec[key])
			return out
		if type.has("map"):
			var out_map := {}
			if value is Dictionary:
				for key in value:
					out_map[String(key)] = _convert(value[key], type["map"])
			return out_map
		if type.has("list"):
			var out_list: Array = []
			if value is Array:
				for item in value:
					out_list.append(_convert(item, type["list"]))
			return out_list
		return null
	match String(type):
		"s":
			return String(value) if value != null else ""
		"i":
			return int(value) if value is int or value is float else 0
		"b":
			return bool(value)
		"ids":
			var ids: Array = []
			if value is Array:
				for item in value:
					ids.append(String(item))
			return ids
		"ints":
			var ints: Array = []
			if value is Array:
				for item in value:
					ints.append(int(item))
			return ints
		"smap":
			var strings := {}
			if value is Dictionary:
				for key in value:
					strings[String(key)] = String(value[key])
			return strings
		"open":
			return value.duplicate(true) if value is Dictionary else {}
	return value
