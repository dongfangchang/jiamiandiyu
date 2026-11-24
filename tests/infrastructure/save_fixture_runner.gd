extends SceneTree

## Save fixtures v1..v6 (+ corrupt / newer / schema-invalid) through the real
## migration chain (ADR-0033). Fixtures under fixtures/saves are frozen
## historical shapes derived from the golden replay checkpoint (seed 20261124);
## never regenerate them from current code.

const SaveMigrationsScript := preload("res://src/infrastructure/save_migrations.gd")
const AppBootstrapScript := preload("res://src/app/bootstrap.gd")
const CheckpointCodecScript := preload("res://src/app/checkpoint_codec.gd")
const RouteEngineScript := preload("res://src/gameplay/route_engine.gd")

const FIXTURES := "res://tests/infrastructure/fixtures/saves"
const ROOT := "user://save_fixture_tests"
const SLOT := "checkpoint"
const P := "route.v028.first_stage.node."

var _checks := 0
var _failures: Array[String] = []


func _initialize() -> void:
	_remove_tree(ROOT)
	for version in range(1, 7):
		_test_fixture(version)
	_test_v1_markers()
	_test_v4_annotations()
	_test_v5_annotations_and_pruning()
	_test_rejections()
	_test_invariants()
	_test_codec_covers_engine_state()
	_remove_tree(ROOT)
	if _failures.is_empty():
		print("SAVE_FIXTURES_PASS checks=%d" % _checks)
		quit(0)
		return
	for failure in _failures:
		printerr("SAVE_FIXTURES_FAIL %s" % failure)
	quit(1)


func _test_fixture(version: int) -> void:
	var label := "v%d" % version
	var directory := _install(label, "v%d.json" % version)
	var original := FileAccess.get_file_as_string(directory.path_join(SLOT + ".json"))
	var service := SaveMigrationsScript.create_service(directory)
	var loaded := service.load_slot(SLOT)
	_expect(loaded.ok, "%s loads (%s %s)" % [label, loaded.code, JSON.stringify(loaded.details)])
	if not loaded.ok:
		return
	var document: Dictionary = loaded.data
	_expect(int(document.get("save_version", 0)) == 6, "%s migrates to save_version 6" % label)
	_expect(int(document.get("content_revision", 0)) == 1, "%s carries content_revision 1" % label)
	_expect(not document.has("content_version"), "%s drops content_version" % label)
	_expect(bool(loaded.details.get("migrated", false)) == (version < 6), "%s migrated flag" % label)
	_expect(
		FileAccess.get_file_as_string(directory.path_join(SLOT + ".json")) == original,
		"%s load does not rewrite the file" % label
	)

	# Round trip through the writer.
	var written := service.save_slot("roundtrip", document)
	_expect(written.ok, "%s re-saves as v6 (%s)" % [label, written.code])
	var reloaded := service.load_slot("roundtrip")
	_expect(reloaded.ok and _canon(reloaded.data) == _canon(document), "%s round-trips unchanged" % label)

	# Round trip through the game: resume, then write a checkpoint from live engines.
	# v1 is excluded: its migrated progression reset has no starter cards, so the
	# default deck cannot be confirmed (pre-existing; see infrastructure report).
	if version == 1:
		return
	var started := AppBootstrapScript.start_route_v07(
		20261124, {"save_directory": directory}, SLOT, true
	)
	_expect(started.ok, "%s resumes through bootstrap (%s %s)" % [label, started.code, JSON.stringify(started.details)])
	if not started.ok:
		return
	var session = started.data
	var saved: InfrastructureResult = session.save_checkpoint("route")
	_expect(saved.ok, "%s session writes a checkpoint (%s %s)" % [label, saved.code, JSON.stringify(saved.details)])
	var resaved := service.load_slot(SLOT)
	_expect(resaved.ok, "%s session checkpoint reloads" % label)
	if not resaved.ok:
		return
	var after: Dictionary = resaved.data
	_expect(int(after.get("save_version", 0)) == 6, "%s session writes v6" % label)
	if bool(document.get("route", {}).get("initialized", false)):
		# Older states gain engine-derived fields on restore; every saved field must survive.
		for key in document.route.state:
			_expect(
				_canon(after.route.state.get(key)) == _canon(document.route.state[key]),
				"%s route.state.%s survives decode/encode" % [label, key]
			)
		if version >= 5:
			_expect(_canon(after.route.state) == _canon(document.route.state), "%s route state identical" % label)
	if version >= 5:
		_expect(_canon(after.progression) == _canon(document.progression), "%s progression survives decode/encode" % label)
		_expect(_canon(after.deck) == _canon(document.deck), "%s deck survives decode/encode" % label)
	_expect(
		FileAccess.file_exists(service.get_slot_path(SLOT, true)),
		"%s first v6 write keeps the old file as backup" % label
	)


