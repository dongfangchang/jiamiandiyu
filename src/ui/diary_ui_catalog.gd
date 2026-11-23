extends RefCounted

## UI-side diary volume → Spread list (FileAccess stays out of gameplay).
## v0.84 P0: one main clue → one spread (cross-page level).

const DIARY_PATH := "res://data/diaries/v0.55.0/tingen_volume_1.json"
const SceneCatalog := preload("res://src/ui/scene_ui_catalog.gd")

## Clue visual states matching the flip subsystem contract.
const STATE_LOCKED := 0
const STATE_AVAILABLE := 1
const STATE_COMPLETED := 2

const TITLE_MAX := 10
const INK_MAX := 60

var _volume: Dictionary = {}
var _pages: Array = []
var _loaded := false


func ensure_loaded() -> bool:
	if _loaded:
		return not _pages.is_empty()
	_loaded = true
	if not FileAccess.file_exists(DIARY_PATH):
		return false
	var file := FileAccess.open(DIARY_PATH, FileAccess.READ)
	if file == null:
		return false
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return false
	_volume = parsed
	_pages = _volume.get("pages", [])
	if not _pages is Array:
		_pages = []
	return not _pages.is_empty()


func build_view(route_data: Dictionary) -> Dictionary:
	ensure_loaded()
	var completed: Array = route_data.get("completed_node_ids", [])
	var unlocked: Array = route_data.get("unlocked_node_ids", [])
	if unlocked.is_empty():
		var available_id := String(route_data.get("available_node_id", ""))
		if not available_id.is_empty():
			unlocked = [available_id]
		for node_id_value in completed:
			var node_id := String(node_id_value)
			if node_id not in unlocked:
				unlocked.append(node_id)
	var annotations: Dictionary = route_data.get("clue_annotations", {})
	if not annotations is Dictionary:
		annotations = {}
	var overlays: Dictionary = route_data.get("clue_overlays", {})
	if not overlays is Dictionary:
		overlays = {}
	var node_meta := _node_meta_map(route_data)
	var run_state: Dictionary = route_data.get("run_state", {})
	var spread_list: Array = []
	var prior_complete := true
	for page_value in _pages:
		if not page_value is Dictionary:
			continue
		var page: Dictionary = page_value
		## Collect kind!=main as side stickers attached to the next main spread on this page.
		var pending_sides: Array = []
		for clue_value in page.get("clues", []):
			if not clue_value is Dictionary:
				continue
			var clue_src: Dictionary = clue_value
			if String(clue_src.get("kind", "main")) != "main":
				pending_sides.append({
					"clue_id": String(clue_src.get("clue_id", "")),
					"node_id": String(clue_src.get("node_id", "")),
					"kind": String(clue_src.get("kind", "side")),
					"title_zh": _clip(String(clue_src.get("margin_note_zh", clue_src.get("text_zh", "旁支"))), 16),
					"margin_note_zh": String(clue_src.get("margin_note_zh", "")),
					"text_zh": String(clue_src.get("text_zh", "")),
				})
				continue
			var node_id := String(clue_src.get("node_id", ""))
			var state := STATE_LOCKED
			if node_id in completed:
				state = STATE_COMPLETED
			elif prior_complete and node_id in unlocked:
				state = STATE_AVAILABLE
			var base_text_zh := String(clue_src.get("text_zh", ""))
			var text_zh := base_text_zh
			var overwrite_text_zh := ""
			var margin_note_zh := String(clue_src.get("margin_note_zh", ""))
			var rewritten := false
			var overlay_value = overlays.get(node_id, {})
			if overlay_value is Dictionary and not overlay_value.is_empty():
				var overlay_text := String(overlay_value.get("text_zh", ""))
				if not overlay_text.is_empty():
					overwrite_text_zh = overlay_text
					text_zh = overlay_text
					rewritten = true
				var overlay_margin := String(overlay_value.get("margin_note_zh", ""))
				if not overlay_margin.is_empty():
					margin_note_zh = overlay_margin
			var meta: Dictionary = node_meta.get(node_id, {})
			var node_type := String(meta.get("type", ""))
			var scene_id := String(meta.get("scene_id", ""))
			var display_name := String(meta.get("display_name_zh", ""))
			var title_zh := _title_for(display_name, margin_note_zh)
			var ink_zh := _clip(text_zh, INK_MAX)
			var art_kind := "battle"
			if node_type == "rest":
				art_kind = "rest"
			elif node_type == "ritual":
				art_kind = "ritual"
			## Leaf art is portrait-first; falls back to the 16:9 plate.
			var left_art_path := SceneCatalog.diary_path_for(scene_id, art_kind)
			var clue := {
				"id": String(clue_src.get("clue_id", "")),
				"clue_id": String(clue_src.get("clue_id", "")),
				"node_id": node_id,
				"kind": "main",
				"node_type": node_type,
				"text_zh": text_zh,
				"base_text_zh": base_text_zh,
				"overwrite_text_zh": overwrite_text_zh,
				"margin_note_zh": margin_note_zh,
				"rewritten_by_pen": rewritten,
				"state": state,
				"state_name": _state_name(state),
				"annotation_zh": String(annotations.get(node_id, "")),
				"scene_id": scene_id,
				"title_zh": title_zh,
				"ink_zh": ink_zh,
				"left_art_path": left_art_path,
			}
			var main_complete := state == STATE_COMPLETED
			var spread_index := spread_list.size()
			var side_notes: Array = pending_sides.duplicate(true)
			pending_sides.clear()
			spread_list.append({
				"page_index": spread_index,
				"spread_index": spread_index,
				"title_zh": title_zh,
				"spread_label_zh": String(page.get("spread_label_zh", "")),
				"node_id": node_id,
				"clue_id": String(clue_src.get("clue_id", "")),
				"scene_id": scene_id,
				"left_art_path": left_art_path,
				"ink_zh": ink_zh,
				"node_type": node_type,
				"state": state,
				"left_clues": [],
				"right_clues": [clue],
				"clues": [clue],
				"side_notes": side_notes,
				"is_main_complete": main_complete,
				"completed": main_complete,
				"investigable": prior_complete,
				"is_locked": state == STATE_LOCKED,
				"is_available": state == STATE_AVAILABLE,
				"is_completed": main_complete,
			})
			if not main_complete:
				prior_complete = false
		## Orphan sides after last main on the page attach to the last spread.
		if not pending_sides.is_empty() and not spread_list.is_empty():
			var last: Dictionary = spread_list[spread_list.size() - 1]
			var attached: Array = last.get("side_notes", [])
			if not attached is Array:
				attached = []
			attached.append_array(pending_sides)
			last["side_notes"] = attached
	var current_idx := 0
	for spread in spread_list:
		if not bool(spread.get("is_main_complete", false)):
			current_idx = int(spread.get("page_index", 0))
			break
		current_idx = int(spread.get("page_index", 0))
	return {
		"volume_id": String(_volume.get("volume_id", "")),
		"display_name_zh": String(
			_volume.get("display_name_zh", route_data.get("display_name_zh", ""))
		),
		"carrier_zh": String(_volume.get("carrier_zh", "罗塞尔日记")),
		"pen_zh": String(_volume.get("pen_zh", "阿勒苏霍德之笔")),
		"base_notes_zh": _volume.get("base_notes_zh", []),
		"spread_list": spread_list,
		"pages": spread_list,
		"current_spread_idx": current_idx,
		"current_page_index": current_idx,
		"run_state": run_state.duplicate(true) if run_state is Dictionary else {},
		"phase": String(route_data.get("phase", "")),
		"chapter_summary_zh": String(route_data.get("chapter_summary_zh", "")),
		"can_begin_ascension": bool(route_data.get("can_begin_ascension", false)),
	}


