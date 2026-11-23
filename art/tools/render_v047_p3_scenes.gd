extends SceneTree

const SOURCE_DIRECTORY := "res://art/assets/svg/v0.47.0/scenes"
const OUTPUT_DIRECTORY := "res://assets/game/v0.47.0/scenes"
const SCENE_FILES := [
	"title-mask-desk",
	"hub-route-map",
	"hub-deck-archive",
	"hub-gacha-altar",
]


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(
		ProjectSettings.globalize_path(OUTPUT_DIRECTORY)
	)
	var rendered := 0
	for stem in SCENE_FILES:
		var source_path := SOURCE_DIRECTORY.path_join("%s.svg" % stem)
		var output_path := OUTPUT_DIRECTORY.path_join("%s.png" % stem)
		var texture := load(source_path) as Texture2D
		if texture == null:
			printerr("V047_SCENE_RENDER_FAIL: %s" % source_path)
			quit(1)
			return
		var image := texture.get_image()
		if image == null or image.is_empty():
			printerr("V047_SCENE_RENDER_FAIL image=%s" % source_path)
			quit(1)
			return
		var error := image.save_png(ProjectSettings.globalize_path(output_path))
		if error != OK:
			printerr("V047_SCENE_RENDER_FAIL: %s error=%d" % [output_path, error])
			quit(1)
			return
		rendered += 1
		print("V047_SCENE_RENDER_OK: %s" % output_path)
	print("V047_P3_SCENE_RENDER_OK assets=%d" % rendered)
	quit(0)
