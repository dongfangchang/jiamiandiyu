extends Control

signal route_changed(route_name: StringName)

const AppBootstrapScript := preload("res://src/app/bootstrap.gd")
const ContentManifestScript := preload("res://src/infrastructure/content_manifest.gd")
const ChallengeSessionScript := preload("res://src/app/challenge_session.gd")
const ChallengeEngineScript := preload("res://src/gameplay/challenge_engine.gd")
const ChallengeCommandScript := preload("res://src/core/challenge_command.gd")
const DeckCommandScript := preload("res://src/core/deck_command.gd")
const ProgressionCommandScript := preload("res://src/core/progression_command.gd")
const UpgradedBattleContentPortScript := preload("res://src/gameplay/upgraded_battle_content_port.gd")
const StartScreenScene := preload("res://scenes/ui/start_screen.tscn")
const ChallengeScreenScene := preload("res://scenes/ui/challenge_screen.tscn")
const ChallengeResultScreenScene := preload("res://scenes/ui/challenge_result_screen.tscn")
const ChallengeHubScreenScene := preload("res://scenes/ui/challenge_hub_screen.tscn")
const DeckScreenScene := preload("res://scenes/ui/deck_screen.tscn")
const IdentityScreenScene := preload("res://scenes/ui/identity_screen.tscn")
const RouteScreenScene := preload("res://scenes/ui/diary_chapter_screen.tscn")
const RouteSelectScreenScene := preload("res://scenes/ui/route_select_screen.tscn")
const BattleScreenScene := preload("res://scenes/ui/battle_screen.tscn")
const RewardScreenScene := preload("res://scenes/ui/reward_screen.tscn")
const GachaScreenScene := preload("res://scenes/ui/gacha_screen.tscn")
const UpgradeScreenScene := preload("res://scenes/ui/upgrade_screen.tscn")
const RestScreenScene := preload("res://scenes/ui/rest_screen.tscn")
const RitualScreenScene := preload("res://scenes/ui/ritual_screen.tscn")
const RouteResultScreenScene := preload("res://scenes/ui/route_result_screen.tscn")
const DiagnosticsServiceScript := preload("res://src/infrastructure/playtest_diagnostics_service.gd")
const ScreenRouterScript := preload("res://src/app/screen_router.gd")
const CardArtCatalogScript := preload("res://src/ui/card_art_catalog.gd")
const DiaryUiCatalogScript := preload("res://src/ui/diary_ui_catalog.gd")
const EffectTextScript := preload("res://src/ui/text/effect_text.gd")
const AppTextScript := preload("res://src/ui/text/app_text.gd")

const ROUTE_START: StringName = &"start"
const ROUTE_CHALLENGE_HUB: StringName = &"challenge_hub"
const ROUTE_CHALLENGE_SELECT: StringName = &"challenge_select"
const ROUTE_CHALLENGE_RESULT: StringName = &"challenge_result"
const ROUTE_DECK: StringName = &"deck"
const ROUTE_IDENTITY: StringName = &"identity"
const ROUTE_HUB: StringName = &"hub"
const ROUTE_MAP: StringName = &"map"
const ROUTE_ROUTE_SELECT: StringName = &"route_select"
const ROUTE_REST: StringName = &"rest"
const ROUTE_BATTLE: StringName = &"battle"
const ROUTE_REWARD: StringName = &"reward"
const ROUTE_GACHA: StringName = &"gacha"
const ROUTE_UPGRADE: StringName = &"upgrade"
const ROUTE_RITUAL: StringName = &"ritual"
const ROUTE_ROUTE_RESULT: StringName = &"route_result"

## Where "back"/"exit" leads from each route: [campaign, challenge] session.
## Non-title targets fall back to the title when no session exists. Deck
## opened from the hub returns there; the challenge entry is the deck shown
## mid-start. Battle reaches the diary by reloading the last checkpoint, and
## ritual by its cancel command, so neither goes through _navigate_back.
const BACK_TARGETS := {
	ROUTE_ROUTE_SELECT: [ROUTE_HUB, ROUTE_HUB],
	ROUTE_IDENTITY: [ROUTE_START, ROUTE_START],
	ROUTE_HUB: [ROUTE_START, ROUTE_START],
	ROUTE_DECK: [ROUTE_HUB, ROUTE_CHALLENGE_HUB],
	ROUTE_MAP: [ROUTE_HUB, ROUTE_HUB],
	ROUTE_BATTLE: [ROUTE_MAP, ROUTE_MAP],
	ROUTE_REWARD: [ROUTE_HUB, ROUTE_HUB],
	ROUTE_REST: [ROUTE_MAP, ROUTE_MAP],
	ROUTE_RITUAL: [ROUTE_MAP, ROUTE_MAP],
	ROUTE_GACHA: [ROUTE_HUB, ROUTE_HUB],
	ROUTE_UPGRADE: [ROUTE_HUB, ROUTE_HUB],
	ROUTE_ROUTE_RESULT: [ROUTE_HUB, ROUTE_HUB],
	ROUTE_CHALLENGE_HUB: [ROUTE_START, ROUTE_START],
	ROUTE_CHALLENGE_SELECT: [ROUTE_CHALLENGE_HUB, ROUTE_CHALLENGE_HUB],
	ROUTE_CHALLENGE_RESULT: [ROUTE_CHALLENGE_HUB, ROUTE_CHALLENGE_HUB],
}
const TEST_PROFILE_SLOT := "test_profile"

var save_directory: String = AtomicSaveService.DEFAULT_DIRECTORY
var checkpoint_slot: String = "checkpoint"

var _base_checkpoint_slot := "checkpoint"
var _route: StringName = &""
var _router: Control = null
var _screen: Control:
	get:
		return _router.get_current_screen() if _router != null else null
var _session: RefCounted = null
var _challenge_hub_cache: Dictionary = {}
var _last_checkpoint_summary: Dictionary = {}
var _seed_override: int = -1
var _deck_after_confirm_route: StringName = ROUTE_HUB
var _challenge_sequence_state: Dictionary = {}
var _preferences: Dictionary = {
	"settings_version": 1,
	"tutorial_seen": false,
	"fullscreen": false,
	"ui_scale": 1.0,
	"reduce_flash": false,
	"mute_sfx": false,
}
var _preferences_path: String = "user://preferences.json"
var _diagnostics: RefCounted = null
var _diagnostics_directory: String = "user://diagnostics"
var _testing_mode := false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	configure_ui_content()
	_ensure_router()
	get_tree().auto_accept_quit = _testing_mode
	_load_preferences()
	_start_diagnostics()
	show_start_screen()


## R2-09: the UI never opens content files. Card definitions and the diary
## volume are loaded once here through the schema-validating loader and handed
## to the UI catalogs as read-only views. Static so tests that build screens
## without an AppController can reuse the same path.
static func configure_ui_content(force := false) -> bool:
	if not force and CardArtCatalogScript.is_configured() and DiaryUiCatalogScript.is_configured():
		return true
	var manifest_result := ContentManifestScript.load_manifest()
	if not manifest_result.ok:
		push_error("ui content: manifest failed to load (%s)" % manifest_result.code)
		return false
	var manifest = manifest_result.data
	var cards = manifest.load_kind("cards")
	var diary = manifest.load_kind("diary")
	if cards.ok:
		CardArtCatalogScript.configure(cards.data.get("cards", []))
	else:
		push_error("ui content: cards failed to load (%s)" % cards.code)
	if diary.ok:
		DiaryUiCatalogScript.configure(diary.data)
	else:
		push_error("ui content: diary failed to load (%s)" % diary.code)
	return cards.ok and diary.ok


