extends Node

## v0.77: live hub/exit copy matches diary main path (from screenshot audit).

var _checks := 0
var _failures: Array[String] = []


func _ready() -> void:
	_expect_source(
		"res://src/ui/identity_screen.gd",
		"打开日记",
		"identity hub CTA opens diary"
	)
	_expect_source(
		"res://src/ui/identity_screen.gd",
		"打开日记续读主线",
		"identity hub status mentions diary"
	)
	_expect_absent(
		"res://src/ui/identity_screen.gd",
		"进入夜间战斗",
		"identity drops night-battle CTA"
	)
	_expect_absent(
		"res://src/ui/identity_screen.gd",
		"路线页可看主线进度",
		"identity drops route-page coaching"
	)

	for path in [
		"res://src/ui/reward_screen.gd",
		"res://src/ui/gacha_screen.gd",
		"res://src/ui/upgrade_screen.gd",
		"res://src/ui/result_screen.gd",
		"res://src/ui/route_result_screen.gd",
		"res://src/ui/challenge_screen.gd",
		"res://src/ui/challenge_result_screen.gd",
		"res://src/ui/challenge_hub_screen.gd",
		"res://src/ui/route_screen.gd",
	]:
		_expect_source(path, "回日记", "%s exits to diary" % path.get_file())
		_expect_absent(path, "返回白昼档案", "%s drops daylight-archive exit" % path.get_file())

	_expect_source(
		"res://src/ui/start_screen.gd",
		"打开日记续读主线线索",
		"start coaching points at diary"
	)
	_expect_absent(
		"res://src/ui/start_screen.gd",
		"路线页看主线进度",
		"start drops route-page coaching"
	)
	_expect_source(
		"res://src/ui/route_screen.gd",
		"调查线索",
		"legacy route screen uses investigate CTA"
	)
	_expect_absent(
		"res://src/ui/route_screen.gd",
		"前往节点",
		"legacy route screen drops enter-node CTA"
	)
	_expect_source(
		"res://project.godot",
		'config/version="0.77.0"',
		"project version 0.77.0"
	)

	## Diary contrast knobs stayed ink-forward (not washed out).
	var diary := FileAccess.get_file_as_string("res://src/ui/diary_chapter_screen.gd")
	_expect(diary.find("#e8c25a") >= 0, "gold overwrite uses brighter ink")
	_expect(diary.find("0.28)") >= 0 or diary.find("0.28,") >= 0, "ink seal plate alpha reduced")

	if _failures.is_empty():
		print("V077_LIVE_COPY_OK checks=%d" % _checks)
	else:
		print("V077_LIVE_COPY_FAIL checks=%d failures=%s" % [_checks, str(_failures)])
		for failure in _failures:
			push_error(failure)
	get_tree().quit(0 if _failures.is_empty() else 1)


func _expect_source(path: String, needle: String, label: String) -> void:
	var text := FileAccess.get_file_as_string(path)
	_expect(not text.is_empty() and text.find(needle) >= 0, label)


func _expect_absent(path: String, needle: String, label: String) -> void:
	var text := FileAccess.get_file_as_string(path)
	_expect(text.find(needle) < 0, label)


func _expect(cond: bool, label: String) -> void:
	_checks += 1
	if not cond:
		_failures.append(label)
