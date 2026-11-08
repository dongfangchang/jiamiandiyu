extends Node

const BattleContentAdapterScript := preload(
	"res://src/infrastructure/battle_content_adapter.gd"
)
const BattleBalanceAdapterScript := preload(
	"res://src/infrastructure/battle_balance_adapter.gd"
)
const ProgressionContentAdapterScript := preload(
	"res://src/infrastructure/progression_content_adapter.gd"
)
const ProgressionEngineScript := preload(
	"res://src/gameplay/progression_engine.gd"
)
const ProgressionCommandScript := preload(
	"res://src/core/progression_command.gd"
)
const IdentityScreenScene := preload("res://scenes/ui/identity_screen.tscn")

var _passed := 0
var _failures: Array[String] = []


func _ready() -> void:
	var cards := _read_json("res://data/cards/v0.7.0/cards.json")
	var progression := _read_json("res://data/cards/v0.7.0/progression.json")
	var balance := _read_json("res://data/balance/v0.7.0/balance.json")
	_expect(not cards.is_empty(), "v0.7 cards should load")
	_expect(not progression.is_empty(), "v0.7 progression should load")
	_expect(not balance.is_empty(), "v0.7 balance should load")
	if cards.is_empty() or progression.is_empty() or balance.is_empty():
		_finish()
		return
	var battle_content = BattleContentAdapterScript.new(cards.get("cards", []))
	var content = ProgressionContentAdapterScript.new(
		progression,
		battle_content
	)
	var engine = ProgressionEngineScript.new(
		content,
		BattleBalanceAdapterScript.new(balance),
		FakeRandom.new(12)
	)
	var initialized = engine.initialize()
	_expect(initialized.accepted, "identity passive engine should initialize")
	var picked = engine.submit(
		ProgressionCommandScript.select_identity(&"identity.gravedigger")
	)
	_expect(picked.accepted, "gravedigger should be selectable")
	var modified = engine.apply_battle_modifiers({
		"actor_id": "player",
		"hp": 20,
		"max_hp": 20,
		"block": 0,
		"spirit": 3,
		"max_spirit": 3,
		"corruption": 0,
		"max_corruption": 10,
		"attention": 0,
		"max_attention": 10,
		"statuses": [],
	})
	_expect(
		int(modified.get("max_spirit", 0)) == 4
		and int(modified.get("spirit", 0)) == 4,
		"gravedigger should enter battle with one extra spirit"
	)
	var snapshot = engine.get_snapshot()
	var passive_text := ""
	for identity in snapshot.data.get("identity_options", []):
		if String(identity.get("id", "")) == "identity.gravedigger":
			passive_text = String(identity.get("passive_text_zh", ""))
	_expect(
		passive_text.contains("最大灵性 +1")
		and passive_text.contains("残页"),
		"gravedigger snapshot should expose readable identity benefits"
	)
	var screen = IdentityScreenScene.instantiate()
	add_child(screen)
	screen.apply_snapshot(snapshot)
	await get_tree().process_frame
	_expect(
		_contains_label_text(screen, "身份特性"),
		"identity screen should display passive benefits"
	)
	screen.queue_free()
	await get_tree().process_frame
	_finish()


func _read_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	return parsed if parsed is Dictionary else {}


func _contains_label_text(root: Node, needle: String) -> bool:
	if root is Label and (root as Label).text.contains(needle):
		return true
	for child in root.get_children():
		if _contains_label_text(child, needle):
			return true
	return false


func _finish() -> void:
	if _failures.is_empty():
		print("V012_IDENTITY_PASSIVE_OK checks=%d" % _passed)
		get_tree().quit(0)
		return
	for failure in _failures:
		printerr("V012_IDENTITY_PASSIVE_FAIL: %s" % failure)
	get_tree().quit(1)


func _expect(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
	else:
		_failures.append(message)


class FakeRandom:
	extends BattleRandomPort

	var state := 1

	func _init(seed_value: int) -> void:
		state = maxi(1, seed_value)

	func next_int(max_exclusive: int) -> int:
		if max_exclusive <= 0:
			return 0
		state = (state * 1103515245 + 12345) & 0x7fffffff
		return state % max_exclusive