func _test_v1_markers() -> void:
	var document := _load_fixture("v1_markers", "v1.json")
	if document.is_empty():
		return
	_expect(bool(document.progression.get("migrated_from_v1", false)), "v1 marks the progression reset")
	_expect(bool(document.route.get("migrated_from_v2", false)), "v1 gets an uninitialized route")
	_expect(bool(document.challenge.get("migrated_from_v3", false)), "v1 gets an inactive challenge")
	_expect(bool(document.deck.get("migrated_from_v4", false)), "v1 gets an uninitialized deck")


func _test_v4_annotations() -> void:
	var document := _load_fixture("v4_annotations", "v4.json")
	if document.is_empty():
		return
	_expect(
		String(document.route.state.clue_annotations.get(P + "first_hunt", "")) == "annotation.victory.first_hunt",
		"v4 annotation text maps to its id"
	)


func _test_v5_annotations_and_pruning() -> void:
	var document := _load_fixture("v5_annotations", "v5.json")
	if document.is_empty():
		return
	var state: Dictionary = document.route.state
	var annotations: Dictionary = state.clue_annotations
	_expect(String(annotations.get(P + "first_hunt", "")) == "annotation.victory.first_hunt", "v5 known text maps to id")
	_expect(not annotations.has(P + "tenant_trace"), "v5 unknown text is not kept as an id")
	_expect(
		String(state.get("legacy_clue_annotations_zh", {}).get(P + "tenant_trace", "")) == "【0-08】自由书写的旧旁注。",
		"v5 unknown text kept display-only"
	)
	var lamud: Dictionary = state.clue_overlays.get(P + "lamud", {})
	_expect(String(lamud.get("annotation_id", "")) == "annotation.pen_rewrite.lamud", "v5 overlay text maps to id")
	_expect(String(lamud.get("margin_note_id", "")) == "annotation.pen_rewrite.margin", "v5 margin text maps to id")
	_expect(not lamud.has("text_zh") and not lamud.has("margin_note_zh"), "v5 overlay text fields removed")
	var mirror: Dictionary = state.clue_overlays.get(P + "mirror_pursuit", {})
	_expect(String(mirror.get("legacy_text_zh", "")) == "旧存档里的改写文本", "v5 unknown overlay text kept as legacy_text_zh")
	_expect(not mirror.has("annotation_id"), "v5 unknown overlay text has no id")
	_expect(not state.has("obsolete_engine_field"), "v5 fields unknown to v6 are pruned")

	# The engine now only ever sees ids: a restored route exposes them unchanged.
	var started := AppBootstrapScript.start_route_v07(
		20261124, {"save_directory": ROOT.path_join("v5_annotations")}, SLOT, true
	)
	_expect(started.ok, "v5 with legacy text resumes")
	if started.ok:
		var snapshot: Dictionary = started.data.get_route_snapshot().data
		_expect(
			String(snapshot.get("legacy_clue_annotations_zh", {}).get(P + "tenant_trace", "")) == "【0-08】自由书写的旧旁注。",
			"restored snapshot shows legacy text display-only"
		)


func _test_rejections() -> void:
	var cases := [
		["corrupt", "corrupt.json", &"invalid_json"],
		["newer", "newer_version.json", &"unsupported_save_version"],
		["schema_invalid", "v5_schema_invalid.json", &"source_validation_failed"],
	]
	for case in cases:
		var directory := _install(case[0], case[1])
		var path := directory.path_join(SLOT + ".json")
		var original := FileAccess.get_file_as_string(path)
		var service := SaveMigrationsScript.create_service(directory)
		var loaded := service.load_slot(SLOT)
		_expect(not loaded.ok and loaded.code == case[2], "%s rejected as %s (got %s)" % [case[0], case[2], loaded.code])
		var inspected := AppBootstrapScript.inspect_route_checkpoint_v07(SLOT, directory)
		_expect(
			inspected.ok and String(inspected.data.get("status", "")) == "corrupt"
			and String(inspected.data.get("error_code", "")) == String(case[2]),
			"%s inspect reports corrupt with its code" % case[0]
		)
		var resumed := AppBootstrapScript.start_route_v07(1, {"save_directory": directory}, SLOT, true)
		_expect(not resumed.ok and resumed.code == &"route_checkpoint_unavailable", "%s cannot be resumed" % case[0])
		# A new write must not replace a file that cannot be read back as backup.
		var v6: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(FIXTURES.path_join("v6.json")))
		var overwrite := service.save_slot(SLOT, v6)
		_expect(not overwrite.ok and overwrite.code == &"backup_validation_failed", "%s blocks overwrite (%s)" % [case[0], overwrite.code])
		_expect(FileAccess.get_file_as_string(path) == original, "%s file left untouched" % case[0])


