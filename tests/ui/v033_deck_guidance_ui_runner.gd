extends Node

## v0.33.0 UI: preset cards show 适合 / 慎用 from snapshot fields.

const DeckScreenScene := preload("res://scenes/ui/deck_screen.tscn")
const DeckSnapshotScript := preload("res://src/core/deck_snapshot.gd")
const ProgressionSnapshotScript := preload("res://src/core/progression_snapshot.gd")

var _checks := 0
var _failures: Array[String] = []


func _ready() -> void:
	await get_tree().process_frame
	await _test_guidance_render()
	await _test_sequence_locked_reason()
	_finish()


func _test_guidance_render() -> void:
	var screen = DeckScreenScene.instantiate()
	add_child(screen)
	await get_tree().process_frame
	screen.apply_snapshot(_guided_snapshot())
	screen.set_progression_snapshot(_progression_snapshot())
	await get_tree().process_frame
	for preset_id in [
		"deck.preset.ward",
		"deck.preset.oracle",
		"deck.preset.burst",
		"deck.preset.echo",
	]:
		var guidance: Dictionary = screen.get_preset_guidance(preset_id)
		_expect(not String(guidance.get("tag", "")).is_empty(), "%s tag visible" % preset_id)
		_expect(not String(guidance.get("best_against", "")).is_empty(), "%s best_against visible" % preset_id)
		_expect(not String(guidance.get("caution", "")).is_empty(), "%s caution visible" % preset_id)
		_expect(not String(guidance.get("when", "")).is_empty(), "%s combo focus visible" % preset_id)
	var echo: Dictionary = screen.get_preset_guidance("deck.preset.echo")
	_expect(
		String(echo.get("best_against", "")).contains("梅高欧丝")
			or String(echo.get("best_against", "")).contains("老尼尔"),
		"echo UI surfaces boss guidance"
	)
	screen.queue_free()
	await get_tree().process_frame


func _test_sequence_locked_reason() -> void:
	var screen = DeckScreenScene.instantiate()
	add_child(screen)
	await get_tree().process_frame
	var snapshot: Variant = _guided_snapshot()
	var data: Dictionary = snapshot.data.duplicate(true)
	for card_value in data.get("cards", []):
		if String(card_value.get("definition_id", "")) == "card.skill.hollow_bell":
			card_value["owned"] = true
			card_value["can_add"] = false
			card_value["add_reason"] = "sequence_locked"
			card_value["required_sequence"] = 8
	screen.apply_snapshot(DeckSnapshotScript.new(data))
	await get_tree().process_frame
	var DeckCatalog = load("res://src/ui/deck_ui_catalog.gd")
	_expect(
		String(DeckCatalog.reason_text("sequence_locked")).contains("序列"),
		"sequence_locked reason stays Chinese"
	)
	screen.queue_free()
	await get_tree().process_frame


func _guided_snapshot():
	var current := [
		"card.skill.ink_dart",
		"card.skill.paper_guard",
		"card.skill.calm_breath",
		"card.skill.focus",
		"card.skill.insight",
		"card.skill.second_look",
		"card.skill.warding_circle",
		"card.skill.lantern_step",
	]
	var cards: Array = []
	for definition_id in current + ["card.skill.hollow_bell"]:
		cards.append({
			"definition_id": definition_id,
			"display_name_zh": definition_id,
			"description_zh": "测试卡",
			"rules_text_zh": "测试效果",
			"category": "skill",
			"cost_spirit": 1,
			"target_type": "enemy",
			"owned": definition_id in current,
			"in_deck": definition_id in current,
			"can_add": definition_id in current,
			"add_reason": "playable" if definition_id in current else "card_not_owned",
		})
	var presets := [
		{
			"id": "deck.preset.ward",
			"display_name_zh": "值夜者制式装备",
			"description_zh": "先看清意图再开枪。",
			"strategy_tag_zh": "稳守 / 射击",
			"best_against_zh": "前半普通战",
			"caution_zh": "高压首领缺少封印物爆发",
			"combo_focus_zh": "灵视后射击",
			"card_definition_ids": current,
			"legal": true,
			"reason_code": "playable",
			"selected": true,
		},
		{
			"id": "deck.preset.oracle",
			"display_name_zh": "仪式魔法",
			"description_zh": "叠仪式再兑现。",
			"strategy_tag_zh": "仪式 / 兑现",
			"best_against_zh": "灵体与不死",
			"caution_zh": "叠不起仪式会断档",
			"combo_focus_zh": "准备后驱邪",
			"card_definition_ids": current,
			"legal": true,
			"reason_code": "playable",
			"selected": false,
		},
		{
			"id": "deck.preset.burst",
			"display_name_zh": "提利尔仓库",
			"description_zh": "束缚后集火。",
			"strategy_tag_zh": "控制 / 联动",
			"best_against_zh": "需要束缚的精英",
			"caution_zh": "单场一次打错目标",
			"combo_focus_zh": "2-049 后左轮",
			"card_definition_ids": current,
			"legal": true,
			"reason_code": "playable",
			"selected": false,
		},
		{
			"id": "deck.preset.echo",
			"display_name_zh": "值夜者小队",
			"description_zh": "队友与封印物。",
			"strategy_tag_zh": "队友 / 封印物",
			"best_against_zh": "失控的老尼尔、梅高欧丝",
			"caution_zh": "高费须为守护者留费",
			"combo_focus_zh": "骨灰 + 阳炎",
			"card_definition_ids": current,
			"legal": true,
			"reason_code": "playable",
			"selected": false,
		},
	]
	return DeckSnapshotScript.new({
		"revision": 1,
		"phase": "ready",
		"required_deck_size": 8,
		"current_card_ids": current,
		"current_deck_size": 8,
		"legal": true,
		"reason_code": "playable",
		"selected_preset_id": "deck.preset.ward",
		"default_preset_id": "deck.preset.ward",
		"confirmed": true,
		"cards": cards,
		"presets": presets,
		"available_commands": ["confirm_deck"],
	})


func _progression_snapshot():
	return ProgressionSnapshotScript.new({
		"revision": 1,
		"phase": "hub",
		"identity_id": "identity.reporter",
		"identity_options": [],
		"battle_modifiers": {},
		"divination_tickets": 0,
		"collection": [],
		"pity_counter": 0,
		"rare_pity": 4,
		"gacha_costs": {"single": 2, "triple": 5},
		"rarity_weights": {"common": 85, "rare": 15},
		"reward_options": [],
		"last_battle_outcome": "",
		"last_gacha_results": [],
	})


func _finish() -> void:
	if _failures.is_empty():
		print("V033_DECK_GUIDANCE_UI_OK checks=%d" % _checks)
		get_tree().quit(0)
		return
	for failure in _failures:
		printerr("V033_DECK_GUIDANCE_UI_FAIL %s" % failure)
	get_tree().quit(1)


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(message)
