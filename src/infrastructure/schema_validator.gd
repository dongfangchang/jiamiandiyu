class_name SchemaValidator
extends RefCounted

const MAX_REPORTED_ERRORS := 24


func validate_document(document: Variant, schema_path: String) -> InfrastructureResult:
	if not (schema_path.begins_with("res://") or schema_path.begins_with("user://")):
		return InfrastructureResult.failure(&"invalid_schema_path", "Schema path must use res:// or user://.")
	if not FileAccess.file_exists(schema_path):
		return InfrastructureResult.failure(&"schema_not_found", "Schema file does not exist.", {"path": schema_path})

	var file := FileAccess.open(schema_path, FileAccess.READ)
	if file == null:
		return InfrastructureResult.failure(
			&"schema_read_failed",
			"Schema file could not be opened.",
			{"path": schema_path, "error": FileAccess.get_open_error()}
		)
	var text := file.get_as_text()
	file.close()

	var json := JSON.new()
	var parse_error := json.parse(text)
	if parse_error != OK:
		return InfrastructureResult.failure(
			&"invalid_schema_json",
			"Schema file is not valid JSON.",
			{"path": schema_path, "line": json.get_error_line(), "message": json.get_error_message()}
		)
	if not json.data is Dictionary:
		return InfrastructureResult.failure(
			&"invalid_schema_root",
			"Schema root must be an object.",
			{"path": schema_path}
		)

	var errors: Array[String] = []
	_validate_value(document, json.data, "$", errors)
	if not errors.is_empty():
		return InfrastructureResult.failure(
			&"schema_validation_failed",
			"Document does not satisfy its schema.",
			{"schema_path": schema_path, "errors": errors}
		)
	return InfrastructureResult.success(document, {"schema_path": schema_path})


func _validate_value(value: Variant, schema: Dictionary, path: String, errors: Array[String]) -> void:
	if errors.size() >= MAX_REPORTED_ERRORS:
		return

	if schema.has("const") and not _values_equal(value, schema["const"]):
		_add_error(errors, path, "must equal %s" % str(schema["const"]))
		return
	if schema.has("enum") and not _value_in_enum(value, schema["enum"]):
		_add_error(errors, path, "must be one of %s" % str(schema["enum"]))
		return

	var expected_type: Variant = schema.get("type")
	if expected_type != null and not _matches_type(value, String(expected_type)):
		_add_error(errors, path, "must be %s" % expected_type)
		return

	match typeof(value):
		TYPE_DICTIONARY:
			_validate_object(value, schema, path, errors)
		TYPE_ARRAY:
			_validate_array(value, schema, path, errors)
		TYPE_STRING:
			_validate_string(value, schema, path, errors)
		TYPE_INT, TYPE_FLOAT:
			_validate_number(value, schema, path, errors)


func _validate_object(value: Dictionary, schema: Dictionary, path: String, errors: Array[String]) -> void:
	var required: Array = schema.get("required", [])
	for required_key in required:
		if not value.has(String(required_key)):
			_add_error(errors, path, "missing required property '%s'" % required_key)

	var properties: Dictionary = schema.get("properties", {})
	for property_name in properties:
		if value.has(property_name):
			_validate_value(
				value[property_name],
				properties[property_name],
				"%s.%s" % [path, property_name],
				errors
			)

	var additional_properties: Variant = schema.get("additionalProperties", true)
	if additional_properties is bool and not additional_properties:
		for key in value:
			if not properties.has(String(key)):
				_add_error(errors, path, "unexpected property '%s'" % key)
	elif additional_properties is Dictionary:
		for key in value:
			if not properties.has(String(key)):
				_validate_value(
					value[key],
					additional_properties,
					"%s.%s" % [path, key],
					errors
				)

	var minimum_properties: Variant = schema.get("minProperties")
	if _is_integer_number(minimum_properties) and value.size() < int(minimum_properties):
		_add_error(errors, path, "must contain at least %d properties" % int(minimum_properties))


func _validate_array(value: Array, schema: Dictionary, path: String, errors: Array[String]) -> void:
	var minimum_items: Variant = schema.get("minItems")
	if _is_integer_number(minimum_items) and value.size() < int(minimum_items):
		_add_error(errors, path, "must contain at least %d items" % int(minimum_items))
	var maximum_items: Variant = schema.get("maxItems")
	if _is_integer_number(maximum_items) and value.size() > int(maximum_items):
		_add_error(errors, path, "must contain at most %d items" % int(maximum_items))

	var item_schema: Variant = schema.get("items")
	if item_schema is Dictionary:
		for index in range(value.size()):
			_validate_value(value[index], item_schema, "%s[%d]" % [path, index], errors)

	var unique_by: Variant = schema.get("x-uniqueBy")
	if unique_by is String and not unique_by.is_empty():
		var seen_values: Dictionary = {}
		for index in range(value.size()):
			var item: Variant = value[index]
			if not item is Dictionary or not item.has(unique_by):
				continue
			var unique_value: Variant = item[unique_by]
			if seen_values.has(unique_value):
				_add_error(
					errors,
					"%s[%d].%s" % [path, index, unique_by],
					"duplicates value '%s'" % unique_value
				)
			else:
				seen_values[unique_value] = true


func _validate_string(value: String, schema: Dictionary, path: String, errors: Array[String]) -> void:
	var minimum_length: Variant = schema.get("minLength")
	if _is_integer_number(minimum_length) and value.length() < int(minimum_length):
		_add_error(errors, path, "length must be at least %d" % int(minimum_length))
	var maximum_length: Variant = schema.get("maxLength")
	if _is_integer_number(maximum_length) and value.length() > int(maximum_length):
		_add_error(errors, path, "length must be at most %d" % int(maximum_length))
	var pattern: Variant = schema.get("pattern")
	if pattern is String:
		var regex := RegEx.new()
		if regex.compile(pattern) == OK and regex.search(value) == null:
			_add_error(errors, path, "does not match pattern '%s'" % pattern)


func _validate_number(value: Variant, schema: Dictionary, path: String, errors: Array[String]) -> void:
	var numeric_value := float(value)
	var minimum: Variant = schema.get("minimum")
	if _is_number(minimum) and numeric_value < float(minimum):
		_add_error(errors, path, "must be at least %s" % minimum)
	var maximum: Variant = schema.get("maximum")
	if _is_number(maximum) and numeric_value > float(maximum):
		_add_error(errors, path, "must be at most %s" % maximum)


func _matches_type(value: Variant, expected_type: String) -> bool:
	match expected_type:
		"object":
			return value is Dictionary
		"array":
			return value is Array
		"string":
			return value is String
		"integer":
			return _is_integer_number(value)
		"number":
			return _is_number(value)
		"boolean":
			return value is bool
		"null":
			return value == null
		_:
			return true


func _value_in_enum(value: Variant, allowed_values: Variant) -> bool:
	if not allowed_values is Array:
		return false
	for allowed in allowed_values:
		if _values_equal(value, allowed):
			return true
	return false


func _values_equal(left: Variant, right: Variant) -> bool:
	if _is_number(left) and _is_number(right):
		return is_equal_approx(float(left), float(right))
	return left == right


func _is_number(value: Variant) -> bool:
	return value is int or value is float


func _is_integer_number(value: Variant) -> bool:
	if value is int:
		return true
	if value is float:
		return is_equal_approx(value, round(value))
	return false


func _add_error(errors: Array[String], path: String, message: String) -> void:
	if errors.size() < MAX_REPORTED_ERRORS:
		errors.append("%s %s" % [path, message])
