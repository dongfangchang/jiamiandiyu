extends RefCounted

const BACKGROUND := "res://assets/game/v0.7.0/scenes/deck_archive.png"
const CARD_BACK := "res://assets/game/v0.4.0/cards/card-back-sealed-omen.png"
const V07_CARD_DIR := "res://assets/game/v0.7.0/cards/"
const V013_CARD_DIR := "res://assets/game/v0.13.0/cards/"
const V03_CARD_DIR := "res://assets/game/v0.3.0/cards/"

const V07_CARD_IDS: Array[String] = [
	"card.skill.warding_circle",
	"card.skill.lantern_step",
	"card.skill.whispered_hunch",
	"card.skill.mirrored_memory",
	"card.skill.fated_echo",
	"card.skill.piercing_omen",
	"card.skill.coffin_nail",
	"card.skill.second_sight",
	"card.skill.dream_question",
	"card.skill.mirror_ward",
	"card.skill.severed_string",
	"card.skill.last_rites",
]

const PRESET_NAMES := {
	"deck.preset.ward": "守夜档案",
	"deck.preset.oracle": "灵性预感",
	"deck.preset.burst": "棺钉凶兆",
	"deck.preset.echo": "镜中余响",
}


static func card_art(definition_id: String) -> String:
	var suffix := definition_id.get_slice(".", definition_id.get_slice_count(".") - 1)
	if not suffix.is_empty():
		if definition_id in [
			"card.skill.dream_question",
			"card.skill.mirror_ward",
			"card.skill.severed_string",
			"card.skill.last_rites",
		]:
			return V013_CARD_DIR + "card_skill_%s.png" % suffix
		var v07_path := V07_CARD_DIR + "card_skill_%s.png" % suffix
		if suffix in V07_CARD_IDS.map(
			func(value: String) -> String:
				return value.get_slice(".", value.get_slice_count(".") - 1)
		):
			return v07_path
		var legacy_path := V03_CARD_DIR + "card-skill-%s.png" % suffix.replace("_", "-")
		if ResourceLoader.exists(legacy_path):
			return legacy_path
		if ResourceLoader.exists(v07_path):
			return v07_path
	return CARD_BACK


static func target_text(target_type: String) -> String:
	match target_type:
		"enemy":
			return "敌方"
		"self":
			return "自身"
		"none":
			return "无目标"
		"":
			return "未指定"
		_:
			return target_type


static func reason_text(reason_code: String) -> String:
	match reason_code:
		"playable":
			return "牌组合法，可以确认出战。"
		"empty_deck":
			return "牌组为空，请加入 8 张不同卡牌。"
		"wrong_deck_size":
			return "出战牌组必须为 8 张。"
		"duplicate_card":
			return "同一张卡不能重复放入牌组。"
		"card_not_owned":
			return "这张卡尚未收入收藏。"
		"unknown_card":
			return "卡牌记录不存在。"
		"card_not_in_deck":
			return "这张卡不在当前牌组中。"
		"unknown_preset":
			return "预设不存在。"
		"preset_missing", "preset_invalid", "presets_invalid":
			return "牌组预设记录异常，可恢复初始牌组。"
		"not_initialized":
			return "牌组档案尚未准备完成。"
		"invalid_command":
			return "牌组操作无效。"
		"":
			return ""
		_:
			return "牌组操作未通过：%s" % reason_code


static func preset_name(preset_id: String) -> String:
	return String(PRESET_NAMES.get(preset_id, preset_id))
