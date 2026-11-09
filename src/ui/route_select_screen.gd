extends Control

signal route_selected(route_id: StringName)
signal back_requested

const UiTheme := preload("res://src/ui/mask_ui_theme.gd")
const RouteCatalog := preload("res://src/ui/route_ui_catalog.gd")

var _routes: Array[Dictionary] = []
var _cards: HBoxContainer
var _status_label: Label
var _back_button: Button


func _ready() -> void:
	theme = UiTheme.build_theme()
	_build()
	_render_routes()


func set_routes(routes: Array[Dictionary]) -> void:
	_routes = routes.duplicate(true)
	if is_instance_valid(_cards):
		_render_routes()


func get_route_count() -> int:
	return _routes.size()


func choose_route(route_id: String) -> void:
	for route in _routes:
		if String(route.get("id", "")) == route_id:
			route_selected.emit(StringName(route_id))
			return
	if is_instance_valid(_status_label):
		_status_label.text = "这条调查路线不可用。"


func request_back() -> void:
	back_requested.emit()


func get_background_path() -> String:
	return RouteCatalog.ROUTE_BACKGROUND


func _build() -> void:
	UiTheme.add_background(
		self,
		RouteCatalog.ROUTE_BACKGROUND,
		UiTheme.C_BG,
		RouteCatalog.ROUTE_BACKGROUND_DIM
	)
	var safe := MarginContainer.new()
	safe.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	safe.add_theme_constant_override("margin_left", 72)
	safe.add_theme_constant_override("margin_top", 54)
	safe.add_theme_constant_override("margin_right", 72)
	safe.add_theme_constant_override("margin_bottom", 46)
	add_child(safe)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 18)
	safe.add_child(column)
	var header := VBoxContainer.new()
	header.add_theme_constant_override("separation", 6)
	header.add_child(UiTheme.label("雾都入口 · 调查路线", 12, UiTheme.C_GOLD))
	header.add_child(UiTheme.label("选择调查路线", 38, UiTheme.C_TEXT))
	header.add_child(UiTheme.wrapped_label(
		"不同路线复用同一套牌组与敌人，但节点顺序、资源压力和遭遇组合不同。",
		15,
		UiTheme.C_MUTED
	))
	column.add_child(UiTheme.padded_panel(
		header,
		14,
		Color(0.045, 0.049, 0.041, 0.92),
		UiTheme.C_LINE
	))
	var divider := ColorRect.new()
	divider.color = UiTheme.C_LINE
	divider.custom_minimum_size = Vector2(0, 1)
	column.add_child(divider)
	var cards_scroll := ScrollContainer.new()
	cards_scroll.name = "RouteCardsScroll"
	cards_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	cards_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	cards_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cards_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(cards_scroll)
	_cards = HBoxContainer.new()
	_cards.add_theme_constant_override("separation", 18)
	_cards.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_cards.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	cards_scroll.add_child(_cards)
	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 12)
	column.add_child(footer)
	_status_label = UiTheme.wrapped_label(
		"选择一条路线后进入白昼身份选择。",
		14,
		UiTheme.C_MUTED
	)
	_status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(_status_label)
	_back_button = UiTheme.button("返回标题", request_back, false, 150)
	footer.add_child(_back_button)


func _render_routes() -> void:
	if not is_instance_valid(_cards):
		return
	for child in _cards.get_children():
		child.free()
	for route in _routes:
		_cards.add_child(_build_route_card(route))


func _build_route_card(route: Dictionary) -> Control:
	var route_id := String(route.get("id", ""))
	var panel := UiTheme.panel(
		Color(0.055, 0.059, 0.048, 0.98),
		UiTheme.C_GOLD
	)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var pad := MarginContainer.new()
	pad.add_theme_constant_override("margin_left", 26)
	pad.add_theme_constant_override("margin_top", 24)
	pad.add_theme_constant_override("margin_right", 26)
	pad.add_theme_constant_override("margin_bottom", 24)
	panel.add_child(pad)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 16)
	pad.add_child(column)
	var icon := TextureRect.new()
	icon.texture = load(RouteCatalog.ROUTE_ICON_BASE + "route-current.png")
	icon.custom_minimum_size = Vector2(112, 112)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	column.add_child(icon)
	column.add_child(UiTheme.center_label(
		String(route.get("display_name_zh", "未知路线")),
		28,
		UiTheme.C_TEXT
	))
	var description := UiTheme.wrapped_label(
		String(route.get("description_zh", "")),
		15,
		UiTheme.C_MUTED
	)
	description.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(description)
	column.add_child(UiTheme.center_label(
		"五节点调查 · 独立资源节奏",
		13,
		UiTheme.C_GOLD
	))
	column.add_child(UiTheme.button(
		"选择此路线",
		func() -> void: choose_route(route_id),
		true,
		0
	))
	return panel
