extends SceneTree

const UiTheme := preload("res://src/ui/mask_ui_theme.gd")

var _characters: Dictionary = {}
var _missing: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_collect_characters("res://src/ui")
	_collect_characters("res://data")
	var font := UiTheme.build_theme().default_font
	for character in _characters:
		if not font.has_char(String(character).unicode_at(0)):
			_missing.append(character)
	if not _missing.is_empty():
		printerr("V030_FONT_FAILED missing=" + "".join(_missing))
		quit(1)
		return
	if DisplayServer.get_name() != "headless":
		root.size = Vector2i(1100, 700)
		var panel := PanelContainer.new()
		panel.theme = UiTheme.build_theme()
		panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		root.add_child(panel)
		var text := UiTheme.wrapped_label(
			"中文字体回归\n\n敌方 · 稳守 · 防御 · 提灯步 · 诡秘之主\n目标：敌方\n已拥有 · 需序列 8\n序列未解锁\n当前序列尚未解锁这张卡，请晋升至卡牌所需序列后再加入。\n\n守夜档案：适合先熟悉敌方压力，再用护盾和治疗稳住路线。",
			28
		)
		panel.add_child(UiTheme.padded_panel(text, 32))
		await process_frame
		await RenderingServer.frame_post_draw
		DirAccess.make_dir_recursive_absolute("res://.tools/ui-captures/v0.30.0")
		var result := root.get_texture().get_image().save_png("res://.tools/ui-captures/v0.30.0/chinese-font.png")
		if result != OK:
			quit(1)
			return
	print("V030_FONT_OK glyphs=%d" % _characters.size())
	quit(0)


func _collect_characters(directory: String) -> void:
	for filename in DirAccess.get_files_at(directory):
		if filename.get_extension() not in ["gd", "json"]:
			continue
		for character in FileAccess.get_file_as_string(directory.path_join(filename)):
			var codepoint := character.unicode_at(0)
			if codepoint >= 0x3400 and codepoint <= 0x9fff:
				_characters[character] = true
	for child in DirAccess.get_directories_at(directory):
		_collect_characters(directory.path_join(child))
