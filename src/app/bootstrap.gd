class_name AppBootstrap
extends RefCounted

const InfrastructureResultScript := preload("res://src/infrastructure/infrastructure_result.gd")
const BattleContentAdapterScript := preload("res://src/infrastructure/battle_content_adapter.gd")
const BattleBalanceAdapterScript := preload("res://src/infrastructure/battle_balance_adapter.gd")
const CampaignContentCatalogScript := preload("res://src/infrastructure/campaign_content_catalog.gd")
const ProgressionContentAdapterScript := preload("res://src/infrastructure/progression_content_adapter.gd")
const RouteContentAdapterScript := preload("res://src/infrastructure/route_content_adapter.gd")
const ChallengeContentAdapterScript := preload("res://src/infrastructure/challenge_content_adapter.gd")
const DeckContentAdapterScript := preload("res://src/infrastructure/deck_content_adapter.gd")
const SaveMigrationsScript := preload("res://src/infrastructure/save_migrations.gd")
const PlayerPreferencesServiceScript := preload("res://src/infrastructure/player_preferences_service.gd")
const RouteSessionScript := preload("res://src/app/route_session.gd")
const ChallengeSessionScript := preload("res://src/app/challenge_session.gd")
const DeckEngineScript := preload("res://src/gameplay/deck_engine.gd")
const DeckCommandScript := preload("res://src/core/deck_command.gd")

const ContentManifestScript := preload("res://src/infrastructure/content_manifest.gd")
const CheckpointCodecScript := preload("res://src/app/checkpoint_codec.gd")

# Load order defines which stage a failure reports first. Paths come from data/manifest.json.
const V07_DOCUMENT_KINDS: Array[String] = [
	"cards", "enemies", "encounters", "routes", "rituals",
	"balance", "progression", "decks", "diary",
]


static func create_services(run_seed: int) -> AppServices:
	return AppServices.new(SeededRandomService.new(run_seed))


static func get_route_previews_v07(
	paths: Dictionary = {}
) -> InfrastructureResult:
	var manifest := _load_manifest(paths)
	if not manifest.ok:
		return manifest
	var routes_result: InfrastructureResult = manifest.data.load_kind("routes", paths)
	if not routes_result.ok:
		return routes_result
	var previews: Array[Dictionary] = []
	for route_value in routes_result.data.get("routes", []):
		if not route_value is Dictionary:
			continue
		var route: Dictionary = route_value
		if String(route.get("id", "")) != "route.v028.first_stage":
			continue
		previews.append({
			"id": String(route.get("id", "")),
			"display_name_zh": String(route.get(
				"display_name_zh",
				route.get("id", "")
			)),
			"description_zh": String(route.get(
				"description_zh",
				"选择这条调查路线。"
			)),
			"playable": true,
			"progression_hint_zh": "%d 个调查节点 · 序列 9 占卜家" % route.get("nodes", []).size(),
		})
	previews.append_array([
		{
			"id": "chapter.planned.tingen",
			"display_name_zh": "廷根 · 后续调查",
			"description_zh": "规划占位：在廷根继续值夜者调查，围绕小丑阶段的扮演与廷根事件收束推进。当前尚未开放小丑能力。",
			"playable": false,
			"progression_hint_zh": "序列 8 小丑阶段 · 规划中",
		},
		{
			"id": "chapter.planned.backlund",
			"display_name_zh": "贝克兰德 · 侦探生活",
			"description_zh": "规划占位：廷根篇结束后，进入贝克兰德的侦探委托、非凡聚会与调查。能力随魔术师、无面人阶段逐步开放。",
			"playable": false,
			"progression_hint_zh": "廷根之后 · 规划中",
		},
		{
			"id": "chapter.planned.sea",
			"display_name_zh": "海上 · 冒险家旅程",
			"description_zh": "规划占位：贝克兰德篇之后展开海上冒险，以无面人扮演和海上调查为主线；后续晋升按剧情进展开放。",
			"playable": false,
			"progression_hint_zh": "贝克兰德之后 · 规划中",
		},
	])
	return InfrastructureResultScript.success(previews)