func configure_for_testing(
	save_directory_value: String,
	checkpoint_slot_value: String = "checkpoint",
	seed_override_value: int = -1,
	preferences_path_value: String = "user://preferences.json",
	diagnostics_directory_value: String = ""
) -> void:
	_testing_mode = true
	_ensure_router()
	_router.instant = true
	save_directory = save_directory_value
	checkpoint_slot = checkpoint_slot_value
	_base_checkpoint_slot = checkpoint_slot_value
	_seed_override = seed_override_value
	_preferences_path = preferences_path_value
	_diagnostics_directory = (
		diagnostics_directory_value
		if not diagnostics_directory_value.is_empty()
		else save_directory_value.path_join("diagnostics")
	)
	_load_preferences()
	_start_diagnostics()


func show_start_screen(load_error: InfrastructureResult = null) -> void:
	if _router_busy():
		return
	_set_session(null)
	checkpoint_slot = _base_checkpoint_slot
	_swap(StartScreenScene, ROUTE_START, func(screen: Control) -> void:
		screen.new_game_requested.connect(_on_new_game_requested)
		screen.continue_requested.connect(_on_continue_requested)
		screen.challenge_requested.connect(_on_challenge_requested)
		screen.preferences_changed.connect(_on_preferences_changed)
		screen.restore_backup_requested.connect(_on_restore_backup_requested)
		screen.feedback_submitted.connect(_on_feedback_submitted)
		screen.test_game_requested.connect(_on_test_game_requested)
		screen.quit_requested.connect(_on_quit_requested)
		_refresh_checkpoint_summary(screen)
		if load_error != null:
			screen.show_checkpoint_status(
				"corrupt",
				{},
				"%s: %s" % [String(load_error.code), load_error.message]
			)
	)


func get_back_target(route_name: StringName) -> StringName:
	var targets: Array = BACK_TARGETS.get(route_name, [ROUTE_START, ROUTE_START])
	var target: StringName = targets[1 if _is_challenge_session() else 0]
	if route_name == ROUTE_DECK and _deck_after_confirm_route == ROUTE_HUB:
		## Opened from the hub: back returns there in either session kind.
		target = ROUTE_HUB
	if target != ROUTE_START and _session == null:
		return ROUTE_START
	return target


func is_transitioning() -> bool:
	return _router != null and _router.is_busy()


func get_router() -> Control:
	return _router


## Real fades/hooks in tests that exercise transitions; configure_for_testing
## starts instant so synchronous runners keep their semantics.
func set_transitions_instant(value: bool) -> void:
	_ensure_router()
	_router.instant = value


func start_new_game(
	seed_value: int = -1,
	_encounter_id: StringName = &"",
	route_id: StringName = &""
) -> InfrastructureResult:
	checkpoint_slot = _base_checkpoint_slot
	var resolved_seed := _resolve_seed(seed_value)
	var paths := {"save_directory": save_directory}
	if not route_id.is_empty():
		paths["route_id"] = String(route_id)
	var result = AppBootstrapScript.start_route_v07(
		resolved_seed,
		paths,
		checkpoint_slot,
		false
	)
	if not result.ok:
		_report_error(result, AppTextScript.text("toast.new_game_failed"))
		return result
	_set_session(result.data)
	_record_diagnostic("route_started", {"seed": resolved_seed, "kind": "first_route"})
	_show_current_state()
	return result


func start_test_game(seed_value: int = -1) -> InfrastructureResult:
	var resolved_seed := _resolve_seed(seed_value)
	var result = AppBootstrapScript.start_route_v07(
		resolved_seed,
		{
			"save_directory": save_directory,
			"test_profile": true,
		},
		TEST_PROFILE_SLOT,
		false
	)
	if not result.ok:
		_report_error(result, AppTextScript.text("toast.test_profile_create_failed"))
		return result
	checkpoint_slot = TEST_PROFILE_SLOT
	_set_session(result.data)
	var initial_checkpoint: InfrastructureResult = (
		_session.save_checkpoint("test_profile")
	)
	if not initial_checkpoint.ok:
		_report_error(initial_checkpoint, AppTextScript.text("toast.test_profile_save_failed"))
		return initial_checkpoint
	_record_diagnostic("test_profile_started", {"seed": resolved_seed})
	_show_current_state()
	return result


func start_new_challenge(
	seed_value: int = -1,
	challenge_id: StringName = &"",
	sequence_state: Dictionary = {}
) -> InfrastructureResult:
	var resolved_seed := _resolve_seed(seed_value)
	var paths := {"save_directory": save_directory}
	if not challenge_id.is_empty():
		paths["challenge_id"] = String(challenge_id)
	if not sequence_state.is_empty():
		paths["sequence_state"] = sequence_state.duplicate(true)
	var result = AppBootstrapScript.start_challenge_v07(
		resolved_seed,
		paths,
		checkpoint_slot,
		false,
		true
	)
	if not result.ok:
		_report_error(result, AppTextScript.text("toast.challenge_start_failed"))
		return result
	_set_session(result.data)
	_record_diagnostic("challenge_started", {
		"seed": resolved_seed,
		"challenge_id": String(challenge_id),
	})
	_show_current_state()
	return result


func continue_saved_checkpoint() -> InfrastructureResult:
	var inspected = AppBootstrapScript.inspect_route_checkpoint_v07(
		checkpoint_slot,
		save_directory
	)
	if not inspected.ok or String(inspected.data.get("status", "")) != "loaded":
		var failed := InfrastructureResult.failure(
			&"checkpoint_not_available",
			"No loaded checkpoint is available to continue."
		)
		_show_load_error(failed)
		return failed
	_last_checkpoint_summary = inspected.data.get("checkpoint", {}).duplicate(true)
	var seed_value := int(_last_checkpoint_summary.get("rng_seed", _resolve_seed(-1)))
	var challenge_phase := String(
		_last_checkpoint_summary.get("challenge_phase", "inactive")
	)
	var challenge_id := StringName(
		_last_checkpoint_summary.get("challenge_id", "")
	)
	var result
	if challenge_phase != "inactive":
		result = AppBootstrapScript.start_challenge_v07(
			seed_value,
			{
				"save_directory": save_directory,
				"challenge_id": String(challenge_id),
			},
			checkpoint_slot,
			true,
			false
		)
	else:
		result = AppBootstrapScript.start_route_v07(
			seed_value,
			{"save_directory": save_directory},
			checkpoint_slot,
			true
		)
	if not result.ok:
		_show_load_error(result)
		return result
	_set_session(result.data)
	_record_diagnostic("checkpoint_resumed", {
		"challenge_phase": challenge_phase,
		"challenge_id": String(challenge_id),
	})
	_show_current_state()
	return result


func get_current_route() -> StringName:
	return _route


func get_current_screen() -> Control:
	return _screen


func get_session() -> RefCounted:
	return _session


