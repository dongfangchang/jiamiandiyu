class_name ContentValidator
extends RefCounted

## Validates the manifest content set: every entry exists and satisfies its
## schema, IDs are unique, and cross-document references resolve. Reference
## checks reuse the adapters the game boots with.

const ContentManifestScript := preload("res://src/infrastructure/content_manifest.gd")
const CampaignContentCatalogScript := preload("res://src/infrastructure/campaign_content_catalog.gd")
const BattleContentAdapterScript := preload("res://src/infrastructure/battle_content_adapter.gd")
const ProgressionContentAdapterScript := preload("res://src/infrastructure/progression_content_adapter.gd")
const RouteContentAdapterScript := preload("res://src/infrastructure/route_content_adapter.gd")
const ChallengeContentAdapterScript := preload("res://src/infrastructure/challenge_content_adapter.gd")
const DeckContentAdapterScript := preload("res://src/infrastructure/deck_content_adapter.gd")

const ANNOTATION_PREFIX := "annotation."


static func validate_manifest(
	manifest_path: String = ContentManifestScript.DEFAULT_PATH,
	overrides: Dictionary = {}
) -> InfrastructureResult:
	var manifest_result := ContentManifestScript.load_manifest(manifest_path)
	if not manifest_result.ok:
		return manifest_result
	return validate(manifest_result.data, overrides)


static func validate(manifest: ContentManifest, overrides: Dictionary = {}) -> InfrastructureResult:
	var errors: Array[String] = []
	var documents := {}
	for kind in manifest.kinds():
		var loaded := manifest.load_kind(kind, overrides)
		if not loaded.ok:
			errors.append("%s: %s (%s) %s" % [
				kind, String(loaded.code), manifest.resolve(kind, overrides).path,
				JSON.stringify(loaded.details.get("errors", []))
			])
			continue
		documents[kind] = loaded.data
		_check_unique_ids(kind, loaded.data, errors)
	if errors.is_empty():
		_check_references(documents, errors)
	if not errors.is_empty():
		return InfrastructureResult.failure(
			&"content_invalid",
			"Manifest content failed validation.",
			{"errors": errors, "content_revision": manifest.content_revision}
		)
	return InfrastructureResult.success(
		{"content_revision": manifest.content_revision, "kinds": manifest.kinds()}
	)


static func _check_unique_ids(kind: String, document: Dictionary, errors: Array[String]) -> void:
	for key in document.keys():
		var value: Variant = document[key]
		if not value is Array:
			continue
		var seen := {}
		for item in value:
			if not item is Dictionary or not item.has("id"):
				continue
			var item_id := String(item["id"])
			if seen.has(item_id):
				errors.append("%s.%s: duplicate id %s" % [kind, key, item_id])
			seen[item_id] = true


static func _check_references(documents: Dictionary, errors: Array[String]) -> void:
	var catalog := CampaignContentCatalogScript.new()
	var catalog_result := catalog.load_from_documents(
		documents.cards, documents.enemies, documents.encounters
	)
	if not catalog_result.ok:
		errors.append("catalog: %s %s" % [String(catalog_result.code), JSON.stringify(catalog_result.details)])
		return
	var battle_content := BattleContentAdapterScript.new(
		documents.cards.get("cards", []), documents.cards.get("synergies", [])
	)
	var progression := ProgressionContentAdapterScript.new(documents.progression, battle_content)
	if progression.base_cards_version != catalog.cards_content_version:
		errors.append("progression.base_cards_version does not match cards")
	var route_content := RouteContentAdapterScript.new(
		documents.routes, documents.rituals, catalog, documents.balance, documents.diary
	)
	for message in route_content.validation_errors():
		errors.append("routes: " + message)
	var deck_content := DeckContentAdapterScript.new(documents.decks, battle_content)
	for message in deck_content.validation_errors():
		errors.append("decks: " + message)
	var challenge_content := ChallengeContentAdapterScript.new(
		documents.challenges, catalog, route_content, progression
	)
	for message in challenge_content.validation_errors():
		errors.append("challenges: " + message)
	if not challenge_content.is_valid() and challenge_content.validation_errors().is_empty():
		errors.append("challenges: default challenge missing")
	_check_route_refs(documents, errors)
	_check_annotation_refs(documents, errors)


static func _check_route_refs(documents: Dictionary, errors: Array[String]) -> void:
	var encounter_ids := _ids(documents.encounters.get("encounters", []))
	var ritual_ids := _ids(documents.rituals.get("rituals", []))
	var node_ids := {}
	for route in documents.routes.get("routes", []):
		for node in route.get("nodes", []):
			var node_id := String(node.get("id", ""))
			if node_ids.has(node_id):
				errors.append("routes: duplicate node id %s" % node_id)
			node_ids[node_id] = true
			var encounter_id := String(node.get("encounter_id", ""))
			if not encounter_id.is_empty() and not encounter_ids.has(encounter_id):
				errors.append("routes: %s references unknown encounter %s" % [node_id, encounter_id])
			var ritual_id := String(node.get("ritual_id", ""))
			if not ritual_id.is_empty() and not ritual_ids.has(ritual_id):
				errors.append("routes: %s references unknown ritual %s" % [node_id, ritual_id])
	var diary_route := String(documents.diary.get("route_id", ""))
	if not diary_route.is_empty() and not _ids(documents.routes.get("routes", [])).has(diary_route):
		errors.append("diary: route_id %s does not exist" % diary_route)


static func _check_annotation_refs(documents: Dictionary, errors: Array[String]) -> void:
	var annotations: Dictionary = documents.diary.get("annotations", {})
	var entries: Dictionary = annotations.get("entries", {})
	for entry_id in entries.keys():
		if not String(entry_id).begins_with(ANNOTATION_PREFIX):
			errors.append("diary.annotations: entry id %s lacks prefix" % entry_id)
	var referenced: Array[String] = []
	_collect_annotation_ids(annotations.get("pools", {}), referenced)
	_collect_annotation_ids(annotations.get("fixed", {}), referenced)
	for annotation_id in referenced:
		if not entries.has(annotation_id):
			errors.append("diary.annotations: %s is referenced but not defined" % annotation_id)


static func _collect_annotation_ids(value: Variant, out: Array[String]) -> void:
	if value is String:
		if String(value).begins_with(ANNOTATION_PREFIX):
			out.append(String(value))
	elif value is Array:
		for item in value:
			_collect_annotation_ids(item, out)
	elif value is Dictionary:
		for item in value.values():
			_collect_annotation_ids(item, out)


static func _ids(items: Array) -> Dictionary:
	var result := {}
	for item in items:
		if item is Dictionary:
			result[String(item.get("id", ""))] = true
	return result
