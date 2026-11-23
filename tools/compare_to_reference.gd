extends SceneTree
## Quantify reference vs current render, so "still too far off" becomes numbers
## instead of taste. Run after a capture:
##
##   "$GODOT" --path . res://tests/ui/v084_diary_desk_capture_runner.tscn
##   "$GODOT" --headless --path . --script tools/compare_to_reference.gd
##
## What the numbers mean:
##   亮度        overall exposure. The reference is a dim candlelit photo (0.237).
##   中间调占比   share of pixels in bins 5-10. A photo fills these; a CG render
##               with crushed blacks and a bright subject leaves a hole.
##   细节        mean neighbour luma delta — grain and material micro-contrast.
##   直方图      16 luma buckets. The reference has NOTHING above bucket 11:
##               if our top buckets are populated, something is blown out.
const REF := "res://art/assets/raster/v0.85.0/reference/样板.jpg"
const CUR := "res://.tools/ui-captures/v084_desk_idle.png"

func _init() -> void:
	var a := Image.load_from_file(ProjectSettings.globalize_path(REF))
	var b := Image.load_from_file(ProjectSettings.globalize_path(CUR))
	if a == null or b == null:
		print("CMP_FAIL ref=%s cur=%s" % [str(a != null), str(b != null)])
		quit(1); return
	_report("参考样板", a)
	_report("现网渲染", b)
	quit(0)

func _report(label: String, img: Image) -> void:
	img.convert(Image.FORMAT_RGBA8)
	var w := img.get_width()
	var h := img.get_height()
	var hist := PackedInt32Array(); hist.resize(16)
	var sum := 0.0
	var sat := 0.0
	var warm := 0.0
	var detail := 0.0
	var n := 0
	var dn := 0
	for y in range(0, h, 3):
		for x in range(0, w, 3):
			var c := img.get_pixel(x, y)
			var l := 0.2126*c.r + 0.7152*c.g + 0.0722*c.b
			sum += l; n += 1
			hist[clampi(int(l*16.0), 0, 15)] += 1
			sat += maxf(c.r, maxf(c.g, c.b)) - minf(c.r, minf(c.g, c.b))
			warm += c.r - c.b
			if x + 3 < w:
				var c2 := img.get_pixel(x+3, y)
				detail += absf(l - (0.2126*c2.r + 0.7152*c2.g + 0.0722*c2.b))
				dn += 1
	var mean := sum / float(n)
	var vs := 0.0
	for y in range(0, h, 3):
		for x in range(0, w, 3):
			var c := img.get_pixel(x, y)
			var l := 0.2126*c.r + 0.7152*c.g + 0.0722*c.b
			vs += (l-mean)*(l-mean)
	## Mid-tone occupancy: bins 5..10. A photo fills these; a CG render with
	## crushed blacks and a bright subject leaves them empty.
	var mid := 0
	for i in range(5, 11):
		mid += hist[i]
	print("%s %dx%d" % [label, w, h])
	print("  亮度=%.3f 标准差=%.3f 饱和=%.3f 暖偏=%.3f 细节=%.4f 中间调占比=%.1f%%" % [
		mean, sqrt(vs/float(n)), sat/float(n), warm/float(n),
		detail/float(dn), 100.0*float(mid)/float(n)])
	var s := "  直方图:"
	for i in range(16):
		s += " %d" % int(100.0*float(hist[i])/float(n))
	print(s)
