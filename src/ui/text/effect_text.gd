extends RefCounted

## Chinese copy for card effects (R2-12, moved out of app_controller). Pure
## presentation: reads an effect definition, never decides a rule.


static func format_card_effects(definition: Dictionary) -> String:
	var parts: Array[String] = []
	if bool(definition.get("consumes_ritual", false)):
		parts.append("消耗全部仪式准备")
	for effect_value in definition.get("effects", []):
		if not effect_value is Dictionary:
			continue
		var text := format_single_effect(effect_value)
		if text.is_empty():
			continue
		var condition_text := format_condition(effect_value.get("condition", {}))
		parts.append(condition_text + text if not condition_text.is_empty() else text)
	var result := "；".join(parts) if not parts.is_empty() else "无直接数值效果"
	if bool(definition.get("exhaust", false)):
		result = "单场一次。" + result
	return result


static func format_single_effect(effect: Dictionary) -> String:
	var effect_id := String(effect.get("effect_id", ""))
	var per_stack := int(effect.get("per_ritual_stack", 0))
	var ritual_suffix := "（每层准备+%d）" % per_stack if per_stack != 0 else ""
	var target := String(effect.get("target", ""))
	var all_prefix := "所有敌人" if target == "all_enemies" else ""
	match effect_id:
		"damage":
			return "造成 %d 伤害%s" % [int(effect.get("amount", 0)), ritual_suffix]
		"damage_all":
			return "对所有敌人造成 %d 伤害%s" % [int(effect.get("amount", 0)), ritual_suffix]
		"block":
			return "获得 %d 护盾" % int(effect.get("amount", 0))
		"heal":
			return "恢复 %d 生命" % int(effect.get("amount", 0))
		"lose_hp":
			return "失去 %d 生命（代价）" % int(effect.get("amount", 0))
		"spirit":
			return "获得 %d 灵性" % int(effect.get("amount", 0))
		"draw":
			return "抽 %d 张牌" % int(effect.get("count", 0))
		"apply_status":
			var status_id := StringName(effect.get("status_id", ""))
			var stacks := int(effect.get("stacks", 0))
			match status_id:
				&"bound":
					return "%s束缚 %d 回合（跳过行动）" % [all_prefix, stacks]
				&"evasion":
					return "获得 %d 闪避" % stacks
				&"sluggish":
					return "副作用：下回合灵性 -%d" % stacks
				&"silenced":
					return "使其失声 %d 回合（无法诅咒）" % int(effect.get("duration", stacks))
				&"weaken":
					return "%s下一次攻击 -%d" % [all_prefix if not all_prefix.is_empty() else "敌人", stacks]
				&"mark":
					return "%s施加 %d 层标记（下次受伤时附加等量伤害并消耗）" % [all_prefix, stacks]
				_:
					return "%s施加 %d 层%s" % [all_prefix, stacks, status_label(status_id)]
		"remove_status":
			return "移除 %s" % status_label(StringName(effect.get("status_id", "")))
		"reveal_intent":
			return "揭示意图（预见）"
		"reveal_all":
			return "揭示全部意图（预见）"
		"steal_attack":
			return "窃取 %d 点攻击" % int(effect.get("amount", 0))
		"prepare_ritual":
			return "仪式准备 +%d" % int(effect.get("amount", 1))
		"risk":
			var risk_name := "污染" if String(effect.get("risk_id", "")) == "corruption" else "被注视"
			return "%s %+d" % [risk_name, int(effect.get("amount", 0))]
		"discard":
			return "弃置 %d 张牌" % int(effect.get("count", 0))
	return String(effect_id)


static func format_condition(condition_value: Variant) -> String:
	if not condition_value is Dictionary or condition_value.is_empty():
		return ""
	var condition: Dictionary = condition_value
	if condition.has("target_has_trait"):
		var names: Array[String] = []
		var traits: Variant = condition["target_has_trait"]
		for trait_id in (traits if traits is Array else [traits]):
			names.append(trait_label(String(trait_id)))
		return "若目标为%s：" % "/".join(names)
	if condition.has("target_has_status"):
		return "若目标处于%s：" % status_label(StringName(condition["target_has_status"]))
	if condition.has("any_enemy_danger"):
		return "若有危险意图："
	if condition.has("target_intent_revealed"):
		return "若意图已揭示："
	return "满足条件时："


static func trait_label(trait_id: String) -> String:
	match trait_id:
		"spirit":
			return "灵体"
		"undead":
			return "不死"
		"filth":
			return "污秽"
		"lost_control":
			return "失控者"
		"beyonder":
			return "非凡者"
		"human":
			return "普通人"
		_:
			return trait_id


static func status_label(status_id: StringName) -> String:
	match status_id:
		&"mark":
			return "标记"
		&"weaken":
			return "削弱"
		&"bound":
			return "束缚"
		&"evasion":
			return "闪避"
		&"silenced":
			return "失声"
		&"sluggish":
			return "迟缓"
		&"foresight":
			return "预见"
		&"ritual_preparation":
			return "仪式准备"
		_:
			return String(status_id)
