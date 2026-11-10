extends Node

## v0.31.0 canon sampling: runs every deck preset against every Tingen
## encounter with a simple greedy policy (play affordable cards left to right,
## lowest-HP enemy first) and reports win rate, average rounds and remaining HP.
## It is a sanity probe for difficulty, not a balance proof.
##
## godot --headless --path . res://tools/simulation/v031_canon_sampling_runner.tscn

const BattleEngineScript := preload("res://src/gameplay/battle_engine.gd")
const BattleCommandScript := preload("res://src/core/battle_command.gd")
const BattleContentAdapterScript := preload("res://src/infrastructure/battle_content_adapter.gd")
const BattleBalanceAdapterScript := preload("res://src/infrastructure/battle_balance_adapter.gd")
const CampaignContentCatalogScript := preload("res://src/infrastructure/campaign_content_catalog.gd")
const SeededRandomServiceScript := preload("res://src/infrastructure/seeded_random_service.gd")
const BattleRandomAdapterScript := preload("res://src/infrastructure/battle_random_adapter.gd")

const RUNS := 60
const ENCOUNTERS := [
	"encounter.first_hunt",
	"encounter.v028.tenant_trace",
	"encounter.mirror_pursuit",
	"encounter.v028.boundary",
	"encounter.v070.twin_pursuit",
	"encounter.v031.cargo_ship",
	"encounter.mirror_baron",
	"encounter.v070.broken_baron",
]


func _ready() -> void:
	var cards: Dictionary = _read("res://data/cards/v0.7.0/cards.json")
	var decks: Dictionary = _read("res://data/decks/v0.7.0/decks.json")
	var balance := BattleBalanceAdapterScript.new(_read("res://data/balance/v0.7.0/balance.json"))
	var catalog = CampaignContentCatalogScript.new()
	catalog.load_from_documents(cards, _read("res://data/enemies/v0.7.0/enemies.json"), _read("res://data/encounters/v0.7.0/encounters.json"))
	var content := BattleContentAdapterScript.new(cards.get("cards", []), cards.get("synergies", []))
	var lines: Array[String] = []
	for preset in decks.get("presets", []):
		for encounter_id in ENCOUNTERS:
			var resolved = catalog.resolve_encounter(StringName(encounter_id))
			var wins := 0
			var rounds := 0
			var hp_left := 0
			var synergies := 0
			for run in range(RUNS):
				var outcome := _run(content, balance, preset.get("card_definition_ids", []), resolved.data.enemy_configs, run)
				if outcome.victory:
					wins += 1
					hp_left += outcome.hp
				rounds += outcome.rounds
				synergies += outcome.synergies
			lines.append("%-10s %-30s win=%3d%% rounds=%.1f hp_on_win=%.1f synergies/run=%.2f" % [
				String(preset.get("id", "")).get_slice(".", 2),
				encounter_id,
				int(100.0 * wins / RUNS),
				float(rounds) / RUNS,
				float(hp_left) / maxf(1.0, wins),
				float(synergies) / RUNS,
			])
	for line in lines:
		print(line)
	print("V031_CANON_SAMPLING_DONE")
	get_tree().quit(0)


func _run(content, balance, deck: Array, enemy_configs: Array, seed_value: int) -> Dictionary:
	var engine = BattleEngineScript.new()
	var random := BattleRandomAdapterScript.new(SeededRandomServiceScript.new(1000 + seed_value).get_stream(&"sample"))
	engine.initialize(content, balance, random, &"battle.sample", {
		"actor_id": "player", "hp": 54, "max_hp": 54, "block": 0, "spirit": 3, "max_spirit": 3,
		"corruption": 0, "max_corruption": 10, "attention": 0, "max_attention": 10, "statuses": [],
	}, deck, enemy_configs)
	var synergies := 0
	for _turn in range(12):
		var snapshot: Dictionary = engine.get_snapshot().data
		if not String(snapshot.get("outcome", "")).is_empty():
			break
		var progressed := true
		while progressed:
			progressed = false
			snapshot = engine.get_snapshot().data
			if not String(snapshot.get("outcome", "")).is_empty():
				break
			for card in snapshot.get("hand", []):
				var target := &""
				if String(card.get("target_type", "")) == "enemy":
					target = _lowest(snapshot)
				var query = engine.query_card_play(StringName(card.get("instance_id", "")), target)
				if not query.playable:
					continue
				var result = engine.submit(BattleCommandScript.play_card(StringName(card.get("instance_id", "")), target))
				for event in result.events:
					if event.type == &"SynergyTriggered":
						synergies += 1
				progressed = true
				break
		if String(engine.get_snapshot().data.get("outcome", "")).is_empty():
			engine.submit(BattleCommandScript.end_turn())
	var final: Dictionary = engine.get_snapshot().data
	return {
		"victory": String(final.get("outcome", "")) == "victory",
		"rounds": int(final.get("round_number", 0)),
		"hp": int(final.get("player", {}).get("hp", 0)),
		"synergies": synergies,
	}


func _lowest(snapshot: Dictionary) -> StringName:
	var best := &""
	var best_hp := 1 << 30
	for enemy in snapshot.get("enemies", []):
		if int(enemy.get("hp", 0)) > 0 and int(enemy.get("hp", 0)) < best_hp:
			best_hp = int(enemy.get("hp", 0))
			best = StringName(enemy.get("actor_id", ""))
	return best


func _read(path: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}
