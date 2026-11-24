class_name SaveMigrations
extends RefCounted

const V04_SAVE_VERSION := 2
const V04_SAVE_SCHEMA_PATH := "res://data/schema/v0.4.0/save.schema.json"
const V05_SAVE_VERSION := 3
const V05_SAVE_SCHEMA_PATH := "res://data/schema/v0.5.0/save.schema.json"
const V06_SAVE_VERSION := 4
const V06_SAVE_SCHEMA_PATH := "res://data/schema/v0.6.0/save.schema.json"
const V07_SAVE_VERSION := 5
const V07_SAVE_SCHEMA_PATH := "res://data/schema/v0.7.0/save.schema.json"
const V6_SAVE_VERSION := 6
const V6_SAVE_SCHEMA_PATH := "res://data/schema/save/v6.schema.json"
const CURRENT_SAVE_VERSION := V6_SAVE_VERSION
const CURRENT_SAVE_SCHEMA_PATH := V6_SAVE_SCHEMA_PATH
# content_revision the v0.7.0 content package became when the manifest was introduced.
const V6_INITIAL_CONTENT_REVISION := 1
const ANNOTATION_ID_PREFIX := "annotation."
const ContentManifestScript := preload("res://src/infrastructure/content_manifest.gd")

# Append-only: the schema each historical save_version must satisfy before migration.
const VERSION_SCHEMAS := {
	1: AtomicSaveService.DEFAULT_SAVE_SCHEMA_PATH,
	V04_SAVE_VERSION: V04_SAVE_SCHEMA_PATH,
	V05_SAVE_VERSION: V05_SAVE_SCHEMA_PATH,
	V06_SAVE_VERSION: V06_SAVE_SCHEMA_PATH,
	V07_SAVE_VERSION: V07_SAVE_SCHEMA_PATH,
}


static func migrate_v1_to_v2(document: Dictionary) -> Dictionary:
	var migrated := document.duplicate(true)
	migrated["save_version"] = V04_SAVE_VERSION
	migrated["content_version"] = "v0.4.0"
	if not migrated.get("profile") is Dictionary:
		migrated["profile"] = {}
	if not migrated.get("run") is Dictionary:
		migrated["run"] = {}
	if not migrated.get("collection") is Dictionary:
		migrated["collection"] = {}
	if not migrated.get("progression") is Dictionary:
		migrated["progression"] = {
			"phase": "identity_selection",
			"identity_id": "",
			"divination_tickets": 0,
			"collection": {},
			"pity_counter": 0,
			"reward_option_ids": [],
			"last_battle_outcome": "",
			"last_gacha_results": [],
			"gacha_history": [],
			"revision": 1,
			"migrated_from_v1": true,
		}
	return migrated


static func migrate_v2_to_v3(document: Dictionary) -> Dictionary:
	var migrated := document.duplicate(true)
	migrated["save_version"] = V05_SAVE_VERSION
	migrated["content_version"] = "v0.5.0"
	if not migrated.get("profile") is Dictionary:
		migrated["profile"] = {}
	if not migrated["profile"].has("pathway"):
		migrated["profile"]["pathway"] = "seer"
	if not migrated["profile"].has("sequence"):
		migrated["profile"]["sequence"] = 9
	if not migrated.get("run") is Dictionary:
		migrated["run"] = {}
	if not migrated["run"].has("checkpoint_kind"):
		migrated["run"]["checkpoint_kind"] = "legacy"
	if not migrated.get("collection") is Dictionary:
		migrated["collection"] = {}
	if not migrated.get("progression") is Dictionary:
		migrated["progression"] = {}
	migrated["route"] = {
		"initialized": false,
		"route_id": "",
		"phase": "map",
		"run_state": {},
		"completed_node_ids": [],
		"sequence_state": "locked",
		"state": {},
		"migrated_from_v2": true,
	}
	return migrated


static func migrate_v3_to_v4(document: Dictionary) -> Dictionary:
	var migrated := document.duplicate(true)
	migrated["save_version"] = V06_SAVE_VERSION
	migrated["content_version"] = "v0.6.0"
	if not migrated.get("profile") is Dictionary:
		migrated["profile"] = {}
	if not migrated.get("run") is Dictionary:
		migrated["run"] = {}
	if not migrated.get("collection") is Dictionary:
		migrated["collection"] = {}
	if not migrated.get("progression") is Dictionary:
		migrated["progression"] = {}
	if not migrated.get("route") is Dictionary:
		migrated["route"] = {}
	migrated["challenge"] = {
		"challenge_id": "",
		"phase": "inactive",
		"selected_modifier_id": "",
		"challenge_outcome": "",
		"state": {},
		"migrated_from_v3": true,
	}
	return migrated