func get_progression_snapshot() -> ProgressionSnapshot:
	if _session == null:
		return null
	return _session.get_progression_snapshot()


func get_route_snapshot() -> RouteSnapshot:
	if _session == null:
		return null
	return _session.get_route_snapshot()


func get_ritual_snapshot() -> RitualSnapshot:
	if _session == null:
		return null
	return _session.get_ritual_snapshot()


func get_deck_snapshot() -> DeckSnapshot:
	if _session == null or not _session.has_method("get_deck_snapshot"):
		return null
	return _session.get_deck_snapshot()


func get_challenge_snapshot() -> ChallengeSnapshot:
	if _session == null or not _session.has_method("get_challenge_snapshot"):
		return null
	return _session.get_challenge_snapshot()


func get_last_checkpoint_summary() -> Dictionary:
	return _last_checkpoint_summary.duplicate(true)


func _refresh_checkpoint_summary(start_screen: Control) -> void:
	var inspected = AppBootstrapScript.inspect_route_checkpoint_v07(
		checkpoint_slot,
		save_directory
	)
	if not inspected.ok:
		_last_checkpoint_summary = {}
		start_screen.show_checkpoint_status(
			"corrupt",
			{"backup_available": false},
			AppTextScript.text("checkpoint.inspect_failed"),
			_preferences
		)
		return

	var status := String(inspected.data.get("status", "none"))
	if status == "loaded":
		_last_checkpoint_summary = inspected.data.get("checkpoint", {}).duplicate(true)
		_last_checkpoint_summary["backup_available"] = bool(
			inspected.data.get("backup_available", false)
		)
		if not bool(_last_checkpoint_summary.get("deck_confirmed", false)):
			_last_checkpoint_summary["challenge_available"] = false
			_last_checkpoint_summary["challenge_reason"] = AppTextScript.text("challenge.reason.deck_unconfirmed")
		start_screen.show_checkpoint_status(
			"loaded",
			_last_checkpoint_summary,
			"",
			_preferences
		)
		return
	_last_checkpoint_summary = {}
	if status == "corrupt":
		var backup_available := bool(
			inspected.data.get("backup_available", false)
		)
		start_screen.show_checkpoint_status(
			"corrupt",
			{"backup_available": backup_available},
			(
				AppTextScript.text("checkpoint.corrupt_with_backup")
				if backup_available
				else AppTextScript.text("checkpoint.corrupt_no_backup")
			),
			_preferences
		)
		return
	start_screen.show_checkpoint_status("none", {}, "", _preferences)


func _show_current_state() -> void:
	if _session == null:
		_show_load_error(InfrastructureResult.failure(
			&"campaign_missing",
			"Campaign session was not created."
		))
		return
	if _is_challenge_session():
		_show_challenge_current_state()
		return
	var progression: ProgressionSnapshot = _session.get_progression_snapshot()
	if progression == null:
		_show_load_error(InfrastructureResult.failure(
			&"progression_missing",
			"Campaign progression snapshot is unavailable."
		))
		return
	var progression_phase := String(progression.data.get("phase", ""))
	if progression_phase == "identity_selection":
		_show_identity_selection()
		return
	if progression_phase == "reward":
		_show_reward()
		return
	var deck_snapshot = _session.get_deck_snapshot()
	if (
		deck_snapshot != null
		and String(deck_snapshot.data.get("phase", "")) != "unavailable"
		and not bool(deck_snapshot.data.get("confirmed", false))
	):
		_show_deck_screen(ROUTE_HUB)
		return
	var route: RouteSnapshot = _session.get_route_snapshot()
	var route_data := route.data if route != null else {}
	var route_phase := String(route_data.get("phase", ""))
	match route_phase:
		"map":
			_show_route_screen()
		"rest_pending":
			_show_rest_screen()
		"ritual":
			_show_ritual_screen()
		"completed", "failed":
			_show_route_result()
		"battle_pending":
			_show_route_screen()
		_:
			if progression_phase == "hub":
				_show_hub()
			else:
				_show_load_error(InfrastructureResult.failure(
					&"route_state_invalid",
					"The saved campaign is in an unsupported state.",
					{
						"progression_phase": progression_phase,
						"route_phase": route_phase,
					}
				))


func _show_challenge_current_state() -> void:
	var challenge = _session.get_challenge_snapshot()
	var challenge_phase := (
		String(challenge.data.get("phase", ""))
		if challenge != null
		else "init_error"
	)
	if challenge_phase in ["locked", "modifier_selection"]:
		_show_challenge_selection()
		return
	if challenge_phase in ["completed", "failed"]:
		_show_challenge_result()
		return
	if challenge_phase == "init_error":
		_show_load_error(InfrastructureResult.failure(
			&"challenge_state_invalid",
			"Challenge state could not be restored."
		))
		return
	var deck_snapshot = _session.get_deck_snapshot()
	if (
		deck_snapshot != null
		and String(deck_snapshot.data.get("phase", "")) != "unavailable"
		and not bool(deck_snapshot.data.get("confirmed", false))
	):
		_show_deck_screen(ROUTE_MAP)
		return
	var progression: ProgressionSnapshot = _session.get_progression_snapshot()
	var progression_phase := String(progression.data.get("phase", ""))
	if progression_phase == "reward":
		_show_reward()
		return
	var route: RouteSnapshot = _session.get_route_snapshot()
	var route_phase := String(route.data.get("phase", ""))
	match route_phase:
		"map", "battle_pending":
			_show_route_screen()
		"rest_pending":
			_show_rest_screen()
		"ritual":
			_show_ritual_screen()
		"completed", "failed":
			_show_challenge_result()
		_:
			if progression_phase == "hub":
				_show_hub()
			else:
				_show_load_error(InfrastructureResult.failure(
					&"challenge_state_invalid",
					"The saved challenge is in an unsupported state.",
					{
						"progression_phase": progression_phase,
						"route_phase": route_phase,
						"challenge_phase": challenge_phase,
					}
				))


func _is_challenge_session() -> bool:
	return (
		_session != null
		and _session.get_script() == ChallengeSessionScript
	)


func _show_challenge_selection() -> void:
	if _session == null:
		return
	_swap(ChallengeScreenScene, ROUTE_CHALLENGE_SELECT, func(screen: Control) -> void:
		screen.challenge_command_requested.connect(_on_challenge_command_requested)
		screen.exit_requested.connect(_navigate_back)
		screen.apply_snapshot(_session.get_challenge_snapshot())
	)


func _show_challenge_hub() -> void:
	if _router_busy():
		return
	var previews := _challenge_hub_previews()
	if not previews.ok:
		_report_error(previews, AppTextScript.text("toast.challenge_hub_unavailable"))
		return
	_challenge_sequence_state = previews.data.sequence_state.duplicate(true)
	_swap(ChallengeHubScreenScene, ROUTE_CHALLENGE_HUB, func(screen: Control) -> void:
		screen.challenge_selected.connect(_on_challenge_hub_selected)
		screen.exit_requested.connect(_navigate_back)
		screen.set_reward_labels(previews.data.reward_labels)
		screen.apply_snapshots(previews.data.snapshots)
	)


func is_challenge_hub_preview_cached() -> bool:
	return not _challenge_hub_cache.is_empty()


