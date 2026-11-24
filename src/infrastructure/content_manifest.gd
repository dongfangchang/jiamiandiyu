class_name ContentManifest
extends RefCounted

## data/manifest.json is the only definition of the live content set (ADR-0033).

const DEFAULT_PATH := "res://data/manifest.json"
const SCHEMA_PATH := "res://data/schema/manifest.schema.json"
const JsonDocumentLoaderScript := preload("res://src/infrastructure/json_document_loader.gd")

var source_path := ""
var content_revision := 0
var _documents: Dictionary = {}


static func load_manifest(path: String = DEFAULT_PATH) -> InfrastructureResult:
	var loaded := JsonDocumentLoaderScript.new().load_document(path, SCHEMA_PATH)
	if not loaded.ok:
		var details := loaded.details.duplicate(true)
		details["stage"] = "manifest"
		return InfrastructureResult.failure(loaded.code, loaded.message, details)
	var manifest := ContentManifest.new()
	manifest.source_path = path
	manifest.content_revision = int(loaded.data.get("content_revision", 0))
	manifest._documents = loaded.data.get("documents", {}).duplicate(true)
	return InfrastructureResult.success(manifest, {"path": path})


func kinds() -> Array[String]:
	var result: Array[String] = []
	for kind in _documents.keys():
		result.append(String(kind))
	result.sort()
	return result


func has_kind(kind: String) -> bool:
	return _documents.has(kind)


func path_for(kind: String) -> String:
	return String(_documents.get(kind, {}).get("path", ""))


func schema_for(kind: String) -> String:
	return String(_documents.get(kind, {}).get("schema", ""))


## Applies the bootstrap override convention: paths[kind] / paths[kind + "_schema"].
func resolve(kind: String, overrides: Dictionary = {}) -> Dictionary:
	return {
		"path": String(overrides.get(kind, path_for(kind))),
		"schema": String(overrides.get(kind + "_schema", schema_for(kind))),
	}


func load_kind(kind: String, overrides: Dictionary = {}) -> InfrastructureResult:
	if not has_kind(kind) and not overrides.has(kind):
		return InfrastructureResult.failure(
			&"manifest_kind_missing",
			"Content manifest has no entry for this kind.",
			{"kind": kind, "stage": kind}
		)
	var spec := resolve(kind, overrides)
	var loaded := JsonDocumentLoaderScript.new().load_document(spec.path, spec.schema)
	if not loaded.ok:
		var details := loaded.details.duplicate(true)
		details["stage"] = kind
		return InfrastructureResult.failure(loaded.code, loaded.message, details)
	return loaded
