extends Node

const DeckScreenScene := preload("res://scenes/ui/deck_screen.tscn")
const ChallengeHubScene := preload("res://scenes/ui/challenge_hub_screen.tscn")
const ChallengeScreenScene := preload("res://scenes/ui/challenge_screen.tscn")
const IdentityScreenScene := preload("res://scenes/ui/identity_screen.tscn")
const DeckSnapshotScript := preload("res://src/core/deck_snapshot.gd")
const DeckCommandResultScript := preload("res://src/core/deck_command_result.gd")
const ProgressionSnapshotScript := preload("res://src/core/progression_snapshot.gd")
const ChallengeSnapshotScript := preload("res://src/core/challenge_snapshot.gd")

var _checks := 0
var _failures: Array[String] = []
var _captured_command := ""
var _captured_definition_id := ""
var _captured_preset_id := ""
var _captured_challenge_id := ""
var _deck_requests := 0


func _ready() -> void:
	await get_tree().process_frame
	_test_assets()
	await _test_deck_screen()
	await _test_identity_deck_entry()
	await _test_challenge_hub()
	await _test_second_challenge_screen()
	_finish()


func _test_assets() -> void:
	var paths := [
		"res://assets/game/v0.7.0/scenes/deck_archive.png",
		"res://assets/game/v0.7.0/icons/challenge_broken_procession.png",
		"res://assets/game/v0.7.0/icons/modifier_obituary_echo.png",
		"res://assets/game/v0.7.0/icons/modifier_twin_shadow.png",
		"res://assets/game/v0.7.0/icons/modifier_ritual_vigil.png",
		"res://assets/game/v0.7.0/cards/card_skill_warding_circle.png",
		"res://assets/game/v0.7.0/cards/card_skill_lantern_step.png",
		"res://assets/game/v0.7.0/cards/card_skill_whispered_hunch.png",
		"res://assets/game/v0.7.0/cards/card_skill_mirrored_memory.png",
		"res://assets/game/v0.7.0/cards/card_skill_fated_echo.png",
		"res://assets/game/v0.7.0/cards/card_skill_piercing_omen.png",
		"res://assets/game/v0.7.0/cards/card_skill_coffin_nail.png",
		"res://assets/game/v0.7.0/cards/card_skill_second_sight.png",
	]
	for path in paths:
		_expect(ResourceLoader.exists(path), "v0.7 UI art exists: %s" % path)


func _test_deck_screen() -> void:
	var screen = DeckScreenScene.instantiate()
	add_child(screen)
	await get_tree().process_frame
	screen.deck_command_requested.connect(func(command: DeckCommand) -> void:
		_captured_command = String(command.type)
		_captured_definition_id = String(command.definition_id)
		_captured_preset_id = String(command.preset_id)
	)
	var deck = _deck_snapshot()
	screen.apply_snapshot(deck)
	screen.set_progression_snapshot(_progression_snapshot())
	_expect(screen.get_background_path().ends_with("deck_archive.png"), "deck archive art resolves")
	_expect(screen.get_total_card_count() == 16, "deck screen renders full 16-card pool")
	_expect(screen.get_card_count() == 16, "all filter shows every card")
	_expect(screen.get_preset_count() == 3, "deck screen renders three presets")
	_expect(screen.get_current_deck_count() == 8, "deck screen renders eight current cards")
	_expect(screen.get_selected_preset_id() == "deck.preset.ward", "deck screen retains selected preset")
	_expect(screen.is_confirm_enabled(), "legal snapshot enables confirm")

	screen.set_filter("owned")
	_expect(screen.get_card_count() == 8, "owned filter reads snapshot ownership")
	screen.set_filter("unowned")
	_expect(screen.get_card_count() == 8, "unowned filter reads snapshot ownership")
	screen.set_filter("deck")
	_expect(screen.get_card_count() == 8, "deck filter reads current ids")
	screen.set_filter("all")

	_captured_command = ""
	screen.request_add_card("card.skill.warding_circle")
	_expect(screen.is_pending(), "deck command enters pending")
	_expect(_captured_command == "add_card", "deck add emits stable command")
	_expect(_captured_definition_id == "card.skill.warding_circle", "deck add emits stable id")
	screen.apply_command_result(DeckCommandResultScript.new(
		false,
		&"wrong_deck_size",
		[],
		deck
	))
	_expect(not screen.is_pending(), "deck rejection clears pending")
	_expect(screen.get_status_text().contains("必须为 8 张"), "deck rejection reason is readable")

	_captured_command = ""
	screen.request_select_preset("deck.preset.oracle")
	_expect(_captured_command == "select_preset", "preset selection emits command")
	_expect(_captured_preset_id == "deck.preset.oracle", "preset selection emits stable id")
	screen.set_pending(false)

	_captured_command = ""
	screen.request_confirm_deck()
	_expect(_captured_command == "confirm_deck", "confirmed legal deck emits command")
	screen.queue_free()
	await get_tree().process_frame


