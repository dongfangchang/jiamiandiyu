extends RefCounted

## Registry for keyed prop art (desk, paper, seal, state tokens, ornaments).
##
## Pipeline:
##   art/assets/raster/<ver>/props/*.png   (RGB on a studio backdrop)
##     -> props.manifest.json              (declares key mode / trim)
##     -> art/tools/key_props.gd           (writes RGBA cutouts)
##     -> PROPS below                      (runtime lookup)
##
## Adding art is a manifest row + a file drop + one tool run. Only brand new
## *kinds* of prop need a line here. Every lookup degrades gracefully, so a
## missing file leaves the procedural look in place instead of crashing.

const PROP_DIR := "res://assets/ui/diary/props"

const PROPS := {
	"desk_wood": "desk-wood.png",
	"parchment_sheet": "parchment-sheet.png",
	"wax_seal": "wax-seal.png",
	"token_available": "token-available.png",
	"token_failed": "token-failed.png",
	"token_silence": "token-silence.png",
	"token_archive": "token-archive.png",
	"corner_ornament": "corner-ornament.png",
	"bookmark": "bookmark.png",
	"candle": "candle.png",
	"inkwell": "inkwell.png",
	"quill_pen": "quill-pen.png",
	"open_journal": "open-journal.png",
	## Title screen: the main menu reuses the same desk, with the journal shut
	## instead of open. See art/assets/raster/v0.85.0/title/PROMPTS.md.
	"title_journal_closed": "title-journal-closed.png",
	"title_journal_new": "title-journal-new.png",
	"title_dossier_stack": "title-dossier-stack.png",
	"title_pocket_watch": "title-pocket-watch.png",
	"title_candle_snuffer": "title-candle-snuffer.png",
	"title_note_slip": "title-note-slip.png",
	"title_desk_wide": "title-desk-wide.png",
}

## Diary leaf state -> which token lights up. Mirrors 样板.jpg's rail.
const STATE_TOKENS: Array[String] = [
	"token_available",
	"token_failed",
	"token_silence",
	"token_archive",
]

const TOKEN_LABELS: Array[String] = ["可用", "曾失败", "静默", "归藏"]

static var _cache: Dictionary = {}


static func path(prop_id: String) -> String:
	var leaf := String(PROPS.get(prop_id, ""))
	if leaf.is_empty():
		return ""
	return "%s/%s" % [PROP_DIR, leaf]


static func has(prop_id: String) -> bool:
	var p := path(prop_id)
	if p.is_empty():
		return false
	## Check the SOURCE file, not just ResourceLoader: a stale .import cache
	## keeps reporting a deleted PNG as present, which would let a missing
	## delivery pass as ingested.
	if not FileAccess.file_exists(p):
		return false
	return ResourceLoader.exists(p)


static func texture(prop_id: String) -> Texture2D:
	## Null when the art has not been ingested yet — callers must handle it and
	## keep their procedural fallback.
	if _cache.has(prop_id):
		return _cache[prop_id] as Texture2D
	var tex: Texture2D = null
	var p := path(prop_id)
	if not p.is_empty() and ResourceLoader.exists(p):
		tex = load(p) as Texture2D
	_cache[prop_id] = tex
	return tex


static func token_for_state(state_index: int) -> Texture2D:
	if state_index < 0 or state_index >= STATE_TOKENS.size():
		return null
	return texture(STATE_TOKENS[state_index])


static func missing() -> PackedStringArray:
	## Lets probes and reports tell "not delivered" from "delivered but wrong",
	## instead of silently accepting a fallback.
	var out: PackedStringArray = []
	for prop_id in PROPS.keys():
		if not has(String(prop_id)):
			out.append(String(prop_id))
	return out


static func clear_cache() -> void:
	_cache.clear()
