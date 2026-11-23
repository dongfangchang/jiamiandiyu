extends Node

## v0.37.0: archive desk scanability — deck tiles/cost, preset face matchup,
## gacha empty-state copy, hub seal grid. No OptionButton on these screens.

const DeckScreenScene := preload("res://scenes/ui/deck_screen.tscn")
const GachaScreenScene := preload("res://scenes/ui/gacha_screen.tscn")
const IdentityScreenScene := preload("res://scenes/ui/identity_screen.tscn")
const DeckSnapshotScript := preload("res://src/core/deck_snapshot.gd")
const ProgressionSnapshotScript := preload("res://src/core/progression_snapshot.gd")

var _checks := 0
var _failures: Array[String] = []


func _ready() -> void:
	await get_tree().process_frame
	await _test_deck_desk()
	await _test_gacha_empty()
	await _test_hub_seals()
	_finish()


func _test_deck_desk() -> void:
	var screen = DeckScreenScene.instantiate()
	add_child(screen)
	await get_tree().process_frame
	screen.apply_snapshot(_guided_snapshot())
	await get_tree().process_frame
	_expect(_count_named(screen, "OptionButton") == 0, "deck screen has no OptionButton")
	var guidance: Dictionary = screen.get_preset_guidance("deck.preset.ward")
	_expect(not String(guidance.get("best_against", "")).is_empty(), "preset guidance best_against")
	_expect(not String(guidance.get("caution", "")).is_empty(), "preset guidance caution")
	var face_hits := 0
	for child in screen.get("_preset_row").get_children():
		face_hits += _count_label_containing(child, "适合：")
		face_hits += _count_label_containing(child, "慎用：")
	_expect(face_hits >= 2, "preset face shows 适合/慎用 lines")
	var cost_badges := _count_named(screen, "CostBadge")
	_expect(cost_badges > 0, "collection tiles expose CostBadge")
	var cost_pips := _count_named(screen, "CostPip")
	_expect(cost_pips >= 8, "deck rows expose CostPip for each slot")
	screen.queue_free()
	await get_tree().process_frame


func _test_gacha_empty() -> void:
	var screen = GachaScreenScene.instantiate()
	add_child(screen)
	await get_tree().process_frame
	_expect(_count_named(screen, "OptionButton") == 0, "gacha screen has no OptionButton")
	screen.apply_snapshot(ProgressionSnapshotScript.new({
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
		"gacha_history": [],
	}))
	await get_tree().process_frame
	_expect(screen.find_child("GachaEmptyPack", true, false) != null, "empty pack panel exists")
	_expect(screen.get_empty_state_text().contains("不足"), "empty state explains ticket shortage")

	screen.apply_snapshot(_gacha_result_snapshot(), true)
	await get_tree().process_frame
	_expect(screen.get_result_count() == 1, "result card rendered")
	var result_card := screen.find_child("GachaResultCard", true, false)
	_expect(result_card != null, "named result card exists")
	if result_card != null:
		_expect(result_card.find_child("RarityBanner", true, false) != null, "rarity banner present")
		_expect(result_card.find_child("OutcomeBadge", true, false) != null, "outcome badge present")
	screen.queue_free()
	await get_tree().process_frame


func _test_hub_seals() -> void:
	var screen = IdentityScreenScene.instantiate()
	add_child(screen)
	await get_tree().process_frame
	screen.apply_snapshot(ProgressionSnapshotScript.new({
		"revision": 1,
		"phase": "hub",
		"identity_id": "identity.reporter",
		"identity_options": [{
			"id": "identity.reporter",
			"display_name_zh": "记者",
			"description_zh": "用笔记录廷根的异常，并在白昼维持普通人的可信外表。",
			"selected": true,
			"battle_modifiers": {"starting_spirit_bonus": 1},
			"passive_text_zh": "开局多 1 灵性",
		}],
		"battle_modifiers": {},
		"divination_tickets": 3,
		"collection": [{"definition_id": "card.skill.ink_dart", "copies": 1}],
		"pity_counter": 1,
		"rare_pity": 4,
		"gacha_costs": {"single": 2, "triple": 5},
		"rarity_weights": {"common": 85, "rare": 15},
		"reward_options": [],
		"last_battle_outcome": "victory",
		"last_gacha_results": [],
	}))
	await get_tree().process_frame
	_expect(_count_named(screen, "OptionButton") == 0, "identity hub has no OptionButton")
	_expect(screen.find_child("HubSealGrid", true, false) != null, "hub seal grid exists")
	_expect(screen.has_hub_actions(), "hub actions present")
	_expect(screen.has_deck_action(), "deck action present")
	screen.queue_free()
	await get_tree().process_frame


func _gacha_result_snapshot():
	return ProgressionSnapshotScript.new({
		"revision": 2,
		"phase": "hub",
		"identity_id": "identity.reporter",
		"identity_options": [],
		"battle_modifiers": {},
		"divination_tickets": 4,
		"collection": [],
		"pity_counter": 0,
		"rare_pity": 4,
		"gacha_costs": {"single": 2, "triple": 5},
		"rarity_weights": {"common": 85, "rare": 15},
		"reward_options": [],
		"last_battle_outcome": "",
		"last_gacha_results": [{
			"definition_id": "card.skill.ink_dart",
			"rarity": "rare",
			"duplicate": false,
			"fragments": 0,
		}],
		"gacha_history": [{
			"draw_index": 1,
			"pull_count": 1,
			"results": [{
				"definition_id": "card.skill.ink_dart",
				"rarity": "rare",
				"duplicate": false,
				"fragments": 0,
			}],
		}],
	})


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
	for definition_id in current:
		cards.append({
			"definition_id": definition_id,
			"display_name_zh": definition_id,
			"description_zh": "测试卡",
			"rules_text_zh": "测试效果",
			"category": "skill",
			"cost_spirit": 1 + (definition_id.length() % 3),
			"target_type": "enemy",
			"owned": true,
			"in_deck": true,
			"can_add": true,
			"add_reason": "playable",
		})
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
		"presets": [{
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
		}],
		"available_commands": ["confirm_deck"],
	})


func _count_named(root: Node, type_or_name: String) -> int:
	var count := 0
	if root == null:
		return 0
	if root.get_class() == type_or_name or root.name == type_or_name:
		count += 1
	for child in root.get_children():
		count += _count_named(child, type_or_name)
	return count


func _count_label_containing(root: Node, needle: String) -> int:
	var count := 0
	if root is Label and String((root as Label).text).contains(needle):
		count += 1
	for child in root.get_children():
		count += _count_label_containing(child, needle)
	return count


func _finish() -> void:
	if _failures.is_empty():
		print("V037_ARCHIVE_DESK_OK checks=%d" % _checks)
		get_tree().quit(0)
		return
	for failure in _failures:
		printerr("V037_ARCHIVE_DESK_FAIL %s" % failure)
	get_tree().quit(1)


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(message)
