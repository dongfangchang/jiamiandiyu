extends SceneTree

## data/manifest.json is the single definition of live content (ADR-0033, R2-08).

const ContentManifestScript := preload("res://src/infrastructure/content_manifest.gd")
const ContentValidatorScript := preload("res://src/infrastructure/content_validator.gd")
const AppBootstrapScript := preload("res://src/app/bootstrap.gd")

const ROOT := "user://content_manifest_tests"
const BOOT_KINDS := ["cards", "progression", "enemies", "encounters", "balance", "routes", "rituals", "challenges", "decks", "diary"]

var _checks := 0
var _failures: Array[String] = []


func _initialize() -> void:
	_remove_tree(ROOT)
	var loaded := ContentManifestScript.load_manifest()
	_expect(loaded.ok, "manifest loads against its schema (%s)" % loaded.code)
	if loaded.ok:
		var manifest: ContentManifest = loaded.data
		_expect(manifest.content_revision >= 1, "manifest has a content_revision")
		for kind in BOOT_KINDS:
			_expect(manifest.has_kind(kind), "manifest lists %s" % kind)
			_expect(FileAccess.file_exists(manifest.path_for(kind)), "%s path exists" % kind)
			_expect(FileAccess.file_exists(manifest.schema_for(kind)), "%s schema exists" % kind)
		var override := manifest.resolve("cards", {"cards": "user://x.json"})
		_expect(override.path == "user://x.json" and override.schema == manifest.schema_for("cards"), "path overrides keep working")

	var validated := ContentValidatorScript.validate_manifest()
	_expect(validated.ok, "live content validates: %s" % JSON.stringify(validated.details.get("errors", [])))

	_test_detects_missing_file()
	_test_detects_duplicate_id()
	_test_detects_dangling_reference()
	_test_bootstrap_reports_manifest_revision()
	_remove_tree(ROOT)
	if _failures.is_empty():
		print("CONTENT_MANIFEST_PASS checks=%d" % _checks)
		quit(0)
		return
	for failure in _failures:
		printerr("CONTENT_MANIFEST_FAIL %s" % failure)
	quit(1)


func _test_detects_missing_file() -> void:
	var result := ContentValidatorScript.validate_manifest(
		ContentManifestScript.DEFAULT_PATH, {"rituals": "res://data/rituals/missing.json"}
	)
	_expect(not result.ok and _errors_contain(result, "rituals: not_found"), "missing file is reported")


func _test_detects_duplicate_id() -> void:
	var cards: Dictionary = _read(_manifest_path("cards"))
	cards.cards.append(cards.cards[0].duplicate(true))
	var path := _write(ROOT.path_join("cards_dup.json"), cards)
	var result := ContentValidatorScript.validate_manifest(ContentManifestScript.DEFAULT_PATH, {"cards": path})
	_expect(not result.ok and _errors_contain(result, "duplicate"), "duplicate id is reported %s" % JSON.stringify(result.details))


func _test_detects_dangling_reference() -> void:
	var routes: Dictionary = _read(_manifest_path("routes"))
	routes.routes[0].nodes[0].encounter_id = "encounter.does_not_exist"
	var path := _write(ROOT.path_join("routes_bad.json"), routes)
	var result := ContentValidatorScript.validate_manifest(ContentManifestScript.DEFAULT_PATH, {"routes": path})
	_expect(not result.ok and _errors_contain(result, "unknown encounter"), "dangling encounter reference is reported")


func _test_bootstrap_reports_manifest_revision() -> void:
	var manifest: ContentManifest = ContentManifestScript.load_manifest().data
	var started := AppBootstrapScript.start_route_v07(
		7, {"save_directory": ROOT.path_join("saves"), "test_profile": true}, "manifest_probe", false
	)
	_expect(started.ok, "bootstrap starts from the manifest")
	if not started.ok:
		return
	_expect(int(started.details.get("content_revision", 0)) == manifest.content_revision, "bootstrap reports the manifest revision")
	_expect(started.data.content_revision == manifest.content_revision, "session writes the manifest revision")
	var broken := AppBootstrapScript.start_route_v07(7, {"manifest": "res://data/missing_manifest.json"}, "manifest_probe", false)
	_expect(not broken.ok and String(broken.details.get("stage", "")) == "manifest", "missing manifest fails at the manifest stage")


func _errors_contain(result: InfrastructureResult, needle: String) -> bool:
	for message in result.details.get("errors", []):
		if String(message).contains(needle):
			return true
	return false


func _manifest_path(kind: String) -> String:
	return ContentManifestScript.load_manifest().data.path_for(kind)


func _read(path: String) -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(path))


func _write(path: String, document: Dictionary) -> String:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(document))
	file.close()
	return path


func _expect(condition: bool, label: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(label)


func _remove_tree(path: String) -> void:
	var absolute := ProjectSettings.globalize_path(path)
	if not DirAccess.dir_exists_absolute(absolute):
		return
	for file_name in DirAccess.get_files_at(absolute):
		DirAccess.remove_absolute(absolute.path_join(file_name))
	for child in DirAccess.get_directories_at(absolute):
		_remove_tree(path.path_join(child))
	DirAccess.remove_absolute(absolute)