# The only migration chain factory: every save loads through v1 -> v6.
# annotation_lookup maps legacy annotation text -> annotation id (see build_annotation_lookup);
# when omitted it is built from the manifest diary.
static func create_service(
	save_directory: String = AtomicSaveService.DEFAULT_DIRECTORY,
	annotation_lookup: Variant = null,
	content_revision: int = -1
) -> AtomicSaveService:
	var service := AtomicSaveService.new(
		save_directory,
		CURRENT_SAVE_VERSION,
		CURRENT_SAVE_SCHEMA_PATH
	)
	for version in VERSION_SCHEMAS:
		service.register_version_schema(int(version), String(VERSION_SCHEMAS[version]))
	var lookup: Dictionary = (
		annotation_lookup if annotation_lookup is Dictionary else load_default_annotation_lookup()
	)
	var revision := content_revision if content_revision > 0 else _manifest_revision()
	var v6_schema := _read_schema(V6_SAVE_SCHEMA_PATH)
	var steps := [
		[1, func(document: Dictionary) -> Dictionary: return migrate_v1_to_v2(document)],
		[2, func(document: Dictionary) -> Dictionary: return migrate_v2_to_v3(document)],
		[3, func(document: Dictionary) -> Dictionary: return migrate_v3_to_v4(document)],
		[4, func(document: Dictionary) -> Dictionary: return migrate_v4_to_v5(document)],
		[5, func(document: Dictionary) -> Dictionary: return migrate_v5_to_v6(document, lookup, v6_schema)],
	]
	for step in steps:
		var registered := service.register_migration(int(step[0]), step[1])
		if not registered.ok:
			push_error("Failed to register v%d save migration: %s" % [int(step[0]), registered.message])
	service.register_invariant(func(document: Dictionary) -> Array: return check_invariants(document, revision))
	return service


## Load invariants beyond schema shape (ADR-0033 §4).
static func check_invariants(document: Dictionary, current_revision: int = -1) -> Array:
	var errors: Array = []
	var revision := int(document.get("content_revision", 0))
	if current_revision > 0 and revision > current_revision:
		errors.append("content_revision %d is newer than this build (%d)" % [revision, current_revision])
	var route: Dictionary = document.get("route", {})
	var state: Dictionary = route.get("state", {})
	# An initialized route with an empty state restarts the route (pre-v0.6 behaviour).
	if bool(route.get("initialized", false)) and not state.is_empty():
		_check_route_state(state, "route.state", errors)
		if String(state.get("route_id", "")) != String(route.get("route_id", "")):
			errors.append("route.route_id does not match route.state.route_id")
	var challenge_state: Dictionary = document.get("challenge", {}).get("state", {})
	var challenge_route: Variant = challenge_state.get("route_state", {})
	if challenge_route is Dictionary and not challenge_route.is_empty():
		_check_route_state(challenge_route, "challenge.state.route_state", errors)
	return errors


static func _check_route_state(state: Dictionary, label: String, errors: Array) -> void:
	for key in ["route_id", "phase", "run_state"]:
		if not state.has(key):
			errors.append("%s is missing %s" % [label, key])
	var completed: Array = state.get("completed_node_ids", [])
	var seen := {}
	for node_id in completed:
		if seen.has(String(node_id)):
			errors.append("%s.completed_node_ids repeats %s" % [label, node_id])
		seen[String(node_id)] = true


static func build_annotation_lookup(diary_document: Dictionary) -> Dictionary:
	var lookup := {}
	var entries: Variant = diary_document.get("annotations", {}).get("entries", {})
	if not entries is Dictionary:
		return lookup
	for annotation_id in entries:
		var entry: Variant = entries[annotation_id]
		if not entry is Dictionary:
			continue
		var text := String(entry.get("text_zh", ""))
		if not text.is_empty() and not lookup.has(text):
			lookup[text] = String(annotation_id)
	return lookup


static func load_default_annotation_lookup() -> Dictionary:
	var manifest := ContentManifestScript.load_manifest()
	if not manifest.ok:
		push_error("Save migrations: content manifest unavailable (%s)." % manifest.code)
		return {}
	var diary: InfrastructureResult = manifest.data.load_kind("diary")
	if not diary.ok:
		push_error("Save migrations: diary unavailable (%s)." % diary.code)
		return {}
	return build_annotation_lookup(diary.data)


static func _manifest_revision() -> int:
	var manifest := ContentManifestScript.load_manifest()
	return int(manifest.data.content_revision) if manifest.ok else -1