static func start_route_v07(
	run_seed: int,
	paths: Dictionary = {},
	checkpoint_slot: String = "checkpoint",
	resume_from_checkpoint: bool = false
) -> InfrastructureResult:
	var manifest_result := _load_manifest(paths)
	if not manifest_result.ok:
		return manifest_result
	var manifest: ContentManifest = manifest_result.data
	var loaded_documents := _load_v07_documents(manifest, paths)
	if not loaded_documents.ok:
		return loaded_documents
	var documents: Dictionary = loaded_documents.data

	var catalog := CampaignContentCatalogScript.new()
	var catalog_result := catalog.load_from_documents(
		documents.cards,
		documents.enemies,
		documents.encounters
	)
	if not catalog_result.ok:
		return _with_stage(catalog_result, &"catalog")
	if String(catalog.content_version) != "v0.7.0":
		return InfrastructureResultScript.failure(
			&"v07_content_version_mismatch",
			"v0.7 route startup requires the complete v0.7 content package."
		)

	var route_content := RouteContentAdapterScript.new(
		documents.routes,
		documents.rituals,
		catalog,
		documents.balance,
		documents.diary
	)
	if not route_content.is_valid():
		return InfrastructureResultScript.failure(
			&"route_content_invalid",
			"Route and ritual content references are invalid.",
			{"errors": route_content.validation_errors()}
		)
	var battle_content: BattleContentPort = BattleContentAdapterScript.new(
		documents.cards.get("cards", []),
		documents.cards.get("synergies", [])
	)
	var global_balance: BattleBalancePort = BattleBalanceAdapterScript.new(
		documents.balance
	)
	var progression_content: ProgressionContentPort = (
		ProgressionContentAdapterScript.new(
			documents.progression,
			battle_content
		)
	)
	if progression_content.base_cards_version != catalog.cards_content_version:
		return InfrastructureResultScript.failure(
			&"progression_base_cards_version_mismatch",
			"Progression content must reference the loaded v0.7 cards.",
			{
				"progression": progression_content.base_cards_version,
				"cards": catalog.cards_content_version,
			}
		)
	if documents.decks.get("content_version", "") != "v0.7.0":
		return InfrastructureResultScript.failure(
			&"deck_content_version_mismatch",
			"Deck content must use v0.7.0."
		)
	var deck_content := DeckContentAdapterScript.new(
		documents.decks,
		battle_content
	)
	if not deck_content.is_valid():
		return InfrastructureResultScript.failure(
			&"deck_content_invalid",
			"Deck catalog or presets are invalid.",
			{"errors": deck_content.validation_errors()}
		)

	var save_directory := String(
		paths.get("save_directory", AtomicSaveService.DEFAULT_DIRECTORY)
	)
	var save_service := SaveMigrationsScript.create_service(
		save_directory,
		SaveMigrationsScript.build_annotation_lookup(documents.diary),
		manifest.content_revision
	)
	var selected_seed := run_seed
	var selected_route_id := StringName(paths.get("route_id", ""))
	var progression_state: Dictionary = {}
	var route_state: Dictionary = {}
	var deck_state: Dictionary = {}
	var resumed_sequence: Dictionary = {}
	if resume_from_checkpoint:
		var loaded := save_service.load_slot(checkpoint_slot)
		if not loaded.ok:
			return InfrastructureResultScript.failure(
				&"route_checkpoint_unavailable",
				"v0.7 checkpoint could not be loaded.",
				{
					"cause": String(loaded.code),
					"cause_message": loaded.message,
					"cause_details": loaded.details,
				}
			)
		var envelope: Dictionary = loaded.data
		selected_seed = int(envelope.get("rng_seed", run_seed))
		var saved_progression: Variant = envelope.get("progression", {})
		if saved_progression is Dictionary:
			progression_state = CheckpointCodecScript.decode_progression(saved_progression)
		var saved_route: Variant = envelope.get("route", {})
		if (
			bool(paths.get("restore_route_state", true))
			and saved_route is Dictionary
			and bool(saved_route.get("initialized", false))
		):
			var stored_state: Variant = saved_route.get("state", {})
			if stored_state is Dictionary:
				route_state = CheckpointCodecScript.decode_route_state(stored_state)
				var stored_route_id := StringName(
					stored_state.get("route_id", "")
				)
				if not stored_route_id.is_empty():
					selected_route_id = stored_route_id
		var saved_sequence: Variant = saved_route.get("sequence_state", {})
		if saved_sequence is Dictionary:
			resumed_sequence = saved_sequence.duplicate(true)
		var saved_deck: Variant = envelope.get("deck", {})
		if saved_deck is Dictionary and bool(
			saved_deck.get("initialized", false)
		):
			var saved_deck_state: Variant = saved_deck.get("state", {})
			if saved_deck_state is Dictionary:
				deck_state = CheckpointCodecScript.decode_deck_state(saved_deck_state)
	if (
		not resume_from_checkpoint
		and bool(paths.get("test_profile", false))
	):
		progression_state = _build_test_progression_state(deck_content)
	if not resume_from_checkpoint:
		var explicit_progression: Variant = paths.get("progression_state", {})
		if explicit_progression is Dictionary and not explicit_progression.is_empty():
			progression_state = explicit_progression.duplicate(true)
		var explicit_deck: Variant = paths.get("deck_state", {})
		if explicit_deck is Dictionary and not explicit_deck.is_empty():
			deck_state = explicit_deck.duplicate(true)
	if selected_route_id.is_empty():
		selected_route_id = route_content.get_default_route_id()
	if not route_content.has_route(selected_route_id):
		return InfrastructureResultScript.failure(
			&"route_not_found",
			"Requested v0.7 route does not exist.",
			{"route_id": String(selected_route_id)}
		)

	var services := create_services(selected_seed)
	services.saves = save_service
	services.catalog = catalog
	var progression_engine := ProgressionEngine.new(
		progression_content,
		global_balance,
		services.create_random(&"gacha.draw")
	)
	var initialized_progression := progression_engine.initialize(
		progression_state
	)
	if not initialized_progression.accepted:
		return InfrastructureResultScript.failure(
			&"progression_initialization_failed",
			"Persistent progression could not be initialized.",
			{
				"reason_code": String(initialized_progression.reason_code),
				"snapshot": initialized_progression.snapshot.to_dictionary(),
			}
		)
	var owned_ids: Array[String] = []
	for card_value in initialized_progression.snapshot.data.get(
		"collection",
		[]
	):
		if (
			card_value is Dictionary
			and int(card_value.get("copies", 0)) > 0
		):
			owned_ids.append(String(card_value.get("definition_id", "")))
	var deck_engine := DeckEngineScript.new(deck_content, battle_content)
	var initialized_deck := deck_engine.initialize(
		owned_ids,
		deck_state,
		int(initialized_progression.snapshot.data.get("sequence", 9))
	)
	if not initialized_deck.accepted:
		return InfrastructureResultScript.failure(
			&"deck_initialization_failed",
			"Persistent deck state could not be initialized.",
			{
				"reason_code": String(initialized_deck.reason_code),
				"snapshot": initialized_deck.snapshot.to_dictionary(),
			}
		)
	if (
		deck_state.is_empty()
		and not bool(initialized_deck.snapshot.data.get("confirmed", false))
	):
		var confirmed := deck_engine.submit(DeckCommandScript.confirm_deck())
		if not confirmed.accepted:
			return InfrastructureResultScript.failure(
				&"default_deck_invalid",
				"The default v0.7 deck could not be confirmed.",
				{"reason_code": String(confirmed.reason_code)}
			)

	var session := RouteSessionScript.new(
		services,
		catalog,
		battle_content,
		global_balance,
		progression_content,
		progression_engine,
		route_content,
		selected_seed,
		checkpoint_slot,
		deck_engine,
		manifest.content_revision,
		CheckpointCodecScript.SAVE_VERSION,
		selected_route_id
	)
	var initialized_route := session.initialize(route_state)
	if not initialized_route.ok:
		return initialized_route
	return InfrastructureResultScript.success(
		session,
		{
			"resumed": resume_from_checkpoint,
			"route_id": String(selected_route_id),
			"content_revision": manifest.content_revision,
			"sequence_state": resumed_sequence,
		}
	)


