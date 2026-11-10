class_name CampaignContentCatalog
extends RefCounted

const InfrastructureResultScript := preload("res://src/infrastructure/infrastructure_result.gd")

var content_version: String = ""
var cards_content_version: String = ""
var _cards_by_id: Dictionary = {}
var _enemies_by_id: Dictionary = {}
var _encounters_by_id: Dictionary = {}
var _encounter_order: Array[String] = []


func load_from_documents(
	cards_document: Dictionary,
	enemies_document: Dictionary,
	encounters_document: Dictionary
) -> InfrastructureResult:
	var cards_version := String(cards_document.get("content_version", ""))
	var enemies_version := String(enemies_document.get("content_version", ""))
	var encounters_version := String(encounters_document.get("content_version", ""))
	var enemies_base_cards := String(
		enemies_document.get("base_cards_version", "")
	)
	var encounters_base_cards := String(
		encounters_document.get("base_cards_version", "")
	)
	var cross_version_package := (
		not enemies_base_cards.is_empty()
		or not encounters_base_cards.is_empty()
	)
	var versions_valid := false
	if cross_version_package:
		versions_valid = (
			not cards_version.is_empty()
			and not enemies_version.is_empty()
			and enemies_version == encounters_version
			and enemies_base_cards == cards_version
			and encounters_base_cards == cards_version
		)
	else:
		versions_valid = (
			not cards_version.is_empty()
			and cards_version == enemies_version
			and cards_version == encounters_version
		)
	if not versions_valid:
		return InfrastructureResultScript.failure(
			&"content_version_mismatch",
			"Content packages must share a package version and reference one base card version.",
			{
				"cards_version": cards_version,
				"enemies_version": enemies_version,
				"encounters_version": encounters_version,
				"enemies_base_cards_version": enemies_base_cards,
				"encounters_base_cards_version": encounters_base_cards,
			}
		)
	content_version = enemies_version
	cards_content_version = cards_version
	_cards_by_id.clear()
	_enemies_by_id.clear()
	_encounters_by_id.clear()
	_encounter_order.clear()

	var cards: Variant = cards_document.get("cards")
	if not cards is Array or cards.is_empty():
		return InfrastructureResultScript.failure(&"cards_missing", "Cards array must not be empty.")
	for value in cards:
		if not value is Dictionary:
			return InfrastructureResultScript.failure(&"card_invalid", "Card entry must be an object.")
		var card: Dictionary = value
		var card_id := String(card.get("id", ""))
		if card_id.is_empty() or _cards_by_id.has(card_id):
			return InfrastructureResultScript.failure(
				&"card_id_invalid",
				"Card IDs must be non-empty and unique.",
				{"id": card_id}
			)
		_cards_by_id[card_id] = card.duplicate(true)

	var enemies: Variant = enemies_document.get("enemies")
	if not enemies is Array or enemies.is_empty():
		return InfrastructureResultScript.failure(&"enemies_missing", "Enemies array must not be empty.")
	for value in enemies:
		if not value is Dictionary:
			return InfrastructureResultScript.failure(&"enemy_invalid", "Enemy entry must be an object.")
		var enemy: Dictionary = value
		var enemy_id := String(enemy.get("id", ""))
		if enemy_id.is_empty() or _enemies_by_id.has(enemy_id):
			return InfrastructureResultScript.failure(
				&"enemy_id_invalid",
				"Enemy IDs must be non-empty and unique.",
				{"id": enemy_id}
			)
		_enemies_by_id[enemy_id] = enemy.duplicate(true)

	var encounters: Variant = encounters_document.get("encounters")
	if not encounters is Array or encounters.is_empty():
		return InfrastructureResultScript.failure(
			&"encounters_missing",
			"Encounters array must not be empty."
		)
	for value in encounters:
		if not value is Dictionary:
			return InfrastructureResultScript.failure(
				&"encounter_invalid",
				"Encounter entry must be an object."
			)
		var encounter: Dictionary = value
		var encounter_id := String(encounter.get("id", ""))
		if encounter_id.is_empty() or _encounters_by_id.has(encounter_id):
			return InfrastructureResultScript.failure(
				&"encounter_id_invalid",
				"Encounter IDs must be non-empty and unique.",
				{"id": encounter_id}
			)
		var encounter_error := _validate_encounter_references(encounter)
		if not encounter_error.ok:
			return encounter_error
		_encounters_by_id[encounter_id] = encounter.duplicate(true)
		_encounter_order.append(encounter_id)

	return InfrastructureResultScript.success(content_version, {
		"cards": _cards_by_id.size(),
		"enemies": _enemies_by_id.size(),
		"encounters": _encounters_by_id.size(),
	})


func default_encounter_id() -> String:
	return _encounter_order[0] if not _encounter_order.is_empty() else ""


func has_encounter(encounter_id: StringName) -> bool:
	return _encounters_by_id.has(String(encounter_id))


func get_card(definition_id: StringName) -> Dictionary:
	var value: Variant = _cards_by_id.get(String(definition_id), {})
	return value.duplicate(true) if value is Dictionary else {}


func get_enemy(definition_id: StringName) -> Dictionary:
	var value: Variant = _enemies_by_id.get(String(definition_id), {})
	return value.duplicate(true) if value is Dictionary else {}


