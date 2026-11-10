extends RefCounted

const SELECTION_BACKGROUND := "res://assets/game/v0.24.0/v0.6.0/scenes/challenge-selection.png"
const RESULT_BACKGROUND := "res://assets/game/v0.24.0/v0.6.0/scenes/challenge-result.png"
const ICON_BASE := "res://assets/game/v0.24.0/v0.6.0/icons/"
const EMBLEM := "res://assets/game/v0.24.0/v0.6.0/icons/challenge-emblem.png"
const ICON_BASE_V07 := "res://assets/game/v0.24.0/v0.7.0/icons/"
const EMBLEM_V07 := "res://assets/game/v0.24.0/v0.7.0/icons/challenge_broken_procession.png"

const MODIFIER_ICONS := {
	"modifier.rushed_reflection": "modifier-pressure-advance.png",
	"modifier.tainted_margins": "modifier-mirror-echo.png",
	"modifier.fractured_deck": "modifier-compact-deck.png",
}

const MODIFIER_ICONS_V07 := {
	"modifier.obituary_echo": "modifier_obituary_echo.png",
	"modifier.twin_shadow": "modifier_twin_shadow.png",
	"modifier.ritual_vigil": "modifier_ritual_vigil.png",
}

const CHALLENGE_NAMES := {
	"challenge.v060.mirror_echoes": "值夜者档案：笔记案",
	"challenge.v070.broken_procession": "值夜者档案：邪神子嗣降临",
}

const REQUIRED_CHALLENGE_NAMES := {
	"challenge.v060.mirror_echoes": "值夜者档案：笔记案",
}

const ROUTE_NAMES := {
	"route.v070.first_case": "安提哥努斯笔记案",
	"route.v070.broken_procession": "邪神子嗣降临",
	"route.v050.first_case": "安提哥努斯笔记案",
}

const REWARD_NAMES := {
	"reward.divination_tickets": "灵界占卜券",
	"reward.ink_dart_fragments": "左轮手枪残页",
}


static func modifier_icon(modifier_id: String) -> String:
	if MODIFIER_ICONS_V07.has(modifier_id):
		return ICON_BASE_V07 + String(MODIFIER_ICONS_V07[modifier_id])
	var file_name := String(
		MODIFIER_ICONS.get(modifier_id, "modifier-restricted-reward.png")
	)
	return ICON_BASE + file_name


static func challenge_emblem(challenge_id: String) -> String:
	if challenge_id == "challenge.v070.broken_procession":
		return EMBLEM_V07
	return EMBLEM


static func challenge_name(challenge_id: String) -> String:
	return String(CHALLENGE_NAMES.get(challenge_id, challenge_id))


static func required_challenge_names(ids: Variant) -> String:
	if not ids is Array or ids.is_empty():
		return ""
	var names: Array[String] = []
	for value in ids:
		var challenge_id := String(value)
		names.append(String(REQUIRED_CHALLENGE_NAMES.get(
			challenge_id,
			challenge_id
		)))
	return "、".join(names)


static func route_name(route_id: String) -> String:
	return String(ROUTE_NAMES.get(route_id, route_id))


static func outcome_icon(completed: bool) -> String:
	return ICON_BASE + (
		"challenge-success.png" if completed else "challenge-failure.png"
	)


static func reward_text(
	reward_value: Variant,
	labels: Dictionary = {}
) -> String:
	if not reward_value is Dictionary:
		return "奖励由挑战规则结算。"
	var reward: Dictionary = reward_value
	var lines: Array[String] = []
	for reward_id in reward:
		var label := String(labels.get(reward_id, REWARD_NAMES.get(
			reward_id,
			String(reward_id).replace("reward.", "").replace("_", " ")
		)))
		lines.append("%s +%d" % [label, int(reward[reward_id])])
	return " · ".join(lines) if not lines.is_empty() else "无额外奖励"


static func reason_text(reason_code: String) -> String:
	match reason_code:
		"challenge_locked":
			return "挑战尚未解锁：请先完成占卜家序列 8 晋升。"
		"required_challenge_incomplete":
			return "挑战尚未解锁：请先完成前置挑战。"
		"wrong_phase":
			return "当前挑战阶段不能执行这个操作。"
		"unknown_modifier":
			return "这个挑战修饰不存在。"
		"modifier_required":
			return "请先选择一个挑战修饰。"
		"route_not_initialized":
			return "挑战路线尚未准备完成。"
		"invalid_route_command", "invalid_command":
			return "挑战操作无效，请重新选择。"
		"state_invalid", "content_invalid":
			return "挑战档案不完整；原有收藏不会被覆盖。"
		"insufficient_spirit":
			return "灵性不足，无法执行该操作。"
		"hint_already_used":
			return "本步骤的仪式提示已经使用。"
		"":
			return ""
		_:
			return "挑战操作未通过：%s" % reason_code