static func inspect_route_checkpoint_v07(
	save_slot: String = "checkpoint",
	save_directory: String = AtomicSaveService.DEFAULT_DIRECTORY
) -> InfrastructureResult:
	var service := SaveMigrationsScript.create_service(save_directory)
	var slot_info := service.inspect_slot(save_slot)
	if not slot_info.ok:
		return slot_info
	if not bool(slot_info.data.get("has_save", false)):
		return InfrastructureResultScript.success({
			"status": "none",
			"checkpoint": null,
			"backup_available": bool(slot_info.data.get("has_backup", false)),
		})
	var loaded := service.load_slot(save_slot)
	if not loaded.ok:
		return InfrastructureResultScript.success({
			"status": "corrupt",
			"checkpoint": null,
			"error_code": String(loaded.code),
			"message": loaded.message,
			"backup_available": bool(loaded.details.get("backup_available", false)),
		})
	return InfrastructureResultScript.success({
		"status": "loaded",
		"checkpoint": _checkpoint_summary(loaded.data),
		"backup_available": bool(slot_info.data.get("has_backup", false)),
	})


static func start_challenge_v07(
	run_seed: int,
	paths: Dictionary = {},
	checkpoint_slot: String = "checkpoint",
	resume_from_checkpoint: bool = false,
	start_fresh_challenge: bool = false
) -> InfrastructureResult:
	var base_paths: Dictionary = paths.duplicate(true)
	base_paths["restore_route_state"] = false
	var base_result := start_route_v07(run_seed, base_paths, checkpoint_slot, true)
	if not base_result.ok and not resume_from_checkpoint:
		base_result = start_route_v07(run_seed, base_paths, checkpoint_slot, false)
	if not base_result.ok:
		return _with_stage(base_result, &"challenge_base_route")
	var base_session: RouteSession = base_result.data
	var manifest := _load_manifest(paths)
	if not manifest.ok:
		return manifest
	var challenge_result: InfrastructureResult = manifest.data.load_kind("challenges", paths)
	if not challenge_result.ok:
		return challenge_result
	var challenge_content := ChallengeContentAdapterScript.new(
		challenge_result.data,
		base_session.catalog,
		base_session.route_content,
		base_session.progression_content
	)
	if not challenge_content.is_valid():
		return InfrastructureResultScript.failure(
			&"challenge_content_invalid",
			"v0.7 challenge content failed reference validation.",
			{"errors": challenge_content.validation_errors()}
		)
	var selected_challenge_id := StringName(
		paths.get(
			"challenge_id",
			String(challenge_content.get_default_challenge_id())
		)
	)
	if not challenge_content.has_challenge(selected_challenge_id):
		return InfrastructureResultScript.failure(
			&"challenge_not_found",
			"Requested challenge does not exist.",
			{"challenge_id": String(selected_challenge_id)}
		)

	var save_service: AtomicSaveService = base_session.services.saves
	var saved := save_service.load_slot(checkpoint_slot)
	var challenge_state: Dictionary = {}
	var reward_applied := false
	var saved_sequence_state: Dictionary = {}
	if resume_from_checkpoint:
		if not saved.ok:
			return InfrastructureResultScript.failure(
				&"challenge_checkpoint_unavailable",
				"v0.7 challenge checkpoint could not be loaded.",
				{
					"cause": String(saved.code),
					"cause_message": saved.message,
					"cause_details": saved.details,
				}
			)
	elif not saved.ok:
		saved = InfrastructureResultScript.success({})
	if not start_fresh_challenge and saved.ok and saved.data is Dictionary:
		var envelope: Dictionary = saved.data
		var saved_challenge: Variant = envelope.get("challenge", {})
		if saved_challenge is Dictionary:
			var state_value: Variant = saved_challenge.get("state", {})
			if state_value is Dictionary:
				challenge_state = CheckpointCodecScript.decode_challenge_state(state_value)
			reward_applied = bool(
				saved_challenge.get("reward_applied", false)
			)
			var sequence_value: Variant = saved_challenge.get(
				"sequence_state",
				{}
			)
			if sequence_value is Dictionary:
				saved_sequence_state = sequence_value.duplicate(true)

	var sequence_data := (
		saved_sequence_state
		if not saved_sequence_state.is_empty()
		else base_session.get_sequence_state().to_dictionary()
	)
	var explicit_sequence: Variant = paths.get("sequence_state", {})
	if explicit_sequence is Dictionary and not explicit_sequence.is_empty():
		sequence_data = explicit_sequence.duplicate(true)
	var session := ChallengeSessionScript.new(
		base_session.services,
		base_session.catalog,
		base_session.base_content,
		base_session.balance,
		base_session.progression_content,
		base_session.progression,
		base_session.route_content,
		challenge_content,
		selected_challenge_id,
		sequence_data,
		int(base_session.root_seed),
		checkpoint_slot,
		base_session.deck_engine,
		base_session.content_revision,
		base_session.save_version
	)
	var initialized := session.initialize(
		challenge_state,
		reward_applied
	)
	if not initialized.ok:
		return initialized
	return InfrastructureResultScript.success(
		session,
		{
			"resumed": resume_from_checkpoint,
			"challenge_id": String(selected_challenge_id),
			"content_revision": base_session.content_revision,
			"unlocked": bool(
				session.get_challenge_snapshot().data.get(
					"unlocked",
					false
				)
			),
		}
	)


