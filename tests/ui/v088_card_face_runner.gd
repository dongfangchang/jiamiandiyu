extends Node

## v0.88 H-01: gacha and upgrade must show the same card face as the deck
## screen (v0.85 art window + rarity x mechanic seal), not the legacy
## 40-row plate table in progression_ui_catalog.

const CardArt := preload("res://src/ui/card_art_catalog.gd")
const CardFace := preload("res://src/ui/common/card_face.gd")
const GachaScreen := preload("res://src/ui/gacha_screen.gd")
const UpgradeScreen := preload("res://src/ui/upgrade_screen.gd")
const DeckScreen := preload("res://src/ui/deck_screen.gd")

var _checks := 0
var _failures: Array[String] = []


func _ready() -> void:
	var gacha: Control = GachaScreen.new()
	var upgrade: Control = UpgradeScreen.new()
	var deck: Control = DeckScreen.new()
	add_child(gacha)
	add_child(upgrade)
	add_child(deck)

	var ids := CardArt.all_card_ids()
	_expect(ids.size() >= 40, "catalog lists cards (%d)" % ids.size())
	for id_value in ids:
		var id := String(id_value)
		var window := CardArt.art_window(id)
		_expect(not window.is_empty(), "%s has a v0.85 window" % id)
		_expect(CardFace.art_path(id) == window, "%s shared face prefers the window" % id)

		var gacha_card: Control = gacha._build_result_card(
			{"definition_id": id, "rarity": "common", "duplicate": false, "fragments": 0}, 0
		)
		var gacha_face := gacha_card.find_child("CardFace", true, false)
		_expect(gacha_face != null, "%s gacha builds a CardFace" % id)
		if gacha_face != null:
			_expect(
				CardFace.face_art_path(gacha_face) == window,
				"%s gacha shows the window (got %s)" % [id, CardFace.face_art_path(gacha_face)]
			)
			_expect(gacha_face.find_child("CardSeal", true, false) != null, "%s gacha stamps the seal" % id)
		gacha_card.free()

		var upgrade_row: Control = upgrade._build_card_row({
			"definition_id": id, "level": 1, "max_level": 3, "copies": 1,
			"fragments": 0, "next_upgrade_cost": 5,
		})
		var upgrade_face := upgrade_row.find_child("CardFace", true, false)
		_expect(upgrade_face != null, "%s upgrade builds a CardFace" % id)
		if upgrade_face != null:
			_expect(
				CardFace.face_art_path(upgrade_face) == window,
				"%s upgrade shows the window (got %s)" % [id, CardFace.face_art_path(upgrade_face)]
			)
			_expect(upgrade_face.find_child("CardSeal", true, false) != null, "%s upgrade stamps the seal" % id)
		upgrade_row.free()

		var deck_tile: Control = deck._build_card_tile({"definition_id": id, "owned": true})
		var thumb := deck_tile.find_child("CardThumb", true, false)
		_expect(thumb != null and CardFace.face_art_path(thumb) == window, "%s deck still shows the window" % id)
		deck_tile.free()

	## Unknown ids degrade to the card back and get no invented seal.
	_expect(CardFace.art_path("card.does.not.exist") == CardArt.CARD_BACK, "unknown id falls back to card back")
	_expect(CardFace.make_seal("card.does.not.exist") == null, "unknown id gets no seal")

	if _failures.is_empty():
		print("V088_CARD_FACE_OK checks=%d" % _checks)
		get_tree().quit(0)
		return
	for failure in _failures.slice(0, 20):
		printerr("V088_CARD_FACE_FAIL: %s" % failure)
	print("V088_CARD_FACE_FAIL checks=%d failures=%d" % [_checks, _failures.size()])
	get_tree().quit(1)


func _expect(cond: bool, label: String) -> void:
	_checks += 1
	if not cond:
		_failures.append(label)
