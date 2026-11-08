extends RefCounted

const IDENTITY_ART := {
	"identity.reporter": "res://assets/game/v0.4.0/identities/card-identity-reporter.png",
	"identity.doctor": "res://assets/game/v0.4.0/identities/card-identity-doctor.png",
	"identity.gravedigger": "res://assets/game/v0.4.0/identities/card-identity-gravedigger.png",
}

const CARD_ART := {
	"card.skill.ink_dart": "res://assets/game/v0.3.0/cards/card-skill-ink-dart.png",
	"card.skill.paper_guard": "res://assets/game/v0.3.0/cards/card-skill-paper-guard.png",
	"card.skill.calm_breath": "res://assets/game/v0.3.0/cards/card-skill-calm-breath.png",
	"card.skill.focus": "res://assets/game/v0.3.0/cards/card-skill-focus.png",
	"card.skill.insight": "res://assets/game/v0.3.0/cards/card-skill-insight.png",
	"card.skill.omen": "res://assets/game/v0.3.0/cards/card-skill-omen.png",
	"card.skill.whisper": "res://assets/game/v0.3.0/cards/card-skill-whisper.png",
	"card.skill.second_look": "res://assets/game/v0.3.0/cards/card-skill-second-look.png",
	"card.skill.warding_circle": "res://assets/game/v0.7.0/cards/card_skill_warding_circle.png",
	"card.skill.lantern_step": "res://assets/game/v0.7.0/cards/card_skill_lantern_step.png",
	"card.skill.whispered_hunch": "res://assets/game/v0.7.0/cards/card_skill_whispered_hunch.png",
	"card.skill.mirrored_memory": "res://assets/game/v0.7.0/cards/card_skill_mirrored_memory.png",
	"card.skill.fated_echo": "res://assets/game/v0.7.0/cards/card_skill_fated_echo.png",
	"card.skill.piercing_omen": "res://assets/game/v0.7.0/cards/card_skill_piercing_omen.png",
	"card.skill.coffin_nail": "res://assets/game/v0.7.0/cards/card_skill_coffin_nail.png",
	"card.skill.second_sight": "res://assets/game/v0.7.0/cards/card_skill_second_sight.png",
	"card.skill.dream_question": "res://assets/game/v0.13.0/cards/card_skill_dream_question.png",
	"card.skill.mirror_ward": "res://assets/game/v0.13.0/cards/card_skill_mirror_ward.png",
	"card.skill.severed_string": "res://assets/game/v0.13.0/cards/card_skill_severed_string.png",
	"card.skill.last_rites": "res://assets/game/v0.13.0/cards/card_skill_last_rites.png",
}

const CARD_BACK := "res://assets/game/v0.4.0/cards/card-back-sealed-omen.png"
const IDENTITY_BACKGROUND := "res://assets/game/scenes/title-screen.png"
const REWARD_BACKGROUND := "res://assets/game/v0.4.0/scenes/reward-archive.png"
const GACHA_BACKGROUND := "res://assets/game/v0.4.0/scenes/gacha-altar.png"
const UPGRADE_BACKGROUND := "res://assets/game/v0.4.0/scenes/reward-archive.png"
const TICKET_ICON := "res://assets/game/v0.4.0/icons/divination-ticket.png"
const SHARD_ICON := "res://assets/game/v0.4.0/icons/card-shard.png"


static func identity_art(identity_id: String) -> String:
	return String(IDENTITY_ART.get(identity_id, ""))


static func card_art(definition_id: String) -> String:
	return String(CARD_ART.get(definition_id, ""))


static func upgrade_icon(level: int) -> String:
	var clamped := clampi(level, 1, 3)
	return "res://assets/game/v0.4.0/icons/upgrade-%d.png" % clamped


static func reward_icon(kind: String) -> String:
	return SHARD_ICON if kind == "card_fragments" else TICKET_ICON


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
