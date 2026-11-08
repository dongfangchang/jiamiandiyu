class_name PlayerPreferencesService
extends RefCounted

const DEFAULT_PATH := "user://preferences.json"
const SETTINGS_VERSION := 1

const DEFAULT_PREFERENCES := {
	"settings_version": SETTINGS_VERSION,
	"tutorial_seen": false,
	"fullscreen": false,
	"ui_scale": 1.0,
	"reduce_flash": false,
}

var path: String


func _init(path_value: String = DEFAULT_PATH) -> void:
	path = path_value


func load_preferences() -> InfrastructureResult:
	if not FileAccess.file_exists(path):
		return InfrastructureResult.success(
			DEFAULT_PREFERENCES.duplicate(true),
			{"status": "default"}
		)
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return InfrastructureResult.failure(
			&"preferences_read_failed",
			"Preferences file could not be opened.",
			{"path": path, "error": FileAccess.get_open_error()}
		)
	var text := file.get_as_text()
	file.close()
	var json := JSON.new()
	var parse_error := json.parse(text)
	if parse_error != OK or not json.data is Dictionary:
		return InfrastructureResult.failure(
			&"preferences_invalid_json",
			"Preferences file is invalid; the original file was preserved.",
			{
				"path": path,
				"line": json.get_error_line(),
				"message": json.get_error_message(),
			}
		)
	var normalized := _normalize(json.data)
	if int(json.data.get("settings_version", 0)) != SETTINGS_VERSION:
		return InfrastructureResult.failure(
			&"preferences_version_invalid",
			"Preferences version is unsupported; the original file was preserved.",
			{"path": path}
		)
	return InfrastructureResult.success(normalized, {"status": "loaded"})


func save_preferences(preferences: Dictionary) -> InfrastructureResult:
	var normalized := _normalize(preferences)
	var absolute_path := ProjectSettings.globalize_path(path)
	var directory := absolute_path.get_base_dir()
	var mkdir_error := DirAccess.make_dir_recursive_absolute(directory)
	if mkdir_error != OK and mkdir_error != ERR_ALREADY_EXISTS:
		return InfrastructureResult.failure(
			&"preferences_directory_failed",
			"Preferences directory could not be created.",
			{"path": directory, "error": mkdir_error}
		)
	var temp_path := absolute_path + ".tmp"
	var file := FileAccess.open(temp_path, FileAccess.WRITE)
	if file == null:
		return InfrastructureResult.failure(
			&"preferences_write_failed",
			"Temporary preferences file could not be opened.",
			{"path": temp_path, "error": FileAccess.get_open_error()}
		)
	file.store_string(JSON.stringify(normalized, "  ", true, true))
	file.flush()
	file.close()

	var verify_file := FileAccess.open(temp_path, FileAccess.READ)
	if verify_file == null:
		_remove_if_exists(temp_path)
		return InfrastructureResult.failure(
			&"preferences_verify_failed",
			"Temporary preferences file could not be verified."
		)
	var verify_json := JSON.new()
	var verify_error := verify_json.parse(verify_file.get_as_text())
	verify_file.close()
	if verify_error != OK or not verify_json.data is Dictionary:
		_remove_if_exists(temp_path)
		return InfrastructureResult.failure(
			&"preferences_verify_failed",
			"Temporary preferences file is invalid."
		)

	if FileAccess.file_exists(absolute_path):
		var remove_error := DirAccess.remove_absolute(absolute_path)
		if remove_error != OK:
			_remove_if_exists(temp_path)
			return InfrastructureResult.failure(
				&"preferences_replace_failed",
				"Existing preferences file could not be replaced."
			)
	var rename_error := DirAccess.rename_absolute(temp_path, absolute_path)
	if rename_error != OK:
		_remove_if_exists(temp_path)
		return InfrastructureResult.failure(
			&"preferences_replace_failed",
			"Preferences file could not be committed.",
			{"error": rename_error}
		)
	return InfrastructureResult.success(normalized, {"path": path})


func _normalize(source: Dictionary) -> Dictionary:
	var result := DEFAULT_PREFERENCES.duplicate(true)
	result["settings_version"] = SETTINGS_VERSION
	result["tutorial_seen"] = bool(source.get("tutorial_seen", false))
	result["fullscreen"] = bool(source.get("fullscreen", false))
	result["reduce_flash"] = bool(source.get("reduce_flash", false))
	result["ui_scale"] = clampf(
		float(source.get("ui_scale", 1.0)),
		0.85,
		1.2
	)
	return result


func _remove_if_exists(target_path: String) -> void:
	if FileAccess.file_exists(target_path):
		DirAccess.remove_absolute(target_path)
