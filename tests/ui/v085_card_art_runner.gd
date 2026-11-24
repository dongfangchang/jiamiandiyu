extends Node

const UiContentFixture := preload("res://tests/ui/ui_content_fixture.gd")

## v0.85 card art architecture probe.
## The point is not "the files exist" but "adding a card needs no code edit":
## every id in data/cards/** must resolve art + seal purely by convention.

const CardArt := preload("res://src/ui/card_art_catalog.gd")
const DeckCatalog := preload("res://src/ui/deck_ui_catalog.gd")
const ProgressionCatalog := preload("res://src/ui/progression_ui_catalog.gd")
const CARDS_PATH := "res://data/cards/v0.7.0/cards.json"

var _checks := 0
var _failures: Array[String] = []


func _ready() -> void:
	UiContentFixture.ensure()
	var ids := CardArt.all_card_ids()
	_expect(ids.size() >= 40, "catalog reads card data (%d ids)" % ids.size())

	## Convention: art path is derived from the id, never from a lookup table.
	var missing := CardArt.missing_art()
	_expect(missing.is_empty(), "every card has art (missing=%s)" % str(missing))

	## Seal is derived from rarity x mechanic; both must resolve for every card.
	var no_seal: Array[String] = []
	for id in ids:
		if CardArt.seal(String(id)).is_empty():
			no_seal.append(String(id))
	_expect(no_seal.is_empty(), "every card resolves a seal (missing=%s)" % str(no_seal))

	for id in ids:
		var card_id := String(id)
		_expect(
			CardArt.rarity_of(card_id) in CardArt.RARITIES,
			"%s rarity is known" % card_id
		)
		_expect(
			CardArt.mechanic_of(card_id) in CardArt.MECHANICS,
			"%s mechanic is known" % card_id
		)

	## Art window must be the 512x390 illustration, not a full card face:
	## the frame relies on that aspect.
	var sample := CardArt.art_window("card.skill.ink_dart")
	_expect(not sample.is_empty(), "sample art resolves")
	if not sample.is_empty():
		var tex := load(sample) as Texture2D
		_expect(tex != null, "sample art loads")
		if tex != null:
			_expect(
				tex.get_width() == 512 and tex.get_height() == 390,
				"art window is 512x390 (got %dx%d)" % [tex.get_width(), tex.get_height()]
			)

	## Unknown ids must degrade, and must NOT invent a plausible seal.
	_expect(CardArt.art_window("card.does.not.exist").is_empty(), "unknown id has no art")
	_expect(CardArt.seal("card.does.not.exist").is_empty(), "unknown id has no seal")
	_expect(
		CardArt.card_art("card.does.not.exist").ends_with("card-back-sealed-omen.png"),
		"unknown id falls back to card back"
	)

	## Legacy entry points must keep working — other screens still call them.
	for id in ids:
		var card_id := String(id)
		_expect(
			ResourceLoader.exists(DeckCatalog.card_art(card_id)),
			"legacy deck art resolves for %s" % card_id
		)
		_expect(
			ResourceLoader.exists(ProgressionCatalog.card_art(card_id)),
			"legacy progression art resolves for %s" % card_id
		)

	## The seal matrix must be complete, so a NEW card in any combination is
	## already covered without new art.
	var gaps: Array[String] = []
	for rarity in CardArt.RARITIES:
		for mechanic in CardArt.MECHANICS:
			var p := CardArt.seal_path(rarity, mechanic)
			if not ResourceLoader.exists(p):
				gaps.append("%s-%s" % [rarity, mechanic])
	_expect(gaps.is_empty(), "seal matrix 4x6 complete (gaps=%s)" % str(gaps))

	if _failures.is_empty():
		print("V085_CARD_ART_OK checks=%d" % _checks)
		get_tree().quit(0)
		return
	for failure in _failures:
		printerr("V085_CARD_ART_FAIL: %s" % failure)
	print("V085_CARD_ART_FAIL checks=%d failures=%s" % [_checks, str(_failures.slice(0, 6))])
	get_tree().quit(1)


func _expect(cond: bool, label: String) -> void:
	_checks += 1
	if not cond:
		_failures.append(label)
