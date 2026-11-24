extends RefCounted

## UI-side diary volume → Spread list. The volume is the schema-validated
## document the app loads at startup and hands over via `configure()` (R2-09);
## this file never opens content itself.
## v0.84 P0: one main clue → one spread (cross-page level).
## BUG-0038: route nodes the volume does not map (challenge routes) get plain
## fallback spreads titled by the node's own display name.

const SceneCatalog := preload("res://src/ui/scene_ui_catalog.gd")

## Clue visual states matching the flip subsystem contract.
const STATE_LOCKED := 0
const STATE_AVAILABLE := 1
const STATE_COMPLETED := 2

const TITLE_MAX := 10
const INK_MAX := 60
const FALLBACK_TITLE_ZH := "无名之页"
const ANNOTATION_ID_PREFIX := "annotation."
## Per-node rule answers from the RouteEngine snapshot (R2-03); the UI reads them.
const SNAPSHOT_FLAG_KEYS: Array[String] = [
	"can_open", "can_advance", "open_command", "wipeable", "wipe_cost",
	"ink_stained", "annotation_id", "annotation_ids",
]
const OPEN_SELECT_NODE := "select_node"

static var _configured_volume: Dictionary = {}

var _volume: Dictionary = {}
var _pages: Array = []
var _loaded := false


static func configure(volume: Dictionary) -> void:
	_configured_volume = volume


static func is_configured() -> bool:
	return not _configured_volume.is_empty()


func ensure_loaded() -> bool:
	if _loaded:
		return not _pages.is_empty()
	_loaded = true
	_volume = _configured_volume
	var pages: Variant = _volume.get("pages", [])
	_pages = pages if pages is Array else []
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
	var annotations: Dictionary = _resolved_annotations(route_data)
	var overlays: Dictionary = route_data.get("clue_overlays", {})
	if not overlays is Dictionary:
		overlays = {}
	var node_meta := _node_meta_map(route_data)
	var run_state: Dictionary = route_data.get("run_state", {})
	var spread_list: Array = []
	var prior_complete := true
	var mapped := _volume_node_ids()
	var use_volume := node_meta.is_empty()
	for meta_id in node_meta.keys():
		if mapped.has(meta_id):
			use_volume = true
			break
	for page_value in (_pages if use_volume else []):
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
			var can_open := _node_can_open(node_meta.get(node_id, {}), prior_complete)
			var state := STATE_LOCKED
			if node_id in completed:
				state = STATE_COMPLETED
			elif can_open and node_id in unlocked:
				state = STATE_AVAILABLE
			var base_text_zh := String(clue_src.get("text_zh", ""))
			var text_zh := base_text_zh
			var overwrite_text_zh := ""
			var margin_note_zh := String(clue_src.get("margin_note_zh", ""))
			var rewritten := false
			var overlay_value = overlays.get(node_id, {})
			if overlay_value is Dictionary and not overlay_value.is_empty():
				var overlay_text := _overlay_text(overlay_value)
				if not overlay_text.is_empty():
					overwrite_text_zh = overlay_text
					text_zh = overlay_text
					rewritten = true
				var overlay_margin := _overlay_margin(overlay_value)
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
			}.merged(_clue_flags(meta))
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
				"investigable": can_open,
				"can_open": can_open,
				"can_advance": main_complete,
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
	for node_value in route_data.get("nodes", []):
		if not node_value is Dictionary:
			continue
		var fallback_id := String(node_value.get("id", ""))
		if fallback_id.is_empty() or mapped.has(fallback_id):
			continue
		var fallback := _fallback_spread(
			fallback_id, node_meta.get(fallback_id, {}), spread_list.size(),
			completed, unlocked,
			_node_can_open(node_meta.get(fallback_id, {}), prior_complete),
			annotations, overlays
		)
		spread_list.append(fallback)
		if not bool(fallback.get("is_main_complete", false)):
			prior_complete = false
	var current_idx := 0
	for spread in spread_list:
		if not bool(spread.get("is_main_complete", false)):
			current_idx = int(spread.get("page_index", 0))
			break
		current_idx = int(spread.get("page_index", 0))
	var volume: Dictionary = _volume if use_volume else {}
	return {
		"volume_id": String(volume.get("volume_id", "")),
		"display_name_zh": String(
			volume.get("display_name_zh", route_data.get("display_name_zh", ""))
		),
		"carrier_zh": String(_volume.get("carrier_zh", "罗塞尔日记")),
		"pen_zh": String(_volume.get("pen_zh", "阿勒苏霍德之笔")),
		"base_notes_zh": volume.get("base_notes_zh", []),
		"spread_list": spread_list,
		"pages": spread_list,
		"current_spread_idx": current_idx,
		"current_page_index": current_idx,
		"run_state": run_state.duplicate(true) if run_state is Dictionary else {},
		"phase": String(route_data.get("phase", "")),
		"chapter_summary_zh": String(route_data.get("chapter_summary_zh", "")),
		"can_begin_ascension": bool(route_data.get("can_begin_ascension", false)),
	}