func _challenge_hub_previews() -> InfrastructureResult:
	## Rebuilding a probe session plus one engine per challenge is slow, and its
	## only input is the checkpoint summary, so reuse it until that changes.
	var inspected = AppBootstrapScript.inspect_route_checkpoint_v07(
		checkpoint_slot,
		save_directory
	)
	if not inspected.ok or String(inspected.data.get("status", "")) != "loaded":
		_challenge_hub_cache = {}
		return InfrastructureResult.failure(
			&"challenge_checkpoint_unavailable",
			"A completed sequence-eight checkpoint is required to inspect challenges."
		)
	var summary: Dictionary = inspected.data.get("checkpoint", {})
	var key := "%s|%s|%s" % [save_directory, checkpoint_slot, JSON.stringify(summary, "", true)]
	if String(_challenge_hub_cache.get("key", "")) == key:
		return InfrastructureResult.success(_challenge_hub_cache.data)
	var probe := _load_challenge_hub_probe(summary)
	if not probe.ok:
		return probe
	var probe_session = probe.data.session
	var snapshots: Array = []
	for challenge_id_value in probe.data.challenge_ids:
		var engine = ChallengeEngineScript.new(
			probe_session.route_content,
			probe_session.challenge_content,
			StringName(challenge_id_value)
		)
		var initialized = engine.initialize(
			probe.data.sequence_state,
			{}
		)
		if initialized.accepted:
			snapshots.append(engine.get_snapshot())
	var data := {
		"snapshots": snapshots,
		"sequence_state": probe.data.sequence_state,
		"reward_labels": _build_reward_labels(probe_session.progression_content),
	}
	_challenge_hub_cache = {"key": key, "data": data}
	return InfrastructureResult.success(data)


func _load_challenge_hub_probe(summary: Dictionary) -> InfrastructureResult:
	var seed_value := int(summary.get("rng_seed", _resolve_seed(-1)))
	var saved_challenge_id := String(summary.get("challenge_id", ""))
	var paths := {"save_directory": save_directory}
	if not saved_challenge_id.is_empty():
		paths["challenge_id"] = saved_challenge_id
	var result = AppBootstrapScript.start_challenge_v07(
		seed_value,
		paths,
		checkpoint_slot,
		false,
		false
	)
	if not result.ok and not saved_challenge_id.is_empty():
		paths.erase("challenge_id")
		result = AppBootstrapScript.start_challenge_v07(
			seed_value,
			paths,
			checkpoint_slot,
			false,
			false
		)
	if not result.ok:
		return result
	var session = result.data
	var sequence_state: Dictionary = session.get_sequence_state().to_dictionary()
	var persisted_sequence := int(summary.get("sequence", 9))
	if persisted_sequence > 0:
		sequence_state["current_sequence"] = persisted_sequence
		if persisted_sequence <= 8:
			sequence_state["advancement_state"] = "completed"
	var completed_challenges: Variant = summary.get(
		"completed_challenge_ids",
		[]
	)
	if completed_challenges is Array:
		sequence_state["completed_challenge_ids"] = (
			completed_challenges.duplicate()
		)
	var challenge_ids: Array = session.challenge_content.get_challenge_ids()
	return InfrastructureResult.success({
		"session": session,
		"sequence_state": sequence_state,
		"challenge_ids": challenge_ids,
	})


func _build_reward_labels(content) -> Dictionary:
	var labels := {}
	if content == null:
		return labels
	for reward_value in content.get_reward_options():
		if not reward_value is Dictionary:
			continue
		var reward_id := String(reward_value.get("id", ""))
		if not reward_id.is_empty():
			labels[reward_id] = String(
				reward_value.get("display_name_zh", reward_id)
			)
	return labels


func _on_challenge_hub_selected(challenge_id: StringName) -> void:
	if _router_busy() or _route != ROUTE_CHALLENGE_HUB:
		return
	start_new_challenge(
		_resolve_seed(-1),
		challenge_id,
		_challenge_sequence_state
	)


func _on_challenge_command_requested(command: ChallengeCommand) -> void:
	if (
		_session == null
		or _screen == null
		or _route != ROUTE_CHALLENGE_SELECT
		or command == null
		or _router_busy()
	):
		return
	var result: ChallengeCommandResult = _session.submit_challenge(command)
	_screen.apply_command_result(result)
	if not result.accepted:
		return
	var challenge = _session.get_challenge_snapshot()
	if String(challenge.data.get("phase", "")) == "active":
		_show_route_screen()


func _show_challenge_result() -> void:
	if _session == null:
		show_start_screen()
		return
	var save_state := _checkpoint_save_state()
	_swap(ChallengeResultScreenScene, ROUTE_CHALLENGE_RESULT, func(screen: Control) -> void:
		screen.show_result(_session.get_challenge_snapshot(), save_state)
		screen.hub_requested.connect(_navigate_back)
		screen.retry_requested.connect(_on_challenge_retry_requested)
	)


func _on_challenge_retry_requested() -> void:
	if _router_busy():
		return
	var challenge_id: StringName = &""
	var sequence_state: Dictionary = _challenge_sequence_state.duplicate(true)
	if _session != null and _session.has_method("get_challenge_snapshot"):
		var snapshot = _session.get_challenge_snapshot()
		if snapshot != null:
			challenge_id = StringName(
				snapshot.data.get("challenge_id", "")
			)
			sequence_state = _session.get_sequence_state().to_dictionary()
	start_new_challenge(
		_resolve_seed(-1),
		challenge_id,
		sequence_state
	)


func _checkpoint_save_state() -> String:
	if _session == null or _session.last_checkpoint_result == null:
		return "failed"
	var save_result: InfrastructureResult = _session.last_checkpoint_result
	if save_result.ok:
		return "saved"
	if bool(save_result.details.get("backup_available", false)):
		return "backup"
	return "failed"


func _show_identity_selection() -> void:
	_swap(IdentityScreenScene, ROUTE_IDENTITY, _setup_identity_screen)


func _show_hub() -> void:
	if _session == null:
		show_start_screen()
		return
	_swap(IdentityScreenScene, ROUTE_HUB, _setup_identity_screen)


func _setup_identity_screen(screen: Control) -> void:
	_connect_identity_screen(screen)
	screen.apply_snapshot(_session.get_progression_snapshot())
	screen.set_deck_snapshot(_session.get_deck_snapshot())


func _connect_identity_screen(screen: Control) -> void:
	screen.identity_selected.connect(_on_identity_selected)
	screen.battle_requested.connect(_on_battle_requested)
	screen.gacha_requested.connect(_on_gacha_requested)
	screen.upgrade_requested.connect(_on_upgrade_requested)
	screen.deck_requested.connect(_on_deck_requested)
	screen.main_menu_requested.connect(_navigate_back)
	screen.restart_requested.connect(_on_restart_requested)


func _on_restart_requested() -> void:
	if _router_busy() or _session == null:
		return
	_show_route_selection()


func _on_identity_selected(identity_id: StringName) -> void:
	if _session == null or _route != ROUTE_IDENTITY or _router_busy():
		return
	var result: ProgressionCommandResult = _session.submit_progression(
		ProgressionCommandScript.select_identity(identity_id)
	)
	if _screen != null:
		_screen.apply_command_result(result)
	if result.accepted:
		_record_diagnostic("identity_selected", {
			"identity_id": String(identity_id),
		})
		_show_deck_screen(ROUTE_HUB)


