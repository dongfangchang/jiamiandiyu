extends SceneTree

const SOURCE_DIRECTORY := "res://art/assets/svg/v0.13.0/cards"
const OUTPUT_DIRECTORY := "res://assets/game/v0.13.0/cards"
const CARD_IDS := [
	"dream_question",
	"mirror_ward",
	"severed_string",
	"last_rites",
]


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(
		ProjectSettings.globalize_path(OUTPUT_DIRECTORY)
	)
	for card_id in CARD_IDS:
		var source_path := SOURCE_DIRECTORY.path_join(
			"card_skill_%s.svg" % card_id
		)
		var output_path := OUTPUT_DIRECTORY.path_join(
			"card_skill_%s.png" % card_id
		)
		var texture := load(source_path) as Texture2D
		if texture == null:
			printerr("V013_CARD_RENDER_FAIL: %s" % source_path)
			quit(1)
			return
		var image := texture.get_image()
		var error := image.save_png(ProjectSettings.globalize_path(output_path))
		if error != OK:
			printerr("V013_CARD_RENDER_FAIL: %s error=%d" % [
				output_path,
				error,
			])
			quit(1)
			return
		print("V013_CARD_RENDER_OK: %s" % output_path)
	quit(0)