## Same state/seal contract as a volume spread; body is the node's own beat text.
func _fallback_spread(
	node_id: String,
	meta: Dictionary,
	spread_index: int,
	completed: Array,
	unlocked: Array,
	can_open: bool,
	annotations: Dictionary,
	overlays: Dictionary
) -> Dictionary:
	var state := STATE_LOCKED
	if node_id in completed:
		state = STATE_COMPLETED
	elif can_open and node_id in unlocked:
		state = STATE_AVAILABLE
	var base_text_zh := String(meta.get("narrative_beat_zh", ""))
	var text_zh := base_text_zh
	var overwrite_text_zh := ""
	var margin_note_zh := ""
	var overlay_value = overlays.get(node_id, {})
	if overlay_value is Dictionary and not overlay_value.is_empty():
		overwrite_text_zh = _overlay_text(overlay_value)
		if not overwrite_text_zh.is_empty():
			text_zh = overwrite_text_zh
		margin_note_zh = _overlay_margin(overlay_value)
	var node_type := String(meta.get("type", ""))
	var scene_id := String(meta.get("scene_id", ""))
	var display_name := String(meta.get("display_name_zh", ""))
	var title_zh := FALLBACK_TITLE_ZH
	if not display_name.is_empty():
		title_zh = _clip(display_name, TITLE_MAX)
	var ink_zh := _clip(text_zh, INK_MAX)
	var art_kind := node_type if node_type in ["rest", "ritual"] else "battle"
	var left_art_path := SceneCatalog.diary_path_for(scene_id, art_kind)
	var main_complete := state == STATE_COMPLETED
	var clue := {
		"id": node_id,
		"clue_id": node_id,
		"node_id": node_id,
		"kind": "main",
		"node_type": node_type,
		"text_zh": text_zh,
		"base_text_zh": base_text_zh,
		"overwrite_text_zh": overwrite_text_zh,
		"margin_note_zh": margin_note_zh,
		"rewritten_by_pen": not overwrite_text_zh.is_empty(),
		"state": state,
		"state_name": _state_name(state),
		"annotation_zh": String(annotations.get(node_id, "")),
		"scene_id": scene_id,
		"title_zh": title_zh,
		"ink_zh": ink_zh,
		"left_art_path": left_art_path,
	}.merged(_clue_flags(meta))
	return {
		"page_index": spread_index,
		"spread_index": spread_index,
		"title_zh": title_zh,
		"spread_label_zh": "",
		"node_id": node_id,
		"clue_id": node_id,
		"scene_id": scene_id,
		"left_art_path": left_art_path,
		"ink_zh": ink_zh,
		"node_type": node_type,
		"state": state,
		"left_clues": [],
		"right_clues": [clue],
		"clues": [clue],
		"side_notes": [],
		"is_main_complete": main_complete,
		"completed": main_complete,
		"investigable": can_open,
		"can_open": can_open,
		"can_advance": main_complete,
		"is_locked": state == STATE_LOCKED,
		"is_available": state == STATE_AVAILABLE,
		"is_completed": main_complete,
		"is_fallback": true,
	}


