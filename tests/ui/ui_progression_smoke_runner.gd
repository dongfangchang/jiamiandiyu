extends Node

const IdentityScreenScene := preload("res://scenes/ui/identity_screen.tscn")
const RewardScreenScene := preload("res://scenes/ui/reward_screen.tscn")
const GachaScreenScene := preload("res://scenes/ui/gacha_screen.tscn")
const UpgradeScreenScene := preload("res://scenes/ui/upgrade_screen.tscn")
const ProgressionSnapshotScript := preload("res://src/core/progression_snapshot.gd")
const ProgressionCommandResultScript := preload("res://src/core/progression_command_result.gd")

var _checks := 0
var _failures: Array[String] = []
var _captured_identity := ""
var _captured_reward := ""
var _captured_pull_count := 0
var _captured_upgrade := ""


func _ready() -> void:
	await get_tree().process_frame
	await _test_assets()
	await _test_identity_and_hub()
	await _test_reward()
	await _test_gacha()
	await _test_upgrade()
	_finish()


func _test_assets() -> void:
	var paths := [
		"res://assets/game/v0.4.0/identities/card-identity-reporter.png",
		"res://assets/game/v0.4.0/identities/card-identity-doctor.png",
		"res://assets/game/v0.4.0/identities/card-identity-gravedigger.png",
		"res://assets/game/v0.4.0/scenes/gacha-altar.png",
		"res://assets/game/v0.4.0/scenes/reward-archive.png",
		"res://assets/game/v0.4.0/cards/card-back-sealed-omen.png",
		"res://assets/game/v0.4.0/icons/divination-ticket.png",
		"res://assets/game/v0.4.0/icons/card-shard.png",
		"res://assets/game/v0.4.0/icons/upgrade-1.png",
		"res://assets/game/v0.4.0/icons/upgrade-2.png",
		"res://assets/game/v0.4.0/icons/upgrade-3.png",
		"res://assets/game/v0.3.0/cards/card-skill-ink-dart.png",
	]
	for path in paths:
		_expect(ResourceLoader.exists(path), "formal UI art exists: %s" % path)


func _test_identity_and_hub() -> void:
	var screen = IdentityScreenScene.instantiate()
	add_child(screen)
	await get_tree().process_frame
	screen.identity_selected.connect(func(identity_id: StringName) -> void:
		_captured_identity = String(identity_id)
	)
	screen.apply_snapshot(_progression_snapshot({
		"phase": "identity_selection",
		"identity_id": "",
		"identity_options": _identity_options(""),
	}))
	_expect(not screen.has_hub_actions(), "identity phase hides hub actions")
	_expect(screen.get_background_path().ends_with("title-screen.png"), "identity art review background resolves")
	screen.choose_identity("identity.doctor")
	_expect(screen.is_pending(), "identity command enters pending state")
	_expect(_captured_identity == "identity.doctor", "identity command emits stable id")
	var result = ProgressionCommandResultScript.new(
		true,
		&"ok",
		[],
		_progression_snapshot({
			"phase": "hub",
			"identity_id": "identity.doctor",
			"identity_options": _identity_options("identity.doctor"),
		})
	)
	screen.apply_command_result(result)
	_expect(not screen.is_pending(), "identity pending clears after result")
	_expect(screen.has_hub_actions(), "hub exposes battle, gacha and upgrade actions")
	_expect(screen.get_selected_identity_id() == "identity.doctor", "hub retains selected identity")
	screen.queue_free()
	await get_tree().process_frame


