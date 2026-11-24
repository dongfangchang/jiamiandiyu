extends Node

## Golden replay (ROADMAP R0-04, TARGET_ARCHITECTURE 3.8).
##
## Drives the first chapter (route.v028.first_stage) through the same
## composition the app uses for a new game (AppBootstrap.start_route_v07) with
## a fixed seed and a deterministic command policy, snapshots every stage,
## normalizes it and compares sha256 digests with tests/golden/expected.json.
##
## Pure refactors must keep every digest. Intentional rule changes regenerate:
##   "$GODOT" --headless --path . res://tests/golden/golden_replay_runner.tscn -- --update

const AppBootstrapScript := preload("res://src/app/bootstrap.gd")
const BattleCommandScript := preload("res://src/core/battle_command.gd")
const ProgressionCommandScript := preload("res://src/core/progression_command.gd")
const RouteCommandScript := preload("res://src/core/route_command.gd")

const EXPECTED_PATH := "res://tests/golden/expected.json"
const SAVE_DIRECTORY := "user://golden_replay"
const SAVE_SLOT := "golden_replay"
const ACTUAL_DIRECTORY := "user://golden_replay_actual"
const RUN_SEED := 20261124
const ROUTE_ID := "route.v028.first_stage"
const IDENTITY_ID := &"identity.reporter"
const MAX_NODES := 12
const MAX_BATTLE_ACTIONS := 240
const MAX_BATTLE_TURNS := 40
const GACHA_PULLS := 1

## Keys whose values vary between runs or machines and carry no rule meaning.
const VOLATILE_KEYS: Array[String] = ["created_at", "saved_at", "checksum", "path"]
const VOLATILE_SUFFIXES: Array[String] = ["_at", "_unix", "_ms", "_path", "timestamp_utc"]

var _failures: Array[String] = []


func _ready() -> void:
	var update := "--update" in OS.get_cmdline_user_args()
	var first := _replay()
	var second := _replay()
	if not _failures.is_empty():
		_finish()
		return
	var first_digest := _digest(first)
	var second_digest := _digest(second)
	for stage in first_digest.keys():
		if String(first_digest[stage]["hash"]) != String(second_digest.get(stage, {}).get("hash", "")):
			_failures.append("non-deterministic stage within one process: %s" % stage)
	if first_digest.size() != second_digest.size():
		_failures.append("non-deterministic stage count: %d vs %d" % [first_digest.size(), second_digest.size()])
	if not _failures.is_empty():
		_finish()
		return
	if update:
		_write_expected(first_digest)
		print("GOLDEN_REPLAY_UPDATED stages=%d path=%s" % [
			first_digest.size(),
			ProjectSettings.globalize_path(EXPECTED_PATH),
		])
		_finish()
		return
	_compare(first, first_digest)
	_finish()


# --- replay ---------------------------------------------------------------

## Returns an ordered Array of {"stage": String, "data": Dictionary}.
func _replay() -> Array:
	_clear_directory(SAVE_DIRECTORY)
	var stages: Array = []
	var started = AppBootstrapScript.start_route_v07(
		RUN_SEED,
		{"save_directory": SAVE_DIRECTORY, "route_id": ROUTE_ID},
		SAVE_SLOT,
		false
	)
	if not started.ok:
		_failures.append("start_route_v07 failed: %s %s" % [started.code, started.details])
		return stages
	var session = started.data
	var picked = session.submit_progression(
		ProgressionCommandScript.select_identity(IDENTITY_ID)
	)
	if not picked.accepted:
		_failures.append("select_identity rejected: %s" % picked.reason_code)
		return stages
	stages.append(_stage("01_start", session, {
		"identity": _command_log_entry("select_identity", picked),
	}))

	var stage_index := 2
	for _node_step in range(MAX_NODES):
		var route: Dictionary = session.get_route_snapshot().data
		var phase := String(route.get("phase", ""))
		if phase != "map":
			break
		var node_id := String(route.get("available_node_id", ""))
		var node := _node_by_id(route, node_id)
		if node.is_empty():
			break
		var node_type := String(node.get("type", ""))
		var extra := {"node_id": node_id, "node_type": node_type}
		match node_type:
			"normal", "elite", "boss":
				extra.merge(_play_battle(session))
				var outcome := String(extra.get("outcome", ""))
				if outcome == "victory":
					extra["reward"] = _claim_first_reward(session)
				if outcome != "victory":
					stages.append(_stage(_stage_name(stage_index, node_id), session, extra))
					stage_index += 1
					break
			"rest":
				extra.merge(_take_first_rest(session, node_id))
			"ritual":
				extra.merge(_perform_ritual(session))
			_:
				extra["skipped"] = "unhandled node type"
				stages.append(_stage(_stage_name(stage_index, node_id), session, extra))
				break
		stages.append(_stage(_stage_name(stage_index, node_id), session, extra))
		stage_index += 1

	var gacha := {}
	var pulled = session.submit_progression(
		ProgressionCommandScript.draw_gacha(GACHA_PULLS)
	)
	gacha["draw"] = _command_log_entry("draw_gacha", pulled)
	stages.append(_stage("%02d_gacha" % stage_index, session, gacha))
	stage_index += 1

	var loaded = session.services.saves.load_slot(SAVE_SLOT)
	stages.append({
		"stage": "%02d_checkpoint" % stage_index,
		"data": {
			"ok": loaded.ok,
			"code": String(loaded.code),
			"envelope": loaded.data if loaded.ok else {},
		},
	})
	return stages


