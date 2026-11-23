extends SceneTree

const SOURCE_DIRECTORY := "res://art/assets/svg/v0.42.0/cards"
const OUTPUT_DIRECTORY := "res://assets/game/v0.42.0/cards"
const CARD_IDS := [
	"ink_scarlet",
	"echo_reading",
	"midnight_ledger",
	"borrowed_breath",
	"glass_thesis",
	"hungry_symbol",
	"candle_archive",
	"omen_chorus",
	"closed_eye",
	"black_thread",
	"eclipse",
	"red_corridor",
]


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(
		ProjectSettings.globalize_path(OUTPUT_DIRECTORY)
	)
	var rendered := 0
	for card_id in CARD_IDS:
		var source_path := SOURCE_DIRECTORY.path_join(
			"card_skill_%s.svg" % card_id
		)
		var output_path := OUTPUT_DIRECTORY.path_join(
			"card_skill_%s.png" % card_id
		)
		var texture := load(source_path) as Texture2D
		if texture == null:
			printerr("V042_CARD_RENDER_FAIL: %s" % source_path)
			quit(1)
			return
		var image := texture.get_image()
		if image == null or image.is_empty():
			printerr("V042_CARD_RENDER_FAIL image=%s" % source_path)
			quit(1)
			return
		var error := image.save_png(ProjectSettings.globalize_path(output_path))
		if error != OK:
			printerr("V042_CARD_RENDER_FAIL: %s error=%d" % [output_path, error])
			quit(1)
			return
		rendered += 1
		print("V042_CARD_RENDER_OK: %s" % output_path)
	print("V042_GAP_ART_RENDER_OK assets=%d" % rendered)
	quit(0)