func _title_for(display_name: String, margin_note: String) -> String:
	if not display_name.is_empty():
		return _clip(display_name, TITLE_MAX)
	if margin_note.is_empty():
		return "未署名页"
	var first := margin_note
	for sep in ["。", "；", "，", ".", ";", ","]:
		var cut := margin_note.find(sep)
		if cut > 0:
			first = margin_note.substr(0, cut)
			break
	return _clip(first, TITLE_MAX)


func _clip(text: String, max_chars: int) -> String:
	if text.length() <= max_chars:
		return text
	return text.substr(0, max_chars)


func _state_name(state: int) -> String:
	match state:
		STATE_AVAILABLE:
			return "available"
		STATE_COMPLETED:
			return "completed"
		_:
			return "locked"


func _node_meta_map(route_data: Dictionary) -> Dictionary:
	var result := {}
	for node_value in route_data.get("nodes", []):
		if node_value is Dictionary:
			var node: Dictionary = node_value
			var id := String(node.get("id", ""))
			if id.is_empty():
				continue
			result[id] = {
				"type": String(node.get("type", "")),
				"display_name_zh": String(node.get("display_name_zh", "")),
				"scene_id": String(node.get("scene_id", "")),
			}
	return result


func _node_type_map(route_data: Dictionary) -> Dictionary:
	## Legacy helper kept for older call sites.
	var result := {}
	var meta := _node_meta_map(route_data)
	for id in meta.keys():
		result[id] = String(meta[id].get("type", ""))
	return result
