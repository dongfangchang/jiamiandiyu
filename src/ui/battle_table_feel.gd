extends RefCounted
## v0.35 battle-table helpers: diegetic meters, intent glyphs, drag thresholds.
## Presentation only — never computes rules or damage.

const UiTheme := preload("res://src/ui/mask_ui_theme.gd")

const DRAG_THRESHOLD_PX := 14.0
const HOVER_SCALE := 1.16
const INTENT_ICON := {
	"attack": "attack",
	"curse": "corruption",
	"defend": "block",
	"block": "block",
	"guard": "block",
}


static func intent_icon_id(intent_id: String, visible_fields: Dictionary = {}) -> String:
	var key := intent_id.strip_edges().to_lower()
	if INTENT_ICON.has(key):
		return String(INTENT_ICON[key])
	if int(visible_fields.get("block", 0)) > 0 and int(visible_fields.get("damage", 0)) <= 0:
		return "block"
	if int(visible_fields.get("corruption", 0)) > 0 and int(visible_fields.get("damage", 0)) <= 0:
		return "corruption"
	return "attack"


static func intent_short_zh(intent_id: String, visible_fields: Dictionary = {}) -> String:
	match intent_icon_id(intent_id, visible_fields):
		"block":
			return "防备"
		"corruption":
			return "诅咒"
		_:
			return "攻击"


static func diegetic_meter(
	title: String,
	icon_id: String,
	fill_color: Color,
	width: float = 128.0
) -> VBoxContainer:
	var result := VBoxContainer.new()
	result.name = "DiegeticMeter"
	result.add_theme_constant_override("separation", 3)
	result.custom_minimum_size = Vector2(width, 56)
	result.set_meta("meter_title", title)
	result.set_meta("fill_color", fill_color)

	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 5)
	var icon := TextureRect.new()
	icon.name = "StatusIcon"
	icon.custom_minimum_size = Vector2(18, 18)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	var icon_path := "res://assets/game/v0.24.0/v0.3.0/status/status-%s.png" % icon_id
	if ResourceLoader.exists(icon_path):
		icon.texture = load(icon_path) as Texture2D
	title_row.add_child(icon)
	title_row.add_child(UiTheme.label(title, 12, UiTheme.C_MUTED))
	result.add_child(title_row)

	var bar := ProgressBar.new()
	bar.name = "MeterBar"
	bar.custom_minimum_size = Vector2(0, 12)
	bar.max_value = 100.0
	bar.value = 0.0
	bar.show_percentage = false
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bg := UiTheme.style_box(Color("#14120e"), UiTheme.C_LINE, 1, 3)
	var fill := StyleBoxFlat.new()
	fill.bg_color = fill_color
	fill.set_corner_radius_all(3)
	bar.add_theme_stylebox_override("background", bg)
	bar.add_theme_stylebox_override("fill", fill)
	result.add_child(bar)

	var value_label := UiTheme.clip_label("—", 18, UiTheme.C_TEXT)
	value_label.name = "MeterValue"
	result.add_child(value_label)
	return result


static func set_diegetic_meter(
	meter: VBoxContainer,
	value_text: String,
	current: int,
	maximum: int,
	value_color: Color = UiTheme.C_TEXT
) -> void:
	if not is_instance_valid(meter):
		return
	var value_label := meter.get_node_or_null("MeterValue") as Label
	if is_instance_valid(value_label):
		UiTheme.set_clip_text(value_label, value_text)
		value_label.add_theme_color_override("font_color", value_color)
	var bar := meter.get_node_or_null("MeterBar") as ProgressBar
	if not is_instance_valid(bar):
		return
	bar.max_value = float(maxi(1, maximum))
	bar.value = float(clampi(current, 0, maximum))
	if meter.has_meta("fill_color"):
		var base: Color = meter.get_meta("fill_color")
		var fill := StyleBoxFlat.new()
		fill.bg_color = base if bar.value / bar.max_value < 0.85 else base.lightened(0.12)
		fill.set_corner_radius_all(3)
		bar.add_theme_stylebox_override("fill", fill)


static func missing_definition_ids(synergies_value: Variant) -> Dictionary:
	## definition_id -> true for cards that would advance a partially-satisfied synergy.
	var hints := {}
	if not synergies_value is Array:
		return hints
	for synergy_value in synergies_value:
		if not synergy_value is Dictionary:
			continue
		var synergy: Dictionary = synergy_value
		if not bool(synergy.get("in_deck", false)):
			continue
		if bool(synergy.get("triggered_this_turn", false)):
			continue
		var satisfied: Array = synergy.get("satisfied", [])
		var done := 0
		for flag in satisfied:
			if bool(flag):
				done += 1
		if done <= 0:
			continue
		var index := 0
		for group in synergy.get("requires", []):
			var group_satisfied := index < satisfied.size() and bool(satisfied[index])
			if not group_satisfied and group is Array:
				for card_id in group:
					hints[String(card_id)] = true
			index += 1
	return hints