func _play_battle(session) -> Dictionary:
	var log: Array = []
	var begun = session.begin_route_battle()
	if not begun.ok:
		return {"begin": String(begun.code), "outcome": ""}
	var turns := 0
	var final_snapshot: Dictionary = {}
	for _action in range(MAX_BATTLE_ACTIONS):
		var snapshot = session.get_battle_snapshot()
		if snapshot == null:
			break
		final_snapshot = snapshot.data
		if not String(final_snapshot.get("outcome", "")).is_empty():
			break
		if turns >= MAX_BATTLE_TURNS:
			break
		var played := false
		var target_id := _first_alive_enemy(final_snapshot)
		for card_value in final_snapshot.get("hand", []):
			if not card_value is Dictionary:
				continue
			var card: Dictionary = card_value
			var instance_id := StringName(card.get("instance_id", ""))
			var target := target_id if String(card.get("target_type", "")) == "enemy" else &""
			var discards: Array = session.auto_discard_ids_for(instance_id)
			if not session.query_card_play(instance_id, target, discards).playable:
				continue
			var result = session.submit_battle(
				BattleCommandScript.play_card(instance_id, target, discards)
			)
			log.append(_command_log_entry(
				"play:%s" % String(card.get("definition_id", "")), result
			))
			if result.accepted:
				played = true
				break
		if not played:
			var ended = session.submit_battle(BattleCommandScript.end_turn())
			log.append(_command_log_entry("end_turn", ended))
			turns += 1
			if not ended.accepted:
				break
	var last = session.get_battle_snapshot()
	if last != null:
		final_snapshot = last.data
	return {
		"outcome": String(final_snapshot.get("outcome", "")),
		"turns": turns,
		"commands": log,
		"battle_final": final_snapshot,
	}


func _claim_first_reward(session) -> Dictionary:
	var rewards: Array = session.get_progression_snapshot().data.get("reward_options", [])
	if rewards.is_empty():
		return {"claimed": "", "accepted": false}
	var reward_id := String(rewards[0].get("id", ""))
	var result = session.submit_progression(
		ProgressionCommandScript.claim_reward(StringName(reward_id))
	)
	return {"claimed": reward_id, "result": _command_log_entry("claim_reward", result)}


func _take_first_rest(session, node_id: String) -> Dictionary:
	var selected = session.submit_route(RouteCommandScript.select_node(StringName(node_id)))
	var route: Dictionary = session.get_route_snapshot().data
	var options: Array = route.get("rest_options", [])
	var rest_id := ""
	if not options.is_empty() and options[0] is Dictionary:
		rest_id = String(options[0].get("id", ""))
	var used = session.submit_route(RouteCommandScript.use_rest(StringName(rest_id)))
	return {
		"select": _command_log_entry("select_node", selected),
		"rest_id": rest_id,
		"rest": _command_log_entry("use_rest", used),
	}