func _on_battle_requested() -> void:
	if _session == null or _route != ROUTE_HUB or _router_busy():
		return
	## Through the state machine so a pending reward or deck is never skipped.
	_show_current_state()


func _on_deck_requested() -> void:
	if _session == null or _route != ROUTE_HUB or _router_busy():
		return
	_show_deck_screen(ROUTE_HUB)


func _show_deck_screen(after_confirm_route: StringName) -> void:
	if _session == null:
		return
	_deck_after_confirm_route = after_confirm_route
	_swap(DeckScreenScene, ROUTE_DECK, func(screen: Control) -> void:
		screen.deck_command_requested.connect(_on_deck_command_requested)
		screen.back_requested.connect(_navigate_back)
		screen.apply_snapshot(_session.get_deck_snapshot())
		screen.set_progression_snapshot(_session.get_progression_snapshot())
	)


func _on_deck_command_requested(command: DeckCommand) -> void:
	if (
		_session == null
		or _screen == null
		or _route != ROUTE_DECK
		or command == null
		or _router_busy()
	):
		return
	var result: DeckCommandResult = _session.submit_deck(command)
	_screen.apply_command_result(result)
	if not result.accepted:
		return
	if command.type == DeckCommand.CONFIRM_DECK:
		_record_diagnostic("deck_confirmed", {
			"deck_size": int(_session.get_deck_snapshot().data.get("current_deck_size", 0)),
		})
		## A challenge confirms its deck mid-start; continue into its route
		## instead of bouncing to the hub, which restarted the challenge.
		if _deck_after_confirm_route == ROUTE_HUB:
			_show_hub()
		else:
			_show_current_state()


func _show_route_screen() -> void:
	if _session == null:
		return
	_swap(RouteScreenScene, ROUTE_MAP, func(screen: Control) -> void:
		screen.route_command_requested.connect(_on_route_command_requested)
		if _is_challenge_session():
			var challenge = _session.get_challenge_snapshot()
			var selected: Dictionary = challenge.data.get("selected_modifier", {})
			screen.set_challenge_context(
				String(challenge.data.get("display_name_zh", AppTextScript.text("challenge.fallback_name"))),
				String(selected.get("display_name_zh", ""))
			)
			screen.result_requested.connect(_show_challenge_result)
		else:
			screen.result_requested.connect(_show_route_result)
		screen.hub_requested.connect(_navigate_back)
		screen.apply_snapshot(_session.get_route_snapshot())
		_present_diary_settlement_if_any(screen)
	, {"cache": true})


func _present_diary_settlement_if_any(screen) -> void:
	## Battle/rest rebuild the diary via apply_snapshot; flash + auto-flip live here.
	if screen == null or not screen.has_method("present_post_encounter"):
		return
	if _session == null or not _session.has_method("consume_diary_settlement"):
		return
	var settlement: Dictionary = _session.consume_diary_settlement()
	if settlement.is_empty():
		return
	screen.present_post_encounter(
		String(settlement.get("node_id", "")),
		String(settlement.get("outcome", ""))
	)


func _show_rest_screen() -> void:
	if _session == null:
		return
	_swap(RestScreenScene, ROUTE_REST, func(screen: Control) -> void:
		screen.route_command_requested.connect(_on_route_command_requested)
		screen.back_requested.connect(_navigate_back)
		screen.apply_snapshot(_session.get_route_snapshot())
		_apply_route_scene(screen, "rest")
	)


func _show_ritual_screen() -> void:
	if _session == null:
		return
	_swap(RitualScreenScene, ROUTE_RITUAL, func(screen: Control) -> void:
		screen.route_command_requested.connect(_on_route_command_requested)
		screen.apply_snapshot(_session.get_ritual_snapshot())
		_apply_route_scene(screen, "ritual")
	)


func _on_route_command_requested(command: RouteCommand) -> void:
	if _session == null or _screen == null or _router_busy():
		return
	if command == null:
		return
	if command.type == RouteCommand.SELECT_NODE:
		var node := _route_node(command.node_id)
		var node_type := String(node.get("type", ""))
		if node_type == "rest" and _is_pending_rest(command.node_id):
			## Re-opening a rest the player stepped back from.
			_show_rest_screen()
			return
		if node_type in ["normal", "elite", "boss"]:
			var started: InfrastructureResult = _begin_current_battle(command.node_id)
			if not started.ok:
				if _screen != null:
					_screen.apply_command_result(RouteCommandResult.new(
						false,
						started.code
					))
				return
			_show_battle()
			return
		var selected: RouteCommandResult = _submit_route_command(command)
		_screen.apply_command_result(selected)
		if selected.accepted:
			if String(selected.snapshot.data.get("phase", "")) == "rest_pending":
				_show_rest_screen()
		return
	var result: RouteCommandResult = _submit_route_command(command)
	_screen.apply_command_result(result)
	if not result.accepted:
		return
	var phase := String(result.snapshot.data.get("phase", ""))
	match command.type:
		RouteCommand.USE_REST:
			_show_route_screen()
		RouteCommand.BEGIN_ASCENSION:
			_show_ritual_screen()
		RouteCommand.SUBMIT_RITUAL_STEP, RouteCommand.REQUEST_RITUAL_HINT:
			if phase == "completed":
				if _is_challenge_session():
					_show_challenge_result()
				else:
					_show_route_result()
			elif phase == "failed":
				## Legacy hard-fail path (should be rare after soft ritual fail).
				if _is_challenge_session():
					_show_challenge_result()
				else:
					_show_route_result()
			elif phase == "map":
				## Soft ritual fail / emptied ritual → diary/map, chapter kept.
				_show_route_screen()
			else:
				_show_ritual_screen()
		RouteCommand.CANCEL_RITUAL:
			_show_route_screen()


func _submit_route_command(command: RouteCommand) -> RouteCommandResult:
	if _session == null:
		return RouteCommandResult.new(false, &"campaign_missing")
	if _is_challenge_session():
		var challenge_result: ChallengeCommandResult = _session.submit_route(
			command
		)
		if challenge_result.route_result != null:
			return challenge_result.route_result
		return RouteCommandResult.new(
			false,
			challenge_result.reason_code
		)
	return _session.submit_route(command)


func _begin_current_battle(preferred_node_id: StringName = &"") -> InfrastructureResult:
	if _session == null:
		return InfrastructureResult.failure(
			&"campaign_missing",
			"Campaign session is unavailable."
		)
	if _is_challenge_session():
		return _session.begin_challenge_battle(preferred_node_id)
	return _session.begin_route_battle(preferred_node_id)


func _is_pending_rest(node_id: StringName) -> bool:
	var data: Dictionary = _session.get_route_snapshot().data
	return (
		String(data.get("phase", "")) == "rest_pending"
		and String(data.get("current_node_id", "")) == String(node_id)
	)


func _route_node(node_id: StringName) -> Dictionary:
	if _session == null:
		return {}
	var snapshot: RouteSnapshot = _session.get_route_snapshot()
	for value in snapshot.data.get("nodes", []):
		if value is Dictionary and String(value.get("id", "")) == String(node_id):
			return value
	return {}


