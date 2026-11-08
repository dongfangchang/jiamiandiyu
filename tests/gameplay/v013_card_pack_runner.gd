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
	_expect(cards.size() == 20, "card pack should contain twenty cards")
	var definition_ids: Dictionary = {}
	for definition in cards:
		definition_ids[String(definition.get("id", ""))] = true
	_expect(
		definition_ids.size() == 20,
		"all twenty card definitions should have unique IDs"
	)
	_content = BattleContentAdapterScript.new(cards)
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
	for card_id in NEW_CARD_IDS:
		_expect(card_id in gacha_ids, "new card should be in gacha pool: %s" % card_id)
		_expect(card_id in catalog_ids, "new card should be in deck catalog: %s" % card_id)
		_expect(
			progression_document.get("upgrade_definitions", {}).has(card_id),
			"new card should have an upgrade definition: %s" % card_id
		)
	_test_dream_question()
	_test_mirror_ward()
	_test_severed_string()
	_test_last_rites()
	if _failures.is_empty():
		print("V013_CARD_PACK_OK checks=%d" % _passed)
		get_tree().quit(0)
		return
	for failure in _failures:
		printerr("V013_CARD_PACK_FAIL: %s" % failure)
	get_tree().quit(1)


func _test_dream_question() -> void:
	var engine = _engine(
		[&"card.skill.dream_question"],
		[_enemy(12)],
		{}
	)
	var result = _play(engine, &"card.skill.dream_question", &"enemy.0")
	_expect(result.accepted, "梦问 should be playable")
	_expect(
		int(result.snapshot.data.get("player", {}).get("spirit", 0)) == 3,
		"梦问 should cost no spirit"
	)
	_expect(
		int(result.snapshot.data.get("chain", {}).get("count", -1)) == 0,
		"zero-cost 梦问 should not advance chain"
	)
	var enemy: Dictionary = result.snapshot.data.get("enemies", [])[0]
	_expect(
		bool(enemy.get("intent", {}).get("revealed", false)),
		"梦问 should reveal enemy intent"
	)
	_expect(
		_has_status(enemy, "mark", 1),
		"梦问 should apply one mark"
	)


func _test_mirror_ward() -> void:
	var engine = _engine(
		[&"card.skill.mirror_ward"],
		[_enemy(12)],
		{"attention": 3}
	)
	var result = _play(engine, &"card.skill.mirror_ward")
	var player: Dictionary = result.snapshot.data.get("player", {})
	_expect(int(player.get("block", 0)) == 6, "镜面替身 should grant six block")
	_expect(
		int(player.get("attention", 0)) == 2,
		"镜面替身 should reduce attention by one"
	)


func _test_severed_string() -> void:
	var engine = _engine(
		[&"card.skill.severed_string"],
		[_enemy(12)],
		{}
	)
	var result = _play(engine, &"card.skill.severed_string", &"enemy.0")
	var enemy: Dictionary = result.snapshot.data.get("enemies", [])[0]
	_expect(int(enemy.get("hp", 0)) == 7, "断线 should deal five damage")
	_expect(_has_status(enemy, "weaken", 2), "断线 should apply two weaken")


func _test_last_rites() -> void:
	var engine = _engine(
		[
			&"card.skill.last_rites",
			&"card.skill.last_rites",
			&"card.skill.last_rites",
			&"card.skill.last_rites",
			&"card.skill.last_rites",
			&"card.skill.last_rites",
		],
		[_enemy(30)],
		{"hp": 8, "starting_hand_override": 5}
	)
	var before_hand: int = engine.get_snapshot().data.get("hand", []).size()
	var result = _play(engine, &"card.skill.last_rites")
	var player: Dictionary = result.snapshot.data.get("player", {})
	_expect(int(player.get("hp", 0)) == 11, "临终圣礼 should heal three")
	var drew := false
	for event in result.events:
		if event.type == &"CardDrawn":
			drew = true
	_expect(
		drew and before_hand >= 5,
		"临终圣礼 should draw a card"
	)


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


func _enemy(hp: int) -> Dictionary:
	return {
		"id": "enemy.0",
		"definition_id": "enemy.test",
		"lane_index": 0,
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
