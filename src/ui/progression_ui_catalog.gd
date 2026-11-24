extends RefCounted

const AssetRegistry := preload("res://src/ui/asset_registry.gd")
const CardArt := preload("res://src/ui/card_art_catalog.gd")
const SceneCatalog := preload("res://src/ui/scene_ui_catalog.gd")


static func identity_art(identity_id: String) -> String:
	return AssetRegistry.lookup("identities", identity_id)


static func card_art(definition_id: String) -> String:
	return CardArt.card_art(definition_id)


static func card_back() -> String:
	return CardArt.card_back()


static func identity_background() -> String:
	return SceneCatalog.path_for("scene.title.mask_desk", "hub")


static func reward_background() -> String:
	return SceneCatalog.path_for("scene.hub.reward_archive", "hub")


static func gacha_background() -> String:
	return SceneCatalog.path_for("scene.hub.gacha_altar", "hub")


static func upgrade_background() -> String:
	return SceneCatalog.path_for("scene.hub.reward_archive", "hub")


static func ticket_icon() -> String:
	return AssetRegistry.lookup("icons", "icon.reward.divination_tickets")


static func upgrade_icon(level: int) -> String:
	return AssetRegistry.lookup("icons", "icon.upgrade.%d" % clampi(level, 1, 3))


static func reward_icon(kind: String) -> String:
	var path := AssetRegistry.lookup("icons", "icon.reward." + kind)
	return path if not path.is_empty() else AssetRegistry.fallback("reward")


static func reward_guidance(kind: String) -> Dictionary:
	match kind:
		"divination_tickets":
			return {
				"tag": "资源储备",
				"when": "适合准备下一次祈愿，或想保留更多抽卡选择时。",
			}
		"card_fragments":
			return {
				"tag": "定向成长",
				"when": "适合已经确定构筑方向，想尽快升级一张关键卡时。",
			}
		_:
			return {
				"tag": "未知奖励",
				"when": "奖励类型未知，请查看档案记录后再决定。",
			}


static func rarity_text(rarity: String) -> String:
	match rarity:
		"rare":
			return "稀有回响"
		"common":
			return "普通回响"
		_:
			return "未知品阶"


static func modifier_text(modifiers: Dictionary) -> String:
	if modifiers.is_empty():
		return "无直接战斗修正"
	var lines: Array[String] = []
	if int(modifiers.get("max_hp_bonus", 0)) != 0:
		lines.append("生命上限 %+d" % int(modifiers["max_hp_bonus"]))
	if int(modifiers.get("starting_attention", 0)) != 0:
		lines.append("初始被注视 %+d" % int(modifiers["starting_attention"]))
	if int(modifiers.get("max_attention_bonus", 0)) != 0:
		lines.append("被注视上限 %+d" % int(modifiers["max_attention_bonus"]))
	if int(modifiers.get("max_spirit_bonus", 0)) != 0:
		lines.append("灵性上限 %+d" % int(modifiers["max_spirit_bonus"]))
	return " · ".join(lines) if not lines.is_empty() else "无直接战斗修正"


static func reason_text(reason_code: String) -> String:
	match reason_code:
		"wrong_phase":
			return "当前阶段不能执行这个操作。"
		"unknown_identity":
			return "这个身份不在当前档案中。"
		"reward_not_available":
			return "这份奖励已经失效或不可领取。"
		"invalid_pull_count":
			return "祈愿次数只能是单抽或三连。"
		"insufficient_divination_tickets":
			return "占卜券不足。"
		"upgrade_not_supported":
			return "这张卡当前不能升级。"
		"card_not_owned":
			return "尚未收容这张卡。"
		"card_level_max":
			return "这张卡已经达到当前等级上限。"
		"insufficient_fragments":
			return "残页不足，无法完成升级。"
		"content_invalid", "balance_missing":
			return "成长档案不完整，操作已取消。"
		"":
			return ""
		_:
			return "操作未通过：%s" % reason_code