func _test_reward() -> void:
	var screen = RewardScreenScene.instantiate()
	add_child(screen)
	await get_tree().process_frame
	screen.reward_claimed.connect(func(reward_id: StringName) -> void:
		_captured_reward = String(reward_id)
	)
	screen.apply_snapshot(_progression_snapshot({
		"phase": "reward",
		"identity_id": "identity.reporter",
		"identity_options": _identity_options("identity.reporter"),
		"reward_options": [
			{"id": "reward.divination_tickets", "display_name_zh": "灵界占卜券", "kind": "divination_tickets", "amount": 3},
			{"id": "reward.ink_dart_fragments", "display_name_zh": "墨刺残页", "kind": "card_fragments", "amount": 6},
		],
	}))
	_expect(screen.get_option_count() == 2, "reward screen renders two choices")
	_expect(screen.get_background_path().ends_with("reward-archive.png"), "reward art background resolves")
	screen.claim_reward("reward.ink_dart_fragments")
	_expect(screen.is_pending(), "reward command enters pending")
	_expect(_captured_reward == "reward.ink_dart_fragments", "reward command emits stable id")
	screen.apply_command_result(ProgressionCommandResultScript.new(
		true,
		&"ok",
		[],
		_progression_snapshot({
			"phase": "hub",
			"identity_id": "identity.reporter",
			"identity_options": _identity_options("identity.reporter"),
			"reward_options": [],
		})
	))
	_expect(screen.get_option_count() == 0, "claimed reward is removed")
	_expect(screen.get_status_text().contains("写入"), "reward success is shown")
	screen.queue_free()
	await get_tree().process_frame


func _test_gacha() -> void:
	var screen = GachaScreenScene.instantiate()
	add_child(screen)
	await get_tree().process_frame
	screen.draw_requested.connect(func(pull_count: int) -> void:
		_captured_pull_count = pull_count
	)
	screen.configure({
		"card.skill.ink_dart": "墨刺",
		"card.skill.omen": "凶兆",
	})
	screen.apply_snapshot(_progression_snapshot({
		"phase": "hub",
		"identity_id": "identity.gravedigger",
		"identity_options": _identity_options("identity.gravedigger"),
		"divination_tickets": 7,
		"gacha_costs": {"single": 2, "triple": 5},
		"pity_counter": 3,
		"rare_pity": 4,
		"last_gacha_results": [],
	}))
	_expect(screen.get_background_path().ends_with("gacha-altar.png"), "gacha altar background resolves")
	_expect(screen.get_ticket_text().contains("7"), "gacha reads tickets from snapshot")
	_expect(screen.get_guidance_text().contains("稀有回响权重 15"), "gacha explains rare probability from snapshot")
	_expect(screen.get_guidance_text().contains("保底上限 4 次"), "gacha explains pity ceiling from snapshot")
	_expect(screen.get_result_count() == 0, "gacha starts with no result cards")
	screen.request_draw(3)
	_expect(screen.is_pending(), "gacha command enters pending")
	_expect(_captured_pull_count == 3, "gacha emits triple pull count")
	var pulls := [
		{"definition_id": "card.skill.ink_dart", "rarity": "common", "duplicate": true, "fragments": 6},
		{"definition_id": "card.skill.ink_dart", "rarity": "common", "duplicate": true, "fragments": 6},
		{"definition_id": "card.skill.omen", "rarity": "rare", "duplicate": false, "fragments": 0},
	]
	screen.apply_command_result(ProgressionCommandResultScript.new(
		true,
		&"ok",
		[],
		_progression_snapshot({
			"phase": "hub",
			"identity_id": "identity.gravedigger",
			"identity_options": _identity_options("identity.gravedigger"),
			"divination_tickets": 2,
			"gacha_costs": {"single": 2, "triple": 5},
			"pity_counter": 0,
			"rare_pity": 4,
			"last_gacha_results": pulls,
		})
	))
	_expect(not screen.is_pending(), "gacha pending clears after result")
	_expect(screen.get_result_count() == 3, "triple result renders three cards")
	_expect(screen.get_status_text().contains("稀有 1"), "gacha displays returned rare count")
	screen.set_pending(true)
	screen.apply_command_result(ProgressionCommandResultScript.new(
		false,
		&"insufficient_divination_tickets",
		[],
		ProgressionSnapshotScript.new({})
	))
	_expect(screen.get_status_text().contains("占卜券不足"), "gacha rejection reason is shown")
	screen.queue_free()
	await get_tree().process_frame


