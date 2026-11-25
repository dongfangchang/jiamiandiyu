extends RefCounted

## Headless-safe page occlusion probe (AR-07 / EXPERIENCE §5.1).
## Casts camera → page sample segments against other visible MeshInstance3D
## AABBs in DeskWorld. Book-root meshes are allowed; anything else that
## intersects the open segment counts as an occluder (e.g. a leaned RoomBack).

## Sample UVs on each leaf: four corners + title / body / wax regions.
const SAMPLE_UVS: Array[Dictionary] = [
	{"id": "corner_tl", "uv": Vector2(0.06, 0.06)},
	{"id": "corner_tr", "uv": Vector2(0.94, 0.06)},
	{"id": "corner_bl", "uv": Vector2(0.06, 0.94)},
	{"id": "corner_br", "uv": Vector2(0.94, 0.94)},
	{"id": "title", "uv": Vector2(0.50, 0.10)},
	{"id": "body", "uv": Vector2(0.50, 0.42)},
	{"id": "wax", "uv": Vector2(0.50, 0.78)},
]

## Stop short of the leaf so coplanar page AABBs never count as hits.
const END_EPSILON := 0.012


var _cam: Camera3D
var _desk_world: Node3D
var _book_root: Node3D
var _left_page: MeshInstance3D
var _right_page: MeshInstance3D
var _uv_to_world: Callable


func _init(
	cam: Camera3D,
	desk_world: Node3D,
	book_root: Node3D,
	left_page: MeshInstance3D,
	right_page: MeshInstance3D,
	uv_to_world: Callable
) -> void:
	_cam = cam
	_desk_world = desk_world
	_book_root = book_root
	_left_page = left_page
	_right_page = right_page
	_uv_to_world = uv_to_world


func report() -> Dictionary:
	var hits: Array[Dictionary] = []
	var candidates := _collect_candidate_meshes()
	var eye := _cam.global_position
	for side in [
		{"name": "left", "mesh": _left_page, "is_left": true},
		{"name": "right", "mesh": _right_page, "is_left": false},
	]:
		var mesh: MeshInstance3D = side["mesh"]
		if not is_instance_valid(mesh):
			continue
		for sample in SAMPLE_UVS:
			var uv: Vector2 = sample["uv"]
			var world: Vector3 = _uv_to_world.call(bool(side["is_left"]), uv)
			var end := eye.lerp(world, 1.0 - END_EPSILON)
			for other in candidates:
				if other == mesh:
					continue
				if _is_under_book(other):
					continue
				var aabb := _world_aabb(other)
				if aabb.size.length() < 1e-6:
					continue
				if _segment_hits_aabb(eye, end, aabb):
					hits.append({
						"side": String(side["name"]),
						"sample": String(sample["id"]),
						"uv": uv,
						"occluder": String(other.name),
						"occluder_path": String(other.get_path()),
					})
	var backplate := _find_backplate()
	return {
		"clear": hits.is_empty(),
		"hit_count": hits.size(),
		"hits": hits,
		"sample_count": SAMPLE_UVS.size() * 2,
		"candidate_mesh_count": candidates.size(),
		"quality_backplate_present": backplate != null,
		"quality_backplate_named": backplate.name if backplate != null else "",
	}


func _collect_candidate_meshes() -> Array[MeshInstance3D]:
	var out: Array[MeshInstance3D] = []
	if not is_instance_valid(_desk_world):
		return out
	_walk_meshes(_desk_world, out)
	return out


func _walk_meshes(node: Node, out: Array[MeshInstance3D]) -> void:
	if node is MeshInstance3D:
		var mi := node as MeshInstance3D
		if mi.visible and mi.mesh != null:
			out.append(mi)
	for child in node.get_children():
		_walk_meshes(child, out)


func _is_under_book(mi: MeshInstance3D) -> bool:
	if not is_instance_valid(_book_root):
		return false
	var n: Node = mi
	while n != null:
		if n == _book_root:
			return true
		n = n.get_parent()
	return false


func _find_backplate() -> MeshInstance3D:
	if not is_instance_valid(_desk_world):
		return null
	var named := _desk_world.find_child("RoomBackplate", true, false) as MeshInstance3D
	if named != null:
		return named
	return _desk_world.find_child("RoomBack", true, false) as MeshInstance3D


static func _world_aabb(mi: MeshInstance3D) -> AABB:
	return mi.global_transform * mi.get_aabb()


static func _segment_hits_aabb(from: Vector3, to: Vector3, aabb: AABB) -> bool:
	## Slab test on the closed segment [from, to].
	var dir := to - from
	var length := dir.length()
	if length < 1e-8:
		return aabb.has_point(from)
	dir /= length
	var tmin := 0.0
	var tmax := length
	for axis in range(3):
		var origin := from[axis]
		var d := dir[axis]
		var min_b := aabb.position[axis]
		var max_b := aabb.end[axis]
		if absf(d) < 1e-8:
			if origin < min_b or origin > max_b:
				return false
			continue
		var inv_d := 1.0 / d
		var t1 := (min_b - origin) * inv_d
		var t2 := (max_b - origin) * inv_d
		if t1 > t2:
			var tmp := t1
			t1 = t2
			t2 = tmp
		tmin = maxf(tmin, t1)
		tmax = minf(tmax, t2)
		if tmin > tmax:
			return false
	return true
