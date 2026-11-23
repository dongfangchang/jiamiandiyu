extends SceneTree

## Prop ingest: RGB art on a flat studio backdrop -> RGBA cutouts for UI/3D.
##
## Driven entirely by `props.manifest.json`, so adding art is a manifest row +
## a file drop + one run of this tool. No code change.
##
##   "$GODOT" --headless --path . --script art/tools/key_props.gd
##
## Keying is a BORDER FLOOD FILL, not a luma threshold: these props contain
## genuinely dark pixels (the wax seal's shadowed red, the tokens' black
## inlay) that a global threshold would punch holes through. The backdrop is
## the region connected to the image border, so that is what we remove.

const MANIFEST := "res://art/assets/raster/v0.85.0/props/props.manifest.json"


func _init() -> void:
	var ok := _run()
	quit(0 if ok else 1)


func _run() -> bool:
	var f := FileAccess.open(MANIFEST, FileAccess.READ)
	if f == null:
		printerr("KEY_PROPS_FAIL cannot open manifest")
		return false
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	if not parsed is Dictionary:
		printerr("KEY_PROPS_FAIL manifest is not an object")
		return false
	var man: Dictionary = parsed
	var src_dir := String(man.get("source_dir", ""))
	var out_dir := String(man.get("output_dir", ""))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out_dir))

	var done := 0
	var failed: Array[String] = []
	for entry_value in man.get("props", []):
		if not entry_value is Dictionary:
			continue
		var entry: Dictionary = entry_value
		var id := String(entry.get("id", "?"))
		var src_path := "%s/%s" % [src_dir, String(entry.get("src", ""))]
		var out_path := "%s/%s" % [out_dir, String(entry.get("out", ""))]
		var img := Image.load_from_file(ProjectSettings.globalize_path(src_path))
		if img == null:
			failed.append("%s (load)" % id)
			continue
		img.convert(Image.FORMAT_RGBA8)

		var mode := String(entry.get("key", "none"))
		if mode != "none":
			_flood_key(
				img,
				mode == "flood_light",
				float(entry.get("tolerance", 0.18)),
				int(entry.get("feather", 2))
			)
			if bool(entry.get("trim", false)):
				img = _trim(img, int(entry.get("pad", 4)))

		var err := img.save_png(ProjectSettings.globalize_path(out_path))
		if err != OK:
			failed.append("%s (save %s)" % [id, str(err)])
			continue

		## Extra copies for call sites that hardcode a path.
		for extra_value in entry.get("also_out", []):
			var extra := String(extra_value)
			DirAccess.make_dir_recursive_absolute(
				ProjectSettings.globalize_path(extra.get_base_dir())
			)
			if img.save_png(ProjectSettings.globalize_path(extra)) != OK:
				failed.append("%s (also_out %s)" % [id, extra])

		## Derived tints, so one painted source covers several states.
		for variant_value in entry.get("variants", []):
			if not variant_value is Dictionary:
				continue
			var variant: Dictionary = variant_value
			var v_out := String(variant.get("out", ""))
			if v_out.is_empty():
				continue
			var copy := Image.create_from_data(
				img.get_width(), img.get_height(), false,
				Image.FORMAT_RGBA8, img.get_data()
			)
			_tint(
				copy,
				variant.get("tint", [1.0, 1.0, 1.0]),
				float(variant.get("desaturate", 0.0))
			)
			DirAccess.make_dir_recursive_absolute(
				ProjectSettings.globalize_path(v_out.get_base_dir())
			)
			if copy.save_png(ProjectSettings.globalize_path(v_out)) != OK:
				failed.append("%s (variant %s)" % [id, v_out])
			else:
				print("    variant -> %s" % v_out)

		done += 1
		print("  %-18s %4dx%-4d -> %s" % [id, img.get_width(), img.get_height(), out_path])

	if not failed.is_empty():
		printerr("KEY_PROPS_FAIL %s" % str(failed))
		return false
	print("KEY_PROPS_OK count=%d" % done)
	return true