static func _build_test_progression_state(deck_content) -> Dictionary:
	var collection: Dictionary = {}
	for definition_id in deck_content.get_card_catalog_ids():
		collection[String(definition_id)] = {
			"copies": 1,
			"level": 0,
			"fragments": 99,
		}
	return {
		"phase": "hub",
		"identity_id": "identity.doctor",
		"divination_tickets": 99,
		"collection": collection,
		"pity_counter": 0,
		"reward_option_ids": [],
		"last_battle_outcome": "",
		"last_gacha_results": [],
		"revision": 1,
	}


static func load_player_preferences(
	path: String = "user://preferences.json"
) -> InfrastructureResult:
	return PlayerPreferencesServiceScript.new(path).load_preferences()


static func save_player_preferences(
	preferences: Dictionary,
	path: String = "user://preferences.json"
) -> InfrastructureResult:
	return PlayerPreferencesServiceScript.new(path).save_preferences(preferences)


static func restore_checkpoint_backup(
	save_slot: String = "checkpoint",
	save_directory: String = AtomicSaveService.DEFAULT_DIRECTORY
) -> InfrastructureResult:
	var service := SaveMigrationsScript.create_service(save_directory)
	var backup := service.load_backup(save_slot)
	if not backup.ok:
		return InfrastructureResultScript.failure(
			&"checkpoint_backup_unavailable",
			"Checkpoint backup could not be loaded.",
			{
				"cause": String(backup.code),
				"cause_message": backup.message,
				"cause_details": backup.details,
			}
		)
	var restored := service.restore_backup(save_slot)
	if not restored.ok:
		return InfrastructureResultScript.failure(
			&"checkpoint_backup_restore_failed",
			"Checkpoint backup could not be restored without replacing the current slot.",
			{
				"cause": String(restored.code),
				"cause_message": restored.message,
				"cause_details": restored.details,
			}
		)
	return InfrastructureResultScript.success(
		_checkpoint_summary(backup.data),
		restored.details
	)


