extends SceneTree

## Renders v0.41 clown card SVGs into assets/game/v0.41.0/cards/*.png

const SOURCE_DIRECTORY := "res://art/assets/svg/v0.41.0/cards"
const OUTPUT_DIRECTORY := "res://assets/game/v0.41.0/cards"
const CARD_IDS := [
	"veil_step",
	"severed_fate",
	"paper_swarm",
	"mirror_shard",
	"last_witness",
	"false_death",
	"sealed_answer",
	"hollow_bell",
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
			printerr("V041_CARD_RENDER_FAIL: %s" % source_path)
			quit(1)
			return
		var image := texture.get_image()
		if image == null or image.is_empty():
			printerr("V041_CARD_RENDER_FAIL image=%s" % source_path)
			quit(1)
			return
		var error := image.save_png(ProjectSettings.globalize_path(output_path))
		if error != OK:
			printerr("V041_CARD_RENDER_FAIL: %s error=%d" % [
				output_path,
				error,
			])
			quit(1)
			return
		rendered += 1
		print("V041_CARD_RENDER_OK: %s" % output_path)
	print("V041_CLOWN_ART_RENDER_OK assets=%d" % rendered)
	quit(0)
