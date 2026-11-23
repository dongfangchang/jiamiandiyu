extends RefCounted

const BACKGROUND := "res://assets/game/v0.54.0/scenes/ui-canvas-gothic-rain-night.png"
const CARD_BACK := "res://assets/game/v0.24.0/v0.4.0/cards/card-back-sealed-omen.png"
const V07_CARD_DIR := "res://assets/game/v0.24.0/v0.7.0/cards/"
const V013_CARD_DIR := "res://assets/game/v0.24.0/v0.13.0/cards/"
const V03_CARD_DIR := "res://assets/game/v0.24.0/v0.3.0/cards/"
const V041_CARD_DIR := "res://assets/game/v0.41.0/cards/"
const V042_CARD_DIR := "res://assets/game/v0.42.0/cards/"

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

const V041_CARD_IDS: Array[String] = [
	"card.skill.veil_step",
	"card.skill.severed_fate",
	"card.skill.paper_swarm",
	"card.skill.mirror_shard",
	"card.skill.last_witness",
	"card.skill.false_death",
	"card.skill.sealed_answer",
	"card.skill.hollow_bell",
]

const V042_CARD_IDS: Array[String] = [
	"card.skill.ink_scarlet",
	"card.skill.echo_reading",
	"card.skill.midnight_ledger",
	"card.skill.borrowed_breath",
	"card.skill.glass_thesis",
	"card.skill.hungry_symbol",
	"card.skill.candle_archive",
	"card.skill.omen_chorus",
	"card.skill.closed_eye",
	"card.skill.black_thread",
	"card.skill.eclipse",
	"card.skill.red_corridor",
]

const PRESET_NAMES := {
	"deck.preset.ward": "值夜者制式装备",
	"deck.preset.oracle": "仪式魔法",
	"deck.preset.burst": "提利尔仓库",
	"deck.preset.echo": "值夜者小队",
	"deck.preset.clown": "小丑技能包",
}

## Fallback only. Authoritative guidance lives in data/decks and deck snapshots.
const PRESET_GUIDANCE := {
	"deck.preset.ward": {
		"tag": "稳守 / 射击",
		"when": "入职时的标准配置：先用灵视看清意图，再用左轮与猎魔子弹处理。",
		"best_against": "前半普通战。",
		"caution": "高压首领缺少封印物爆发。",
	},
	"deck.preset.oracle": {
		"tag": "仪式 / 兑现",
		"when": "先用灵性之墙、银质匕首叠满仪式准备，再一次打出驱邪仪式。",
		"best_against": "灵体与不死目标。",
		"caution": "叠不起仪式时输出断档。",
	},
	"deck.preset.burst": {
		"tag": "控制 / 联动",
		"when": "2-049 束缚后接左轮，触发原著联动“提利尔仓库”。",
		"best_against": "需要先束缚的精英。",
		"caution": "单场一次封印物打错目标会失去联动。",
	},
	"deck.preset.echo": {
		"tag": "队友 / 封印物",
		"when": "邓恩与伦纳德稳住战线；圣赛琳娜骨灰 + 阳炎符咒触发“守护者”。",
		"best_against": "老尼尔、梅高欧丝等首领。",
		"caution": "高费卡多，须为守护者联动留费。",
	},
	"deck.preset.clown": {
		"tag": "闪避 / 飞牌",
		"when": "小丑的微笑 + 危险预感 / 身体控制，触发联动“小丑”；飞牌与纸牌收割。",
		"best_against": "需要先躲开危险意图的精英与挑战。",
		"caution": "仅序列 8；高压首领缺少队友封印物爆发。",
	},
}


static func card_art(definition_id: String) -> String:
	var suffix := definition_id.get_slice(".", definition_id.get_slice_count(".") - 1)
	if not suffix.is_empty():
		if definition_id in V042_CARD_IDS:
			var gap_path := V042_CARD_DIR + "card_skill_%s.png" % suffix
			if ResourceLoader.exists(gap_path):
				return gap_path
		if definition_id in V041_CARD_IDS:
			var clown_path := V041_CARD_DIR + "card_skill_%s.png" % suffix
			if ResourceLoader.exists(clown_path):
				return clown_path
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
		"sequence_locked":
			return "当前序列尚未解锁这张卡，请晋升至卡牌所需序列后再加入。"
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


static func preset_guidance(preset_id: String) -> Dictionary:
	return PRESET_GUIDANCE.get(preset_id, {
		"tag": "自定义方向",
		"when": "根据当前收藏和路线需要调整牌组。",
	})