func resolve_encounter(encounter_id: StringName) -> InfrastructureResult:
	var source: Variant = _encounters_by_id.get(String(encounter_id), {})
	if not source is Dictionary or source.is_empty():
		return InfrastructureResultScript.failure(
			&"encounter_not_found",
			"Encounter does not exist.",
			{"id": String(encounter_id)}
		)
	var encounter: Dictionary = source
	var deck_ids: Array[String] = []
	for value in encounter.get("deck_definition_ids", []):
		deck_ids.append(String(value))
	var enemy_configs: Array[Dictionary] = []
	var waves: Array = encounter.get("waves", [])
	if waves.is_empty():
		waves = [{"enemy_slots": encounter.get("enemy_slots", [])}]
	for wave_index in range(waves.size()):
		var wave_value: Variant = waves[wave_index]
		if not wave_value is Dictionary:
			continue
		var wave: Dictionary = wave_value
		for slot_value in wave.get("enemy_slots", []):
			var slot: Dictionary = slot_value
			var enemy_id := String(slot.get("enemy_id", ""))
			var enemy: Dictionary = _enemies_by_id.get(enemy_id, {})
			var lane_index := int(slot.get("lane_index", -1))
			enemy_configs.append({
				"id": _runtime_enemy_id(String(encounter_id), wave_index, lane_index),
				"definition_id": enemy_id,
				"display_name_zh": String(enemy.get("display_name_zh", enemy_id)),
				"tier": String(enemy.get("tier", "normal")),
				"threat": String(enemy.get("threat", "")),
				"lane_index": lane_index,
				"hp": int(enemy.get("base_health", 0)),
				"max_hp": int(enemy.get("base_health", 0)),
				"base_attack": int(enemy.get("base_attack", 0)),
				"traits": (
					enemy.get("traits", []).duplicate()
					if enemy.get("traits", []) is Array
					else []
				),
				"intents": (
					enemy.get("intents", []).duplicate(true)
					if enemy.get("intents", []) is Array
					else []
				),
				"phases": (
					enemy.get("phases", []).duplicate(true)
					if enemy.get("phases", []) is Array
					else []
				),
				"wave_index": wave_index,
			})
	return InfrastructureResultScript.success({
		"id": String(encounter_id),
		"display_name_zh": String(encounter.get("display_name_zh", encounter_id)),
		"deck_definition_ids": deck_ids,
		"enemy_configs": enemy_configs,
		"enemy_waves": waves.size(),
	})


func _validate_encounter_references(encounter: Dictionary) -> InfrastructureResult:
	var encounter_id := String(encounter.get("id", ""))
	var deck_ids: Variant = encounter.get("deck_definition_ids")
	if not deck_ids is Array or deck_ids.is_empty():
		return InfrastructureResultScript.failure(
			&"encounter_deck_missing",
			"Encounter must define a non-empty deck.",
			{"id": encounter_id}
		)
	for value in deck_ids:
		if not _cards_by_id.has(String(value)):
			return InfrastructureResultScript.failure(
				&"encounter_card_missing",
				"Encounter references a missing card.",
				{"encounter": encounter_id, "card": String(value)}
			)

	var waves_value: Variant = encounter.get("waves", [])
	if waves_value is Array and not waves_value.is_empty():
		for wave_value in waves_value:
			if not wave_value is Dictionary:
				return InfrastructureResultScript.failure(&"encounter_wave_invalid", "Encounter wave must be an object.", {"id": encounter_id})
			var wave_slots: Variant = wave_value.get("enemy_slots", [])
			var wave_error := _validate_enemy_slots(wave_slots)
			if not wave_error.is_empty():
				return InfrastructureResultScript.failure(wave_error, "Encounter wave must define valid enemy slots.", {"id": encounter_id})
		return InfrastructureResultScript.success()
	var slots: Variant = encounter.get("enemy_slots")
	var slot_error := _validate_enemy_slots(slots)
	if not slot_error.is_empty():
		return InfrastructureResultScript.failure(
			slot_error,
			"Encounter must define one to three valid enemy slots.",
			{"id": encounter_id}
		)
	return InfrastructureResultScript.success()


## Single-wave encounters keep the original deterministic "<encounter>.enemy.<lane>"
## runtime IDs; only later waves carry an explicit wave segment.
func _runtime_enemy_id(encounter_id: String, wave_index: int, lane_index: int) -> String:
	if wave_index <= 0:
		return "%s.enemy.%d" % [encounter_id, lane_index]
	return "%s.wave.%d.enemy.%d" % [encounter_id, wave_index, lane_index]


## Returns an empty code when valid, otherwise the specific rejection code.
func _validate_enemy_slots(slots: Variant) -> StringName:
	if not slots is Array or slots.is_empty() or slots.size() > 3:
		return &"encounter_enemy_slots_invalid"
	var occupied_lanes: Dictionary = {}
	for value in slots:
		if not value is Dictionary:
			return &"encounter_enemy_slots_invalid"
		var slot: Dictionary = value
		var enemy_id := String(slot.get("enemy_id", ""))
		var lane_index := int(slot.get("lane_index", -1))
		if not _enemies_by_id.has(enemy_id):
			return &"encounter_enemy_missing"
		if lane_index < 0 or lane_index > 2 or occupied_lanes.has(lane_index):
			return &"encounter_lane_invalid"
		occupied_lanes[lane_index] = true
	return &""
