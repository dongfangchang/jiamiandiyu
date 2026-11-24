extends SceneTree

## One-shot migration (R2-10): writes data/registry/assets.json from the path
## tables that used to live in src/ui/*_catalog.gd and battle_screen.gd, plus a
## scan of the v0.85 card / seal / diary delivery folders.
##
##   godot --headless --path . --script res://tools/gen_asset_registry.gd
##
## After the migration the JSON is the single source of truth: the coordinator
## edits it when ingesting assets. Re-running this script restores the v0.88
## baseline and overwrites hand edits, so only do it deliberately.

const OUT_PATH := "res://data/registry/assets.json"
const CARDS_PATH := "res://data/cards/v0.7.0/cards.json"
const CARD_WINDOW_DIR := "res://assets/game/v0.85.0/cards"
const SEAL_DIR := "res://assets/game/v0.85.0/seals"
const DIARY_DIR := "res://assets/game/v0.85.0/diary"
const STATUS_DIR := "res://assets/game/v0.24.0/v0.3.0/status"
const PROP_DIR := "res://assets/ui/diary/props"

const UI_CANVAS := "res://assets/game/v0.54.0/scenes/ui-canvas-gothic-rain-night.png"
const BATTLE_FALLBACK := "res://assets/game/v0.24.0/v0.3.0/scenes/battle-tingen-old-house.png"
const CARD_BACK := "res://assets/game/v0.24.0/v0.4.0/cards/card-back-sealed-omen.png"

const RARITIES: Array[String] = ["common", "uncommon", "rare", "mythic"]
const MECHANICS: Array[String] = ["attack", "defense", "ritual", "divination", "support", "curse"]

## Legacy composed card plates (was progression_ui_catalog.CARD_ART, identical
## to deck_ui_catalog's version-directory resolution for all 40 cards).
const CARD_PLATES := {
	"card.skill.ink_dart": "res://assets/game/v0.24.0/v0.3.0/cards/card-skill-ink-dart.png",
	"card.skill.paper_guard": "res://assets/game/v0.24.0/v0.3.0/cards/card-skill-paper-guard.png",
	"card.skill.calm_breath": "res://assets/game/v0.24.0/v0.3.0/cards/card-skill-calm-breath.png",
	"card.skill.focus": "res://assets/game/v0.24.0/v0.3.0/cards/card-skill-focus.png",
	"card.skill.insight": "res://assets/game/v0.24.0/v0.3.0/cards/card-skill-insight.png",
	"card.skill.omen": "res://assets/game/v0.24.0/v0.3.0/cards/card-skill-omen.png",
	"card.skill.whisper": "res://assets/game/v0.24.0/v0.3.0/cards/card-skill-whisper.png",
	"card.skill.second_look": "res://assets/game/v0.24.0/v0.3.0/cards/card-skill-second-look.png",
	"card.skill.warding_circle": "res://assets/game/v0.24.0/v0.7.0/cards/card_skill_warding_circle.png",
	"card.skill.lantern_step": "res://assets/game/v0.24.0/v0.7.0/cards/card_skill_lantern_step.png",
	"card.skill.whispered_hunch": "res://assets/game/v0.24.0/v0.7.0/cards/card_skill_whispered_hunch.png",
	"card.skill.mirrored_memory": "res://assets/game/v0.24.0/v0.7.0/cards/card_skill_mirrored_memory.png",
	"card.skill.fated_echo": "res://assets/game/v0.24.0/v0.7.0/cards/card_skill_fated_echo.png",
	"card.skill.piercing_omen": "res://assets/game/v0.24.0/v0.7.0/cards/card_skill_piercing_omen.png",
	"card.skill.coffin_nail": "res://assets/game/v0.24.0/v0.7.0/cards/card_skill_coffin_nail.png",
	"card.skill.second_sight": "res://assets/game/v0.24.0/v0.7.0/cards/card_skill_second_sight.png",
	"card.skill.dream_question": "res://assets/game/v0.24.0/v0.13.0/cards/card_skill_dream_question.png",
	"card.skill.mirror_ward": "res://assets/game/v0.24.0/v0.13.0/cards/card_skill_mirror_ward.png",
	"card.skill.severed_string": "res://assets/game/v0.24.0/v0.13.0/cards/card_skill_severed_string.png",
	"card.skill.last_rites": "res://assets/game/v0.24.0/v0.13.0/cards/card_skill_last_rites.png",
	"card.skill.veil_step": "res://assets/game/v0.41.0/cards/card_skill_veil_step.png",
	"card.skill.severed_fate": "res://assets/game/v0.41.0/cards/card_skill_severed_fate.png",
	"card.skill.paper_swarm": "res://assets/game/v0.41.0/cards/card_skill_paper_swarm.png",
	"card.skill.mirror_shard": "res://assets/game/v0.41.0/cards/card_skill_mirror_shard.png",
	"card.skill.last_witness": "res://assets/game/v0.41.0/cards/card_skill_last_witness.png",
	"card.skill.false_death": "res://assets/game/v0.41.0/cards/card_skill_false_death.png",
	"card.skill.sealed_answer": "res://assets/game/v0.41.0/cards/card_skill_sealed_answer.png",
	"card.skill.hollow_bell": "res://assets/game/v0.41.0/cards/card_skill_hollow_bell.png",
	"card.skill.ink_scarlet": "res://assets/game/v0.42.0/cards/card_skill_ink_scarlet.png",
	"card.skill.echo_reading": "res://assets/game/v0.42.0/cards/card_skill_echo_reading.png",
	"card.skill.midnight_ledger": "res://assets/game/v0.42.0/cards/card_skill_midnight_ledger.png",
	"card.skill.borrowed_breath": "res://assets/game/v0.42.0/cards/card_skill_borrowed_breath.png",
	"card.skill.glass_thesis": "res://assets/game/v0.42.0/cards/card_skill_glass_thesis.png",
	"card.skill.hungry_symbol": "res://assets/game/v0.42.0/cards/card_skill_hungry_symbol.png",
	"card.skill.candle_archive": "res://assets/game/v0.42.0/cards/card_skill_candle_archive.png",
	"card.skill.omen_chorus": "res://assets/game/v0.42.0/cards/card_skill_omen_chorus.png",
	"card.skill.closed_eye": "res://assets/game/v0.42.0/cards/card_skill_closed_eye.png",
	"card.skill.black_thread": "res://assets/game/v0.42.0/cards/card_skill_black_thread.png",
	"card.skill.eclipse": "res://assets/game/v0.42.0/cards/card_skill_eclipse.png",
	"card.skill.red_corridor": "res://assets/game/v0.42.0/cards/card_skill_red_corridor.png",
}

