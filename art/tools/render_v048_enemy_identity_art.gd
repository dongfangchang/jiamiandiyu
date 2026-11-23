extends SceneTree

const ENEMY_SOURCE := "res://art/assets/svg/v0.48.0/enemies"
const ENEMY_OUTPUT := "res://assets/game/v0.48.0/enemies"
const IDENTITY_SOURCE := "res://art/assets/svg/v0.48.0/identities"
const IDENTITY_OUTPUT := "res://assets/game/v0.48.0/identities"

const ENEMY_FILES := [
	"enemy-candle-moth",
	"enemy-tingen-kidnapper",
	"enemy-mirror-hound",
	"enemy-mirror-hound-echo",
	"enemy-weeping-tenant",
	"enemy-tingen-knight-wraith",
	"enemy-tingen-rampager",
	"enemy-mirror-baron",
	"enemy-tingen-megose",
]

const IDENTITY_FILES := [
	"card-identity-reporter",
	"card-identity-doctor",
	"card-identity-gravedigger",
]


func _init() -> void:
	if not _render_batch(ENEMY_SOURCE, ENEMY_OUTPUT, ENEMY_FILES, "enemy"):
		return
	if not _render_batch(IDENTITY_SOURCE, IDENTITY_OUTPUT, IDENTITY_FILES, "identity"):
		return
	print(
		"V048_ART_RENDER_OK enemies=%d identities=%d"
		% [ENEMY_FILES.size(), IDENTITY_FILES.size()]
	)
	quit(0)


func _render_batch(
	source_dir: String, output_dir: String, stems: Array, kind: String
) -> bool:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output_dir))
	for stem in stems:
		var source_path := source_dir.path_join("%s.svg" % stem)
		var output_path := output_dir.path_join("%s.png" % stem)
		var texture := load(source_path) as Texture2D
		if texture == null:
			printerr("V048_ART_RENDER_FAIL: %s" % source_path)
			quit(1)
			return false
		var image := texture.get_image()
		if image == null or image.is_empty():
			printerr("V048_ART_RENDER_FAIL image=%s" % source_path)
			quit(1)
			return false
		var error := image.save_png(ProjectSettings.globalize_path(output_path))
		if error != OK:
			printerr("V048_ART_RENDER_FAIL: %s error=%d" % [output_path, error])
			quit(1)
			return false
		print("V048_ART_RENDER_OK: %s (%s)" % [output_path, kind])
	return true
