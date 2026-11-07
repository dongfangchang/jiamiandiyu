class_name AtomicSaveService
extends RefCounted

const DEFAULT_DIRECTORY := "user://saves"
const DEFAULT_SAVE_VERSION := 1
const DEFAULT_SAVE_SCHEMA_PATH := "res://data/schema/v0.2.0/save.schema.json"
const _SLOT_PATTERN := "^[a-z0-9_]{1,64}$"
const SchemaValidatorScript := preload("res://src/infrastructure/schema_validator.gd")

var directory: String
var current_save_version: int
var save_schema_path: String

var _migrations: Dictionary = {}


func _init(
	save_directory: String = DEFAULT_DIRECTORY,
	supported_version: int = DEFAULT_SAVE_VERSION,
	schema_path: String = DEFAULT_SAVE_SCHEMA_PATH
) -> void:
	directory = save_directory.trim_suffix("/")
	current_save_version = supported_version
	save_schema_path = schema_path


func register_migration(from_version: int, migrator: Callable) -> InfrastructureResult:
	if from_version <= 0:
		return InfrastructureResult.failure(&"invalid_migration_version", "Migration source version must be positive.")
	if from_version >= current_save_version:
		return InfrastructureResult.failure(&"invalid_migration_version", "Migration source version must be below the current version.")
	if not migrator.is_valid():
		return InfrastructureResult.failure(&"invalid_migrator", "Migration callable is not valid.")
	_migrations[from_version] = migrator
	return InfrastructureResult.success()


func save_slot(slot: String, envelope: Dictionary) -> InfrastructureResult:
	var slot_error := _validate_slot_name(slot)
	if not slot_error.ok:
		return slot_error
	var validation := validate_envelope(envelope, current_save_version)
	if not validation.ok:
		return validation

	var directory_error := _ensure_directory()
	if not directory_error.ok:
		return directory_error

	var main_path := get_slot_path(slot)
	var temp_path := get_slot_path(slot, false, ".tmp")
	var backup_path := get_slot_path(slot, true)
	_remove_if_exists(temp_path)

	var file := FileAccess.open(temp_path, FileAccess.WRITE)
	if file == null:
		return InfrastructureResult.failure(
			&"write_failed",
			"Temporary save file could not be opened.",
			{"path": temp_path, "error": FileAccess.get_open_error()}
		)
	file.store_string(JSON.stringify(envelope, "  ", true, true))
	file.flush()
	file.close()

	var temp_document := _read_json_object(temp_path)
	if not temp_document.ok:
		_remove_if_exists(temp_path)
		return InfrastructureResult.failure(
			&"temporary_validation_failed",
			"Temporary save could not be validated.",
			{"cause": String(temp_document.code), "path": temp_path}
		)
	var temp_validation := validate_envelope(temp_document.data, current_save_version)
	if not temp_validation.ok:
		_remove_if_exists(temp_path)
		return InfrastructureResult.failure(
			&"temporary_validation_failed",
			"Temporary save failed envelope validation.",
			{"cause": String(temp_validation.code), "path": temp_path}
		)

	if FileAccess.file_exists(main_path):
		_remove_if_exists(backup_path)
		var copy_error := DirAccess.copy_absolute(
			ProjectSettings.globalize_path(main_path),
			ProjectSettings.globalize_path(backup_path)
		)
		if copy_error != OK:
			_remove_if_exists(temp_path)
			return InfrastructureResult.failure(
				&"backup_failed",
				"Existing save could not be backed up.",
				{"path": backup_path, "error": copy_error}
			)
		var backup_document := _read_json_object(backup_path)
		if not backup_document.ok:
			_remove_if_exists(temp_path)
			return InfrastructureResult.failure(
				&"backup_validation_failed",
				"Backup copy is not a valid save; current save was preserved.",
				{"path": backup_path}
			)
		var backup_validation := validate_envelope(backup_document.data)
		if not backup_validation.ok:
			_remove_if_exists(temp_path)
			return InfrastructureResult.failure(
				&"backup_validation_failed",
				"Backup copy failed validation; current save was preserved.",
				{"path": backup_path, "cause": String(backup_validation.code)}
			)

		var remove_error := DirAccess.remove_absolute(ProjectSettings.globalize_path(main_path))
		if remove_error != OK:
			_remove_if_exists(temp_path)
			return InfrastructureResult.failure(
				&"replace_failed",
				"Existing save could not be replaced.",
				{"path": main_path, "error": remove_error}
			)

	var rename_error := DirAccess.rename_absolute(
		ProjectSettings.globalize_path(temp_path),
		ProjectSettings.globalize_path(main_path)
	)
	if rename_error != OK:
		if FileAccess.file_exists(backup_path):
			DirAccess.copy_absolute(
				ProjectSettings.globalize_path(backup_path),
				ProjectSettings.globalize_path(main_path)
			)
		_remove_if_exists(temp_path)
		return InfrastructureResult.failure(
			&"replace_failed",
			"Temporary save could not be committed.",
			{"path": main_path, "error": rename_error}
		)

	return InfrastructureResult.success(
		{"slot": slot},
		{
			"main_path": main_path,
			"backup_path": backup_path if FileAccess.file_exists(backup_path) else "",
		}
	)


func load_slot(slot: String) -> InfrastructureResult:
	var slot_error := _validate_slot_name(slot)
	if not slot_error.ok:
		return slot_error
	var main_path := get_slot_path(slot)
	var backup_path := get_slot_path(slot, true)
	var result := _load_with_migration(main_path)
	if not result.ok:
		result.details["backup_available"] = FileAccess.file_exists(backup_path)
		result.details["backup_path"] = backup_path
	return result


