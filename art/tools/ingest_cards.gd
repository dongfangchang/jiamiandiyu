extends SceneTree

## Card art ingest: art/assets/raster/<ver>/cards/<card.id>/art.png
##                  -> assets/game/<ver>/cards/<card.id>/art.png
## plus the seal matrix -> assets/game/<ver>/seals/
##
##   "$GODOT" --headless --path . --script art/tools/ingest_cards.gd
##
## Convention over configuration: the SOURCE DIRECTORY NAME IS THE CARD ID, so
## adding a card is "make a folder named after the id, drop art.png" — no
## manifest row, no code change. The tool cross-checks every id against
## data/cards/** and reports orphans (art with no card) and gaps (card with no
## art) rather than silently copying.

const SRC_CARDS := "res://art/assets/raster/v0.85.0/cards"
const SRC_SEALS := "res://art/assets/raster/v0.85.0/seals"
const OUT_CARDS := "res://assets/game/v0.85.0/cards"
const OUT_SEALS := "res://assets/game/v0.85.0/seals"
const CARDS_PATH := "res://data/cards/v0.7.0/cards.json"
const ART_W := 512
const ART_H := 390


func _init() -> void:
	quit(0 if _run() else 1)


func _run() -> bool:
	var known := _known_card_ids()
	if known.is_empty():
		printerr("INGEST_CARDS_FAIL cannot read %s" % CARDS_PATH)
		return false

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_CARDS))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_SEALS))

	var copied := 0
	var orphans: Array[String] = []
	var wrong_size: Array[String] = []
	var seen: Dictionary = {}

	var dir := DirAccess.open(SRC_CARDS)
	if dir == null:
		printerr("INGEST_CARDS_FAIL cannot open %s" % SRC_CARDS)
		return false
	dir.list_dir_begin()
	var entry := dir.get_next()
	while entry != "":
		if dir.current_is_dir() and entry.begins_with("card."):
			var src := "%s/%s/art.png" % [SRC_CARDS, entry]
			if FileAccess.file_exists(src):
				if not known.has(entry):
					## Art for a card that does not exist: copying it would
					## bake a dead id into assets/game.
					orphans.append(entry)
				else:
					seen[entry] = true
					var img := Image.load_from_file(ProjectSettings.globalize_path(src))
					if img == null:
						wrong_size.append("%s (unreadable)" % entry)
					else:
						if img.get_width() != ART_W or img.get_height() != ART_H:
							wrong_size.append(
								"%s (%dx%d)" % [entry, img.get_width(), img.get_height()]
							)
						var out_dir := "%s/%s" % [OUT_CARDS, entry]
						DirAccess.make_dir_recursive_absolute(
							ProjectSettings.globalize_path(out_dir)
						)
						if img.save_png(
							ProjectSettings.globalize_path("%s/art.png" % out_dir)
						) == OK:
							copied += 1
		entry = dir.get_next()
	dir.list_dir_end()

	var seals := _copy_seals()

	var gaps: Array[String] = []
	for id in known.keys():
		if not seen.has(id):
			gaps.append(String(id))
	gaps.sort()

	print("  卡牌插画 %d/%d 张已迁移" % [copied, known.size()])
	print("  蜡封 %d 张已迁移" % seals)
	if not gaps.is_empty():
		print("  尚无插画 (%d): %s" % [gaps.size(), str(gaps)])
	if not wrong_size.is_empty():
		## Not fatal: the frame scales it, but it will not line up pixel-exact.
		print("  尺寸非 %dx%d (%d): %s" % [ART_W, ART_H, wrong_size.size(), str(wrong_size)])
	if not orphans.is_empty():
		printerr("INGEST_CARDS_FAIL 插画无对应卡牌: %s" % str(orphans))
		return false

	print("INGEST_CARDS_OK cards=%d seals=%d gaps=%d" % [copied, seals, gaps.size()])
	return true


func _copy_seals() -> int:
	var n := 0
	var dir := DirAccess.open(SRC_SEALS)
	if dir == null:
		return 0
	dir.list_dir_begin()
	var entry := dir.get_next()
	while entry != "":
		if not dir.current_is_dir() and entry.ends_with(".png"):
			var img := Image.load_from_file(
				ProjectSettings.globalize_path("%s/%s" % [SRC_SEALS, entry])
			)
			if img != null and img.save_png(
				ProjectSettings.globalize_path("%s/%s" % [OUT_SEALS, entry])
			) == OK:
				n += 1
		entry = dir.get_next()
	dir.list_dir_end()
	return n


func _known_card_ids() -> Dictionary:
	var out := {}
	if not FileAccess.file_exists(CARDS_PATH):
		return out
	var file := FileAccess.open(CARDS_PATH, FileAccess.READ)
	if file == null:
		return out
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return out
	for card_value in (parsed as Dictionary).get("cards", []):
		if card_value is Dictionary:
			var id := String((card_value as Dictionary).get("id", ""))
			if not id.is_empty():
				out[id] = true
	return out