func _show_battle() -> void:
	if _session == null:
		return
	var snapshot: BattleSnapshot = _session.get_battle_snapshot()
	if snapshot == null:
		_report_error(InfrastructureResult.failure(
			&"battle_snapshot_missing",
			"Route battle snapshot is unavailable."
		), AppTextScript.text("toast.battle_open_failed"))
		return
	var labels := _build_display_labels(snapshot)
	var encounter_name := AppTextScript.text("encounter.fallback_name")
	var resolved = _session.resolve_current_encounter()
	if resolved.ok:
		encounter_name = String(
			resolved.data.get("display_name_zh", resolved.data.get("id", encounter_name))
		)
	_swap(BattleScreenScene, ROUTE_BATTLE, func(screen: Control) -> void:
		screen.configure(
			encounter_name,
			labels.cards,
			labels.enemies,
			Callable(_session, "query_card_play"),
			labels.details
		)
		screen.command_requested.connect(_on_battle_command_requested)
		screen.battle_finished.connect(_on_battle_finished)
		screen.exit_requested.connect(_on_battle_exit_requested)
		screen.apply_snapshot(snapshot)
		_apply_route_scene(screen, "battle")
	)


func _on_battle_command_requested(command: BattleCommand) -> void:
	if _session == null or _screen == null or _route != ROUTE_BATTLE or _router_busy():
		return
	var result: BattleCommandResult = _session.submit_battle(command)
	_screen.apply_command_result(result)


func _on_battle_exit_requested() -> void:
	if _router_busy() or _route != ROUTE_BATTLE:
		return
	_record_diagnostic("battle_exit_requested", {
		"node_id": String(_session.get_active_node_id())
		if _session != null and _session.has_method("get_active_node_id")
		else "",
	})
	## The battle is never saved mid-fight; reloading the last checkpoint puts
	## the player back on the diary page the battle was launched from.
	continue_saved_checkpoint()


func _on_battle_finished(snapshot: BattleSnapshot) -> void:
	## Deferred only to leave the battle's command call stack; the screen
	## itself stays alive through its on_exit beat (NAV-01).
	call_deferred("_route_after_battle", snapshot)


func _route_after_battle(snapshot: BattleSnapshot) -> void:
	if snapshot == null or _route != ROUTE_BATTLE or _session == null or _router_busy():
		return
	var progression: ProgressionSnapshot = _session.get_progression_snapshot()
	var phase := String(progression.data.get("phase", ""))
	var outcome := String(snapshot.data.get("outcome", ""))
	_record_diagnostic("battle_finished", {
		"outcome": outcome,
		"round_number": int(snapshot.data.get("round_number", 0)),
		"battle_id": String(snapshot.data.get("battle_id", "")),
	})
	if outcome == "victory" and phase == "reward":
		_show_reward()
		return
	var route: RouteSnapshot = _session.get_route_snapshot()
	if String(route.data.get("phase", "")) in ["completed", "failed"]:
		if _is_challenge_session():
			_show_challenge_result()
		else:
			_show_route_result()
		return
	_show_route_screen()


func _show_reward() -> void:
	_swap(RewardScreenScene, ROUTE_REWARD, func(screen: Control) -> void:
		screen.reward_claimed.connect(_on_reward_claimed)
		screen.hub_requested.connect(_navigate_back)
		screen.apply_snapshot(_session.get_progression_snapshot())
	)


func _on_reward_claimed(reward_id: StringName) -> void:
	if _session == null or _screen == null or _route != ROUTE_REWARD or _router_busy():
		return
	var result: ProgressionCommandResult = _session.submit_progression(
		ProgressionCommandScript.claim_reward(reward_id)
	)
	_screen.apply_command_result(result)
	if result.accepted:
		_record_diagnostic("reward_claimed", {"reward_id": String(reward_id)})
		_show_current_state()


func _on_gacha_requested() -> void:
	if _session == null or _route != ROUTE_HUB or _router_busy():
		return
	_show_gacha()


func _show_gacha() -> void:
	_swap(GachaScreenScene, ROUTE_GACHA, func(screen: Control) -> void:
		screen.configure(_build_card_names(), _build_card_details())
		screen.draw_requested.connect(_on_draw_requested)
		screen.back_requested.connect(_navigate_back)
		screen.apply_snapshot(_session.get_progression_snapshot())
	)


func _on_draw_requested(pull_count: int) -> void:
	if _session == null or _screen == null or _route != ROUTE_GACHA or _router_busy():
		return
	var result: ProgressionCommandResult = _session.submit_progression(
		ProgressionCommandScript.draw_gacha(pull_count)
	)
	_screen.configure(_build_card_names(), _build_card_details())
	_screen.apply_command_result(result)


func _on_upgrade_requested() -> void:
	if _session == null or _route != ROUTE_HUB or _router_busy():
		return
	_show_upgrade()


func _show_upgrade() -> void:
	_swap(UpgradeScreenScene, ROUTE_UPGRADE, func(screen: Control) -> void:
		screen.configure(_build_card_names(), _build_effect_previews())
		screen.upgrade_requested.connect(_on_upgrade_command_requested)
		screen.back_requested.connect(_navigate_back)
		screen.apply_snapshot(_session.get_progression_snapshot())
	)


func _on_upgrade_command_requested(definition_id: StringName) -> void:
	if _session == null or _screen == null or _route != ROUTE_UPGRADE or _router_busy():
		return
	var result: ProgressionCommandResult = _session.submit_progression(
		ProgressionCommandScript.upgrade_card(definition_id)
	)
	_screen.apply_command_result(result)


func _show_route_result() -> void:
	if _session == null:
		show_start_screen()
		return
	var save_state := "failed"
	if _session.last_checkpoint_result != null:
		var save_result: InfrastructureResult = _session.last_checkpoint_result
		if save_result.ok:
			save_state = "saved"
		elif bool(save_result.details.get("backup_available", false)):
			save_state = "backup"
	_swap(RouteResultScreenScene, ROUTE_ROUTE_RESULT, func(screen: Control) -> void:
		screen.show_result(_session.get_route_snapshot(), save_state)
		screen.hub_requested.connect(_navigate_back)
		screen.retry_requested.connect(_on_route_retry_requested)
		screen.potion_requested.connect(_on_potion_requested)
		screen.set_potion_state(_session.get_progression_snapshot().data)
	)


func _on_potion_requested(potion_id: StringName) -> void:
	if _session == null or _router_busy():
		return
	var result: ProgressionCommandResult = _session.consume_potion(potion_id)
	if not result.accepted:
		_report_error(InfrastructureResult.failure(
			result.reason_code,
			"Potion cannot be consumed now."
		), AppTextScript.text("toast.potion_unavailable"))
		return
	_show_current_state()


func _on_route_retry_requested() -> void:
	if _session == null or not _session.has_method("get_route_snapshot") or _router_busy():
		return
	var progression_state: Dictionary = _session.progression.export_persistent_state()
	progression_state["phase"] = "hub"
	progression_state["reward_option_ids"] = []
	progression_state["last_battle_outcome"] = ""
	var deck_state: Dictionary = {}
	if _session.deck_engine != null:
		deck_state = _session.deck_engine.export_persistent_state()
	var result = AppBootstrapScript.start_route_v07(
		_resolve_seed(-1),
		{
			"save_directory": save_directory,
			"progression_state": progression_state,
			"deck_state": deck_state,
		},
		checkpoint_slot,
		false
	)
	if not result.ok:
		_report_error(result, AppTextScript.text("toast.route_retry_failed"))
		return
	_set_session(result.data)
	_record_diagnostic("route_retry_requested", {})
	_show_current_state()