const ENEMIES := {
	"enemy.candle_moth": "res://assets/game/v0.48.0/enemies/enemy-candle-moth.png",
	"enemy.tingen.kidnapper": "res://assets/game/v0.48.0/enemies/enemy-tingen-kidnapper.png",
	"enemy.mirror_hound": "res://assets/game/v0.48.0/enemies/enemy-mirror-hound.png",
	"enemy.tingen.rampager": "res://assets/game/v0.48.0/enemies/enemy-tingen-rampager.png",
	"enemy.mirror_hound_echo": "res://assets/game/v0.48.0/enemies/enemy-mirror-hound-echo.png",
	"enemy.weeping_tenant": "res://assets/game/v0.48.0/enemies/enemy-weeping-tenant.png",
	"enemy.tingen.knight_wraith": "res://assets/game/v0.48.0/enemies/enemy-tingen-knight-wraith.png",
	"enemy.mirror_baron": "res://assets/game/v0.48.0/enemies/enemy-mirror-baron.png",
	"enemy.tingen.megose": "res://assets/game/v0.48.0/enemies/enemy-tingen-megose.png",
}

const IDENTITIES := {
	"identity.reporter": "res://assets/game/v0.48.0/identities/card-identity-reporter.png",
	"identity.doctor": "res://assets/game/v0.48.0/identities/card-identity-doctor.png",
	"identity.gravedigger": "res://assets/game/v0.48.0/identities/card-identity-gravedigger.png",
}

