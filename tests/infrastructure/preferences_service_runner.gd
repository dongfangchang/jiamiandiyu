extends SceneTree

const PreferencesServiceScript := preload(
	"res://src/infrastructure/player_preferences_service.gd"
)
const SaveMigrationsScript := preload("res://src/infrastructure/save_migrations.gd")
const AppBootstrapScript := preload("res://src/app/bootstrap.gd")

const TEST_DIRECTORY := "user://mask_whispers_preferences_tests"

var _passed := 0
var _failures: Array[String] = []


func _initialize() -> void:
	_remove_tree(TEST_DIRECTORY)
	DirAccess.make_dir_recursive_absolute(
		ProjectSettings.globalize_path(TEST_DIRECTORY)
	)
	var path := TEST_DIRECTORY.path_join("preferences.json")
	var service = PreferencesServiceScript.new(path)

	var defaults = service.load_preferences()
	_expect(defaults.ok, "missing preferences should use defaults")
	_expect(not bool(defaults.data.get("tutorial_seen", true)), "tutorial should start unseen")

	var values: Dictionary = defaults.data.duplicate(true)
	values["tutorial_seen"] = true
	values["fullscreen"] = true
	values["ui_scale"] = 1.1
	values["reduce_flash"] = true
	var saved = service.save_preferences(values)
	_expect(saved.ok, "valid preferences should save")
	var loaded = service.load_preferences()
	_expect(loaded.ok, "saved preferences should load")
	_expect(bool(loaded.data.get("tutorial_seen", false)), "tutorial seen should persist")
	_expect(bool(loaded.data.get("fullscreen", false)), "fullscreen should persist")
	_expect(
		is_equal_approx(float(loaded.data.get("ui_scale", 0.0)), 1.1),
		"ui scale should persist"
	)

	values["ui_scale"] = 99.0
	var normalized = service.save_preferences(values)
	_expect(normalized.ok, "out-of-range scale should normalize")
	_expect(
		is_equal_approx(float(normalized.data.get("ui_scale", 0.0)), 1.2),
		"ui scale should clamp to the supported maximum"
	)

	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string("{broken")
	file.close()
	var invalid = service.load_preferences()
	_expect(not invalid.ok, "invalid preferences should fail explicitly")
	_expect(FileAccess.file_exists(path), "invalid preferences must be preserved")
	_test_backup_restore()

	_remove_tree(TEST_DIRECTORY)
	if _failures.is_empty():
		print("PREFERENCES_TESTS_OK checks=%d" % _passed)
		quit(0)
		return
	for failure in _failures:
		printerr("PREFERENCES_TEST_FAIL: %s" % failure)
	quit(1)


func _expect(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
	else:
		_failures.append(message)


func _test_backup_restore() -> void:
	var save_directory := TEST_DIRECTORY.path_join("saves")
	var service = SaveMigrationsScript.create_v07_service(save_directory)
	var older := _save_envelope(8, "older")
	var current := _save_envelope(9, "current")
	_expect(service.save_slot("checkpoint", older).ok, "backup baseline should save")
	_expect(service.save_slot("checkpoint", current).ok, "current save should rotate a backup")
	var restored = AppBootstrapScript.restore_checkpoint_backup(
		"checkpoint",
		save_directory
	)
	_expect(restored.ok, "checkpoint backup should restore")
	var loaded = service.load_slot("checkpoint")
	_expect(loaded.ok, "restored checkpoint should remain readable")
	_expect(
		int(loaded.data.get("profile", {}).get("sequence", 0)) == 8,
		"restored checkpoint should contain the backup progress"
	)


func _save_envelope(sequence: int, marker: String) -> Dictionary:
	return {
		"save_version": 5,
		"content_version": "v0.7.0",
		"created_at": "2026-11-08T00:00:00Z",
		"rng_seed": 20261108,
		"profile": {
			"pathway": "seer",
			"sequence": sequence,
			"identity_id": "identity.reporter",
		},
		"run": {
			"checkpoint_kind": "route",
			"marker": marker,
		},
		"collection": {},
		"progression": {
			"phase": "hub",
			"identity_id": "identity.reporter",
			"collection": {},
		},
		"route": {"phase": "map"},
		"challenge": {"phase": "inactive"},
		"deck": {
			"initialized": true,
			"state": {
				"current_card_ids": [],
				"presets": [],
				"confirmed": false,
			},
		},
	}


func _remove_tree(relative_path: String) -> void:
	var absolute_path := ProjectSettings.globalize_path(relative_path)
	if not DirAccess.dir_exists_absolute(absolute_path):
		return
	var directory := DirAccess.open(absolute_path)
	if directory == null:
		return
	for file_name in directory.get_files():
		DirAccess.remove_absolute(absolute_path.path_join(file_name))
	for child_name in directory.get_directories():
		_remove_tree(relative_path.path_join(child_name))
	DirAccess.remove_absolute(absolute_path)