func load_backup(slot: String) -> InfrastructureResult:
	var slot_error := _validate_slot_name(slot)
	if not slot_error.ok:
		return slot_error
	return _load_with_migration(get_slot_path(slot, true))


func inspect_slot(slot: String) -> InfrastructureResult:
	var slot_error := _validate_slot_name(slot)
	if not slot_error.ok:
		return slot_error
	var main_path := get_slot_path(slot)
	var backup_path := get_slot_path(slot, true)
	return InfrastructureResult.success(
		{
			"has_save": FileAccess.file_exists(main_path),
			"has_backup": FileAccess.file_exists(backup_path),
			"main_path": main_path,
			"backup_path": backup_path,
		}
	)


func validate_envelope(envelope: Dictionary, expected_version: int = -1) -> InfrastructureResult:
	var save_version: Variant = envelope.get("save_version")
	if not _is_integer_number(save_version) or int(save_version) < 0:
		return InfrastructureResult.failure(
			&"invalid_save_version",
			"Save must contain a non-negative integer save_version."
		)
	if expected_version > 0 and int(save_version) != expected_version:
		return InfrastructureResult.failure(
			&"save_version_mismatch",
			"Save version does not match the version being written.",
			{"expected": expected_version, "actual": int(save_version)}
		)
	var schema_result = SchemaValidatorScript.new().validate_document(envelope, save_schema_path)
	if not schema_result.ok:
		return InfrastructureResult.failure(
			&"invalid_save_schema",
			"Save does not satisfy its schema.",
			schema_result.details
		)
	return schema_result


func get_slot_path(slot: String, backup: bool = false, suffix: String = "") -> String:
	var file_suffix := suffix if not suffix.is_empty() else ".json"
	if backup:
		file_suffix = ".json.bak"
	return directory.path_join(slot + file_suffix)


func _load_with_migration(path: String) -> InfrastructureResult:
	if not FileAccess.file_exists(path):
		return InfrastructureResult.failure(&"not_found", "Save file does not exist.", {"path": path})
	var loaded := _read_json_object(path)
	if not loaded.ok:
		return loaded

	var document: Dictionary = loaded.data
	var version_value: Variant = document.get("save_version")
	if not _is_integer_number(version_value) or int(version_value) < 0:
		return InfrastructureResult.failure(
			&"invalid_save_version",
			"Save must contain a non-negative integer save_version.",
			{"path": path}
		)
	var original_version := int(version_value)
	var save_version := original_version
	if save_version > current_save_version:
		return InfrastructureResult.failure(
			&"unsupported_save_version",
			"Save was created by a newer build.",
			{"save_version": save_version, "supported_version": current_save_version}
		)

	while save_version < current_save_version:
		if not _migrations.has(save_version):
			return InfrastructureResult.failure(
				&"migration_missing",
				"No migration is registered for this save version.",
				{"save_version": save_version, "supported_version": current_save_version}
			)
		var migrator: Callable = _migrations[save_version]
		var migrated: Variant = migrator.call(document.duplicate(true))
		if not (migrated is Dictionary):
			return InfrastructureResult.failure(
				&"migration_failed",
				"Migration did not return a save object.",
				{"from_version": save_version}
			)
		document = migrated
		var next_version := int(document.get("save_version", 0))
		if next_version <= save_version or next_version > current_save_version:
			return InfrastructureResult.failure(
				&"invalid_migration",
				"Migration produced an invalid save version.",
				{"from_version": save_version, "to_version": next_version}
			)
		var migrated_validation := validate_envelope(document)
		if not migrated_validation.ok:
			return InfrastructureResult.failure(
				&"migration_validation_failed",
				"Migrated save failed validation.",
				{"cause": String(migrated_validation.code), "from_version": save_version}
			)
		save_version = next_version

	var final_validation := validate_envelope(document, current_save_version)
	if not final_validation.ok:
		return InfrastructureResult.failure(
			&"invalid_save",
			"Save failed validation after migration.",
			{"path": path, "cause": String(final_validation.code)}
		)

	return InfrastructureResult.success(document, {"path": path, "migrated": save_version != original_version})


func _read_json_object(path: String) -> InfrastructureResult:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return InfrastructureResult.failure(
			&"read_failed",
			"Save file could not be opened.",
			{"path": path, "error": FileAccess.get_open_error()}
		)
	var text := file.get_as_text()
	file.close()

	var json := JSON.new()
	var parse_error := json.parse(text)
	if parse_error != OK:
		return InfrastructureResult.failure(
			&"invalid_json",
			"Save file is not valid JSON.",
			{
				"path": path,
				"line": json.get_error_line(),
				"message": json.get_error_message(),
			}
		)
	if not json.data is Dictionary:
		return InfrastructureResult.failure(&"invalid_root", "Save root must be an object.", {"path": path})
	return InfrastructureResult.success(json.data, {"path": path})


func _ensure_directory() -> InfrastructureResult:
	var absolute_directory := ProjectSettings.globalize_path(directory)
	var error := DirAccess.make_dir_recursive_absolute(absolute_directory)
	if error != OK and error != ERR_ALREADY_EXISTS:
		return InfrastructureResult.failure(
			&"directory_failed",
			"Save directory could not be created.",
			{"path": directory, "error": error}
		)
	return InfrastructureResult.success()


func _validate_slot_name(slot: String) -> InfrastructureResult:
	var regex := RegEx.new()
	regex.compile(_SLOT_PATTERN)
	if regex.search(slot) == null:
		return InfrastructureResult.failure(
			&"invalid_slot",
			"Save slot must use 1-64 lowercase ASCII letters, digits, or underscores.",
			{"slot": slot}
		)
	return InfrastructureResult.success()


func _is_integer_number(value: Variant) -> bool:
	if value is int:
		return true
	if value is float:
		return is_equal_approx(value, round(value))
	return false


func _remove_if_exists(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
