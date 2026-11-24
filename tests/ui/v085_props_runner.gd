extends Node

## v0.85 prop pipeline probe.
## Asserts the manifest, the keyed outputs and the runtime catalog agree, and
## that a MISSING prop degrades instead of breaking the screen.

const PropCatalog := preload("res://src/ui/prop_ui_catalog.gd")
const DiaryScreenScript := preload("res://src/ui/diary_chapter_screen.gd")
const RouteSnapshotScript := preload("res://src/core/route_snapshot.gd")
const MANIFEST := "res://art/assets/raster/v0.85.0/props/props.manifest.json"

var _checks := 0
var _failures: Array[String] = []


func _ready() -> void:
	## Manifest parses and every declared output is registered in the catalog.
	var f := FileAccess.open(MANIFEST, FileAccess.READ)
	_expect(f != null, "props manifest present")
	if f != null:
		var parsed: Variant = JSON.parse_string(f.get_as_text())
		_expect(parsed is Dictionary, "props manifest parses")
		if parsed is Dictionary:
			var man: Dictionary = parsed
			var rows: Array = man.get("props", [])
			_expect(rows.size() >= 13, "manifest declares the prop set")
			for row_value in rows:
				if not row_value is Dictionary:
					continue
				var row: Dictionary = row_value
				var id := String(row.get("id", ""))
				_expect(
					PropCatalog.PROPS.has(id),
					"catalog knows manifest id %s" % id
				)

	## Keyed art is ingested (run art/tools/key_props.gd if this fails).
	var missing := PropCatalog.missing()
	_expect(missing.is_empty(), "all props ingested (missing=%s)" % str(missing))

	## Alpha actually survived: a keyed cutout must not be fully opaque.
	var seal := PropCatalog.texture("wax_seal")
	_expect(seal != null, "wax seal texture loads")
	if seal != null:
		var img := seal.get_image()
		_expect(img != null and img.detect_alpha() != Image.ALPHA_NONE, "wax seal carries alpha")
		if img != null:
			## Corners are backdrop and must have been keyed out.
			_expect(
				img.get_pixel(0, 0).a <= 0.01,
				"wax seal corner keyed transparent"
			)
			## And the subject must still be there (the flood must not eat it).
			var opaque := 0
			var total := 0
			for y in range(0, img.get_height(), 4):
				for x in range(0, img.get_width(), 4):
					total += 1
					if img.get_pixel(x, y).a > 0.9:
						opaque += 1
			var ratio := float(opaque) / float(maxi(1, total))
			_expect(ratio > 0.25, "wax seal subject retained (opaque=%.0f%%)" % (ratio * 100.0))

	## State tokens map 1:1 onto the rail.
	_expect(PropCatalog.STATE_TOKENS.size() == 4, "four state tokens")
	_expect(PropCatalog.TOKEN_LABELS.size() == 4, "four token labels")
	for i in range(4):
		_expect(PropCatalog.token_for_state(i) != null, "token %d resolves" % i)
	_expect(PropCatalog.token_for_state(99) == null, "out-of-range token is null")

	## Derived seal state variants exist for the paths the stage expects.
	for path in [
		"res://assets/ui/diary/wax_seal_available.png",
		"res://assets/ui/diary/wax_seal_completed.png",
		"res://assets/ui/diary/wax_seal_locked.png",
		"res://assets/ui/diary/desk_wood.png",
	]:
		_expect(ResourceLoader.exists(path), "derived output %s" % path.get_file())

	## The screen builds and shows the rail whether or not art is present.
	var screen = DiaryScreenScript.new()
	add_child(screen)
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen.apply_snapshot(RouteSnapshotScript.new({
		"display_name_zh": "第一卷·小丑：廷根值夜者",
		"phase": "map",
		"available_node_id": "route.v028.first_stage.node.first_hunt",
		"unlocked_node_ids": ["route.v028.first_stage.node.first_hunt"],
		"completed_node_ids": [],
		"run_state": {
			"hp": 30, "max_hp": 30, "spirit": 10, "max_spirit": 10,
			"corruption": 0, "max_corruption": 10, "attention": 0, "max_attention": 10,
		},
		"nodes": [{
			"id": "route.v028.first_stage.node.first_hunt",
			"type": "normal", "state": "available",
			"display_name_zh": "密修会的闯入者",
			"scene_id": "scene.battle.moretti_home",
		}],
	}))
	await get_tree().process_frame
	_expect(screen.find_child("RuneStrip", true, false) != null, "rune rail present")
	for i in range(4):
		_expect(screen.find_child("Rune%d" % i, true, false) != null, "rune %d button" % i)
	_expect(screen.find_child("WaxSealHit", true, false) != null, "wax hit present")

	## Repo-wide .import UID uniqueness. Copying art together with its .import
	## file clones the uid, and Godot then resolves several images to ONE
	## resource — the art looks delivered but the wrong picture renders. It is
	## only a warning at import time, so it is easy to ship. Caught in the wild
	## on the 8 diary chapter plates (all sharing uid://5f63hu8jq632).
	var seen: Dictionary = {}
	var dupes: Array[String] = []
	for root in ["res://assets", "res://art"]:
		_scan_uids(root, seen, dupes)
	_expect(dupes.is_empty(), "no duplicate import UIDs (%s)" % str(dupes.slice(0, 4)))

	if _failures.is_empty():
		print("V085_PROPS_OK checks=%d" % _checks)
		get_tree().quit(0)
		return
	for failure in _failures:
		printerr("V085_PROPS_FAIL: %s" % failure)
	print("V085_PROPS_FAIL checks=%d failures=%s" % [_checks, str(_failures)])
	get_tree().quit(1)


func _scan_uids(path: String, seen: Dictionary, dupes: Array[String]) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		return
	dir.list_dir_begin()
	var entry := dir.get_next()
	while entry != "":
		var full := "%s/%s" % [path, entry]
		if dir.current_is_dir():
			if not entry.begins_with("."):
				_scan_uids(full, seen, dupes)
		elif entry.ends_with(".import"):
			var file := FileAccess.open(full, FileAccess.READ)
			if file != null:
				while not file.eof_reached():
					var line := file.get_line()
					if line.begins_with("uid="):
						var uid := line.split("\"")[1] if line.count("\"") >= 2 else ""
						if not uid.is_empty():
							if seen.has(uid):
								dupes.append("%s == %s" % [
									full.get_file(), String(seen[uid]).get_file()])
							else:
								seen[uid] = full
						break
		entry = dir.get_next()
	dir.list_dir_end()


func _expect(cond: bool, label: String) -> void:
	_checks += 1
	if not cond:
		_failures.append(label)
