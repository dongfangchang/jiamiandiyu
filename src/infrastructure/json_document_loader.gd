class_name JsonDocumentLoader
extends RefCounted

const SUPPORTED_SCHEMA_VERSION := 2
const SchemaValidatorScript := preload("res://src/infrastructure/schema_validator.gd")


func load_document(path: String, schema_path: String = "") -> InfrastructureResult:
	if not _is_supported_runtime_path(path):
		return InfrastructureResult.failure(&"invalid_path", "Only res:// and user:// paths are supported.")
	if not FileAccess.file_exists(path):
		return InfrastructureResult.failure(&"not_found", "Document does not exist.", {"path": path})

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return InfrastructureResult.failure(
			&"read_failed",
			"Document could not be opened.",
			{"path": path, "error": FileAccess.get_open_error()}
		)
	var text := file.get_as_text()
	file.close()
	var parsed := parse_document(text, path)
	if not parsed.ok or schema_path.is_empty():
		return parsed
	var validation = SchemaValidatorScript.new().validate_document(parsed.data, schema_path)
	if not validation.ok:
		validation.details["source"] = path
	return validation


func parse_document(text: String, source: String = "") -> InfrastructureResult:
	var json := JSON.new()
	var parse_error := json.parse(text)
	if parse_error != OK:
		return InfrastructureResult.failure(
			&"invalid_json",
			"Document is not valid JSON.",
			{
				"source": source,
				"line": json.get_error_line(),
				"message": json.get_error_message(),
			}
		)

	if not json.data is Dictionary:
		return InfrastructureResult.failure(
			&"invalid_root",
			"Document root must be an object.",
			{"source": source}
		)

	var document: Dictionary = json.data
	var schema_version: Variant = document.get("schema_version")
	if not _is_positive_integer(schema_version):
		return InfrastructureResult.failure(
			&"invalid_schema_version",
			"Document must contain a positive integer schema_version.",
			{"source": source}
		)
	if int(schema_version) > SUPPORTED_SCHEMA_VERSION:
		return InfrastructureResult.failure(
			&"unsupported_schema_version",
			"Document schema is newer than this build supports.",
			{"source": source, "schema_version": int(schema_version)}
		)

	return InfrastructureResult.success(document, {"source": source, "schema_version": int(schema_version)})


func _is_supported_runtime_path(path: String) -> bool:
	return path.begins_with("res://") or path.begins_with("user://")


func _is_positive_integer(value: Variant) -> bool:
	if value is int:
		return int(value) > 0
	if value is float:
		return value > 0.0 and is_equal_approx(value, round(value))
	return false
