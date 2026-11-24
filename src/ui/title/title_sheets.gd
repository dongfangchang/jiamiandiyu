extends RefCounted

## Second slips laid over the title desk: settings (with backup restore),
## the overwrite confirmation, the first-run guide and the feedback form.
## Every control on them is a text item (title_paper.text_item).

const Paper := preload("res://src/ui/title/title_paper.gd")

const SCALE_VALUES: Array[float] = [0.9, 1.0, 1.1]
const FEEDBACK_STAGES: Array[String] = ["overall", "deck", "battle", "growth", "route", "challenge"]
const FEEDBACK_PACING: Array[String] = ["good", "too_fast", "too_slow"]
const TUTORIAL_STEPS: Array[String] = [
	"第一步：选择一项白昼身份。身份会改变一项战斗或资源倾向；先看清被动，再开始路线。",
	"第二步：确认一套八张唯一卡牌。进入战斗后，点击整张手牌查看费用、目标和当前是否可打出。",
	"第三步：选中卡牌后点击三列中的敌人。页面底部会显示当前选择和规则层返回的原因。",
	"第四步：灵性用完或完成本回合计划后，点击“结束回合”。敌人行动后才会进入下一回合。",
	"第五步：污染与被注视会改变路线风险。休息时在即时生命和下一战资源之间取舍。",
	"第六步：首领战后完成短仪式即可晋升。检查点只在安全边界保存，退出后可从最近检查点继续。",
]

var _screen: Control
var _settings: Control
var _settings_notice: Label
var _restore_item: Button
var _confirm: Control
var _tutorial: Control
var _tutorial_body: Label
var _tutorial_progress: Label
var _tutorial_step := 0
var _feedback: Control
var _feedback_text: TextEdit
var _feedback_status: Label
var _feedback_stage := 0
var _feedback_pacing := 0
var _feedback_stuck := false


func _init(screen: Control) -> void:
	_screen = screen


func is_settings_open() -> bool:
	return is_instance_valid(_settings)


func is_confirm_open() -> bool:
	return is_instance_valid(_confirm)


func is_tutorial_open() -> bool:
	return is_instance_valid(_tutorial)


func set_backup_available(available: bool) -> void:
	if is_instance_valid(_restore_item):
		_restore_item.disabled = not available


func show_settings_notice(text_value: String) -> void:
	if is_instance_valid(_settings_notice):
		_settings_notice.text = text_value


## --- Settings --------------------------------------------------------------

func open_settings(preferences: Dictionary, backup_available: bool) -> void:
	close_settings()
	var sheet := Paper.modal_sheet(_screen, Vector2(640, 0), "SettingsSlip")
	_settings = sheet["blocker"]
	var content: VBoxContainer = sheet["content"]
	content.add_child(Paper.ink_label("设置", 32, Paper.INK, true))
	content.add_child(Paper.wrapped_ink(
		"身份决定一项资源或战斗修正；八张牌组决定可用手段。"
		+ "战斗中会提升污染与被注视，休息和仪式用于控制风险。",
		17,
		Paper.INK_SOFT
	))
	content.add_child(Paper.rule())
	content.add_child(_toggle_item("FullscreenToggle", "全屏显示", "fullscreen", preferences))
	content.add_child(_toggle_item("ReduceFlashToggle", "减少闪烁与高对比反馈", "reduce_flash", preferences))
	content.add_child(_toggle_item("MuteSfxToggle", "静音桌面音效", "mute_sfx", preferences))

	var scale_row := HBoxContainer.new()
	scale_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scale_row.add_theme_constant_override("separation", 18)
	scale_row.add_child(Paper.ink_label("界面缩放", 22, Paper.INK))
	scale_row.add_child(Paper.choice_row(
		["90%", "100%", "110%"],
		_nearest_scale(float(preferences.get("ui_scale", 1.0))),
		func(index: int) -> void:
			_screen.set_preference("ui_scale", SCALE_VALUES[clampi(index, 0, 2)])
	))
	content.add_child(scale_row)

	var help := Paper.wrapped_ink("战斗：拖放打出 · 弃置献祭坛 · 点选仍可用", 16, Paper.INK_SOFT)
	help.name = "OpsHint"
	help.mouse_filter = Control.MOUSE_FILTER_PASS
	help.tooltip_text = (
		"档案蜡封进牌组/祈愿；打开日记续读主线线索。"
		+ "检查点仅在节点或战斗结算后保存；战斗中退出回到最近检查点。"
		+ "存档位于 user://saves，设置在 user://preferences.json。"
	)
	content.add_child(help)
	content.add_child(Paper.rule())
	content.add_child(Paper.text_item("重新查看新手引导", open_tutorial, 22))
	content.add_child(Paper.text_item("记录试玩反馈", open_feedback, 22))
	_restore_item = Paper.text_item("恢复上次备份", _screen.request_restore_backup, 22)
	_restore_item.disabled = not backup_available
	content.add_child(_restore_item)
	_settings_notice = Paper.wrapped_ink("", 15, Paper.INK_SOFT)
	content.add_child(_settings_notice)
	var close := Paper.text_item("合上", close_settings, 24)
	close.size_flags_horizontal = Control.SIZE_SHRINK_END
	content.add_child(close)
	close.grab_focus.call_deferred()


