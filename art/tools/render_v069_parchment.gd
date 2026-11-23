extends SceneTree

## Rasterize formal parchment SVG → UI PNG.

func _init() -> void:
	## Art source lives under art/; coordinator migrates SVG into assets then rasterizes.
	var source_path := "res://assets/ui/diary/parchment_grain.svg"
	var output_path := "res://assets/ui/diary/parchment_grain.png"
	var texture := load(source_path) as Texture2D
	if texture == null:
		printerr("V069_PARCHMENT_RENDER_FAIL: source texture unavailable")
		quit(1)
		return
	var image := texture.get_image()
	if image == null or image.is_empty():
		printerr("V069_PARCHMENT_RENDER_FAIL: source image unavailable")
		quit(1)
		return
	## Ensure target resolution for formal plate.
	if image.get_width() != 1024 or image.get_height() != 1536:
		image.resize(1024, 1536, Image.INTERPOLATE_LANCZOS)
	var abs_out := ProjectSettings.globalize_path(output_path)
	var error := image.save_png(abs_out)
	if error != OK:
		printerr("V069_PARCHMENT_RENDER_FAIL: save error=%d" % error)
		quit(1)
		return
	print("V069_PARCHMENT_RENDER_OK: %s" % output_path)
	quit(0)
