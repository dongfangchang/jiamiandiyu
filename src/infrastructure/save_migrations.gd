class_name SaveMigrations
extends RefCounted

const V04_SAVE_VERSION := 2
const V04_SAVE_SCHEMA_PATH := "res://data/schema/v0.4.0/save.schema.json"


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