static func migrate_v4_to_v5(document: Dictionary) -> Dictionary:
	var migrated := document.duplicate(true)
	migrated["save_version"] = V07_SAVE_VERSION
	migrated["content_version"] = "v0.7.0"
	if not migrated.get("profile") is Dictionary:
		migrated["profile"] = {}
	if not migrated.get("run") is Dictionary:
		migrated["run"] = {}
	if not migrated.get("collection") is Dictionary:
		migrated["collection"] = {}
	if not migrated.get("progression") is Dictionary:
		migrated["progression"] = {}
	if not migrated.get("route") is Dictionary:
		migrated["route"] = {}
	if not migrated.get("challenge") is Dictionary:
		migrated["challenge"] = {}
	migrated["deck"] = {
		"initialized": false,
		"state": {},
		"migrated_from_v4": true,
	}
	return migrated


static func migrate_v5_to_v6(
	document: Dictionary,
	annotation_lookup: Dictionary,
	v6_schema: Dictionary = {}
) -> Dictionary:
	var migrated := document.duplicate(true)
	migrated["save_version"] = V6_SAVE_VERSION
	migrated.erase("content_version")
	migrated["content_revision"] = V6_INITIAL_CONTENT_REVISION
	var route: Variant = migrated.get("route", {})
	if route is Dictionary and route.get("state") is Dictionary:
		_migrate_route_annotations(route["state"], annotation_lookup)
	var challenge: Variant = migrated.get("challenge", {})
	if challenge is Dictionary and challenge.get("state") is Dictionary:
		var challenge_route: Variant = challenge["state"].get("route_state")
		if challenge_route is Dictionary:
			_migrate_route_annotations(challenge_route, annotation_lookup)
	if not v6_schema.is_empty():
		_prune_to_schema(migrated, v6_schema, v6_schema)
	return migrated


## Pre-v0.88 route states stored annotation text. Exact matches become ids;
## anything else is kept display-only as legacy_*_zh.
static func _migrate_route_annotations(state: Dictionary, lookup: Dictionary) -> void:
	var annotations_value: Variant = state.get("clue_annotations", {})
	if annotations_value is Dictionary:
		var annotations: Dictionary = annotations_value
		var legacy_value: Variant = state.get("legacy_clue_annotations_zh", {})
		var legacy: Dictionary = legacy_value if legacy_value is Dictionary else {}
		for node_id in annotations.keys():
			var value := String(annotations[node_id])
			if value.begins_with(ANNOTATION_ID_PREFIX):
				continue
			var mapped := String(lookup.get(value, ""))
			if mapped.is_empty():
				legacy[node_id] = value
				annotations.erase(node_id)
			else:
				annotations[node_id] = mapped
		if not legacy.is_empty():
			state["legacy_clue_annotations_zh"] = legacy
	var overlays_value: Variant = state.get("clue_overlays", {})
	if overlays_value is Dictionary:
		for node_id in overlays_value.keys():
			var overlay: Variant = overlays_value[node_id]
			if not overlay is Dictionary:
				continue
			_migrate_text_field(overlay, "text_zh", "annotation_id", "legacy_text_zh", lookup)
			_migrate_text_field(overlay, "margin_note_zh", "margin_note_id", "legacy_margin_note_zh", lookup)


static func _migrate_text_field(
	record: Dictionary, text_key: String, id_key: String, legacy_key: String, lookup: Dictionary
) -> void:
	if not record.has(text_key):
		return
	var text := String(record[text_key])
	record.erase(text_key)
	if not String(record.get(id_key, "")).is_empty():
		return
	var mapped := String(lookup.get(text, ""))
	if mapped.is_empty():
		if not text.is_empty():
			record[legacy_key] = text
	else:
		record[id_key] = mapped


## Drops keys the v6 schema does not list on strict objects (legacy engine keys
## that no current code reads). Type errors are left for target validation.
static func _prune_to_schema(value: Variant, schema: Dictionary, root: Dictionary) -> void:
	var resolved := schema
	if schema.has("$ref"):
		var definitions: Dictionary = root.get("$defs", {})
		resolved = definitions.get(String(schema["$ref"]).trim_prefix("#/$defs/"), {})
	if value is Dictionary:
		var properties: Dictionary = resolved.get("properties", {})
		var additional: Variant = resolved.get("additionalProperties", true)
		for key in value.keys():
			if properties.has(key):
				_prune_to_schema(value[key], properties[key], root)
			elif additional is bool and not additional:
				value.erase(key)
			elif additional is Dictionary:
				_prune_to_schema(value[key], additional, root)
	elif value is Array and resolved.get("items") is Dictionary:
		for item in value:
			_prune_to_schema(item, resolved["items"], root)


static func _read_schema(path: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}
