extends RefCounted

const AssetRegistry := preload("res://src/ui/asset_registry.gd")
const SceneCatalog := preload("res://src/ui/scene_ui_catalog.gd")

## Per-challenge presentation (AR-16): which story arc a challenge belongs to.
## Screens read these fields instead of branching on challenge ids; an unknown
## challenge uses DEFAULT_PRESENTATION.
const PRESENTATION := {
	"challenge.v060.mirror_echoes": {
		"arc_zh": "安提哥努斯笔记案",
		"select_tag_zh": "可重复挑战",
	},
	"challenge.v070.broken_procession": {
		"arc_zh": "邪神子嗣降临",
		"select_tag_zh": "第二挑战",
	},
}
const DEFAULT_PRESENTATION := {
	"arc_zh": "安提哥努斯笔记案",
	"select_tag_zh": "可重复挑战",
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


static func selection_background() -> String:
	return SceneCatalog.path_for("scene.hub.challenge_board", "hub")


static func result_background() -> String:
	return SceneCatalog.path_for("scene.hub.challenge_result", "hub")


static func presentation(challenge_id: String) -> Dictionary:
	return PRESENTATION.get(challenge_id, DEFAULT_PRESENTATION)


static func selection_eyebrow(challenge_id: String) -> String:
	var entry := presentation(challenge_id)
	return "%s · %s" % [String(entry.get("arc_zh", "")), String(entry.get("select_tag_zh", ""))]


static func result_eyebrow(challenge_id: String) -> String:
	return "%s · 传承" % String(presentation(challenge_id).get("arc_zh", ""))


static func modifier_icon(modifier_id: String) -> String:
	var path := AssetRegistry.lookup("icons", modifier_id)
	return path if not path.is_empty() else AssetRegistry.fallback("modifier")


static func deck_restricted_icon() -> String:
	return AssetRegistry.lookup("icons", "icon.deck.restricted")


static func challenge_emblem(challenge_id: String) -> String:
	## Registry is keyed by challenge id; no id special cases here.
	var path := AssetRegistry.lookup("icons", challenge_id)
	return path if not path.is_empty() else AssetRegistry.fallback("challenge_emblem")


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
	return AssetRegistry.lookup(
		"icons", "icon.challenge.success" if completed else "icon.challenge.failure"
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
