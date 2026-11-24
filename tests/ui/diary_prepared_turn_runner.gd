extends Node

const UiContentFixture := preload("res://tests/ui/ui_content_fixture.gd")

## Diary turn must be prepared, not loaded: with neighbours supplied, a
## committed turn lands on a pair that was already filled and rendered, the
## commit itself does no blocking texture load, and the same three page pairs
## (instance ids) are reused instead of rebuilt. Also checks the turning leaf
## binds front = current right, back = next left, beneath = next right.

const DeskStage := preload("res://src/ui/diary_desk_stage.gd")
const SceneCatalog := preload("res://src/ui/scene_ui_catalog.gd")
const DiaryCatalog := preload("res://src/ui/diary_ui_catalog.gd")
const TableSfx := preload("res://src/ui/table_sfx.gd")

var _checks := 0
var _failures: Array[String] = []
var _committed: Array[int] = []
var _finished := 0
var _spreads: Array = []
var _idx := 0
var _desk: Control


func _ready() -> void:
	UiContentFixture.ensure()
	TableSfx.set_muted(true)
	_spreads = _make_spreads()
	_expect(_spreads.size() >= 4, "need at least 4 illustrated spreads (%d)" % _spreads.size())
	if _spreads.size() < 4:
		_finish()
		return
	var host := SubViewport.new()
	host.size = Vector2i(1280, 720)
	add_child(host)
	_desk = DeskStage.new()
	host.add_child(_desk)
	_desk.flip_committed.connect(_on_committed)
	_desk.flip_visual_finished.connect(func() -> void: _finished += 1)

	_idx = 1
	_desk.apply_spread_list(_spreads, _idx)
	await _wait_ring_ready()
	var ring: Dictionary = _desk.get_ring_state()
	var ids_before: Array = ring["pair_ids"]
	_expect(ring["current_key"] == 1 and ring["prev_key"] == 0 and ring["next_key"] == 2, "ring holds prev/current/next (%s)" % str(ring))
	_expect(_desk.is_ring_ready(), "neighbour art arrives off-thread")
	var stats_before: Dictionary = _desk.get_art_load_stats()
	_expect(int(stats_before["threaded_requests"]) >= 1, "neighbour art requested with load_threaded_request")
	var scene_art := _desk.find_child("SceneArt", true, false) as TextureRect
	_expect(scene_art != null and scene_art.texture != null and scene_art.texture.resource_path == _spreads[1]["left_art_path"], "probe finds the current leaf's art")

	## Forward turn.
	var next_id: int = ring["next_id"]
	var cur_id: int = ring["current_id"]
	_expect(_desk.play_flip(1), "forward turn starts")
	await get_tree().process_frame
	var b: Dictionary = _desk.get_page_bindings()
	_expect(b["right"] == _desk.pair_side_id(cur_id, "right"), "leaf front = current right")
	_expect(b["right_back"] == _desk.pair_side_id(next_id, "left"), "leaf back = next left")
	_expect(b["right_under"] == _desk.pair_side_id(next_id, "right") and b["right_under_visible"], "beneath = next right")
	_expect(b["left"] == _desk.pair_side_id(cur_id, "left"), "static left = current left until landing")
	await _wait_finished(1)
	ring = _desk.get_ring_state()
	var stats_after: Dictionary = _desk.get_art_load_stats()
	_expect(_committed == [1], "one commit (%s)" % str(_committed))
	_expect(ring["current_id"] == next_id, "prepared next pair became current (no rebuild)")
	_expect(ring["current_key"] == 2, "current is leaf 2")
	_expect(_same_ids(ring["pair_ids"], ids_before), "the same three pairs are reused")
	_expect(int(stats_after["blocking_loads"]) == int(stats_before["blocking_loads"]), "no blocking texture load on commit (%s -> %s)" % [str(stats_before), str(stats_after)])
	b = _desk.get_page_bindings()
	_expect(b["left"] == _desk.pair_side_id(next_id, "left") and b["right"] == _desk.pair_side_id(next_id, "right"), "landed spread shows the new pair on both leaves")
	_expect(not b["right_under_visible"] and not b["left_under_visible"], "nothing beneath at rest")
	scene_art = _desk.find_child("SceneArt", true, false) as TextureRect
	_expect(scene_art.texture.resource_path == _spreads[2]["left_art_path"], "probe follows the new current leaf")

	## Backward turn after neighbours refresh.
	await _wait_ring_ready()
	ring = _desk.get_ring_state()
	_expect(ring["prev_key"] == 1 and ring["next_key"] == 3, "ring re-prepared around leaf 2 (%s)" % str(ring))
	var prev_id: int = ring["prev_id"]
	cur_id = ring["current_id"]
	stats_before = _desk.get_art_load_stats()
	_expect(_desk.play_flip(-1), "backward turn starts")
	await get_tree().process_frame
	b = _desk.get_page_bindings()
	_expect(b["left"] == _desk.pair_side_id(cur_id, "left"), "backward leaf front = current left")
	_expect(b["left_back"] == _desk.pair_side_id(prev_id, "right"), "backward leaf back = prev right")
	_expect(b["left_under"] == _desk.pair_side_id(prev_id, "left") and b["left_under_visible"], "beneath = prev left")
	await _wait_finished(2)
	ring = _desk.get_ring_state()
	_expect(ring["current_id"] == prev_id and ring["current_key"] == 1, "prepared prev pair became current")
	_expect(_same_ids(ring["pair_ids"], ids_before), "still the same three pairs")
	_expect(int(_desk.get_art_load_stats()["blocking_loads"]) == int(stats_before["blocking_loads"]), "no blocking load on backward commit")

	## Legacy caller (no neighbours): still turns and lands on the new leaf.
	var cold := DeskStage.new()
	host.add_child(cold)
	cold.apply_spread(_spreads[0])
	cold.flip_committed.connect(func(_d: int) -> void: cold.apply_spread(_spreads[1]))
	var cold_done := [false]
	cold.flip_visual_finished.connect(func() -> void: cold_done[0] = true)
	_expect(cold.play_flip(1), "cold turn starts")
	var frames := 0
	while not cold_done[0] and frames < 240:
		await get_tree().process_frame
		frames += 1
	_expect(cold.get_ring_state()["current_key"] == 1, "cold turn lands on the applied leaf")

	_finish()