func _perform_ritual(session) -> Dictionary:
	var log: Array = []
	var begun = session.submit_route(RouteCommandScript.begin_ascension())
	log.append(_command_log_entry("begin_ascension", begun))
	if not begun.accepted:
		return {"ritual": log}
	var ritual_id := StringName(session.get_ritual_snapshot().data.get("ritual_id", ""))
	var definition: Dictionary = session.route_content.get_ritual(ritual_id)
	for step_value in definition.get("steps", []):
		var step: Dictionary = step_value
		var selections: Array[String] = []
		if step.has("correct_ids"):
			for value in step["correct_ids"]:
				selections.append(String(value))
		elif step.has("correct_order"):
			for value in step["correct_order"]:
				selections.append(String(value))
		elif step.has("correct_id"):
			selections.append(String(step["correct_id"]))
		var result = session.submit_route(RouteCommandScript.submit_ritual_step(selections))
		log.append(_command_log_entry("ritual_step:%s" % String(step.get("id", "")), result))
	return {"ritual": log, "ritual_final": session.get_ritual_snapshot().data}


# --- snapshots ------------------------------------------------------------

func _stage(name: String, session, extra: Dictionary) -> Dictionary:
	return {
		"stage": name,
		"data": {
			"extra": extra,
			"route": session.get_route_snapshot().data,
			"progression": session.get_progression_snapshot().data,
			"deck": session.get_deck_snapshot().data,
			"sequence": session.get_sequence_state().data,
		},
	}


func _stage_name(index: int, node_id: String) -> String:
	return "%02d_%s" % [index, node_id.get_slice(".", node_id.get_slice_count(".") - 1)]


func _command_log_entry(label: String, result) -> Dictionary:
	var event_types: Array[String] = []
	if result != null and "events" in result:
		for event in result.events:
			if event != null:
				event_types.append(String(event.type))
	return {
		"command": label,
		"accepted": result != null and bool(result.accepted),
		"reason": String(result.reason_code) if result != null else "null",
		"events": event_types,
	}


func _node_by_id(route: Dictionary, node_id: String) -> Dictionary:
	for value in route.get("nodes", []):
		if value is Dictionary and String(value.get("id", "")) == node_id:
			return value
	return {}


func _first_alive_enemy(snapshot: Dictionary) -> StringName:
	for enemy_value in snapshot.get("enemies", []):
		if enemy_value is Dictionary and int(enemy_value.get("hp", 0)) > 0:
			return StringName(enemy_value.get("actor_id", ""))
	return &""


# --- normalize / digest ---------------------------------------------------

func _normalize(value: Variant) -> Variant:
	match typeof(value):
		TYPE_DICTIONARY:
			var keys: Array = value.keys().map(func(k): return String(k))
			keys.sort()
			var out := {}
			for key in keys:
				if _is_volatile(key):
					continue
				out[key] = _normalize(value[key] if value.has(key) else value[StringName(key)])
			return out
		TYPE_ARRAY, TYPE_PACKED_STRING_ARRAY, TYPE_PACKED_INT32_ARRAY, TYPE_PACKED_INT64_ARRAY, TYPE_PACKED_FLOAT32_ARRAY, TYPE_PACKED_FLOAT64_ARRAY:
			var items: Array = []
			for item in value:
				items.append(_normalize(item))
			return items
		TYPE_STRING_NAME:
			return String(value)
		TYPE_OBJECT:
			if value != null and value.has_method("to_dictionary"):
				return _normalize(value.to_dictionary())
			return null
		TYPE_FLOAT:
			# Integral floats come back from JSON saves; keep ints and floats comparable.
			if is_equal_approx(value, roundf(value)):
				return int(value)
			return snappedf(value, 0.0001)
	return value


func _is_volatile(key: String) -> bool:
	if key in VOLATILE_KEYS:
		return true
	for suffix in VOLATILE_SUFFIXES:
		if key.ends_with(suffix):
			return true
	return false


func _canonical(stage_data: Dictionary) -> String:
	return JSON.stringify(_normalize(stage_data), "", true)


func _digest(stages: Array) -> Dictionary:
	var out := {}
	for entry in stages:
		var canonical := _canonical(entry["data"])
		out[String(entry["stage"])] = {
			"hash": canonical.sha256_text(),
			"summary": _summary(entry["data"]),
		}
	return out


