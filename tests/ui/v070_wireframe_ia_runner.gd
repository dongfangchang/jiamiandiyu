extends Node

## v0.70–v0.71: wireframe IA synced to diary hub (no route tree / city map exits).

var _checks := 0
var _failures: Array[String] = []


func _ready() -> void:
	_expect(
		FileAccess.file_exists("res://assets/ui/wireframes/00_flow.svg"),
		"flow wireframe present"
	)
	_expect(
		FileAccess.file_exists("res://assets/ui/wireframes/03_map.svg"),
		"diary chapter wireframe present"
	)
	var flow := FileAccess.get_file_as_string("res://assets/ui/wireframes/00_flow.svg")
	_expect(flow.contains("罗塞尔日记"), "flow names diary hub")
	_expect(not flow.contains("城市地图"), "flow drops city map hub label")
	_expect(flow.contains("无线路树"), "flow notes no route tree")
	_expect(flow.contains("软失败"), "flow notes soft-fail")
	var diary := FileAccess.get_file_as_string("res://assets/ui/wireframes/03_map.svg")
	_expect(diary.contains("罗塞尔日记"), "chapter wireframe is diary")
	_expect(diary.contains("无线路树"), "chapter forbids route tree")
	_expect(not diary.contains("进入节点"), "chapter drops enter-node CTA")
	_expect(diary.contains("调查当前线索"), "chapter uses investigate CTA")
	var day := FileAccess.get_file_as_string("res://assets/ui/wireframes/02_day_identity.svg")
	_expect(day.contains("打开日记"), "day identity exits to diary")
	_expect(not day.contains("前往地图"), "day identity drops map CTA")
	var battle := FileAccess.get_file_as_string("res://assets/ui/wireframes/04_battle.svg")
	_expect(battle.contains("回日记"), "battle notes return to diary")
	_expect(battle.contains("无 OptionButton"), "battle forbids OptionButton")
	var reward := FileAccess.get_file_as_string("res://assets/ui/wireframes/05_reward.svg")
	_expect(reward.contains("回日记"), "reward returns to diary")
	var gacha := FileAccess.get_file_as_string("res://assets/ui/wireframes/06_gacha.svg")
	_expect(gacha.contains("回日记"), "gacha returns to diary")
	_expect(not gacha.contains("返回安全屋"), "gacha drops safehouse CTA")
	var ritual := FileAccess.get_file_as_string("res://assets/ui/wireframes/07_ascension.svg")
	_expect(ritual.contains("软失败"), "ritual notes soft-fail")
	_expect(ritual.contains("不灭章") or ritual.contains("章未灭"), "ritual notes chapter survives")
	_expect(ritual.contains("返回日记"), "ritual exits to diary")
	var result := FileAccess.get_file_as_string("res://assets/ui/wireframes/08_result.svg")
	_expect(result.contains("回到日记"), "result primary exit is diary")
	_expect(not result.contains("返回安全屋"), "result drops safehouse CTA")
	var index := FileAccess.get_file_as_string("res://assets/ui/wireframes/index.html")
	_expect(index.contains("日记"), "wireframe index labels diary")
	_expect(index.contains("v0.71"), "wireframe index version bumped")
	_finish()


func _expect(condition: bool, label: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(label)


func _finish() -> void:
	if _failures.is_empty():
		print("V070_WIREFRAME_IA_OK checks=%d" % _checks)
		get_tree().quit(0)
	else:
		print("V070_WIREFRAME_IA_FAIL checks=%d failures=%s" % [_checks, str(_failures)])
		get_tree().quit(1)