func _on_committed(delta: int) -> void:
	## Mirrors diary_chapter_screen: apply the new leaf at the peak, then the
	## neighbours (its one-line apply_spread_list call).
	_committed.append(delta)
	_idx += delta
	_desk.apply_spread_list(_spreads, _idx)


func _wait_ring_ready() -> void:
	var frames := 0
	while not _desk.is_ring_ready() and frames < 600:
		await get_tree().process_frame
		frames += 1


func _wait_finished(count: int) -> void:
	var frames := 0
	while _finished < count and frames < 240:
		await get_tree().process_frame
		frames += 1


func _same_ids(a: Array, b: Array) -> bool:
	var x := a.duplicate()
	var y := b.duplicate()
	x.sort()
	y.sort()
	return x == y


func _make_spreads() -> Array:
	var out: Array = []
	for scene_id in SceneCatalog.diary_scene_ids():
		var path := SceneCatalog.diary_path_for(String(scene_id))
		if path.is_empty() or not ResourceLoader.exists(path):
			continue
		var i := out.size()
		out.append({
			"spread_index": i,
			"page_index": i,
			"title_zh": "第 %d 叶" % (i + 1),
			"ink_zh": "测试墨迹 %d" % i,
			"left_art_path": path,
			"state": DiaryCatalog.STATE_COMPLETED,
			"clues": [{"node_id": "test.node.%d" % i, "state": DiaryCatalog.STATE_COMPLETED}],
		})
		if out.size() >= 5:
			break
	return out


func _finish() -> void:
	if _failures.is_empty():
		print("DIARY_PREPARED_TURN_OK checks=%d" % _checks)
		get_tree().quit(0)
		return
	for failure in _failures:
		printerr("DIARY_PREPARED_TURN_FAIL: %s" % failure)
	print("DIARY_PREPARED_TURN_FAIL checks=%d" % _checks)
	get_tree().quit(1)


func _expect(cond: bool, label: String) -> void:
	_checks += 1
	if not cond:
		_failures.append(label)