func _test_upgrade() -> void:
	var screen = UpgradeScreenScene.instantiate()
	add_child(screen)
	await get_tree().process_frame
	screen.upgrade_requested.connect(func(definition_id: StringName) -> void:
		_captured_upgrade = String(definition_id)
	)
	screen.configure(
		{"card.skill.ink_dart": "墨刺", "card.skill.focus": "凝神"},
		{
			"card.skill.ink_dart": ["造成 4 点伤害", "造成 5 点伤害", "造成 6 点伤害", "造成 7 点伤害"],
			"card.skill.focus": ["获得 1 点灵性", "获得 2 点灵性", "获得 3 点灵性", "获得 4 点灵性"],
		}
	)
	var collection := [
		{"definition_id": "card.skill.ink_dart", "copies": 2, "level": 0, "fragments": 8, "max_level": 3, "next_upgrade_cost": 6},
		{"definition_id": "card.skill.focus", "copies": 1, "level": 0, "fragments": 0, "max_level": 3, "next_upgrade_cost": 6},
	]
	screen.apply_snapshot(_progression_snapshot({
		"phase": "hub",
		"identity_id": "identity.reporter",
		"identity_options": _identity_options("identity.reporter"),
		"collection": collection,
	}))
	_expect(screen.get_card_row_count() == 2, "upgrade renders owned and insufficient cards")
	_expect(screen.get_background_path().ends_with("reward-archive.png"), "upgrade art background resolves")
	screen.request_upgrade("card.skill.ink_dart")
	_expect(screen.is_pending(), "upgrade command enters pending")
	_expect(_captured_upgrade == "card.skill.ink_dart", "upgrade emits stable card id")
	collection[0]["level"] = 1
	collection[0]["fragments"] = 2
	screen.apply_command_result(ProgressionCommandResultScript.new(
		true,
		&"ok",
		[],
		_progression_snapshot({
			"phase": "hub",
			"identity_id": "identity.reporter",
			"identity_options": _identity_options("identity.reporter"),
			"collection": collection,
		})
	))
	_expect(not screen.is_pending(), "upgrade pending clears after result")
	_expect(screen.get_status_text().contains("下一次战斗"), "upgrade success explains next battle effect")
	screen.set_pending(true)
	screen.apply_command_result(ProgressionCommandResultScript.new(
		false,
		&"insufficient_fragments",
		[],
		ProgressionSnapshotScript.new({})
	))
	_expect(screen.get_status_text().contains("残页不足"), "upgrade rejection reason is shown")
	screen.queue_free()
	await get_tree().process_frame


func _identity_options(selected_id: String) -> Array:
	return [
		{"id": "identity.reporter", "display_name_zh": "记者", "description_zh": "记录真相，换取更多占卜券。", "battle_modifiers": {"starting_attention": -1}, "selected": selected_id == "identity.reporter"},
		{"id": "identity.doctor", "display_name_zh": "医生", "description_zh": "以更强的体魄进入战斗。", "battle_modifiers": {"max_hp_bonus": 4}, "selected": selected_id == "identity.doctor"},
		{"id": "identity.gravedigger", "display_name_zh": "守墓人", "description_zh": "从重复的回响中拾取更多残片。", "battle_modifiers": {}, "selected": selected_id == "identity.gravedigger"},
	]


func _progression_snapshot(overrides: Dictionary) -> ProgressionSnapshot:
	var data := {
		"revision": 1,
		"phase": "hub",
		"identity_id": "identity.reporter",
		"identity_options": _identity_options("identity.reporter"),
		"battle_modifiers": {},
		"divination_tickets": 3,
		"collection": [
			{"definition_id": "card.skill.ink_dart", "copies": 1, "level": 0, "fragments": 0, "max_level": 3, "next_upgrade_cost": 6},
			{"definition_id": "card.skill.focus", "copies": 1, "level": 0, "fragments": 0, "max_level": 3, "next_upgrade_cost": 6},
		],
		"pity_counter": 0,
		"rare_pity": 4,
		"gacha_costs": {"single": 2, "triple": 5},
		"rarity_weights": {"common": 85, "rare": 15},
		"reward_options": [],
		"last_battle_outcome": "",
		"last_gacha_results": [],
	}
	for key in overrides:
		data[key] = overrides[key]
	return ProgressionSnapshotScript.new(data)


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("PROGRESSION_UI_SMOKE_OK checks=%d" % _checks)
		get_tree().quit(0)
		return
	for failure in _failures:
		printerr("PROGRESSION_UI_SMOKE_FAIL %s" % failure)
	print("PROGRESSION_UI_SMOKE_FAIL checks=%d failures=%d" % [_checks, _failures.size()])
	get_tree().quit(1)
