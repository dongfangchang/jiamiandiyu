extends RefCounted

const ROUTE_BACKGROUND := "res://assets/game/v0.24.0/v0.5.0/scenes/route-map.png"
## The route map is a light parchment asset; keep its presentation in the
## same ink-dark range as the rest of the UI while preserving node contrast.
const ROUTE_BACKGROUND_DIM := 0.74
const REST_BACKGROUND := "res://assets/game/v0.24.0/v0.5.0/scenes/rest-old-house.png"
const RITUAL_BACKGROUND := "res://assets/game/v0.24.0/v0.5.0/scenes/ritual-tampered-obituary.png"
## Chapter bosses (失控的老尼尔 / 梅高欧丝) share the red-eyed monster art.
const BOSS_ART := "res://assets/game/v0.24.0/v0.3.0/enemies/enemy-candle-moth.png"
const ROUTE_ICON_BASE := "res://assets/game/v0.24.0/v0.5.0/icons/"
const RITUAL_CARD_BASE := "res://assets/game/v0.24.0/v0.5.0/rituals/"

const ROUTE_STATE_ICON := {
	"locked": "route-pending.png",
	"available": "route-current.png",
	"completed": "route-completed.png",
}

const RITUAL_STEP_ART := {
	"select_ids": "ritual-card-name-record.png",
	"ordered_ids": "ritual-card-chronology.png",
	"select_id": "ritual-card-seal.png",
}


static func route_state_icon(state: String) -> String:
	return ROUTE_ICON_BASE + String(
		ROUTE_STATE_ICON.get(state, "route-pending.png")
	)


static func ritual_step_art(step_type: String) -> String:
	return RITUAL_CARD_BASE + String(
		RITUAL_STEP_ART.get(step_type, "ritual-card-seal.png")
	)


static func node_type_text(node_type: String) -> String:
	match node_type:
		"normal":
			return "普通遭遇"
		"elite":
			return "精英追猎"
		"rest":
			return "休整节点"
		"boss":
			return "首领战"
		"ritual":
			return "仪式"
		_:
			return "未知节点"


static func node_state_text(state: String) -> String:
	match state:
		"completed":
			return "已完成"
		"available":
			return "当前可进入"
		_:
			return "尚未抵达"


static func rest_effect_text(effects_value: Variant) -> String:
	if not effects_value is Dictionary:
		return "效果由路线规则结算。"
	var effects: Dictionary = effects_value
	var lines: Array[String] = []
	var hp_delta := int(effects.get("hp_delta", 0))
	var corruption_delta := int(effects.get("corruption_delta", 0))
	var attention_delta := int(effects.get("attention_delta", 0))
	var max_spirit_delta := int(effects.get("max_spirit_delta", 0))
	if hp_delta != 0:
		lines.append("生命 %+d" % hp_delta)
	if corruption_delta != 0:
		lines.append("污染 %+d" % corruption_delta)
	if attention_delta != 0:
		lines.append("被注视 %+d" % attention_delta)
	if max_spirit_delta != 0:
		lines.append("下一战灵性上限 %+d" % max_spirit_delta)
	return " · ".join(lines) if not lines.is_empty() else "无资源变化"


static func reason_text(reason_code: String) -> String:
	match reason_code:
		"wrong_phase":
			return "当前路线阶段不能执行这个操作。"
		"unknown_node":
			return "路线中没有这个节点。"
		"node_not_available":
			return "该节点尚未解锁或已经完成。"
		"wrong_node":
			return "战斗结果与当前节点不一致。"
		"invalid_battle_outcome":
			return "战斗结果无效，路线未推进。"
		"rest_not_available":
			return "这个休息选择当前不可用。"
		"ascension_requires_begin":
			return "请先开始晋升仪式。"
		"ascension_not_available":
			return "首领尚未击败，无法开始晋升。"
		"ritual_selection_count":
			return "当前步骤选择的证物数量不正确。"
		"invalid_ritual_selection":
			return "证物选择无效或重复。"
		"ritual_step_invalid":
			return "仪式步骤状态异常。"
		"insufficient_spirit":
			return "灵性不足，无法取得提示。"
		"hint_already_used":
			return "本步骤的提示已经使用。"
		"not_initialized", "content_invalid":
			return "路线档案不完整，操作已取消。"
		"":
			return ""
		_:
			return "操作未通过：%s" % reason_code
