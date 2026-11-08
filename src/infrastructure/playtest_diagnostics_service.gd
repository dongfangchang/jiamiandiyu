class_name PlaytestDiagnosticsService
extends RefCounted

const DEFAULT_DIRECTORY := "user://diagnostics"
const DOCUMENT_VERSION := 1

var directory: String
var session_id := ""
var session_started_unix := 0
var session_started_ticks := 0
var events: Array[Dictionary] = []
var _finished := false


func _init(directory_value: String = DEFAULT_DIRECTORY) -> void:
	directory = directory_value.trim_suffix("/")


func start_session(content_version: String, build_version: String) -> void:
	session_started_unix = int(Time.get_unix_time_from_system())
	session_started_ticks = Time.get_ticks_msec()
	session_id = "session_%d_%d" % [
		session_started_unix,
		Time.get_ticks_msec(),
	]
	events.clear()
	_finished = false
	_record("session_started", {
		"content_version": content_version,
		"build_version": build_version,
	})


func record_event(event_type: String, details: Dictionary = {}) -> void:
	if session_id.is_empty() or _finished:
		return
	_record(event_type, details)


func finish_session(summary: Dictionary = {}) -> InfrastructureResult:
	if session_id.is_empty():
		return InfrastructureResult.failure(
			&"diagnostics_not_started",
			"Diagnostics session has not started."
		)
	if _finished:
		return InfrastructureResult.success({}, {"duplicate": true})
	_finished = true
	var ended_unix := int(Time.get_unix_time_from_system())
	var duration_ms := maxi(0, Time.get_ticks_msec() - session_started_ticks)
	var document := {
		"document_version": DOCUMENT_VERSION,
		"session_id": session_id,
		"started_at_unix": session_started_unix,
		"ended_at_unix": ended_unix,
		"duration_ms": duration_ms,
		"summary": summary.duplicate(true),
		"events": events.duplicate(true),
	}
	var path := directory.path_join(session_id + ".json")
	return _write_json_atomic(path, document)


func save_feedback(
	text: String,
	stage: String,
	stuck: bool,
	pacing: String
) -> InfrastructureResult:
	var clean_text := text.strip_edges().left(4000)
	if clean_text.is_empty():
		return InfrastructureResult.failure(
			&"feedback_empty",
			"Feedback text is empty."
		)
	var timestamp := int(Time.get_unix_time_from_system())
	var document := {
		"document_version": DOCUMENT_VERSION,
		"feedback_id": "feedback_%d_%d" % [
			timestamp,
			Time.get_ticks_msec(),
		],
		"session_id": session_id,
		"created_at_unix": timestamp,
		"stage": stage.left(64),
		"stuck": stuck,
		"pacing": pacing.left(32),
		"text": clean_text,
	}
	var path := directory.path_join(String(document.feedback_id) + ".json")
	return _write_json_atomic(path, document)


func get_latest_feedback_path() -> String:
	var absolute_directory := ProjectSettings.globalize_path(directory)
	if not DirAccess.dir_exists_absolute(absolute_directory):
		return ""
	var directory_access := DirAccess.open(absolute_directory)
	if directory_access == null:
		return ""
	var latest_name := ""
	for file_name in directory_access.get_files():
		if file_name.begins_with("feedback_") and file_name.ends_with(".json"):
			if file_name > latest_name:
				latest_name = file_name
	return directory.path_join(latest_name) if not latest_name.is_empty() else ""


func _record(event_type: String, details: Dictionary) -> void:
	events.append({
		"elapsed_ms": maxi(0, Time.get_ticks_msec() - session_started_ticks),
		"event": event_type.left(64),
		"details": details.duplicate(true),
	})


func _write_json_atomic(path: String, document: Dictionary) -> InfrastructureResult:
	var absolute_path := ProjectSettings.globalize_path(path)
	var absolute_directory := absolute_path.get_base_dir()
	var mkdir_error := DirAccess.make_dir_recursive_absolute(absolute_directory)
	if mkdir_error != OK and mkdir_error != ERR_ALREADY_EXISTS:
		return InfrastructureResult.failure(
			&"diagnostics_directory_failed",
			"Diagnostics directory could not be created.",
			{"error": mkdir_error}
		)
	var temp_path := absolute_path + ".tmp"
	var file := FileAccess.open(temp_path, FileAccess.WRITE)
	if file == null:
		return InfrastructureResult.failure(
			&"diagnostics_write_failed",
			"Diagnostics file could not be opened.",
			{"error": FileAccess.get_open_error()}
		)
	file.store_string(JSON.stringify(document, "  ", true, true))
	file.flush()
	file.close()
	var verify := FileAccess.open(temp_path, FileAccess.READ)
	if verify == null:
		_remove_if_exists(temp_path)
		return InfrastructureResult.failure(
			&"diagnostics_verify_failed",
			"Diagnostics file could not be verified."
		)
	var json := JSON.new()
	var error := json.parse(verify.get_as_text())
	verify.close()
	if error != OK or not json.data is Dictionary:
		_remove_if_exists(temp_path)
		return InfrastructureResult.failure(
			&"diagnostics_verify_failed",
			"Diagnostics file is invalid after writing."
		)
	if FileAccess.file_exists(absolute_path):
		DirAccess.remove_absolute(absolute_path)
	var rename_error := DirAccess.rename_absolute(temp_path, absolute_path)
	if rename_error != OK:
		_remove_if_exists(temp_path)
		return InfrastructureResult.failure(
			&"diagnostics_replace_failed",
			"Diagnostics file could not be committed.",
			{"error": rename_error}
		)
	return InfrastructureResult.success({}, {"path": path})


func _remove_if_exists(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
