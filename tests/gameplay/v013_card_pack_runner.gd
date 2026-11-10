extends Node

const BattleEngineScript := preload("res://src/gameplay/battle_engine.gd")
const BattleCommandScript := preload("res://src/core/battle_command.gd")
const BattleContentAdapterScript := preload(
	"res://src/infrastructure/battle_content_adapter.gd"
)
const BattleBalanceAdapterScript := preload(
	"res://src/infrastructure/battle_balance_adapter.gd"
)
const ProgressionCatalog := preload("res://src/ui/progression_ui_catalog.gd")
const DeckCatalog := preload("res://src/ui/deck_ui_catalog.gd")

const NEW_CARD_IDS: Array[String] = [
	"card.skill.dream_question",
	"card.skill.mirror_ward",
	"card.skill.severed_string",
	"card.skill.last_rites",
]

var _passed := 0
var _failures: Array[String] = []
var _content
var _balance


func _ready() -> void:
	var cards_document := _read_json("res://data/cards/v0.7.0/cards.json")
	var progression_document := _read_json(
		"res://data/cards/v0.7.0/progression.json"
	)
	var decks_document := _read_json("res://data/decks/v0.7.0/decks.json")
	var balance_document := _read_json(
		"res://data/balance/v0.7.0/balance.json"
	)
	var cards: Array = cards_document.get("cards", [])
	_expect(cards.size() == 40, "card pack should contain forty cards")
	var definition_ids: Dictionary = {}
	for definition in cards:
		definition_ids[String(definition.get("id", ""))] = true
	_expect(
		definition_ids.size() == 40,
		"all forty card definitions should have unique IDs"
	)
	_content = BattleContentAdapterScript.new(cards, cards_document.get("synergies", []))
	_balance = BattleBalanceAdapterScript.new(balance_document)
	for card_id in NEW_CARD_IDS:
		_expect(definition_ids.has(card_id), "new card should exist: %s" % card_id)
		_expect(
			ResourceLoader.exists(ProgressionCatalog.card_art(card_id))
			and ResourceLoader.exists(DeckCatalog.card_art(card_id)),
			"new card should have deck and collection art: %s" % card_id
		)
	var gacha_ids: Array[String] = []
	for item in progression_document.get("gacha_pool", []):
		gacha_ids.append(String(item.get("definition_id", "")))
	var catalog_ids: Array = decks_document.get(
		"card_catalog_definition_ids",
		[]
	)
	var presets: Array = decks_document.get("presets", [])
	_expect(presets.size() == 4, "deck content should expose four presets")
	var squad_preset: Dictionary = {}
	for preset in presets:
		if String(preset.get("id", "")) == "deck.preset.echo":
			squad_preset = preset
	_expect(not squad_preset.is_empty(), "值夜者小队 preset should exist")
	var squad_ids: Array = squad_preset.get("card_definition_ids", [])
	_expect(squad_ids.size() == 8, "值夜者小队 preset should contain eight unique cards")
	for card_id in [
		"card.skill.dream_question",
		"card.skill.mirror_ward",
		"card.skill.last_rites",
		"card.skill.eclipse",
	]:
		_expect(
			card_id in squad_ids,
			"值夜者小队 preset should use canon card: %s" % card_id
		)
	for card_id in NEW_CARD_IDS:
		_expect(card_id in gacha_ids, "new card should be in gacha pool: %s" % card_id)
		_expect(card_id in catalog_ids, "new card should be in deck catalog: %s" % card_id)
		_expect(
			progression_document.get("upgrade_definitions", {}).has(card_id),
			"new card should have an upgrade definition: %s" % card_id
		)
	_test_dream_question()
	_test_mirror_ward()
	_test_antigonus_puppet()
	_test_selena_ashes()
	_test_tyrell_warehouse_synergy()
	if _failures.is_empty():
		print("V013_CARD_PACK_OK checks=%d" % _passed)
		get_tree().quit(0)
		return
	for failure in _failures:
		printerr("V013_CARD_PACK_FAIL: %s" % failure)
	get_tree().quit(1)


func _test_dream_question() -> void:
	var engine = _engine(
		[&"card.skill.dream_question", &"card.skill.ink_dart"],
		[_enemy(12)],
		{}
	)
	var result = _play(engine, &"card.skill.dream_question", &"enemy.0")
	_expect(result.accepted, "梦境占卜 should be playable")
	_expect(
		int(result.snapshot.data.get("player", {}).get("spirit", 0)) == 2,
		"梦境占卜 should cost one spirit"
	)
	_expect(
		int(result.snapshot.data.get("chain", {}).get("count", -1)) == 1,
		"梦境占卜 should advance the chain"
	)
	var enemy: Dictionary = result.snapshot.data.get("enemies", [])[0]
	_expect(
		bool(enemy.get("intent", {}).get("revealed", false)),
		"梦境占卜 should reveal enemy intent"
	)
	_expect(_has_status(enemy, "mark", 1), "梦境占卜 should apply one mark")


func _test_mirror_ward() -> void:
	var engine = _engine(
		[&"card.skill.mirror_ward"],
		[_enemy(12)],
		{"attention": 3}
	)
	var result = _play(engine, &"card.skill.mirror_ward", &"enemy.0")
	var player: Dictionary = result.snapshot.data.get("player", {})
	_expect(int(player.get("spirit", 0)) == 3, "魔镜占卜 should cost no spirit")
	_expect(int(result.snapshot.data.get("chain", {}).get("count", -1)) == 0, "zero-cost 魔镜占卜 should not advance chain")
	_expect(int(player.get("attention", 0)) == 4, "魔镜占卜 should attract attention")
	var enemy: Dictionary = result.snapshot.data.get("enemies", [])[0]
	_expect(_has_status(enemy, "mark", 2), "魔镜占卜 should apply two marks")