func _flood_key(img: Image, light_bg: bool, tolerance: float, feather: int) -> void:
	## Sample the backdrop from the border, then clear everything connected to
	## the border within tolerance. Interior darks/lights stay opaque.
	var w := img.get_width()
	var h := img.get_height()
	var bg := _sample_border(img, light_bg)

	var visited := PackedByteArray()
	visited.resize(w * h)
	var queue := PackedInt32Array()
	for x in range(w):
		queue.append(x)
		queue.append(0)
		queue.append(x)
		queue.append(h - 1)
	for y in range(h):
		queue.append(0)
		queue.append(y)
		queue.append(w - 1)
		queue.append(y)

	var head := 0
	while head < queue.size():
		var x := queue[head]
		var y := queue[head + 1]
		head += 2
		if x < 0 or y < 0 or x >= w or y >= h:
			continue
		var idx := y * w + x
		if visited[idx] != 0:
			continue
		visited[idx] = 1
		var c := img.get_pixel(x, y)
		if _dist(c, bg) > tolerance:
			continue
		img.set_pixel(x, y, Color(c.r, c.g, c.b, 0.0))
		queue.append(x + 1); queue.append(y)
		queue.append(x - 1); queue.append(y)
		queue.append(x); queue.append(y + 1)
		queue.append(x); queue.append(y - 1)

	if feather > 0:
		_feather(img, feather)


func _sample_border(img: Image, light_bg: bool) -> Color:
	## Median-ish backdrop colour: take the most extreme border samples so a
	## vignetted backdrop still keys cleanly.
	var w := img.get_width()
	var h := img.get_height()
	var best := img.get_pixel(0, 0)
	var best_l := _luma(best)
	for i in range(0, w, maxi(1, w / 64)):
		for pt in [Vector2i(i, 0), Vector2i(i, h - 1)]:
			var c := img.get_pixel(pt.x, pt.y)
			var l := _luma(c)
			if (light_bg and l > best_l) or (not light_bg and l < best_l):
				best = c
				best_l = l
	for i in range(0, h, maxi(1, h / 64)):
		for pt in [Vector2i(0, i), Vector2i(w - 1, i)]:
			var c := img.get_pixel(pt.x, pt.y)
			var l := _luma(c)
			if (light_bg and l > best_l) or (not light_bg and l < best_l):
				best = c
				best_l = l
	return best


func _feather(img: Image, radius: int) -> void:
	## Soften the cut edge: any opaque pixel touching transparency gets partial
	## alpha, so the cutout does not read as a jagged sticker.
	var w := img.get_width()
	var h := img.get_height()
	var edge: Array[Vector2i] = []
	for y in range(h):
		for x in range(w):
			if img.get_pixel(x, y).a <= 0.0:
				continue
			var near := false
			var neighbours: Array[Vector2i] = [
				Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)
			]
			for d in neighbours:
				var nx: int = x + d.x
				var ny: int = y + d.y
				if nx < 0 or ny < 0 or nx >= w or ny >= h:
					continue
				if img.get_pixel(nx, ny).a <= 0.0:
					near = true
					break
			if near:
				edge.append(Vector2i(x, y))
	for step in range(radius):
		var a := 0.35 + 0.3 * float(step)
		for p in edge:
			var c := img.get_pixel(p.x, p.y)
			img.set_pixel(p.x, p.y, Color(c.r, c.g, c.b, minf(c.a, a)))


func _tint(img: Image, tint: Variant, desaturate: float) -> void:
	## Preserves alpha; only recolours. Used for state variants of one prop.
	var t := Color(1.0, 1.0, 1.0)
	if tint is Array and (tint as Array).size() >= 3:
		var arr: Array = tint
		t = Color(float(arr[0]), float(arr[1]), float(arr[2]))
	for y in range(img.get_height()):
		for x in range(img.get_width()):
			var c := img.get_pixel(x, y)
			if c.a <= 0.0:
				continue
			var r := c.r
			var g := c.g
			var b := c.b
			if desaturate > 0.0:
				var l := _luma(c)
				r = lerpf(r, l, desaturate)
				g = lerpf(g, l, desaturate)
				b = lerpf(b, l, desaturate)
			img.set_pixel(x, y, Color(r * t.r, g * t.g, b * t.b, c.a))


func _trim(img: Image, pad: int) -> Image:
	var used := img.get_used_rect()
	if used.size.x <= 0 or used.size.y <= 0:
		return img
	used = used.grow(pad)
	used = used.intersection(Rect2i(Vector2i.ZERO, img.get_size()))
	return img.get_region(used)


func _dist(a: Color, b: Color) -> float:
	## MAX channel difference, not the mean. A dark red wax seal against a
	## charcoal backdrop differs strongly in red but barely in green/blue; the
	## mean diluted that under threshold and the flood ate the subject.
	return maxf(absf(a.r - b.r), maxf(absf(a.g - b.g), absf(a.b - b.b)))


func _luma(c: Color) -> float:
	return 0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b
