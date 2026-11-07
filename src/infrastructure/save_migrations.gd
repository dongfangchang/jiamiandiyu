class_name SaveMigrations
extends RefCounted

const V04_SAVE_VERSION := 2
const V04_SAVE_SCHEMA_PATH := "res://data/schema/v0.4.0/save.schema.json"
const V05_SAVE_VERSION := 3
const V05_SAVE_SCHEMA_PATH := "res://data/schema/v0.5.0/save.schema.json"


static func create_v04_service(save_directory: String = AtomicSaveService.DEFAULT_DIRECTORY) -> AtomicSaveService:
	var service := AtomicSaveService.new(
		save_directory,
		V04_SAVE_VERSION,
		V04_SAVE_SCHEMA_PATH
	)
	var registered := service.register_migration(
		1,
		func(document: Dictionary) -> Dictionary:
			return migrate_v1_to_v2(document)
	)
	if not registered.ok:
		push_error("Failed to register v1 to v2 save migration: %s" % registered.message)
	return service


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
			"revision": 1,
			"migrated_from_v1": true,
		}
	return migrated


static func create_v05_service(save_directory: String = AtomicSaveService.DEFAULT_DIRECTORY) -> AtomicSaveService:
	var service := AtomicSaveService.new(
		save_directory,
		V05_SAVE_VERSION,
		V05_SAVE_SCHEMA_PATH
	)
	var migrate_v1 := func(document: Dictionary) -> Dictionary:
		return migrate_v1_to_v2(document)
	var migration_v1 := service.register_migration(
		1,
		migrate_v1,
		V04_SAVE_SCHEMA_PATH
	)
	if not migration_v1.ok:
		push_error("Failed to register v1 to v2 save migration: %s" % migration_v1.message)
	var migrate_v2 := func(document: Dictionary) -> Dictionary:
		return migrate_v2_to_v3(document)
	var migration_v2 := service.register_migration(
		2,
		migrate_v2,
		V05_SAVE_SCHEMA_PATH
	)
	if not migration_v2.ok:
		push_error("Failed to register v2 to v3 save migration: %s" % migration_v2.message)
	return service


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