func _test_antigonus_puppet() -> void:
	var engine = _engine(
		[&"card.skill.severed_string", &"card.skill.paper_guard"],
		[_enemy(20)],
		{}
	)
	var result = _play(engine, &"card.skill.severed_string", &"enemy.0")
	_expect(result.accepted, "2-049 should be playable")
	var enemy: Dictionary = result.snapshot.data.get("enemies", [])[0]
	_expect(_has_status(enemy, "bound", 2), "2-049 should bind for two turns")
	_expect(int(result.snapshot.data.get("exhaust_pile_count", 0)) == 1, "2-049 is single-use per battle")
	var hp_before := int(result.snapshot.data.get("player", {}).get("hp", 0))
	var ended = engine.submit(BattleCommandScript.end_turn())
	_expect(int(ended.snapshot.data.get("player", {}).get("hp", 0)) == hp_before, "bound enemy skips its attack")
	_expect(ended.events.any(func(event): return event.type == &"EnemyBound"), "binding is announced")
	_expect(int(ended.snapshot.data.get("player", {}).get("spirit", 0)) == 2, "2-049 slows its user: next turn spirit -1")


func _test_selena_ashes() -> void:
	var engine = _engine(
		[&"card.skill.last_rites"],
		[_enemy(20), _enemy(20, "enemy.1", 2)],
		{}
	)
	var result = _play(engine, &"card.skill.last_rites")
	_expect(result.accepted, "圣赛琳娜骨灰 should be playable without a target")
	for enemy in result.snapshot.data.get("enemies", []):
		_expect(_has_status(enemy, "bound", 2), "圣赛琳娜骨灰 binds every enemy")
		_expect(_has_status(enemy, "weaken", 2), "圣赛琳娜骨灰 weakens every enemy")
	_expect(int(result.snapshot.data.get("player", {}).get("attention", 0)) == 1, "opening the urn draws attention")


func _test_tyrell_warehouse_synergy() -> void:
	var engine = _engine(
		[&"card.skill.severed_string", &"card.skill.ink_dart"],
		[_enemy(30)],
		{}
	)
	_play(engine, &"card.skill.severed_string", &"enemy.0")
	var result = _play(engine, &"card.skill.ink_dart", &"enemy.0")
	var triggered := false
	for event in result.events:
		if event.type == &"SynergyTriggered" and String(event.data.get("synergy_id", "")) == "synergy.tyrell_warehouse":
			triggered = true
	_expect(triggered, "2-049 + 左轮 triggers 提利尔仓库")
	var enemy: Dictionary = result.snapshot.data.get("enemies", [])[0]
	# 5 base + 2 consumed marks + 3 vs bound + 8 synergy = 18
	_expect(int(enemy.get("hp", 0)) == 12, "提利尔仓库 resolves to 18 total damage (actual hp=%d)" % int(enemy.get("hp", 0)))


func _engine(
	deck: Array,
	enemies: Array,
	player_overrides: Dictionary
):
	var engine = BattleEngineScript.new()
	var player := {
		"actor_id": "player",
		"hp": 20,
		"max_hp": 20,
		"block": 0,
		"spirit": 3,
		"max_spirit": 3,
		"corruption": 0,
		"max_corruption": 10,
		"attention": 0,
		"max_attention": 10,
		"statuses": [],
	}
	for key in player_overrides:
		if String(key) != "starting_hand_override":
			player[String(key)] = player_overrides[key]
	var initialized = engine.initialize(
		_content,
		_balance,
		FakeRandom.new(20261108),
		&"battle.v013",
		player,
		deck,
		enemies
	)
	_expect(initialized.accepted, "new card battle should initialize")
	return engine


func _play(engine, definition_id: StringName, target_id: StringName = &""):
	var snapshot: Dictionary = engine.get_snapshot().to_dictionary()
	for card in snapshot.get("hand", []):
		if StringName(card.get("definition_id", "")) == definition_id:
			return engine.submit(BattleCommandScript.play_card(
				StringName(card.get("instance_id", "")),
				target_id
			))
	_expect(false, "card should be in hand: %s" % definition_id)
	return null


func _enemy(hp: int, actor_id: String = "enemy.0", lane: int = 0) -> Dictionary:
	return {
		"id": actor_id,
		"definition_id": "enemy.test",
		"lane_index": lane,
		"hp": hp,
		"max_hp": hp,
		"base_attack": 1,
	}


func _has_status(enemy: Dictionary, status_id: String, stacks: int) -> bool:
	for status in enemy.get("statuses", []):
		if (
			String(status.get("status_id", "")) == status_id
			and int(status.get("stacks", 0)) == stacks
		):
			return true
	return false


func _read_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	return parsed if parsed is Dictionary else {}


func _expect(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
	else:
		_failures.append(message)


class FakeRandom:
	extends BattleRandomPort

	var state := 1

	func _init(seed_value: int) -> void:
		state = maxi(1, seed_value)

	func next_int(max_exclusive: int) -> int:
		if max_exclusive <= 0:
			return 0
		state = (state * 1103515245 + 12345) & 0x7fffffff
		return state % max_exclusive