func _test_invariants() -> void:
	var base: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(FIXTURES.path_join("v6.json")))
	var mismatched := base.duplicate(true)
	mismatched.route.route_id = "route.v070.first_case"
	var newer_content := base.duplicate(true)
	newer_content.content_revision = 99
	var repeated := base.duplicate(true)
	repeated.route.state.completed_node_ids.append(P + "first_hunt")
	var text_annotation := base.duplicate(true)
	text_annotation.route.state.clue_annotations[P + "baron"] = "旧文本"
	var cases := [
		["route_id_mismatch", mismatched, &"invariant_failed"],
		["content_revision_newer", newer_content, &"invariant_failed"],
		["completed_repeated", repeated, &"invariant_failed"],
		["annotation_text_in_v6", text_annotation, &"source_validation_failed"],
	]
	for case in cases:
		var directory := ROOT.path_join(case[0])
		_write(directory.path_join(SLOT + ".json"), JSON.stringify(case[1]))
		var service := SaveMigrationsScript.create_service(directory)
		var loaded := service.load_slot(SLOT)
		_expect(not loaded.ok and loaded.code == case[2], "%s rejected as %s (got %s)" % [case[0], case[2], loaded.code])
		var write := service.save_slot("other", case[1])
		_expect(not write.ok, "%s is also refused on write" % case[0])


func _test_codec_covers_engine_state() -> void:
	var directory := ROOT.path_join("v6")
	var started := AppBootstrapScript.start_route_v07(20261124, {"save_directory": directory}, SLOT, true)
	if not started.ok:
		_expect(false, "codec audit needs a resumed session")
		return
	var session = started.data
	_expect(CheckpointCodecScript.audit("progression", session.progression.export_persistent_state()).is_empty(), "codec maps every progression field")
	_expect(CheckpointCodecScript.audit("deck", session.deck_engine.export_persistent_state()).is_empty(), "codec maps every deck field")
	# Fresh and mid-route engine states.
	var engine := RouteEngineScript.new(session.route_content, &"route.v028.first_stage")
	engine.initialize()
	_expect(CheckpointCodecScript.audit("route", engine.export_persistent_state()).is_empty(), "codec maps every fresh route field")
	var restored := RouteEngineScript.new(session.route_content, &"route.v028.first_stage")
	var v6: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(FIXTURES.path_join("v6.json")))
	restored.initialize(CheckpointCodecScript.decode_route_state(v6.route.state))
	var unknown := CheckpointCodecScript.audit("route", restored.export_persistent_state())
	_expect(unknown.is_empty(), "codec maps every completed route field %s" % str(unknown))


func _load_fixture(label: String, file_name: String) -> Dictionary:
	var directory := _install(label, file_name)
	var loaded := SaveMigrationsScript.create_service(directory).load_slot(SLOT)
	_expect(loaded.ok, "%s loads (%s)" % [label, loaded.code])
	return loaded.data if loaded.ok else {}


func _install(label: String, file_name: String) -> String:
	var directory := ROOT.path_join(label)
	_write(directory.path_join(SLOT + ".json"), FileAccess.get_file_as_string(FIXTURES.path_join(file_name)))
	return directory


func _write(path: String, text: String) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(text)
	file.close()


## Volatile fields excluded; integral floats folded to int so JSON and engine values compare.
func _canon(value: Variant) -> String:
	return JSON.stringify(_normalize(value), "", true)


func _normalize(value: Variant) -> Variant:
	if value is Dictionary:
		var out := {}
		for key in value:
			if String(key) == "created_at":
				continue
			out[String(key)] = _normalize(value[key])
		return out
	if value is Array:
		var items: Array = []
		for item in value:
			items.append(_normalize(item))
		return items
	if value is float and is_equal_approx(value, round(value)):
		return int(value)
	return value


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
