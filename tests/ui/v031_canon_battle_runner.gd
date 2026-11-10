extends Node

## v0.31.0: drives the real BattleEngine with real Tingen content (cards,
## synergies, enemies) into the real BattleScreen, verifies that boss phases,
## rituals and canon synergies are visible, and that none of the dynamic
## regions push the action controls around (ADR-0030). When run with a
## display it also writes window captures to .tools/ui-captures/v0.31.0/.

const BattleScreenScene := preload("res://scenes/ui/battle_screen.tscn")
const BattleEngineScript := preload("res://src/gameplay/battle_engine.gd")
const BattleCommandScript := preload("res://src/core/battle_command.gd")
const BattleContentAdapterScript := preload("res://src/infrastructure/battle_content_adapter.gd")
const BattleBalanceAdapterScript := preload("res://src/infrastructure/battle_balance_adapter.gd")
const CampaignContentCatalogScript := preload("res://src/infrastructure/campaign_content_catalog.gd")
const OUTPUT_DIRECTORY := "res://.tools/ui-captures/v0.31.0"

var _checks := 0
var _failures: Array[String] = []
var _cards_document: Dictionary
var _catalog


func _ready() -> void:
	_cards_document = _read_json("res://data/cards/v0.7.0/cards.json")
	_catalog = CampaignContentCatalogScript.new()
	var loaded = _catalog.load_from_documents(
		_cards_document,
		_read_json("res://data/enemies/v0.7.0/enemies.json"),
		_read_json("res://data/encounters/v0.7.0/encounters.json")
	)
	_expect(loaded.ok, "canon content catalog loads")
	if DisplayServer.get_name() != "headless":
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIRECTORY))
	for size in [Vector2i(1600, 900), Vector2i(1100, 700)]:
		await _run_megose(size)
	await _run_tyrell(Vector2i(1600, 900))
	_finish()


func _new_engine(encounter_id: String, deck: Array, seed_value: int):
	var resolved = _catalog.resolve_encounter(StringName(encounter_id))
	_expect(resolved.ok, "%s resolves" % encounter_id)
	var engine = BattleEngineScript.new()
	var content = BattleContentAdapterScript.new(
		_cards_document.get("cards", []),
		_cards_document.get("synergies", [])
	)
	var result = engine.initialize(
		content,
		BattleBalanceAdapterScript.new(_read_json("res://data/balance/v0.7.0/balance.json")),
		FixedRandom.new(seed_value),
		StringName("battle.%s" % encounter_id),
		{
			"actor_id": "player", "hp": 54, "max_hp": 54, "block": 0,
			"spirit": 3, "max_spirit": 3, "corruption": 2, "max_corruption": 10,
			"attention": 1, "max_attention": 10, "statuses": [],
		},
		deck,
		resolved.data.enemy_configs
	)
	_expect(result.accepted, "%s battle initializes" % encounter_id)
	return [engine, resolved.data]


func _mount(size: Vector2i, engine, encounter: Dictionary) -> Array:
	var viewport := SubViewport.new()
	viewport.size = size
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(viewport)
	var screen = BattleScreenScene.instantiate()
	viewport.add_child(screen)
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var labels := {}
	var details := {}
	for card in _cards_document.get("cards", []):
		labels[StringName(card.get("id", ""))] = String(card.get("display_name_zh", ""))
		var synergy_names: Array[String] = []
		for synergy in _cards_document.get("synergies", []):
			for group in synergy.get("requires", []):
				if String(card.get("id", "")) in group:
					synergy_names.append(String(synergy.get("display_name_zh", "")))
					break
		details[String(card.get("id", ""))] = {
			"name": String(card.get("display_name_zh", "")),
			"effect_text": String(card.get("rules_text_zh", "")),
			"category": String(card.get("category", "")),
			"exhaust": bool(card.get("exhaust", false)),
			"synergy_names": synergy_names,
			"source_zh": String(card.get("source_zh", "")),
		}
	var enemy_labels := {}
	for config in encounter.get("enemy_configs", []):
		enemy_labels[StringName(config.get("definition_id", ""))] = String(config.get("display_name_zh", ""))
	screen.configure(
		String(encounter.get("display_name_zh", "")),
		labels,
		enemy_labels,
		func(card_id: StringName, target_id: StringName) -> BattlePlayability:
			return engine.query_card_play(card_id, target_id),
		details
	)
	screen.apply_snapshot(engine.get_snapshot())
	await _frames(3)
	return [viewport, screen]


func _play(engine, screen, definition_id: String, target_id: String = "") -> BattleCommandResult:
	for card in engine.get_snapshot().data.get("hand", []):
		if String(card.get("definition_id", "")) == definition_id:
			var result = engine.submit(BattleCommandScript.play_card(
				StringName(card.get("instance_id", "")),
				StringName(target_id)
			))
			screen.apply_command_result(result)
			return result
	_expect(false, "card in hand: %s" % definition_id)
	return null