func _build_display_labels(snapshot: BattleSnapshot = null) -> Dictionary:
	var card_labels: Dictionary = {}
	var enemy_labels: Dictionary = {}
	var card_details: Dictionary = {}
	if _session == null:
		return {
			"cards": card_labels,
			"enemies": enemy_labels,
			"details": card_details,
		}
	var content: BattleContentPort = _session.base_content
	if _session.progression != null and _session.base_content != null:
		content = _session.progression.create_upgraded_content(
			_session.base_content
		)
	var definition_ids: Array[StringName] = []
	var deck_snapshot = (
		_session.get_deck_snapshot()
		if _session.has_method("get_deck_snapshot")
		else null
	)
	if deck_snapshot != null:
		for definition_value in deck_snapshot.data.get("current_card_ids", []):
			definition_ids.append(StringName(definition_value))
		for card_value in deck_snapshot.data.get("cards", []):
			if card_value is Dictionary:
				definition_ids.append(StringName(
					card_value.get("definition_id", "")
				))
	if snapshot != null:
		for hand_value in snapshot.data.get("hand", []):
			if hand_value is Dictionary:
				definition_ids.append(StringName(
					hand_value.get("definition_id", "")
				))
	var levels: Dictionary = {}
	var progression_snapshot: ProgressionSnapshot = (
		_session.get_progression_snapshot()
	)
	for card_value in progression_snapshot.data.get("collection", []):
		if card_value is Dictionary:
			levels[String(card_value.get("definition_id", ""))] = int(
				card_value.get("level", 0)
			)
	for definition_id in definition_ids:
		if String(definition_id).is_empty() or card_labels.has(definition_id):
			continue
		card_labels[definition_id] = _session.card_display_name(definition_id)
		var definition: Dictionary = content.get_card_definition(definition_id)
		card_details[String(definition_id)] = _card_detail(definition, {
			"name": String(card_labels[definition_id]),
			"level": int(levels.get(String(definition_id), 0)),
		}, content)
	if snapshot != null:
		for enemy_value in snapshot.data.get("enemies", []):
			if not enemy_value is Dictionary:
				continue
			var definition_id := StringName(
				enemy_value.get("definition_id", "")
			)
			enemy_labels[definition_id] = _session.enemy_display_name(
				definition_id
			)
	return {
		"cards": card_labels,
		"enemies": enemy_labels,
		"details": card_details,
	}


func _build_card_names() -> Dictionary:
	var names: Dictionary = {}
	if _session == null:
		return names
	var snapshot: ProgressionSnapshot = _session.get_progression_snapshot()
	for card_value in snapshot.data.get("collection", []):
		if not card_value is Dictionary:
			continue
		var definition_id := StringName(card_value.get("definition_id", ""))
		names[definition_id] = _session.card_display_name(definition_id)
	return names


func _build_card_details() -> Dictionary:
	var details: Dictionary = {}
	if _session == null:
		return details
	var content: BattleContentPort = _session.base_content
	for card_value in _session.get_progression_snapshot().data.get("collection", []):
		if not card_value is Dictionary:
			continue
		var definition_id := StringName(card_value.get("definition_id", ""))
		var definition: Dictionary = content.get_card_definition(definition_id)
		details[String(definition_id)] = _card_detail(definition, {}, content)
	return details


func _build_effect_previews() -> Dictionary:
	var previews: Dictionary = {}
	if _session == null:
		return previews
	var snapshot: ProgressionSnapshot = _session.get_progression_snapshot()
	var upgrades: Dictionary = {}
	for card_value in snapshot.data.get("collection", []):
		if not card_value is Dictionary:
			continue
		var definition_id := StringName(card_value.get("definition_id", ""))
		var upgrade: Dictionary = (
			_session.progression_content.get_upgrade_definition(definition_id)
		)
		if not upgrade.is_empty():
			upgrades[String(definition_id)] = upgrade
	for definition_key in upgrades:
		var upgrade: Dictionary = upgrades[definition_key]
		var max_level := int(upgrade.get("max_level", 0))
		var levels: Array[String] = []
		for level in range(max_level + 1):
			var content: BattleContentPort = UpgradedBattleContentPortScript.new(
				_session.base_content,
				upgrades,
				{definition_key: level}
			)
			var definition: Dictionary = content.get_card_definition(
				StringName(definition_key)
			)
			levels.append(EffectTextScript.format_card_effects(definition))
		previews[definition_key] = levels
	return previews


func _card_detail(
	definition: Dictionary,
	base: Dictionary,
	content: BattleContentPort
) -> Dictionary:
	var detail := base.duplicate(true)
	var definition_id := String(definition.get("id", ""))
	detail["description"] = String(definition.get("description_zh", ""))
	detail["effect_text"] = EffectTextScript.format_card_effects(definition)
	detail["category"] = String(definition.get("category", "skill"))
	detail["rarity"] = String(definition.get("rarity", "common"))
	detail["exhaust"] = bool(definition.get("exhaust", false))
	detail["consumes_ritual"] = bool(definition.get("consumes_ritual", false))
	detail["source_zh"] = String(definition.get("source_zh", ""))
	detail["flavor_text_zh"] = String(definition.get("flavor_text_zh", ""))
	detail["mechanic_tags"] = definition.get("mechanic_tags", []).duplicate()
	var synergy_names: Array[String] = []
	if content != null:
		for synergy_value in content.get_synergies():
			if not synergy_value is Dictionary:
				continue
			for group in synergy_value.get("requires", []):
				if group is Array and definition_id in group:
					synergy_names.append(String(synergy_value.get("display_name_zh", "")))
					break
	detail["synergy_names"] = synergy_names
	return detail


func _on_new_game_requested() -> void:
	if _router_busy():
		return
	_show_route_selection()


func _show_route_selection() -> void:
	var previews := AppBootstrapScript.get_route_previews_v07({})
	if not previews.ok:
		_report_error(previews, AppTextScript.text("toast.route_select_unavailable"))
		return
	_swap(RouteSelectScreenScene, ROUTE_ROUTE_SELECT, func(screen: Control) -> void:
		screen.route_selected.connect(_on_route_selected)
		screen.back_requested.connect(_navigate_back)
		if get_back_target(ROUTE_ROUTE_SELECT) == ROUTE_HUB:
			screen.set_back_label(AppTextScript.text("nav.back_to_identity"))
		screen.set_routes(previews.data)
	)


func _on_route_selected(route_id: StringName) -> void:
	if _router_busy() or _route != ROUTE_ROUTE_SELECT:
		return
	start_new_game(_resolve_seed(-1), &"", route_id)


func _on_challenge_requested() -> void:
	if _router_busy():
		return
	_show_challenge_hub()


func _on_test_game_requested() -> void:
	if _router_busy():
		return
	start_test_game(_resolve_seed(-1))