func _volume_node_ids() -> Dictionary:
	var result := {}
	for page_value in _pages:
		if not page_value is Dictionary:
			continue
		for clue_value in page_value.get("clues", []):
			if clue_value is Dictionary:
				var clue_node_id := String(clue_value.get("node_id", ""))
				if not clue_node_id.is_empty():
					result[clue_node_id] = true
	return result


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
				"narrative_beat_zh": String(node.get("narrative_beat_zh", "")),
			}
			for key in SNAPSHOT_FLAG_KEYS:
				if node.has(key):
					result[id][key] = node[key]
	return result


## Annotation ids resolve against the diary data. Pre-v0.88 snapshots carried
## text: legacy_clue_annotations_zh and non-id strings stay display-only.
func annotation_text(annotation_id: String) -> String:
	ensure_loaded()
	var entries: Variant = _volume.get("annotations", {}).get("entries", {})
	if entries is Dictionary:
		var entry: Variant = entries.get(annotation_id, {})
		if entry is Dictionary and entry.has("text_zh"):
			return String(entry["text_zh"])
	if annotation_id.begins_with(ANNOTATION_ID_PREFIX):
		return ""
	return annotation_id


## First line of a narration pool (settlement flash when a clue has no note).
func pool_head_text(pool_id: String) -> String:
	ensure_loaded()
	var pool: Variant = _volume.get("annotations", {}).get("pools", {}).get(pool_id, {})
	var cycle: Variant = pool.get("cycle", []) if pool is Dictionary else []
	if cycle is Array and not cycle.is_empty():
		return annotation_text(String(cycle[0]))
	return ""


func _resolved_annotations(route_data: Dictionary) -> Dictionary:
	var result := {}
	var legacy: Variant = route_data.get("legacy_clue_annotations_zh", {})
	if legacy is Dictionary:
		for node_id in legacy.keys():
			result[String(node_id)] = String(legacy[node_id])
	var annotations: Variant = route_data.get("clue_annotations", {})
	if annotations is Dictionary:
		for node_id in annotations.keys():
			result[String(node_id)] = annotation_text(String(annotations[node_id]))
	return result


func _overlay_text(overlay: Dictionary) -> String:
	var annotation_id := String(overlay.get("annotation_id", ""))
	if not annotation_id.is_empty():
		return annotation_text(annotation_id)
	return String(overlay.get("legacy_text_zh", overlay.get("text_zh", "")))


func _overlay_margin(overlay: Dictionary) -> String:
	var margin_id := String(overlay.get("margin_note_id", ""))
	if not margin_id.is_empty():
		return annotation_text(margin_id)
	return String(overlay.get("legacy_margin_note_zh", overlay.get("margin_note_zh", "")))


## Snapshot can_open wins; hand-built or pre-R2 snapshots without it fall back
## to the spread chain the catalog walks anyway.
func _node_can_open(meta: Dictionary, chain_open: bool) -> bool:
	return bool(meta.get("can_open", chain_open))


func _clue_flags(meta: Dictionary) -> Dictionary:
	return {
		"open_command": String(meta.get("open_command", OPEN_SELECT_NODE)),
		"wipeable": bool(meta.get("wipeable", false)),
		"wipe_cost": int(meta.get("wipe_cost", 0)),
		"ink_stained": bool(meta.get("ink_stained", false)),
		"annotation_id": String(meta.get("annotation_id", "")),
		"annotation_ids": meta.get("annotation_ids", []).duplicate(),
	}