func close_settings() -> void:
	if is_instance_valid(_settings):
		_settings.queue_free()
		_screen.remove_child(_settings)
	_settings = null
	_settings_notice = null
	_restore_item = null


func _toggle_item(node_name: String, label: String, key: String, preferences: Dictionary) -> Button:
	var item := Paper.text_item("", Callable(), 22)
	item.name = node_name
	item.toggle_mode = true
	item.button_pressed = bool(preferences.get(key, false))
	var paint := func() -> void:
		item.text = "%s · %s" % [label, "开" if item.button_pressed else "关"]
	paint.call()
	item.toggled.connect(func(enabled: bool) -> void:
		paint.call()
		_screen.set_preference(key, enabled)
	)
	return item


func _nearest_scale(target: float) -> int:
	var best := 0
	for index in SCALE_VALUES.size():
		if absf(SCALE_VALUES[index] - target) < absf(SCALE_VALUES[best] - target):
			best = index
	return best


## --- Overwrite confirmation ------------------------------------------------

func open_confirm_new_game() -> void:
	if is_instance_valid(_confirm):
		return
	var sheet := Paper.modal_sheet(_screen, Vector2(560, 0), "ConfirmSlip")
	_confirm = sheet["blocker"]
	var content: VBoxContainer = sheet["content"]
	content.add_child(Paper.ink_label("覆盖当前进度？", 30, Paper.INK, true))
	content.add_child(Paper.wrapped_ink(
		"开始新的日记会从下一检查点起覆盖当前存档。"
		+ "最近一次备份会保留，但可能不是最新进度。",
		18,
		Paper.INK_SOFT
	))
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.alignment = BoxContainer.ALIGNMENT_END
	row.add_theme_constant_override("separation", 28)
	content.add_child(row)
	var cancel := Paper.text_item("取消", close_confirm, 24)
	row.add_child(cancel)
	row.add_child(Paper.text_item("开始新的日记", func() -> void:
		close_confirm()
		_screen.confirm_new_game()
	, 24))
	cancel.grab_focus.call_deferred()


func close_confirm() -> void:
	if is_instance_valid(_confirm):
		_confirm.queue_free()
		_screen.remove_child(_confirm)
	_confirm = null


## --- First-run guide -------------------------------------------------------

func open_tutorial() -> void:
	close_settings()
	close_tutorial()
	_tutorial_step = 0
	var sheet := Paper.modal_sheet(_screen, Vector2(760, 380), "TutorialSlip")
	_tutorial = sheet["blocker"]
	var content: VBoxContainer = sheet["content"]
	content.add_child(Paper.ink_label("首次游玩指引", 28, Paper.INK, true))
	_tutorial_body = Paper.wrapped_ink("", 22, Paper.INK)
	_tutorial_body.custom_minimum_size = Vector2(10, 150)
	content.add_child(_tutorial_body)
	_tutorial_progress = Paper.ink_label("", 16, Paper.INK_SOFT)
	content.add_child(_tutorial_progress)
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.alignment = BoxContainer.ALIGNMENT_END
	row.add_theme_constant_override("separation", 28)
	content.add_child(row)
	row.add_child(Paper.text_item("跳过", finish_tutorial, 24))
	var next := Paper.text_item("下一步", advance_tutorial, 24)
	row.add_child(next)
	_paint_tutorial()
	next.grab_focus.call_deferred()


func advance_tutorial() -> void:
	_tutorial_step += 1
	if _tutorial_step >= TUTORIAL_STEPS.size():
		finish_tutorial()
		return
	_paint_tutorial()


func finish_tutorial() -> void:
	close_tutorial()
	_screen.set_preference("tutorial_seen", true)


func close_tutorial() -> void:
	if is_instance_valid(_tutorial):
		_tutorial.queue_free()
		_screen.remove_child(_tutorial)
	_tutorial = null


func tutorial_step() -> int:
	return _tutorial_step


func _paint_tutorial() -> void:
	if not is_instance_valid(_tutorial_body):
		return
	_tutorial_body.text = TUTORIAL_STEPS[clampi(_tutorial_step, 0, TUTORIAL_STEPS.size() - 1)]
	_tutorial_progress.text = "%d / %d" % [_tutorial_step + 1, TUTORIAL_STEPS.size()]