static func _checkpoint_summary(envelope: Dictionary) -> Dictionary:
	var profile: Dictionary = envelope.get("profile", {})
	var run: Dictionary = envelope.get("run", {})
	var progression: Dictionary = envelope.get("progression", {})
	var route: Dictionary = envelope.get("route", {})
	var challenge: Dictionary = envelope.get("challenge", {})
	var deck: Dictionary = envelope.get("deck", {})
	var last_battle: Dictionary = run.get("last_battle", {})
	var deck_summary: Dictionary = run.get("deck_summary", {})
	var sequence_value := int(profile.get("sequence", 0))
	var challenge_phase := String(challenge.get("phase", "inactive"))
	var deck_size := 0
	for count in deck_summary.values():
		deck_size += int(count)
	var collection_size := 0
	var collection_value: Variant = progression.get("collection", {})
	if collection_value is Dictionary:
		for card_state in collection_value.values():
			if card_state is Dictionary and int(card_state.get("copies", 0)) > 0:
				collection_size += 1
	var deck_state_value: Variant = deck.get("state", {})
	var deck_state: Dictionary = (
		deck_state_value if deck_state_value is Dictionary else {}
	)
	var current_deck: Array = (
		deck_state.get("current_card_ids", [])
		if deck_state.get("current_card_ids", []) is Array
		else []
	)
	var challenge_sequence_value: Variant = challenge.get(
		"sequence_state",
		{}
	)
	var challenge_sequence: Dictionary = (
		challenge_sequence_value
		if challenge_sequence_value is Dictionary
		else {}
	)
	var completed_challenges: Array = (
		challenge_sequence.get("completed_challenge_ids", [])
		if challenge_sequence.get("completed_challenge_ids", []) is Array
		else []
	)
	return {
		"content_revision": int(envelope.get("content_revision", 0)),
		"created_at": String(envelope.get("created_at", "")),
		"rng_seed": int(envelope.get("rng_seed", 0)),
		"pathway": String(profile.get("pathway", "")),
		"sequence": int(profile.get("sequence", 0)),
		"identity_id": String(
			profile.get(
				"identity_id",
				progression.get("identity_id", "")
			)
		),
		"progression_phase": String(progression.get("phase", "")),
		"divination_tickets": int(progression.get("divination_tickets", 0)),
		"pity_counter": int(progression.get("pity_counter", 0)),
		"collection_count": collection_size,
		"checkpoint_kind": String(run.get("checkpoint_kind", "")),
		"encounter_id": String(run.get("encounter_id", "")),
		"current_node_id": String(run.get("current_node_id", "")),
		"route_phase": String(route.get("phase", "")),
		"completed_node_count": (
			route.get("completed_node_ids", []).size()
			if route.get("completed_node_ids", []) is Array
			else 0
		),
		"deck_size": deck_size,
		"deck_confirmed": bool(deck_state.get("confirmed", false)),
		"current_deck_card_ids": current_deck.duplicate(),
		"challenge_id": String(challenge.get("challenge_id", "")),
		"challenge_phase": challenge_phase,
		"challenge_available": sequence_value >= 8,
		"challenge_reason": (
			""
			if sequence_value >= 8
			else "完成占卜家序列 8 晋升后开放"
		),
		"challenge_modifier_id": String(
			challenge.get("selected_modifier_id", "")
		),
		"challenge_outcome": String(
			challenge.get("challenge_outcome", "")
		),
		"challenge_reward_applied": bool(
			challenge.get("reward_applied", false)
		),
		"completed_challenge_ids": completed_challenges.duplicate(),
		"last_battle": last_battle.duplicate(true),
	}


static func _load_manifest(paths: Dictionary) -> InfrastructureResult:
	return ContentManifestScript.load_manifest(
		String(paths.get("manifest", ContentManifestScript.DEFAULT_PATH))
	)


static func _load_v07_documents(manifest: ContentManifest, paths: Dictionary) -> InfrastructureResult:
	var documents := {}
	for kind in V07_DOCUMENT_KINDS:
		var loaded := manifest.load_kind(kind, paths)
		if not loaded.ok:
			return loaded
		documents[kind] = loaded.data
	return InfrastructureResultScript.success(documents)


static func _with_stage(result: InfrastructureResult, stage: StringName) -> InfrastructureResult:
	if result.ok:
		return result
	var details := result.details.duplicate(true)
	details["stage"] = String(stage)
	return InfrastructureResultScript.failure(result.code, result.message, details)