func _on_preferences_changed(preferences: Dictionary) -> void:
	_preferences = preferences.duplicate(true)
	var saved = AppBootstrapScript.save_player_preferences(
		_preferences,
		_preferences_path
	)
	if saved.ok:
		_apply_preferences()
		if _screen != null and _screen.has_method("show_preferences_save_state"):
			_screen.show_preferences_save_state(true, "")
	else:
		if _screen != null and _screen.has_method("show_preferences_save_state"):
			_screen.show_preferences_save_state(
				false,
				String(saved.message)
			)


func _on_restore_backup_requested() -> void:
	var restored = AppBootstrapScript.restore_checkpoint_backup(
		checkpoint_slot,
		save_directory
	)
	if not restored.ok:
		if _screen != null and _screen.has_method("show_backup_restore_result"):
			_screen.show_backup_restore_result(false, restored.message)
		return
	if _screen != null and _screen.has_method("show_backup_restore_result"):
		_screen.show_backup_restore_result(true, AppTextScript.text("checkpoint.backup_restored"))
	_refresh_checkpoint_summary(_screen)


func _load_preferences() -> void:
	var loaded = AppBootstrapScript.load_player_preferences(_preferences_path)
	if loaded.ok:
		_preferences = loaded.data.duplicate(true)
	else:
		_preferences = {
			"settings_version": 1,
			"tutorial_seen": false,
			"fullscreen": false,
			"ui_scale": 1.0,
			"reduce_flash": false,
			"mute_sfx": false,
		}
	_apply_preferences()


func _apply_preferences() -> void:
	var fullscreen := bool(_preferences.get("fullscreen", false))
	DisplayServer.window_set_mode(
		DisplayServer.WINDOW_MODE_FULLSCREEN
		if fullscreen
		else DisplayServer.WINDOW_MODE_WINDOWED
	)
	var window := get_window()
	if window != null:
		window.content_scale_factor = clampf(
			float(_preferences.get("ui_scale", 1.0)),
			0.85,
			1.2
		)
		if not fullscreen:
			_clamp_window_to_usable_desktop(window)
	var TableSfx = load("res://src/ui/table_sfx.gd")
	if TableSfx != null:
		TableSfx.set_muted(bool(_preferences.get("mute_sfx", false)))


func _clamp_window_to_usable_desktop(window: Window) -> void:
	var screen_index := window.current_screen
	var usable := DisplayServer.screen_get_usable_rect(screen_index)
	if usable.size.x <= 0 or usable.size.y <= 0:
		return
	var target_size := Vector2i(
		mini(1600, maxi(1, usable.size.x - 24)),
		mini(900, maxi(1, usable.size.y - 24))
	)
	window.size = target_size
	window.position = Vector2i(
		usable.position.x + maxi(0, (usable.size.x - target_size.x) / 2),
		usable.position.y + maxi(0, (usable.size.y - target_size.y) / 2)
	)


func _on_continue_requested() -> void:
	if _router_busy():
		return
	continue_saved_checkpoint()


func _on_quit_requested() -> void:
	_finish_diagnostics()
	get_tree().quit(0)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_finish_diagnostics()
		get_tree().quit(0)


func _on_feedback_submitted(feedback: Dictionary) -> void:
	if _diagnostics == null:
		if _screen != null and _screen.has_method("show_feedback_save_state"):
			_screen.show_feedback_save_state(false, AppTextScript.text("feedback.diagnostics_unavailable"))
		return
	var result = _diagnostics.save_feedback(
		String(feedback.get("text", "")),
		String(feedback.get("stage", "unknown")),
		bool(feedback.get("stuck", false)),
		String(feedback.get("pacing", "unknown"))
	)
	if _screen != null and _screen.has_method("show_feedback_save_state"):
		_screen.show_feedback_save_state(
			result.ok,
			String(result.message if not result.ok else AppTextScript.text("feedback.saved_locally"))
		)


func _start_diagnostics() -> void:
	_diagnostics = DiagnosticsServiceScript.new(_diagnostics_directory)
	_diagnostics.start_session(
		ProjectSettings.get_setting("application/config/version", "0.25.0"),
		"development"
	)


func _record_diagnostic(event_type: String, details: Dictionary = {}) -> void:
	if _diagnostics != null:
		_diagnostics.record_event(event_type, details)


func _finish_diagnostics() -> void:
	if _diagnostics == null:
		return
	var summary := {
		"route": String(_route),
		"has_session": _session != null,
	}
	if _last_checkpoint_summary.has("sequence"):
		summary["sequence"] = int(_last_checkpoint_summary.get("sequence", 0))
	_diagnostics.finish_session(summary)


## Only a checkpoint that cannot be loaded or restored ends the session and
## returns to the title (NAV-06).
func _show_load_error(result: InfrastructureResult) -> void:
	_record_diagnostic("checkpoint_load_failed", {"code": String(result.code)})
	show_start_screen(result)


## In-play failures keep the player where they are and say so in a toast.
func _report_error(result: InfrastructureResult, message_zh: String) -> void:
	_record_diagnostic("navigation_error", {
		"code": String(result.code),
		"route": String(_route),
	})
	if _screen == null:
		show_start_screen(result)
		return
	for release in ["set_busy", "set_pending"]:
		if _screen.has_method(release):
			_screen.call(release, false)
	_router.show_toast(message_zh)


func get_toast_text() -> String:
	return _router.get_toast_text() if _router != null else ""


func _resolve_seed(seed_value: int) -> int:
	if seed_value >= 0:
		return seed_value
	if _seed_override >= 0:
		return _seed_override
	return int(Time.get_unix_time_from_system()) ^ Time.get_ticks_msec()


func _apply_route_scene(screen: Control, kind: String) -> void:
	if screen == null or _session == null or not screen.has_method("set_scene_id"):
		return
	var route_data: Dictionary = _session.get_route_snapshot().data
	var scene_id := String(route_data.get("current_scene_id", ""))
	if scene_id.is_empty():
		var current_node_id := String(route_data.get("current_node_id", ""))
		for node_value in route_data.get("nodes", []):
			if node_value is Dictionary and String(node_value.get("id", "")) == current_node_id:
				scene_id = String(node_value.get("scene_id", ""))
				break
	if scene_id.is_empty():
		return
	screen.call("set_scene_id", scene_id)
	if kind.is_empty():
		return


func _ensure_router() -> void:
	if _router != null:
		return
	_router = ScreenRouterScript.new()
	add_child(_router)


func _router_busy() -> bool:
	return _router != null and _router.is_busy()


func _swap(
	scene: PackedScene,
	route_name: StringName,
	setup: Callable,
	options: Dictionary = {}
) -> void:
	_ensure_router()
	if _router.is_busy():
		return
	_router.swap(scene, func(screen: Control) -> void:
		_set_route(route_name)
		setup.call(screen)
	, options)


func _navigate_back() -> void:
	if _router_busy():
		return
	match get_back_target(_route):
		ROUTE_HUB:
			_show_hub()
		ROUTE_MAP:
			_show_route_screen()
		ROUTE_CHALLENGE_HUB:
			_show_challenge_hub()
		_:
			show_start_screen()


func _set_route(next_route: StringName) -> void:
	_route = next_route
	route_changed.emit(_route)


func _set_session(next_session: RefCounted) -> void:
	if next_session != _session and _router != null:
		_router.clear_cache()
	_session = next_session