## --- Feedback --------------------------------------------------------------

func open_feedback() -> void:
	close_settings()
	close_feedback()
	_feedback_stage = 0
	_feedback_pacing = 0
	_feedback_stuck = false
	var sheet := Paper.modal_sheet(_screen, Vector2(760, 0), "FeedbackSlip")
	_feedback = sheet["blocker"]
	var content: VBoxContainer = sheet["content"]
	content.add_child(Paper.ink_label("记录试玩反馈", 28, Paper.INK, true))
	content.add_child(Paper.ink_label("仅保存在本机，不上传", 16, Paper.INK_SOFT))
	_feedback_text = TextEdit.new()
	_feedback_text.name = "FeedbackText"
	_feedback_text.custom_minimum_size = Vector2(0, 150)
	_feedback_text.placeholder_text = "哪里有趣、哪里卡住、节奏是否合适……"
	_feedback_text.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	_feedback_text.add_theme_font_override("font", Paper.ink_font(false))
	_feedback_text.add_theme_font_size_override("font_size", 18)
	_feedback_text.add_theme_color_override("font_color", Paper.INK)
	_feedback_text.add_theme_color_override("font_placeholder_color", Paper.INK_DISABLED)
	_feedback_text.add_theme_color_override("caret_color", Paper.INK)
	var field := StyleBoxFlat.new()
	field.bg_color = Paper.INK_FIELD
	field.border_color = Paper.INK_RULE
	field.border_width_bottom = 1
	field.set_content_margin_all(8)
	_feedback_text.add_theme_stylebox_override("normal", field)
	_feedback_text.add_theme_stylebox_override("focus", field)
	content.add_child(_feedback_text)
	content.add_child(Paper.ink_label("反馈范围", 16, Paper.INK_SOFT))
	content.add_child(Paper.choice_row(
		["整体", "牌组", "战斗", "成长", "路线", "挑战"], 0,
		func(index: int) -> void: _feedback_stage = index, 20
	))
	content.add_child(Paper.ink_label("节奏感受", 16, Paper.INK_SOFT))
	content.add_child(Paper.choice_row(
		["合适", "偏快", "偏慢"], 0,
		func(index: int) -> void: _feedback_pacing = index, 20
	))
	var stuck := Paper.text_item("", Callable(), 20)
	stuck.toggle_mode = true
	var paint := func() -> void:
		stuck.text = "当前有卡住或无法继续 · %s" % ("是" if stuck.button_pressed else "否")
	paint.call()
	stuck.toggled.connect(func(enabled: bool) -> void:
		_feedback_stuck = enabled
		paint.call()
	)
	content.add_child(stuck)
	_feedback_status = Paper.wrapped_ink("", 16, Paper.INK_SOFT)
	content.add_child(_feedback_status)
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.alignment = BoxContainer.ALIGNMENT_END
	row.add_theme_constant_override("separation", 28)
	content.add_child(row)
	row.add_child(Paper.text_item("取消", close_feedback, 24))
	row.add_child(Paper.text_item("保存反馈", submit_feedback, 24))


func set_feedback_text(text_value: String) -> void:
	if is_instance_valid(_feedback_text):
		_feedback_text.text = text_value


func submit_feedback() -> void:
	if not is_instance_valid(_feedback_text):
		return
	if _feedback_text.text.strip_edges().is_empty():
		_feedback_status.text = "请先写下一句反馈。"
		_feedback_status.add_theme_color_override("font_color", Paper.INK_ACTIVE)
		return
	_screen.submit_feedback({
		"text": _feedback_text.text,
		"stage": FEEDBACK_STAGES[clampi(_feedback_stage, 0, FEEDBACK_STAGES.size() - 1)],
		"stuck": _feedback_stuck,
		"pacing": FEEDBACK_PACING[clampi(_feedback_pacing, 0, FEEDBACK_PACING.size() - 1)],
	})


func show_feedback_result(success: bool, message: String) -> void:
	if not is_instance_valid(_feedback_status):
		return
	_feedback_status.text = "反馈已保存。" if success else "反馈保存失败：" + message
	_feedback_status.add_theme_color_override(
		"font_color", Paper.INK_SOFT if success else Paper.INK_ACTIVE
	)
	if success and _screen.is_inside_tree():
		_screen.get_tree().create_timer(0.8).timeout.connect(close_feedback)


func close_feedback() -> void:
	if is_instance_valid(_feedback):
		_feedback.queue_free()
		_screen.remove_child(_feedback)
	_feedback = null
	_feedback_text = null
	_feedback_status = null
