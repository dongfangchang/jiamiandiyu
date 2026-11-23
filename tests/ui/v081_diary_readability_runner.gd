extends Node

## v0.81: diary ink contrast + parchment plates + chrome readability.

var _checks := 0
var _failures: Array[String] = []


func _ready() -> void:
	var src := FileAccess.get_file_as_string("res://src/ui/diary_chapter_screen.gd")
	_expect(not src.is_empty(), "diary screen source readable")
	_expect(src.find('INK_BASE_BB := "#1a0e06"') >= 0, "base ink darkened")
	_expect(src.find('INK_GOLD_BB := "#f0d070"') >= 0, "gold overwrite brightened")
	_expect(src.find("C_PARCHMENT_PLATE") >= 0, "parchment plate constant present")
	_expect(src.find("PassageParchmentPlate") >= 0, "passage plate node built")
	_expect(src.find("Color(0.94, 0.86, 0.68, 0.34)") >= 0, "page wash alpha raised")
	_expect(src.find('normal_font_size", 18') >= 0, "passage font size 18")
	_expect(src.find('add_theme_font_size_override("font_size", 26)') >= 0, "masthead title 26")
	_expect(src.find("Color(0.10, 0.06, 0.03, 0.55)") >= 0, "header plate visible")
	_expect(src.find("Color(0.08, 0.05, 0.02, 0.62)") >= 0, "footer plate visible")
	_expect(src.find("modulate.a = 0.92") >= 0, "page-turn buttons opaque")
	_expect(src.find('config/version="0.81.0"') < 0, "version lives in project.godot not diary")
	var project := FileAccess.get_file_as_string("res://project.godot")
	_expect(project.find('config/version="0.81.0"') >= 0, "project version 0.81.0")
	_expect(src.find("OptionButton") < 0, "diary source adds no OptionButton")

	if _failures.is_empty():
		print("V081_DIARY_READABILITY_OK checks=%d" % _checks)
	else:
		print("V081_DIARY_READABILITY_FAIL checks=%d failures=%s" % [_checks, str(_failures)])
		for failure in _failures:
			push_error(failure)
	get_tree().quit(0 if _failures.is_empty() else 1)


func _expect(cond: bool, label: String) -> void:
	_checks += 1
	if not cond:
		_failures.append(label)
