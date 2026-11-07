class_name CheckpointEnvelopeBuilder
extends RefCounted


static func build(
	progression_state: Dictionary,
	progression_snapshot: ProgressionSnapshot,
	route_state: Dictionary,
	sequence_state: Dictionary,
	root_seed: int,
	content_version: String,
	save_version: int,
	checkpoint_kind: String,
	last_battle: Dictionary,
	encounter_id: String,
	current_node_id: String,
	deck_summary: Dictionary,
	challenge_state: Dictionary = {}
) -> Dictionary:
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
			"challenge_id": String(
				challenge_state.get("challenge_id", "")
			),
			"phase": String(challenge_state.get("phase", "inactive")),
			"selected_modifier_id": String(
				challenge_state.get("selected_modifier_id", "")
			),
			"challenge_outcome": String(
				challenge_state.get("challenge_outcome", "")
			),
			"reward_applied": bool(
				challenge_state.get("reward_applied", false)
			),
			"sequence_state": challenge_state.get(
				"sequence_state",
				{}
			).duplicate(true),
			"state": challenge_state.duplicate(true),
		}
	return {
		"save_version": save_version,
		"content_version": content_version,
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
			"deck_summary": deck_summary.duplicate(true),
			"last_battle": last_battle.duplicate(true),
		},
		"collection": collection,
		"progression": progression_state.duplicate(true),
		"route": {
			"initialized": not route_state.is_empty(),
			"route_id": String(route_state.get("route_id", "")),
			"phase": String(route_state.get("phase", "")),
			"run_state": route_state.get("run_state", {}).duplicate(true),
			"completed_node_ids": route_state.get(
				"completed_node_ids",
				[]
			).duplicate(),
			"sequence_state": String(
				route_state.get(
					"sequence_state",
					sequence_state.get("advancement_state", "locked")
				)
			),
			"state": route_state.duplicate(true),
		},
		"challenge": challenge,
	}