func _run_megose(size: Vector2i) -> void:
	var setup = _new_engine(
		"encounter.v070.broken_baron",
		[
			"card.skill.last_rites", "card.skill.eclipse", "card.skill.paper_guard",
			"card.skill.second_look", "card.skill.ink_dart", "card.skill.ink_scarlet",
			"card.skill.whisper", "card.skill.dream_question",
		],
		31
	)
	var engine = setup[0]
	var mounted = await _mount(size, engine, setup[1])
	var viewport: SubViewport = mounted[0]
	var screen = mounted[1]
	var boss_id := ""
	for enemy in engine.get_snapshot().data.get("enemies", []):
		boss_id = String(enemy.get("actor_id", ""))
	var before := _region_rects(screen)
	_expect(screen.get("_intel_title_label").text.contains("首领"), "boss intel banner names the boss at %s" % size)
	_expect(screen.get("_intel_detail_label").text.contains("下一阶段"), "boss intel shows the next phase trigger")
	# Push the boss through two HP phases with direct damage via cards.
	for _round in range(4):
		var snapshot: Dictionary = engine.get_snapshot().data
		if not String(snapshot.get("outcome", "")).is_empty():
			break
		for card in snapshot.get("hand", []):
			var definition_id := String(card.get("definition_id", ""))
			if int(card.get("cost_spirit", 0)) > int(engine.get_snapshot().data.get("player", {}).get("spirit", 0)):
				continue
			var target := boss_id if String(card.get("target_type", "")) == "enemy" else ""
			_play(engine, screen, definition_id, target)
			if not String(engine.get_snapshot().data.get("outcome", "")).is_empty():
				break
		await _frames(2)
		if String(engine.get_snapshot().data.get("outcome", "")).is_empty():
			screen.apply_command_result(engine.submit(BattleCommandScript.end_turn()))
			await _frames(2)
	var after := _region_rects(screen)
	for key in before:
		_expect(before[key] == after[key], "%s keeps its rect after phases/synergies at %s (%s -> %s)" % [key, size, before[key], after[key]])
	_expect(screen.get_banner_count() > 0, "phase or synergy banners were shown")
	if DisplayServer.get_name() != "headless":
		await get_tree().create_timer(3.2).timeout
		await RenderingServer.frame_post_draw
		viewport.get_texture().get_image().save_png(
			ProjectSettings.globalize_path(OUTPUT_DIRECTORY).path_join("battle_megose_%dx%d.png" % [size.x, size.y])
		)
	viewport.queue_free()
	await _frames(1)


func _run_tyrell(size: Vector2i) -> void:
	var setup = _new_engine(
		"encounter.mirror_pursuit",
		[
			"card.skill.severed_string", "card.skill.ink_dart", "card.skill.second_look",
			"card.skill.paper_guard", "card.skill.borrowed_breath",
		],
		7
	)
	var engine = setup[0]
	var mounted = await _mount(size, engine, setup[1])
	var viewport: SubViewport = mounted[0]
	var screen = mounted[1]
	var target := String(engine.get_snapshot().data.get("enemies", [])[0].get("actor_id", ""))
	var before := _region_rects(screen)
	_play(engine, screen, "card.skill.borrowed_breath")
	_play(engine, screen, "card.skill.severed_string", target)
	var result = _play(engine, screen, "card.skill.ink_dart", target)
	await _frames(2)
	_expect(
		result != null and result.events.any(func(event): return event.type == &"SynergyTriggered"),
		"提利尔仓库 triggers in the real battle"
	)
	_expect(screen.get_event_count() > 0, "battle log records the synergy")
	var synergy_rows: Array = screen.get("_synergy_list").get_children()
	_expect(not synergy_rows.is_empty(), "synergy panel lists the deck's canon combos")
	_expect(screen.get("_ritual_label").text.contains("1"), "ritual tracker shows the preparation stack")
	var after := _region_rects(screen)
	for key in before:
		_expect(before[key] == after[key], "%s keeps its rect after a synergy (%s -> %s)" % [key, before[key], after[key]])
	if DisplayServer.get_name() != "headless":
		await get_tree().create_timer(3.2).timeout
		await RenderingServer.frame_post_draw
		viewport.get_texture().get_image().save_png(
			ProjectSettings.globalize_path(OUTPUT_DIRECTORY).path_join("battle_tyrell_%dx%d.png" % [size.x, size.y])
		)
	viewport.queue_free()
	await _frames(1)


func _region_rects(screen: Node) -> Dictionary:
	var result := {}
	for node_name in ["BattleHeader", "BattleStatusStrip", "BattleMiddle", "BattlefieldPanel", "SidePanel", "HandPanel", "BossIntelPanel", "SynergyScroll", "BattleLogScroll", "SelectionBox"]:
		var node := screen.find_child(node_name, true, false) as Control
		_expect(node != null, "region %s exists" % node_name)
		if node != null:
			result[node_name] = Rect2(node.get_global_rect().position.round(), node.get_global_rect().size.round())
	var lanes_scroll := screen.find_child("EnemyStatusScroll", true, false) as ScrollContainer
	if lanes_scroll != null and screen.size.y >= 899.0:
		_expect(
			lanes_scroll.get_v_scroll_bar().max_value <= lanes_scroll.get_v_scroll_bar().page + 1.0,
			"enemy lanes fit their area at 1600x900 (target buttons never hidden)"
		)
	var end_turn: Button = screen.get("_end_turn_button")
	result["EndTurnButton"] = Rect2(end_turn.get_global_rect().position.round(), end_turn.get_global_rect().size.round())
	return result


func _frames(count: int) -> void:
	for _index in range(count):
		await get_tree().process_frame


func _read_json(path: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}


func _finish() -> void:
	if _failures.is_empty():
		print("V031_CANON_BATTLE_OK checks=%d" % _checks)
		get_tree().quit(0)
		return
	for failure in _failures:
		printerr("V031_CANON_BATTLE_FAIL %s" % failure)
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