## Human-readable anchors stored next to each hash so a diff says what moved.
func _summary(data: Dictionary) -> Dictionary:
	var extra: Dictionary = data.get("extra", {})
	var route: Dictionary = data.get("route", {})
	var run_state: Dictionary = route.get("run_state", {})
	var progression: Dictionary = data.get("progression", {})
	var summary := {
		"route_phase": String(route.get("phase", "")),
		"completed_nodes": route.get("completed_node_ids", []).size(),
		"hp": int(run_state.get("hp", 0)),
		"corruption": int(run_state.get("corruption", 0)),
		"attention": int(run_state.get("attention", 0)),
		"progression_phase": String(progression.get("phase", "")),
		"tickets": int(progression.get("divination_tickets", 0)),
		"sequence": int(data.get("sequence", {}).get("current_sequence", 0)),
	}
	if extra.has("outcome"):
		summary["outcome"] = String(extra["outcome"])
		summary["turns"] = int(extra.get("turns", 0))
		summary["commands"] = extra.get("commands", []).size()
	if data.has("envelope"):
		summary = {"ok": data.get("ok", false), "code": String(data.get("code", ""))}
		var envelope: Dictionary = data.get("envelope", {})
		summary["save_version"] = int(envelope.get("save_version", 0))
		summary["content_revision"] = int(envelope.get("content_revision", 0))
	return summary


# --- expected.json --------------------------------------------------------

func _compare(stages: Array, digest: Dictionary) -> void:
	if not FileAccess.file_exists(EXPECTED_PATH):
		_failures.append("missing %s; run with -- --update" % EXPECTED_PATH)
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(EXPECTED_PATH))
	if not parsed is Dictionary:
		_failures.append("expected.json is not a JSON object")
		return
	var expected: Dictionary = parsed.get("stages", {})
	var names: Array = expected.keys()
	for name in digest.keys():
		if not name in names:
			names.append(name)
	names.sort()
	for name in names:
		if not expected.has(name):
			_failures.append("stage added: %s %s" % [name, JSON.stringify(digest[name]["summary"])])
			continue
		if not digest.has(name):
			_failures.append("stage missing: %s (expected %s)" % [name, JSON.stringify(_normalize(expected[name].get("summary", {})))])
			continue
		if String(expected[name].get("hash", "")) == String(digest[name]["hash"]):
			continue
		var dump_path := _dump_actual(stages, name)
		_failures.append("stage changed: %s\n    expected summary %s\n    actual   summary %s\n    actual canonical JSON: %s" % [
			name,
			JSON.stringify(_normalize(expected[name].get("summary", {})), "", true),
			JSON.stringify(digest[name]["summary"], "", true),
			dump_path,
		])


func _dump_actual(stages: Array, name: String) -> String:
	DirAccess.make_dir_recursive_absolute(ACTUAL_DIRECTORY)
	var path := "%s/%s.json" % [ACTUAL_DIRECTORY, name]
	for entry in stages:
		if String(entry["stage"]) == name:
			var file := FileAccess.open(path, FileAccess.WRITE)
			if file != null:
				file.store_string(JSON.stringify(_normalize(entry["data"]), "\t", true))
				file.close()
	return ProjectSettings.globalize_path(path)


func _write_expected(digest: Dictionary) -> void:
	var file := FileAccess.open(EXPECTED_PATH, FileAccess.WRITE)
	if file == null:
		_failures.append("cannot write %s" % EXPECTED_PATH)
		return
	file.store_string(JSON.stringify({
		"schema_version": 1,
		"seed": RUN_SEED,
		"route_id": ROUTE_ID,
		"identity_id": String(IDENTITY_ID),
		"stages": digest,
	}, "  ", true) + "\n")
	file.close()


func _clear_directory(path: String) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		DirAccess.make_dir_recursive_absolute(path)
		return
	for file_name in dir.get_files():
		dir.remove(file_name)


func _finish() -> void:
	_clear_directory(SAVE_DIRECTORY)
	if _failures.is_empty():
		print("GOLDEN_REPLAY_OK")
		get_tree().quit(0)
		return
	for failure in _failures:
		printerr("GOLDEN_REPLAY_FAIL %s" % failure)
	print("GOLDEN_REPLAY_FAILED failures=%d" % _failures.size())
	get_tree().quit(1)
