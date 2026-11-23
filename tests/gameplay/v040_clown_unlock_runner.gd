extends Node

## v0.40.0: potion grants 8 clown cards, unlocks sequence lock, selects clown preset.

const AppBootstrapScript := preload("res://src/app/bootstrap.gd")
const ProgressionCommandScript := preload("res://src/core/progression_command.gd")

const CLOWN_IDS: Array[String] = [
	"card.skill.veil_step",
	"card.skill.severed_fate",
	"card.skill.paper_swarm",
	"card.skill.mirror_shard",
	"card.skill.last_witness",
	"card.skill.false_death",
	"card.skill.sealed_answer",
	"card.skill.hollow_bell",
]

var _checks := 0
var _failures: Array[String] = []


func _ready() -> void:
	_test_locked_before_potion()
	_test_grant_and_preset_after_potion()
	_test_forward_fill_preset_on_restore()
	_finish()


func _test_locked_before_potion() -> void:
	var started = AppBootstrapScript.start_route_v07(
		20261117,
		{
			"test_profile": true,
			"save_directory": "user://v040_clown_locked",
			"route_id": "route.v028.first_stage",
		},
		"v040_clown_locked",
		false
	)
	_expect(started.ok, "locked fixture should initialize")
	if not started.ok:
		return
	var session = started.data
	_expect(int(session.get_sequence_state().data.get("current_sequence", 0)) == 9, "starts at sequence 9")
	var deck_snapshot = session.get_deck_snapshot()
	for card in deck_snapshot.data.get("cards", []):
		if String(card.get("definition_id", "")) in CLOWN_IDS:
			_expect(
				String(card.get("add_reason_code", "")) == "sequence_locked"
					or not bool(card.get("owned", false)),
				"%s should be locked or unowned before potion" % card.get("definition_id", "")
			)


func _test_grant_and_preset_after_potion() -> void:
	var started = AppBootstrapScript.start_route_v07(
		20261117,
		{
			"test_profile": true,
			"save_directory": "user://v040_clown_grant",
			"route_id": "route.v028.first_stage",
		},
		"v040_clown_grant",
		false
	)
	_expect(started.ok, "grant fixture should initialize")
	if not started.ok:
		return
	var session = started.data
	for _index in range(8):
		var result = session.record_card_performance(&"card.skill.dream_question")
		_expect(result.accepted, "digestion performance accepted")
	var potion = session.progression.grant_potion(&"potion.seer_to_clown")
	_expect(potion.accepted, "clown potion granted")
	var consumed = session.consume_potion(&"potion.seer_to_clown")
	_expect(consumed.accepted, "clown potion consumed")
	_expect(
		int(session.get_sequence_state().data.get("current_sequence", 0)) == 8,
		"sequence advances to 8"
	)
	var progression_data: Dictionary = session.get_progression_snapshot().data
	var owned_clown := 0
	for card_value in progression_data.get("collection", []):
		if not card_value is Dictionary:
			continue
		var definition_id := String(card_value.get("definition_id", ""))
		if definition_id in CLOWN_IDS and int(card_value.get("copies", 0)) > 0:
			owned_clown += 1
	_expect(owned_clown == CLOWN_IDS.size(), "all eight clown cards owned after grant")

	var deck_snapshot = session.get_deck_snapshot()
	_expect(
		String(deck_snapshot.data.get("selected_preset_id", "")) == "deck.preset.clown",
		"deck selects clown preset after potion"
	)
	_expect(bool(deck_snapshot.data.get("confirmed", false)), "clown deck confirmed after potion")
	_expect(bool(deck_snapshot.data.get("legal", false)), "clown deck legal after potion")
	for card in deck_snapshot.data.get("cards", []):
		var definition_id := String(card.get("definition_id", ""))
		if definition_id in CLOWN_IDS:
			_expect(bool(card.get("owned", false)), "%s owned in deck snapshot" % definition_id)
			_expect(
				String(card.get("add_reason_code", "")) != "sequence_locked",
				"%s sequence lock lifted" % definition_id
			)
	var clown_preset_ok := false
	for preset in deck_snapshot.data.get("presets", []):
		if String(preset.get("id", "")) == "deck.preset.clown":
			clown_preset_ok = bool(preset.get("legal", false))
			_expect(
				String(preset.get("display_name_zh", "")).contains("小丑"),
				"clown preset display name readable"
			)
	_expect(clown_preset_ok, "clown preset legal after grant")

	var pulled = session.submit_progression(ProgressionCommandScript.draw_gacha(1))
	_expect(pulled.accepted, "sequence 8 gacha still works")


func _test_forward_fill_preset_on_restore() -> void:
	var started = AppBootstrapScript.start_route_v07(
		20261118,
		{
			"test_profile": true,
			"save_directory": "user://v040_clown_restore",
			"route_id": "route.v028.first_stage",
		},
		"v040_clown_restore",
		false
	)
	_expect(started.ok, "restore fixture should initialize")
	if not started.ok:
		return
	var session = started.data
	var deck_state: Dictionary = session.deck_engine.export_persistent_state()
	var presets: Dictionary = deck_state.get("presets", {}).duplicate(true)
	presets.erase("deck.preset.clown")
	deck_state["presets"] = presets
	var restarted = AppBootstrapScript.start_route_v07(
		20261118,
		{
			"test_profile": true,
			"save_directory": "user://v040_clown_restore2",
			"route_id": "route.v028.first_stage",
			"deck_state": deck_state,
			"progression_state": session.progression.export_persistent_state(),
		},
		"v040_clown_restore2",
		false
	)
	_expect(restarted.ok, "old deck state without clown preset should forward-fill")
	if not restarted.ok:
		return
	var restored = restarted.data.get_deck_snapshot()
	var found := false
	for preset in restored.data.get("presets", []):
		if String(preset.get("id", "")) == "deck.preset.clown":
			found = true
			_expect(
				(preset.get("card_definition_ids", []) as Array).size() == 8,
				"forward-filled clown preset has eight cards"
			)
	_expect(found, "clown preset present after restore")


func _finish() -> void:
	if _failures.is_empty():
		print("V040_CLOWN_UNLOCK_OK checks=%d" % _checks)
		get_tree().quit(0)
		return
	for failure in _failures:
		printerr("V040_CLOWN_UNLOCK_FAIL %s" % failure)
	get_tree().quit(1)


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(message)
