extends SceneTree


func _init() -> void:
	var source_path := "res://art/assets/svg/scenes/title-screen.svg"
	var output_path := "res://assets/game/scenes/title-screen.png"
	var texture := load(source_path) as Texture2D
	if texture == null:
		printerr("TITLE_RENDER_FAIL: source texture unavailable")
		quit(1)
		return
	var image := texture.get_image()
	if image == null or image.is_empty():
		printerr("TITLE_RENDER_FAIL: source image unavailable")
		quit(1)
		return
	var error := image.save_png(ProjectSettings.globalize_path(output_path))
	if error != OK:
		printerr("TITLE_RENDER_FAIL: save error=%d" % error)
		quit(1)
		return
	print("TITLE_RENDER_OK: %s" % output_path)
	quit(0)