const SCENES := {
	"scene.battle.tingen_old_house": BATTLE_FALLBACK,
	"scene.battle.tyrell_warehouse": "res://assets/game/v0.44.0/scenes/battle-tyrell-warehouse.png",
	"scene.battle.blackthorn_neil": "res://assets/game/v0.44.0/scenes/battle-blackthorn-neil.png",
	"scene.battle.lamud_chapel": "res://assets/game/v0.44.0/scenes/battle-lamud-chapel.png",
	"scene.battle.moretti_home": "res://assets/game/v0.45.0/scenes/battle-moretti-home.png",
	"scene.battle.elliot_ruin": "res://assets/game/v0.45.0/scenes/battle-elliot-ruin.png",
	"scene.battle.wood_house": "res://assets/game/v0.45.0/scenes/battle-wood-house.png",
	"scene.battle.megose_descent": "res://assets/game/v0.46.0/scenes/battle-megose-descent.png",
	"scene.rest.divination_club": "res://assets/game/v0.44.0/scenes/rest-divination-club.png",
	"scene.rest.chanis_gate": "res://assets/game/v0.46.0/scenes/rest-chanis-gate.png",
	"scene.hub.rest_blackthorn": UI_CANVAS,
	"scene.ritual.clown_ascension": "res://assets/game/v0.44.0/scenes/ritual-clown-ascension.png",
	"scene.ritual.obituary": UI_CANVAS,
	"scene.ritual.above_fog": "res://assets/game/v0.46.0/scenes/ritual-above-fog.png",
	"scene.ritual.ascension": UI_CANVAS,
	"scene.title.mask_desk": UI_CANVAS,
	"scene.hub.route_map": UI_CANVAS,
	"scene.hub.deck_archive": UI_CANVAS,
	"scene.hub.gacha_altar": UI_CANVAS,
	"scene.hub.reward_archive": UI_CANVAS,
	"scene.hub.challenge_board": UI_CANVAS,
	"scene.hub.challenge_result": UI_CANVAS,
	"scene.ui.canvas": UI_CANVAS,
}

## Portrait diary-leaf art keyed by the scene it illustrates.
const DIARY_PAGES := {
	"scene.battle.moretti_home": "battle-moretti-home.png",
	"scene.battle.elliot_ruin": "battle-elliot-ruin.png",
	"scene.battle.tyrell_warehouse": "battle-tyrell-warehouse.png",
	"scene.battle.wood_house": "battle-wood-house.png",
	"scene.rest.divination_club": "rest-divination-club.png",
	"scene.battle.lamud_chapel": "battle-lamud-chapel.png",
	"scene.battle.blackthorn_neil": "battle-blackthorn-neil.png",
	"scene.ritual.clown_ascension": "ritual-clown-ascension.png",
}

const ICONS := {
	"icon.reward.divination_tickets": "res://assets/game/v0.24.0/v0.4.0/icons/divination-ticket.png",
	"icon.reward.card_fragments": "res://assets/game/v0.24.0/v0.4.0/icons/card-shard.png",
	"icon.upgrade.1": "res://assets/game/v0.24.0/v0.4.0/icons/upgrade-1.png",
	"icon.upgrade.2": "res://assets/game/v0.24.0/v0.4.0/icons/upgrade-2.png",
	"icon.upgrade.3": "res://assets/game/v0.24.0/v0.4.0/icons/upgrade-3.png",
	"icon.route.locked": "res://assets/game/v0.24.0/v0.5.0/icons/route-pending.png",
	"icon.route.available": "res://assets/game/v0.24.0/v0.5.0/icons/route-current.png",
	"icon.route.completed": "res://assets/game/v0.24.0/v0.5.0/icons/route-completed.png",
	"icon.ritual.success": "res://assets/game/v0.24.0/v0.5.0/icons/ritual-success.png",
	"icon.ritual.failure": "res://assets/game/v0.24.0/v0.5.0/icons/ritual-failure.png",
	"icon.deck.restricted": "res://assets/game/v0.24.0/v0.6.0/icons/deck-restricted.png",
	"icon.challenge.success": "res://assets/game/v0.24.0/v0.6.0/icons/challenge-success.png",
	"icon.challenge.failure": "res://assets/game/v0.24.0/v0.6.0/icons/challenge-failure.png",
	"modifier.rushed_reflection": "res://assets/game/v0.24.0/v0.6.0/icons/modifier-pressure-advance.png",
	"modifier.tainted_margins": "res://assets/game/v0.24.0/v0.6.0/icons/modifier-mirror-echo.png",
	"modifier.fractured_deck": "res://assets/game/v0.24.0/v0.6.0/icons/modifier-compact-deck.png",
	"modifier.obituary_echo": "res://assets/game/v0.24.0/v0.7.0/icons/modifier_obituary_echo.png",
	"modifier.twin_shadow": "res://assets/game/v0.24.0/v0.7.0/icons/modifier_twin_shadow.png",
	"modifier.ritual_vigil": "res://assets/game/v0.24.0/v0.7.0/icons/modifier_ritual_vigil.png",
	"challenge.v060.mirror_echoes": "res://assets/game/v0.24.0/v0.6.0/icons/challenge-emblem.png",
	"challenge.v070.broken_procession": "res://assets/game/v0.24.0/v0.7.0/icons/challenge_broken_procession.png",
}

const RITUAL_STEPS := {
	"select_ids": "res://assets/game/v0.24.0/v0.5.0/rituals/ritual-card-name-record.png",
	"ordered_ids": "res://assets/game/v0.24.0/v0.5.0/rituals/ritual-card-chronology.png",
	"select_id": "res://assets/game/v0.24.0/v0.5.0/rituals/ritual-card-seal.png",
}

