extends SceneTree

const SOURCE_ROOT := "res://art/assets/svg/v0.24.0"
const OUTPUT_ROOT := "res://assets/game/v0.24.0"
const CONTACT_SHEET_SIZE := Vector2i(1024, 0)
const CELL_SIZE := Vector2i(256, 184)

var _assets: Array[Dictionary] = []


func _init() -> void:
	_collect(SOURCE_ROOT)
	_assets.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return String(a["relative"]) < String(b["relative"])
	)
	var manifest: Array[Dictionary] = []
	for asset in _assets:
		var relative := String(asset["relative"])
		var source_path := String(asset["source"])
		var source := load(source_path) as Texture2D
		if source == null:
			printerr("V024_ART_RENDER_FAIL source=%s" % source_path)
			quit(1)
			return
		var image := source.get_image()
		if image == null or image.is_empty():
			printerr("V024_ART_RENDER_FAIL image=%s" % source_path)
			quit(1)
			return
		var output_relative := relative.get_basename() + ".png"
		var output_path := OUTPUT_ROOT.path_join(output_relative)
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output_path.get_base_dir()))
		var error := image.save_png(ProjectSettings.globalize_path(output_path))
		if error != OK:
			printerr("V024_ART_RENDER_FAIL output=%s error=%d" % [output_path, error])
			quit(1)
			return
		manifest.append(_manifest_entry(relative, output_relative, image))
	_generate_contact_sheet(manifest)
	var manifest_path := OUTPUT_ROOT.path_join("render-manifest.json")
	var manifest_json := JSON.stringify({
		"version": "v0.24.0",
		"generator": "art/tools/generate_v024_art_polish.mjs + art/tools/render_v024_art.gd",
		"source_policy": "project-authored SVG only; no external images",
		"assets": manifest,
	}, "  ")
	var manifest_file := FileAccess.open(manifest_path, FileAccess.WRITE)
	manifest_file.store_string(manifest_json + "\n")
	manifest_file.close()
	print("V024_ART_RENDER_OK assets=%d output=%s" % [manifest.size(), OUTPUT_ROOT])
	quit(0)


func _collect(directory: String) -> void:
	var entries := DirAccess.get_files_at(directory)
	for entry in entries:
		if entry.ends_with(".svg"):
			var source_path := directory.path_join(entry)
			_assets.append({
				"source": source_path,
				"relative": source_path.trim_prefix(SOURCE_ROOT + "/"),
			})
	for entry in DirAccess.get_directories_at(directory):
		_collect(directory.path_join(entry))


func _manifest_entry(relative: String, output_relative: String, image: Image) -> Dictionary:
	var stable_id := _stable_id(relative)
	return {
		"stable_id": stable_id,
		"source": "art/assets/svg/v0.24.0/" + relative,
		"png": "assets/game/v0.24.0/" + output_relative,
		"width": image.get_width(),
		"height": image.get_height(),
		"usage_pages": _usage_pages(stable_id, relative),
		"review_status": "candidate_pending_ui_review",
		"source_info": {
			"kind": "project-authored-svg",
			"generator": "art/tools/generate_v024_art_polish.mjs",
			"license": "project-original",
		},
	}


func _stable_id(relative: String) -> String:
	var normalized := relative.to_lower().replace("\\", "/")
	var base := normalized.get_basename()
	var filename := base.get_file()
	if "cards/card-identity-" in normalized and not "identities/" in normalized:
		return "asset.sample_identity." + filename.trim_prefix("card-identity-").replace("-", "_")
	if "cards/card-artifact-" in normalized:
		return "card.artifact." + filename.trim_prefix("card-artifact-").replace("-", "_")
	if "cards/card-skill-" in normalized or "cards/card_skill_" in normalized:
		var skill := filename.trim_prefix("card-skill-").trim_prefix("card_skill_")
		return "card.skill." + skill.replace("-", "_")
	if "enemies/" in normalized:
		return "enemy." + filename.trim_prefix("enemy-").replace("-", "_")
	if "identities/" in normalized and "card-identity-" in filename:
		return "identity." + filename.trim_prefix("card-identity-").replace("-", "_")
	if "scenes/" in normalized:
		return "scene." + filename.replace("-", "_")
	if "status/" in normalized:
		return "status." + filename.trim_prefix("status-").replace("-", "_")
	if "rituals/" in normalized:
		return "ritual.card." + filename.trim_prefix("ritual-card-").replace("-", "_")
	if "icons/" in normalized:
		return "icon." + filename.replace("-", "_")
	return "asset." + filename.replace("-", "_")


func _usage_pages(stable_id: String, relative: String) -> Array[String]:
	if stable_id.begins_with("scene.title"):
		return ["title", "identity", "result"]
	if stable_id.begins_with("scene.battle") or stable_id.begins_with("enemy.") or stable_id.begins_with("card.skill"):
		return ["battle", "deck", "reward", "gacha"]
	if stable_id.begins_with("scene.route") or stable_id.begins_with("scene.rest") or stable_id.begins_with("scene.ritual"):
		return ["route", "rest", "ritual"]
	if stable_id.begins_with("scene.challenge") or stable_id.begins_with("icon.challenge"):
		return ["challenge"]
	if stable_id.begins_with("scene.deck"):
		return ["deck"]
	if stable_id.begins_with("scene.reward") or stable_id.begins_with("scene.gacha") or stable_id.begins_with("identity.") or stable_id.begins_with("card.artifact"):
		return ["identity", "reward", "gacha", "upgrade"]
	return [relative.get_base_dir().get_file()]


func _generate_contact_sheet(manifest: Array[Dictionary]) -> void:
	var columns := 4
	var rows := ceili(float(manifest.size()) / columns)
	var sheet := Image.create(CELL_SIZE.x * columns, CELL_SIZE.y * rows, false, Image.FORMAT_RGBA8)
	sheet.fill(Color("#10140f"))
	for index in manifest.size():
		var item: Dictionary = manifest[index]
		var image := Image.load_from_file(ProjectSettings.globalize_path(String(item["png"])))
		if image == null or image.is_empty():
			continue
		var scale := minf(float(CELL_SIZE.x - 24) / image.get_width(), float(CELL_SIZE.y - 24) / image.get_height())
		var target := Vector2i(maxi(1, int(image.get_width() * scale)), maxi(1, int(image.get_height() * scale)))
		image.resize(target.x, target.y, Image.INTERPOLATE_LANCZOS)
		var cell := Vector2i(index % columns, index / columns) * CELL_SIZE
		var position := cell + Vector2i((CELL_SIZE.x - target.x) / 2, (CELL_SIZE.y - target.y) / 2)
		sheet.blit_rect(image, Rect2i(Vector2i.ZERO, target), position)
	sheet.save_png(ProjectSettings.globalize_path(OUTPUT_ROOT.path_join("contact-sheet.png")))