func _test_identity_deck_entry() -> void:
	var screen = IdentityScreenScene.instantiate()
	add_child(screen)
	await get_tree().process_frame
	screen.deck_requested.connect(func() -> void: _deck_requests += 1)
	screen.apply_snapshot(_progression_snapshot())
	screen.set_deck_snapshot(_deck_snapshot())
	_expect(screen.has_deck_action(), "hub exposes deck editor entry")
	_expect(screen.get_deck_summary_text().contains("8 / 8"), "hub shows current deck size")
	_deck_requests = 0
	screen.deck_requested.emit()
	_expect(_deck_requests == 1, "deck entry signal is connected")
	screen.queue_free()
	await get_tree().process_frame


func _test_challenge_hub() -> void:
	var screen = ChallengeHubScene.instantiate()
	add_child(screen)
	await get_tree().process_frame
	screen.challenge_selected.connect(func(challenge_id: StringName) -> void:
		_captured_challenge_id = String(challenge_id)
	)
	screen.apply_snapshots([
		_challenge_snapshot({}),
		_challenge_snapshot({
			"challenge_id": "challenge.v070.broken_procession",
			"display_name_zh": "破碎游行",
			"phase": "locked",
			"unlocked": false,
			"route_id": "route.v070.broken_procession",
			"required_challenge_ids": ["challenge.v060.mirror_echoes"],
		}),
	])
	_expect(screen.get_challenge_count() == 2, "challenge hub renders both challenges")
	_expect(screen.get_unlocked_count() == 1, "challenge hub reads unlock state")
	_expect(screen.is_challenge_enabled("challenge.v060.mirror_echoes"), "first challenge is enabled")
	_expect(not screen.is_challenge_enabled("challenge.v070.broken_procession"), "second challenge remains locked")
	_captured_challenge_id = ""
	screen.request_challenge("challenge.v070.broken_procession")
	_expect(_captured_challenge_id.is_empty(), "locked second challenge emits no command")
	_expect(screen.get_status_text().contains("镜厅余响"), "lock reason names required challenge")

	screen.apply_snapshots([
		_challenge_snapshot({}),
		_challenge_snapshot({
			"challenge_id": "challenge.v070.broken_procession",
			"display_name_zh": "破碎游行",
			"unlocked": true,
			"route_id": "route.v070.broken_procession",
			"required_challenge_ids": ["challenge.v060.mirror_echoes"],
		}),
	])
	_expect(screen.is_challenge_enabled("challenge.v070.broken_procession"), "completed prerequisite unlocks second challenge")
	screen.request_challenge("challenge.v070.broken_procession")
	_expect(_captured_challenge_id == "challenge.v070.broken_procession", "challenge hub emits stable id")
	screen.queue_free()
	await get_tree().process_frame


func _test_second_challenge_screen() -> void:
	var screen = ChallengeScreenScene.instantiate()
	add_child(screen)
	await get_tree().process_frame
	screen.apply_snapshot(_challenge_snapshot({
		"challenge_id": "challenge.v070.broken_procession",
		"display_name_zh": "破碎游行",
		"description_zh": "双影与双首领组成第二条挑战路线。",
		"route_id": "route.v070.broken_procession",
		"required_challenge_ids": ["challenge.v060.mirror_echoes"],
		"modifiers": _v07_modifiers(),
	}))
	_expect(screen.get_challenge_title() == "破碎游行", "second challenge title is snapshot driven")
	_expect(screen.get_route_text().contains("破碎游行"), "second route variant is visible")
	_expect(screen.get_emblem_path().ends_with("challenge_broken_procession.png"), "second challenge emblem resolves")
	_expect(screen.get_modifier_count() == 3, "second challenge renders three modifiers")
	screen.queue_free()
	await get_tree().process_frame


