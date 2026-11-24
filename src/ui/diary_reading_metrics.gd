extends RefCounted

## Read-only EXPERIENCE §5.1 measurements of the desk diary, taken by
## projecting the current right leaf through the real desk camera. Kept out of
## diary_desk_stage.gd so the stage stays about building and turning pages.

const PagePair := preload("res://src/ui/diary_page_pair.gd")

## Right-leaf points (page UV) where the readable text sits.
const TEXT_SAMPLE_UVS: Array[Vector2] = [
	Vector2(0.15, 0.1), Vector2(0.45, 0.1), Vector2(0.75, 0.1),
	Vector2(0.15, 0.4), Vector2(0.45, 0.4), Vector2(0.75, 0.4),
	Vector2(0.15, 0.7), Vector2(0.45, 0.7), Vector2(0.75, 0.7),
]
## Book cover half extents (book-local), for the framing fraction.
const BOOK_HALF := Vector3(0.745, -0.07, 0.497)

var _cam: Camera3D
var _leaf: MeshInstance3D
var _book: Node3D
var _uv_to_world: Callable
var _cam_px: Vector2
var _screen: Vector2


func _init(
	cam: Camera3D, leaf: MeshInstance3D, book: Node3D, uv_to_world: Callable,
	cam_px: Vector2, screen_size: Vector2
) -> void:
	_cam = cam
	_leaf = leaf
	_book = book
	_uv_to_world = uv_to_world
	_cam_px = cam_px
	_screen = screen_size


func measure(pair: PagePair) -> Dictionary:
	var sizes: Dictionary = pair.font_sizes()
	var colors: Dictionary = pair.text_colors()
	var per_px := page_px_on_screen()
	var out := {
		"page_viewport": PagePair.PAGE_VP_SIZE,
		"page_font_px": sizes,
		"screen_px_per_page_px": per_px,
		"reading_angle_deg": reading_angle_deg(),
		"book_width_frac": book_width_fraction(),
	}
	for key in ["title", "body", "caption"]:
		out["screen_%s_px" % key] = float(sizes[key]) * per_px
		out["contrast_%s" % key] = PagePair.contrast_ratio(colors[key], PagePair.PAPER_TONE)
	return out


func _screen_point(world: Vector3) -> Vector2:
	## Camera pixels -> stage Control units (1600x900 logical).
	return _cam.unproject_position(world) / _cam_px * _screen


func page_px_on_screen() -> float:
	## Smallest on-screen length of one page pixel over the text samples,
	## taking the worse of the horizontal and (foreshortened) vertical axes.
	var step := 16.0
	var du := Vector2(step / PagePair.PAGE_VP_SIZE.x, 0.0)
	var dv := Vector2(0.0, step / PagePair.PAGE_VP_SIZE.y)
	var worst := INF
	for uv in TEXT_SAMPLE_UVS:
		var p := _screen_point(_uv_to_world.call(_leaf, uv))
		var sx := p.distance_to(_screen_point(_uv_to_world.call(_leaf, uv + du)))
		var sy := p.distance_to(_screen_point(_uv_to_world.call(_leaf, uv + dv)))
		worst = minf(worst, minf(sx, sy) / step)
	return worst


func reading_angle_deg() -> float:
	## Largest angle between the leaf surface normal and the line of sight
	## over the text samples (0 = face-on). The normal comes from the actual
	## (arched) surface by finite differences.
	var worst := 0.0
	var e := 0.01
	for uv in TEXT_SAMPLE_UVS:
		var p: Vector3 = _uv_to_world.call(_leaf, uv)
		var tu: Vector3 = _uv_to_world.call(_leaf, uv + Vector2(e, 0.0)) - p
		var tv: Vector3 = _uv_to_world.call(_leaf, uv + Vector2(0.0, e)) - p
		var normal := tv.cross(tu).normalized()
		var to_eye := (_cam.global_position - p).normalized()
		worst = maxf(worst, rad_to_deg(acos(clampf(absf(normal.dot(to_eye)), 0.0, 1.0))))
	return worst


func book_width_fraction() -> float:
	var xs: Array[float] = []
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			var corner := _book.global_transform * Vector3(BOOK_HALF.x * sx, BOOK_HALF.y, BOOK_HALF.z * sz)
			xs.append(_screen_point(corner).x)
	return (xs.max() - xs.min()) / maxf(1.0, _screen.x)