const PROPS := {
	"desk_wood": "desk-wood.png",
	"parchment_sheet": "parchment-sheet.png",
	"wax_seal": "wax-seal.png",
	"token_available": "token-available.png",
	"token_failed": "token-failed.png",
	"token_silence": "token-silence.png",
	"token_archive": "token-archive.png",
	"corner_ornament": "corner-ornament.png",
	"bookmark": "bookmark.png",
	"candle": "candle.png",
	"inkwell": "inkwell.png",
	"quill_pen": "quill-pen.png",
	"open_journal": "open-journal.png",
	"title_journal_closed": "title-journal-closed.png",
	"title_journal_new": "title-journal-new.png",
	"title_dossier_stack": "title-dossier-stack.png",
	"title_pocket_watch": "title-pocket-watch.png",
	"title_candle_snuffer": "title-candle-snuffer.png",
	"title_note_slip": "title-note-slip.png",
	"title_desk_wide": "title-desk-wide.png",
}

## Used when an id has no entry (or its file is missing).
const FALLBACKS := {
	"card_back": CARD_BACK,
	"scene.battle": BATTLE_FALLBACK,
	"scene.rest": UI_CANVAS,
	"scene.ritual": UI_CANVAS,
	"modifier": "res://assets/game/v0.24.0/v0.6.0/icons/modifier-restricted-reward.png",
	"challenge_emblem": "res://assets/game/v0.24.0/v0.6.0/icons/challenge-emblem.png",
	"route_state": "res://assets/game/v0.24.0/v0.5.0/icons/route-pending.png",
	"ritual_step": "res://assets/game/v0.24.0/v0.5.0/rituals/ritual-card-seal.png",
	"reward": "res://assets/game/v0.24.0/v0.4.0/icons/divination-ticket.png",
}


func _init() -> void:
	var cards := {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CARDS_PATH))
	var ids: Array[String] = []
	for card in (parsed as Dictionary).get("cards", []):
		ids.append(String(card.get("id", "")))
	for id in CARD_PLATES.keys():
		if not String(id) in ids:
			ids.append(String(id))
	for id in ids:
		var entry := {}
		var window := "%s/%s/art.png" % [CARD_WINDOW_DIR, id]
		if FileAccess.file_exists(window):
			entry["window"] = window
		if CARD_PLATES.has(id):
			entry["plate"] = CARD_PLATES[id]
		cards[id] = entry
	var seals := {}
	for rarity in RARITIES:
		for mechanic in MECHANICS:
			var key := "%s.%s" % [rarity, mechanic]
			var full := "%s/seal-%s-%s.png" % [SEAL_DIR, rarity, mechanic]
			var small := "%s/seal-%s-%s-128.png" % [SEAL_DIR, rarity, mechanic]
			var seal := {}
			if FileAccess.file_exists(full):
				seal["full"] = full
			if FileAccess.file_exists(small):
				seal["small"] = small
			if not seal.is_empty():
				seals[key] = seal
	var statuses := {}
	for file_name in DirAccess.get_files_at(STATUS_DIR):
		if file_name.begins_with("status-") and file_name.ends_with(".png"):
			statuses[file_name.trim_prefix("status-").trim_suffix(".png")] = "%s/%s" % [STATUS_DIR, file_name]
	var diary := {}
	for scene_id in DIARY_PAGES.keys():
		diary[scene_id] = "%s/%s" % [DIARY_DIR, DIARY_PAGES[scene_id]]
	var props := {}
	for prop_id in PROPS.keys():
		props[prop_id] = "%s/%s" % [PROP_DIR, PROPS[prop_id]]
	var registry := {
		"schema_version": 1,
		"generated_by": "godot --headless --path . --script res://tools/gen_asset_registry.gd (v0.88 R2-10 migration; edit by hand afterwards)",
		"fallbacks": FALLBACKS,
		"cards": cards,
		"seals": seals,
		"enemies": ENEMIES,
		"identities": IDENTITIES,
		"scenes": SCENES,
		"diary_pages": diary,
		"status_icons": statuses,
		"icons": ICONS,
		"ritual_steps": RITUAL_STEPS,
		"props": props,
	}
	DirAccess.make_dir_recursive_absolute(OUT_PATH.get_base_dir())
	var file := FileAccess.open(OUT_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(registry, "  ", true) + "\n")
	file.close()
	print("ASSET_REGISTRY_WRITTEN cards=%d seals=%d" % [cards.size(), seals.size()])
	quit(0)
