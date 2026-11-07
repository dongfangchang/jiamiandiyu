class_name StructuredLogger
extends RefCounted

const DEFAULT_LOG_DIRECTORY := "user://logs"
const DEFAULT_LOG_FILENAME := "game.log"

var log_directory: String
var log_filename: String


func _init(directory: String = DEFAULT_LOG_DIRECTORY, filename: String = DEFAULT_LOG_FILENAME) -> void:
	log_directory = directory.trim_suffix("/")
	log_filename = filename


func write_event(
	level: StringName,
	category: StringName,
	code: StringName,
	message: String,
	context: Dictionary = {}
) -> InfrastructureResult:
	var directory_error := _ensure_directory()
	if not directory_error.ok:
		return directory_error

	var path := log_directory.path_join(log_filename)
	var file: FileAccess
	if FileAccess.file_exists(path):
		file = FileAccess.open(path, FileAccess.READ_WRITE)
		if file != null:
			file.seek_end()
	else:
		file = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return InfrastructureResult.failure(
			&"log_open_failed",
			"Log file could not be opened.",
			{"path": path, "error": FileAccess.get_open_error()}
		)

	var event := {
		"timestamp_utc": Time.get_datetime_string_from_system(true, true),
		"level": String(level),
		"category": String(category),
		"code": String(code),
		"message": message,
		"context": context,
	}
	file.store_line(JSON.stringify(event, "", true, true))
	file.flush()
	file.close()
	return InfrastructureResult.success({"path": path})


func _ensure_directory() -> InfrastructureResult:
	var error := DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(log_directory))
	if error != OK and error != ERR_ALREADY_EXISTS:
		return InfrastructureResult.failure(
			&"log_directory_failed",
			"Log directory could not be created.",
			{"path": log_directory, "error": error}
		)
	return InfrastructureResult.success()