func _deck_snapshot() -> DeckSnapshot:
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
	for index in range(_card_ids().size()):
		var definition_id: String = _card_ids()[index]
		cards.append({
			"definition_id": definition_id,
			"display_name_zh": _card_name(definition_id),
			"description_zh": "用于 UI 验证的卡牌描述。",
			"category": "skill",
			"cost_spirit": index % 3,
			"target_type": (
				"enemy"
				if index % 3 != 1
				else "self"
			),
			"owned": index < 8,
			"in_deck": definition_id in current,
		})
	var presets: Array = [
		{
			"id": "deck.preset.ward",
			"display_name_zh": "守夜档案",
			"description_zh": "护盾与稳定抽牌。",
			"card_definition_ids": current,
			"legal": true,
			"reason_code": "playable",
			"selected": true,
		},
		{
			"id": "deck.preset.oracle",
			"display_name_zh": "灵性预感",
			"description_zh": "灵性与抽牌。",
			"card_definition_ids": current,
			"legal": true,
			"reason_code": "playable",
			"selected": false,
		},
		{
			"id": "deck.preset.burst",
			"display_name_zh": "棺钉凶兆",
			"description_zh": "标记爆发。",
			"card_definition_ids": current,
			"legal": true,
			"reason_code": "playable",
			"selected": false,
		},
	]
	return DeckSnapshotScript.new({
		"revision": 5,
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


func _progression_snapshot() -> ProgressionSnapshot:
	var collection: Array = []
	for index in range(8):
		collection.append({
			"definition_id": _card_ids()[index],
			"copies": 1,
			"level": index % 3,
			"fragments": 6,
			"max_level": 3,
			"next_upgrade_cost": 6,
		})
	return ProgressionSnapshotScript.new({
		"phase": "hub",
		"identity_id": "identity.reporter",
		"identity_options": [
			{
				"id": "identity.reporter",
				"display_name_zh": "记者",
				"description_zh": "调查档案。",
				"battle_modifiers": {"starting_attention": -1},
				"selected": true,
			},
		],
		"collection": collection,
		"divination_tickets": 7,
		"pity_counter": 2,
		"rare_pity": 4,
	})


func _challenge_snapshot(overrides: Dictionary) -> ChallengeSnapshot:
	var data := {
		"revision": 4,
		"challenge_id": "challenge.v060.mirror_echoes",
		"display_name_zh": "镜厅余响",
		"description_zh": "第一场挑战。",
		"phase": "modifier_selection",
		"unlocked": true,
		"required_sequence": 8,
		"required_challenge_ids": [],
		"completed_challenge_ids": [],
		"selected_modifier_id": "",
		"selected_modifier": {},
		"route_id": "route.v070.first_case",
		"modifiers": _v06_modifiers(),
		"completion_reward": {"reward.divination_tickets": 2},
		"challenge_outcome": "",
		"route": {},
		"sequence": {"current_sequence": 8, "advancement_state": "completed"},
		"available_commands": ["select_modifier"],
	}
	for key in overrides:
		data[key] = overrides[key]
	return ChallengeSnapshotScript.new(data)


func _v06_modifiers() -> Array:
	return [
		{"id": "modifier.rushed_reflection", "display_name_zh": "倒影提前", "description_zh": "阶段提前。", "effects": {"phase_round_delta": -2}},
		{"id": "modifier.tainted_margins", "display_name_zh": "染墨页边", "description_zh": "污染上升。", "effects": {"battle_corruption_delta": 2}},
		{"id": "modifier.fractured_deck", "display_name_zh": "残缺牌组", "description_zh": "移除防御牌。", "effects": {"remove_definition_ids": ["card.skill.paper_guard"]}},
	]


func _v07_modifiers() -> Array:
	return [
		{"id": "modifier.obituary_echo", "display_name_zh": "讣告回声", "description_zh": "污染与额外奖励。", "effects": {"starting_corruption_delta": 2}},
		{"id": "modifier.twin_shadow", "display_name_zh": "双影同行", "description_zh": "被注视与额外奖励。", "effects": {"starting_attention_delta": 2}},
		{"id": "modifier.ritual_vigil", "display_name_zh": "通宵守仪", "description_zh": "阶段提前与灵性上限。", "effects": {"phase_round_delta": -1}},
	]


func _card_ids() -> Array[String]:
	return [
		"card.skill.ink_dart",
		"card.skill.paper_guard",
		"card.skill.calm_breath",
		"card.skill.focus",
		"card.skill.insight",
		"card.skill.second_look",
		"card.skill.omen",
		"card.skill.whisper",
		"card.skill.warding_circle",
		"card.skill.lantern_step",
		"card.skill.whispered_hunch",
		"card.skill.mirrored_memory",
		"card.skill.fated_echo",
		"card.skill.piercing_omen",
		"card.skill.coffin_nail",
		"card.skill.second_sight",
	]


func _card_name(definition_id: String) -> String:
	var names := {
		"card.skill.ink_dart": "墨刺",
		"card.skill.paper_guard": "纸符护持",
		"card.skill.calm_breath": "静息",
		"card.skill.focus": "凝神",
		"card.skill.insight": "洞察",
		"card.skill.second_look": "再看一眼",
		"card.skill.omen": "凶兆",
		"card.skill.whisper": "低语",
		"card.skill.warding_circle": "守夜圆环",
		"card.skill.lantern_step": "提灯步",
		"card.skill.whispered_hunch": "灵性预感",
		"card.skill.mirrored_memory": "镜中记忆",
		"card.skill.fated_echo": "命运回声",
		"card.skill.piercing_omen": "穿刺凶兆",
		"card.skill.coffin_nail": "棺钉",
		"card.skill.second_sight": "第二视觉",
	}
	return String(names.get(definition_id, definition_id))


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("V07_DECK_UI_SMOKE_OK checks=%d" % _checks)
		get_tree().quit(0)
		return
	for failure in _failures:
		printerr("V07_DECK_UI_SMOKE_FAIL %s" % failure)
	print("V07_DECK_UI_SMOKE_FAIL checks=%d failures=%d" % [
		_checks,
		_failures.size(),
	])
	get_tree().quit(1)
