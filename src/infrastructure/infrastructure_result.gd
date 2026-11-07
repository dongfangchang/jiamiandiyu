class_name InfrastructureResult
extends RefCounted

var ok: bool
var code: StringName
var message: String
var data: Variant
var details: Dictionary


static func success(value: Variant = null, result_details: Dictionary = {}) -> InfrastructureResult:
	var result := InfrastructureResult.new()
	result.ok = true
	result.code = &"ok"
	result.message = ""
	result.data = value
	result.details = result_details
	return result


static func failure(error_code: StringName, error_message: String, result_details: Dictionary = {}) -> InfrastructureResult:
	var result := InfrastructureResult.new()
	result.ok = false
	result.code = error_code
	result.message = error_message
	result.data = null
	result.details = result_details
	return result
