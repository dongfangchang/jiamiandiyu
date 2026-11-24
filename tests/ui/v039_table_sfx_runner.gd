extends Node

const UiContentFixture := preload("res://tests/ui/ui_content_fixture.gd")

## v0.39.0: procedural table SFX facade + mute + start-screen ops hint.

const TableSfx := preload("res://src/ui/table_sfx.gd")
const StartScreenScene := preload("res://scenes/ui/start_screen.tscn")
const BattleScreenScene := preload("res://scenes/ui/battle_screen.tscn")
const BattleEngineScript := preload("res://src/gameplay/battle_engine.gd")
const BattleContentAdapterScript := preload("res://src/infrastructure/battle_content_adapter.gd")
const BattleBalanceAdapterScript := preload("res://src/infrastructure/battle_balance_adapter.gd")
const CampaignContentCatalogScript := preload("res://src/infrastructure/campaign_content_catalog.gd")
const BattlePlayability := preload("res://src/core/battle_playability.gd")
const PlayerPreferencesServiceScript := preload("res://src/infrastructure/player_preferences_service.gd")

var _checks := 0
var _failures: Array[String] = []


func _ready() -> void:
	UiContentFixture.ensure()
	await get_tree().process_frame
	_test_tone_facade()
	_test_preferences_normalize()
	await _test_start_ops_hint()
	await _test_battle_card_sfx()
	_finish()


func _test_tone_facade() -> void:
	TableSfx.reset_for_tests()
	TableSfx.set_muted(true)
	TableSfx.play(self, TableSfx.KIND_CARD_PLAY)
	TableSfx.play(self, TableSfx.KIND_DAMAGE)
	_expect(TableSfx.call_count() == 2, "muted plays still counted")
	_expect(TableSfx.call_count(TableSfx.KIND_CARD_PLAY) == 1, "card_play counted")
	_expect(TableSfx.is_muted(), "mute flag set")
	TableSfx.set_muted(false)
	TableSfx.play(self, TableSfx.KIND_SEAL)
	_expect(TableSfx.call_count(TableSfx.KIND_SEAL) == 1, "unmuted seal counted")
	var stream: AudioStreamWAV = TableSfx._tone_for(TableSfx.KIND_FLIP)
	_expect(stream != null and stream.data.size() > 0, "procedural tone has samples")


func _test_preferences_normalize() -> void:
	var service = PlayerPreferencesServiceScript.new("user://v039_prefs_test.json")
	var normalized: Dictionary = service._normalize({"mute_sfx": true, "ui_scale": 1.0})
	_expect(bool(normalized.get("mute_sfx", false)), "preferences keep mute_sfx")


func _test_start_ops_hint() -> void:
	var screen = StartScreenScene.instantiate()
	add_child(screen)
	await get_tree().process_frame
	screen.open_settings()
	await get_tree().process_frame
	var hint := screen.find_child("OpsHint", true, false) as Label
	var mute := screen.find_child("MuteSfxToggle", true, false)
	_expect(hint != null and hint.text.contains("拖放"), "ops hint mentions drag")
	_expect(mute != null, "mute sfx toggle exists in settings")
	screen.queue_free()
	await get_tree().process_frame


func _test_battle_card_sfx() -> void:
	TableSfx.reset_for_tests()
	var cards_document: Dictionary = _read_json("res://data/cards/v0.7.0/cards.json")
	var catalog = CampaignContentCatalogScript.new()
	var loaded = catalog.load_from_documents(
		cards_document,
		_read_json("res://data/enemies/v0.7.0/enemies.json"),
		_read_json("res://data/encounters/v0.7.0/encounters.json")
	)
	_expect(loaded.ok, "catalog loads")
	var resolved = catalog.resolve_encounter(&"encounter.first_hunt")
	_expect(resolved.ok, "encounter resolves")
	var engine = BattleEngineScript.new()
	var content = BattleContentAdapterScript.new(
		cards_document.get("cards", []),
		cards_document.get("synergies", [])
	)
	var init_result = engine.initialize(
		content,
		BattleBalanceAdapterScript.new(_read_json("res://data/balance/v0.7.0/balance.json")),
		FixedRandom.new(39),
		&"battle.v039.sfx",
		{
			"actor_id": "player", "hp": 54, "max_hp": 54, "block": 0,
			"spirit": 3, "max_spirit": 3, "corruption": 0, "max_corruption": 10,
			"attention": 0, "max_attention": 10, "statuses": [],
		},
		[
			"card.skill.ink_dart",
			"card.skill.paper_guard",
			"card.skill.calm_breath",
			"card.skill.focus",
			"card.skill.insight",
			"card.skill.omen",
			"card.skill.whisper",
			"card.skill.second_look",
		],
		resolved.data.enemy_configs
	)
	_expect(init_result.accepted, "battle initializes")
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1600, 900)
	add_child(viewport)
	var screen = BattleScreenScene.instantiate()
	viewport.add_child(screen)
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var labels := {}
	var details := {}
	for card in cards_document.get("cards", []):
		labels[StringName(card.get("id", ""))] = String(card.get("display_name_zh", ""))
		details[String(card.get("id", ""))] = {
			"name": String(card.get("display_name_zh", "")),
			"effect_text": String(card.get("rules_text_zh", "")),
		}
	var enemy_labels := {}
	for config in resolved.data.get("enemy_configs", []):
		enemy_labels[StringName(config.get("definition_id", ""))] = String(
			config.get("display_name_zh", "")
		)
	screen.configure(
		"v039 sfx",
		labels,
		enemy_labels,
		func(card_id: StringName, target_id: StringName, discard_ids: Array) -> BattlePlayability:
			return engine.query_card_play(card_id, target_id, discard_ids),
		details
	)
	screen.apply_snapshot(engine.get_snapshot())
	await get_tree().process_frame
	# Select focus to activate altar sfx path.
	var focus_id := StringName("")
	for card in engine.get_snapshot().data.get("hand", []):
		if String(card.get("definition_id", "")) == "card.skill.focus":
			focus_id = StringName(card.get("instance_id", ""))
			break
	if not focus_id.is_empty():
		screen.select_card_instance(focus_id, false)
		await get_tree().process_frame
		_expect(
			TableSfx.call_count(TableSfx.KIND_ALTAR) >= 1,
			"selecting discard-cost card plays altar sfx"
		)
	viewport.queue_free()
	await get_tree().process_frame


func _read_json(path: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}


func _finish() -> void:
	if _failures.is_empty():
		print("V039_TABLE_SFX_OK checks=%d" % _checks)
		get_tree().quit(0)
		return
	for failure in _failures:
		printerr("V039_TABLE_SFX_FAIL %s" % failure)
	get_tree().quit(1)


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(message)


class FixedRandom:
	extends BattleRandomPort

	var state := 1

	func _init(seed_value: int) -> void:
		state = maxi(1, seed_value)

	func next_int(max_exclusive: int) -> int:
		if max_exclusive <= 0:
			return 0
		state = (state * 1103515245 + 12345) & 0x7fffffff
		return state % max_exclusive
