extends Node

const DeskStage := preload("res://src/ui/diary_desk_stage.gd")
const DiaryCatalog := preload("res://src/ui/diary_ui_catalog.gd")
const SceneCatalog := preload("res://src/ui/scene_ui_catalog.gd")
const TableSfx := preload("res://src/ui/table_sfx.gd")
const Ui := preload("res://src/ui/mask_ui_theme.gd")

var _checks := 0
var _failures := 0
var _activations := 0


func _ready() -> void:
	TableSfx.set_muted(true)
	var host := SubViewport.new()
	host.size = Vector2i(1280, 720)
	add_child(host)
	var desk := DeskStage.new()
	host.add_child(desk)
	desk.apply_spread(_spread(DiaryCatalog.STATE_AVAILABLE))
	await get_tree().process_frame
	await get_tree().process_frame
	var wax_art := desk.find_child("WaxSealArt", true, false) as TextureRect
	var fallback_button := desk.find_child("WaxSealButton", true, false) as Button
	if not ResourceLoader.exists(DeskStage.SEAL_PATHS[DiaryCatalog.STATE_AVAILABLE]):
		_expect(not wax_art.visible and fallback_button.visible, "missing seal preserves fallback")
	var desk_mat := desk.get_desk_mesh().material_override as StandardMaterial3D
	var wood_path := DeskStage.WOOD_PATH if ResourceLoader.exists(DeskStage.WOOD_PATH) else DeskStage.GRAIN_PATH
	_expect(desk_mat.albedo_texture.resource_path == wood_path, "desk uses wood or paper fallback")
	desk.free()

	# Stand-in textures exist only in the process resource cache where assets
	# are absent. If delivered, the actual project assets are used instead.
	var seals := {}
	for state in DeskStage.SEAL_PATHS:
		seals[state] = _texture_at(DeskStage.SEAL_PATHS[state], Vector2i(512, 512))
	var wood := _texture_at(DeskStage.WOOD_PATH, Vector2i(2048, 2048))
	var scene_id := "scene.battle.moretti_home"
	var scene_path := SceneCatalog.path_for(scene_id)
	var portrait_path := SceneCatalog.DIARY_ART_DIR.path_join(SceneCatalog.DIARY_PATHS[scene_id])
	var portrait := _texture_at(portrait_path, Vector2i(1260, 1770))
	desk = DeskStage.new()
	host.add_child(desk)
	desk.seal_activated.connect(func(_clue: Dictionary): _activations += 1)
	desk_mat = desk.get_desk_mesh().material_override as StandardMaterial3D
	_expect(desk_mat.albedo_texture == wood, "dedicated wood replaces desk grain")
	_expect(SceneCatalog.has_diary_art(scene_id), "portrait is recognized")
	_expect(SceneCatalog.diary_path_for(scene_id) == portrait_path, "left leaf selects portrait")
	_expect(SceneCatalog.path_for(scene_id) == scene_path, "full-screen scene retains landscape")

	var scene_art := desk.find_child("SceneArt", true, false) as TextureRect
	var page := desk.find_child("RightPageRoot", true, false) as Control
	var title := desk.find_child("TitleLabel", true, false) as Label
	var ink := desk.find_child("InkLabel", true, false) as Label
	var folio := desk.find_child("FolioLabel", true, false) as Label
	var wax_hit := desk.find_child("WaxSealHit", true, false) as Button
	wax_art = desk.find_child("WaxSealArt", true, false) as TextureRect
	fallback_button = desk.find_child("WaxSealButton", true, false) as Button
	_expect(folio.get_theme_font("font") == Ui.UI_FONT, "folio keeps Sans")
	if ResourceLoader.exists(Ui.DIARY_SERIF_PATH):
		var title_font := title.get_theme_font("font") as FontVariation
		var ink_font := ink.get_theme_font("font") as FontVariation
		_expect(title_font != null and title_font.base_font.resource_path == Ui.DIARY_SERIF_PATH, "title switches to Serif")
		_expect(ink_font != null and ink_font.base_font.resource_path == Ui.DIARY_SERIF_PATH, "ink switches to Serif")
		_expect(title_font != null and ink_font != null and title_font.variation_embolden > ink_font.variation_embolden, "title weight separates from ink")
	else:
		_expect(title.get_theme_font("font") == Ui.UI_FONT and ink.get_theme_font("font") == Ui.UI_FONT, "missing font preserves Sans")

	for state in [DiaryCatalog.STATE_LOCKED, DiaryCatalog.STATE_COMPLETED, DiaryCatalog.STATE_AVAILABLE]:
		var spread := _spread(state)
		spread["left_art_path"] = SceneCatalog.diary_path_for(scene_id)
		desk.apply_spread(spread)
		await get_tree().process_frame
		await get_tree().process_frame
		_expect(wax_art.visible and wax_art.texture == seals[state] and not fallback_button.visible, "seal state %d selects its art" % state)
		_expect(page.get_global_rect().encloses(wax_art.get_global_rect()), "seal state %d stays on leaf under long copy" % state)
	_expect(scene_art.stretch_mode == TextureRect.STRETCH_KEEP_ASPECT_CENTERED and scene_art.texture == portrait, "portrait fits whole leaf")
	_expect(not wax_hit.accessibility_name.is_empty(), "seal retains an accessible label")

	desk._sync_wax_hit_rect()
	var hit_rect := wax_hit.get_global_rect()
	_expect(hit_rect.size.x > 24.0 and Rect2(Vector2.ZERO, Vector2(host.size)).encloses(hit_rect), "projected seal hit stays inside 1280x720")
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.position = hit_rect.get_center()
	click.pressed = true
	host.push_input(click, true)
	click = click.duplicate() as InputEventMouseButton
	click.pressed = false
	host.push_input(click, true)
	_expect(_activations == 1, "mouse click on the projected seal activates it once")

	var fallback := _spread(DiaryCatalog.STATE_AVAILABLE)
	fallback["left_art_path"] = scene_path
	desk.apply_spread(fallback)
	_expect(scene_art.stretch_mode == TextureRect.STRETCH_KEEP_ASPECT_COVERED, "legacy landscape still fills art frame")
	print("V085_DIARY_ART_%s checks=%d failures=%d" % ["OK" if _failures == 0 else "FAIL", _checks, _failures])
	get_tree().quit(0 if _failures == 0 else 1)


func _spread(state: int) -> Dictionary:
	return {
		"title_zh": "廷根值夜者异常调查记录".repeat(12),
		"ink_zh": "窗外的脚步比雨声更轻。".repeat(60),
		"state": state,
		"clues": [{"node_id": "route.v028.first_stage.node.first_hunt", "state": state}],
	}


func _texture_at(path: String, image_size: Vector2i) -> Texture2D:
	if ResourceLoader.exists(path, "Texture2D"):
		return load(path) as Texture2D
	var pixels := Image.create_empty(image_size.x, image_size.y, false, Image.FORMAT_RGBA8)
	var texture := ImageTexture.create_from_image(pixels)
	texture.take_over_path(path)
	return texture


func _expect(condition: bool, label: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
		push_error(label)
