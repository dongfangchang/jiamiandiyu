extends Node

## v0.82: no per-passage plates; whole-page wash; stronger flip-3D peak.

var _checks := 0
var _failures: Array[String] = []


func _ready() -> void:
	var src := FileAccess.get_file_as_string("res://src/ui/diary_chapter_screen.gd")
	_expect(src.find("PassageParchmentPlate") < 0, "passage plate removed")
	_expect(src.find("PassageParchmentEdge") < 0, "passage plate edge removed")
	_expect(src.find("C_PARCHMENT_PLATE") < 0, "plate constant removed")
	_expect(src.find("FLIP3D_PEAK_ALPHA := 0.96") >= 0, "flip3d peak alpha raised")
	_expect(src.find("Color(0.96, 0.90, 0.74, 0.22)") >= 0, "whole-page wash kept soft")
	_expect(src.find("Color(1.12, 1.04, 0.92, 1.0)") >= 0, "book art page hearts lifted")
	_expect(src.find('INK_BASE_BB := "#1a0e06"') >= 0, "dark ink retained")
	_expect(src.find('INK_GOLD_BB := "#f0d070"') >= 0, "bright gold retained")
	_expect(src.find("light_energy = 1.55") >= 0, "flip3d key light boosted")
	var project := FileAccess.get_file_as_string("res://project.godot")
	_expect(project.find('config/version="0.82.0"') >= 0, "project version 0.82.0")

	if _failures.is_empty():
		print("V082_NO_PLATE_FLIP3D_OK checks=%d" % _checks)
	else:
		print("V082_NO_PLATE_FLIP3D_FAIL checks=%d failures=%s" % [_checks, str(_failures)])
		for failure in _failures:
			push_error(failure)
	get_tree().quit(0 if _failures.is_empty() else 1)


func _expect(cond: bool, label: String) -> void:
	_checks += 1
	if not cond:
		_failures.append(label)
