class_name RouteEngine
extends RefCounted

const PHASE_MAP: StringName = &"map"
const PHASE_BATTLE_PENDING: StringName = &"battle_pending"
const PHASE_REST_PENDING: StringName = &"rest_pending"
const PHASE_RITUAL: StringName = &"ritual"
const PHASE_COMPLETED: StringName = &"completed"
const PHASE_FAILED: StringName = &"failed"
const PHASE_INIT_ERROR: StringName = &"init_error"

const NODE_NORMAL: StringName = &"normal"
const NODE_ELITE: StringName = &"elite"
const NODE_REST: StringName = &"rest"
const NODE_BOSS: StringName = &"boss"
const NODE_RITUAL: StringName = &"ritual"

const OUTCOME_VICTORY: StringName = &"victory"
const OUTCOME_DEFEAT: StringName = &"defeat"

const ROUTE_OUTCOME_COMPLETED: StringName = &"completed"
const ROUTE_OUTCOME_FAILED: StringName = &"failed"

## Diary spirit wipe: clear 0-08 re-ink on a locked clue.
const SPIRIT_WIPE_COST := 2
## 0-08 rewrite fires on roughly one in three victories (deterministic).
const PEN_REWRITE_EVERY_N := 3

const PEN_REWRITE_TEXTS: Array[String] = [
	"「笔尖一顿——这段字被改成了另一个人的口供。」",
	"「页边多出一行不属于你的笔迹：别信占卜。」",
	"「0-08 把一句警告盖在原句上：雨夜有第三个人。」",
	"「墨水自行爬行，把『救援』改成了『诱饵』。」",
	"「原句还在，但主语被换成了你不认识的姓氏。」",
	"「羽毛笔停了一息：把这段从公开档案里抹掉。」",
	"「金痕压住旧墨：值夜者的记录被改成『勿靠近查尼斯门。』」",
	"「0-08 把『队友』划掉，改写成『目击者会先死。』」",
	"「罗塞尔的句号被撬开——插入半句廷根雨夜里的假名。」",
	"「覆写落下：『灵摆指向的不是人，是诱饵。』」",
	"「页心多出一行暗金：占卜俱乐部今晚有第四把椅子。」",
	"「笔改过：把『安全的退路』改成『唯一的祭品。』」",
]

## Per-clue Branch B overwrite (Tingen volume). Unknown ids fall back to PEN_REWRITE_TEXTS.
const PEN_REWRITE_BY_NODE: Dictionary = {
	"route.v028.first_stage.node.first_hunt":
		"「金痕改写家门一页：密修会找的不是克莱恩——是还活着的『证人』。」",
	"route.v028.first_stage.node.tenant_trace":
		"「灵摆的指向被笔尖掰弯：废弃楼里先到的不是救援，是第二波屠杀。」",
	"route.v028.first_stage.node.mirror_pursuit":
		"「提利尔仓库的记录被改：2-049 先咬住的是你，不是燕尾服小丑。」",
	"route.v028.first_stage.node.boundary":
		"「魔镜旁注被覆写：镜子里多出的那张脸，会先念你的真名。」",
	"route.v028.first_stage.node.rest":
		"「俱乐部守则多出一行暗金：尽信占卜者，蜡烛灭时最先失声。」",
	"route.v028.first_stage.node.lamud":
		"「拉姆德教堂页边改写：铠甲里呼吸的不是风——是封存物在点名。」",
	"route.v028.first_stage.node.baron":
		"「教导者一页被篡改：隐匿贤者要的不是亡妻，是你尚未消化的魔药。」",
	"route.v028.first_stage.node.ascension":
		"「考核三问被金笔涂改：答对也只是把笑脸钉得更紧——小丑在等你。」",
}

const VICTORY_ANNOTATIONS: Array[String] = [
	"【0-08】真相落下。暗金字迹在页边停住，像一声叹息。",
	"【0-08】案情合上半页。雨声替你写下未说完的半句。",
	"【0-08】存活被记入页脊——代价也一并洇开。",
	"【0-08】分支·真相：你活着合上这一叶，金笔只肯承认一半事实。",
	"【0-08】页边落下一滴暗金：活口留下了，名册却少了一行。",
]

## Per-clue Branch A victory notes (Tingen). Unknown ids fall back to VICTORY_ANNOTATIONS.
const VICTORY_ANNOTATIONS_BY_NODE: Dictionary = {
	"route.v028.first_stage.node.first_hunt":
		"【0-08】分支·真相·家门：密修会退进雨里。暗金记下——厨房仍安全，名字还活着。",
	"route.v028.first_stage.node.tenant_trace":
		"【0-08】分支·真相·废屋：艾略特还在呼吸。金笔停在楼梯口：第二波未追上这一叶。",
	"route.v028.first_stage.node.mirror_pursuit":
		"【0-08】分支·真相·提利尔：2-049 先咬住了小丑。页脊留下半句——空气终于能呼吸。",
	"route.v028.first_stage.node.boundary":
		"【0-08】分支·真相·魔镜：恶灵退离笑声。金批写着：别回头，镜面已空。",
	"route.v028.first_stage.node.rest":
		"【0-08】分支·真相·俱乐部：守则两条仍可读。蜡烛灭前，你把扮演演完整了。",
	"route.v028.first_stage.node.lamud":
		"【0-08】分支·真相·拉姆德：铠甲里的呼吸被圣水压住。页边暗金：封存物退回边界。",
	"route.v028.first_stage.node.baron":
		"【0-08】分支·真相·教导者：低语断了一截。安静发丝落下——影子不再替他开口。",
	"route.v028.first_stage.node.ascension":
		"【0-08】分支·真相·考核：三问落印，起誓未泄。笑脸钉进页脊——小丑的门开了一道缝。",
}

const DEFEAT_ANNOTATIONS: Array[String] = [
	"【0-08】失败被写入纸背。墨痕爬行，遮住了旁人的名字。",
	"【0-08】这一叶渗出血色：你还活着，但字句先死了一截。",
	"【0-08】笔尖偏了。悲剧被当成注脚，钉在页边。",
	"【0-08】分支·夜色吞没：败局渗进纸背，旁人的名字先被抹黑。",
	"【0-08】夜色吞没这一叶——你退回日记，章节未灭，字句已半盲。",
	"【0-08】败笔成潮：墨渍从页角回涌，可读的线索沉进雨声里。",
	"【0-08】软失败落印。命运未撕毁卷册，只是把下一句涂成盲文。",
]

## Per-clue Branch C defeat notes (Tingen). Unknown ids fall back to DEFEAT_ANNOTATIONS.
const DEFEAT_ANNOTATIONS_BY_NODE: Dictionary = {
	"route.v028.first_stage.node.first_hunt":
		"【0-08】夜色吞没·家门：雨夜里左轮哑了火，密修会的脚印仍停在厨房门外。章节未灭。",
	"route.v028.first_stage.node.tenant_trace":
		"【0-08】夜色吞没·废屋：艾略特的呼吸被墨渍盖住——你退回日记，第二波仍在楼梯上。",
	"route.v028.first_stage.node.mirror_pursuit":
		"【0-08】夜色吞没·提利尔：2-049 的迟缓先缠住你，燕尾服的笑还停在半空。可重入。",
	"route.v028.first_stage.node.boundary":
		"【0-08】夜色吞没·魔镜：镜中那张多余的脸先念了你的姓。恶灵未散，卷册未撕。",
	"route.v028.first_stage.node.rest":
		"【0-08】夜色吞没·俱乐部：蜡烛灭得太早，扮演守则洇成盲文。注视还在涨。",
	"route.v028.first_stage.node.lamud":
		"【0-08】夜色吞没·拉姆德：铠甲里的呼吸压过圣水。封存物试探成功了一寸，你仍可回页。",
	"route.v028.first_stage.node.baron":
		"【0-08】夜色吞没·教导者：隐匿贤者的低语先吞掉姓名。安静发丝未落下，章节未灭。",
	"route.v028.first_stage.node.ascension":
		"【0-08】夜色吞没·考核：三问未答完，笑脸已半盲。顶满污染只退回本叶——可重考。",
}

const REINK_ANNOTATIONS: Array[String] = [
	"【0-08】墨渍回涌，这段字迹再次被夜色吞没。",
	"【0-08】墨渍回涌——旁人的线索被重新涂黑。",
	"【0-08】墨渍回涌。未读的字重新沉进雨夜里。",
	"【0-08】墨渍回涌·夜色回灌：刚露出的字缝又被墨封堵住。",
	"【0-08】墨渍回涌如潮。分支·吞没把下一句重新藏进纸缝。",
	"【0-08】败后余墨爬行——可拭的污渍盖住了尚未读到的姓名。",
]

## Per-clue re-ink stains after defeat. Unknown ids fall back to REINK_ANNOTATIONS.
const REINK_ANNOTATIONS_BY_NODE: Dictionary = {
	"route.v028.first_stage.node.first_hunt":
		"【0-08】墨渍回涌·家门：窗缝里的名字被重新涂黑，只剩雨声。",
	"route.v028.first_stage.node.tenant_trace":
		"【0-08】墨渍回涌·废屋：灵摆指向被墨封堵住，呼吸声沉进楼板。",
	"route.v028.first_stage.node.mirror_pursuit":
		"【0-08】墨渍回涌·提利尔：仓库页边洇开，2-049 与小丑的字缝再次合拢。",
	"route.v028.first_stage.node.boundary":
		"【0-08】墨渍回涌·魔镜：女孩的笑声被涂成污斑，镜面多出的脸又隐去。",
	"route.v028.first_stage.node.rest":
		"【0-08】墨渍回涌·俱乐部：守则两条被夜色吞没，第四把椅子只剩墨渍。",
	"route.v028.first_stage.node.lamud":
		"【0-08】墨渍回涌·拉姆德：教堂页角封存物的呼吸再次盖住圣水旁注。",
	"route.v028.first_stage.node.baron":
		"【0-08】墨渍回涌·教导者：亡妻与贤者的句子重新沉进纸缝，可灵性擦拭。",
	"route.v028.first_stage.node.ascension":
		"【0-08】墨渍回涌·考核：三问字迹被墨封凝固，笑脸只剩半个轮廓。",
}

const REST_ANNOTATIONS: Array[String] = [
	"【0-08】休整写进页边：呼吸平稳了一些，注视却未退尽。",
	"【0-08】蜡烛熄了一支。伤口收束，扮演仍在继续。",
	"【0-08】俱乐部的茶渍晕开：你借来一晚安宁。",
]

const WIPE_ANNOTATIONS: Array[String] = [
	"【灵性】指尖发热，墨渍退开一线——字迹重新可读。",
	"【灵性】雨夜里搓热掌心，墨渍终于松动。",
	"【灵性】灵性灼过纸面：被吞没的字句重新浮起。",
]

var _content: RouteContentPort
var _requested_route_id: StringName

var _route: Dictionary = {}
var _route_id: StringName = &""
var _nodes: Array[Dictionary] = []
var _node_by_id: Dictionary = {}
var _rest_options: Dictionary = {}
var _ritual: Dictionary = {}

var _state: Dictionary = {}
var _revision: int = 0
var _pending_events: Array[RouteEvent] = []


func _init(
	content: RouteContentPort,
	route_id: StringName = &""
) -> void:
	_content = content
	_requested_route_id = route_id


func initialize(initial_state: Dictionary = {}) -> RouteCommandResult:
	_reset_runtime()
	if _content == null:
		return _initialization_error(&"port_missing")
	if not _load_route():
		return _initialization_error(&"content_invalid")
	if initial_state.is_empty():
		_state = _new_state()
	elif not _restore_state(initial_state):
		return _initialization_error(&"state_invalid")
	_revision = maxi(1, int(_state.get("revision", 1)))
	_state["revision"] = _revision
	return RouteCommandResult.new(
		true,
		&"ok",
		[RouteEvent.new(&"RouteReady", {
			"route_id": String(_route_id),
			"available_node_id": String(_state.get("available_node_id", &"")),
		})],
		get_snapshot(),
		get_ritual_snapshot(),
		get_sequence_state()
	)


func submit(command: RouteCommand) -> RouteCommandResult:
	if command == null:
		return _rejected(&"invalid_command")
	if StringName(_state.get("phase", PHASE_INIT_ERROR)) == PHASE_INIT_ERROR:
		return _rejected(&"not_initialized")
	_pending_events.clear()
	var result: RouteCommandResult
	match command.type:
		RouteCommand.SELECT_NODE:
			result = _select_node(command.node_id)
		RouteCommand.RESOLVE_NODE:
			result = _resolve_node(
				command.node_id,
				command.battle_outcome,
				command.battle_player_state
			)
		RouteCommand.USE_REST:
			result = _use_rest(command.rest_id)
		RouteCommand.WIPE_INK:
			result = _wipe_ink(command.node_id)
		RouteCommand.BEGIN_ASCENSION:
			result = _begin_ascension()
		RouteCommand.SUBMIT_RITUAL_STEP:
			result = _submit_ritual_step(command.ritual_selections)
		RouteCommand.REQUEST_RITUAL_HINT:
			result = _request_ritual_hint()
		RouteCommand.CANCEL_RITUAL:
			result = _cancel_ritual()
		_:
			return _rejected(&"invalid_command")
	if result.accepted:
		_revision += 1
		_state["revision"] = _revision
		result.snapshot = get_snapshot()
		result.ritual_snapshot = get_ritual_snapshot()
		result.sequence_state = get_sequence_state()
	return result


func get_snapshot() -> RouteSnapshot:
	var node_views: Array[Dictionary] = []
	var completed: Array = _state.get("completed_node_ids", [])
	var available_id := String(_state.get("available_node_id", ""))
	var selected_id := String(_state.get("selected_node_id", ""))
	var unlocked: Array = _unlocked_node_ids()
	for node in _nodes:
		var node_id := String(node["id"])
		var node_state := "locked"
		if node_id in completed:
			node_state = "completed"
		elif node_id in unlocked:
			node_state = "available"
		elif node_id == available_id:
			node_state = "available"
		node_views.append({
			"id": node_id,
			"type": String(node.get("type", "")),
			"display_name_zh": String(node.get("display_name_zh", node_id)),
			"encounter_id": String(node.get("encounter_id", "")),
			"ritual_id": String(node.get("ritual_id", "")),
			"scene_id": String(node.get("scene_id", "")),
			"chapter_phase": String(node.get("chapter_phase", "")),
			"narrative_beat_zh": String(node.get("narrative_beat_zh", "")),
			"investigation_goal_zh": String(node.get("investigation_goal_zh", "")),
			"reward_hint_zh": String(node.get("reward_hint_zh", "")),
			"source_zh": String(node.get("source_zh", "")),
			"state": node_state,
		})
	var current_node_id := selected_id if not selected_id.is_empty() else available_id
	var current_scene_id := _scene_id_for_node(current_node_id)
	var phase := StringName(_state.get("phase", PHASE_MAP))
	var annotations: Dictionary = _state.get("clue_annotations", {})
	if not annotations is Dictionary:
		annotations = {}
	var overlays: Dictionary = _state.get("clue_overlays", {})
	if not overlays is Dictionary:
		overlays = {}
	return RouteSnapshot.new({
		"revision": _revision,
		"route_id": String(_route_id),
		"display_name_zh": String(_route.get("display_name_zh", _route_id)),
		"chapter_id": String(_route.get("chapter_id", "")),
		"chapter_title_zh": String(_route.get("chapter_title_zh", "")),
		"chapter_phase_zh": String(_route.get("chapter_phase_zh", "")),
		"chapter_summary_zh": String(_route.get("chapter_summary_zh", "")),
		"chapter_potion_id": String(_route.get("chapter_potion_id", "")),
		"phase": String(phase),
		"current_node_id": current_node_id,
		"current_scene_id": current_scene_id,
		"available_node_id": available_id,
		"selected_node_id": selected_id,
		"completed_node_ids": completed.duplicate(),
		"unlocked_node_ids": unlocked.duplicate(),
		"clue_annotations": annotations.duplicate(true),
		"clue_overlays": overlays.duplicate(true),
		"nodes": node_views,
		"run_state": _state.get("run_state", {}).duplicate(true),
		"rest_options": _available_rest_options(),
		"route_outcome": String(_state.get("route_outcome", "")),
		"end_reason": String(_state.get("end_reason", "")),
		"spirit_wipe_cost": SPIRIT_WIPE_COST,
		"sequence": get_sequence_state().to_dictionary(),
		"ritual": get_ritual_snapshot().to_dictionary(),
		"can_begin_ascension": _can_begin_ascension(),
		"available_commands": _available_commands(),
	})


func get_ritual_snapshot() -> RitualSnapshot:
	var ritual_state: Dictionary = _state.get("ritual_state", {})
	if ritual_state.is_empty():
		return RitualSnapshot.new({
			"status": "inactive",
			"ritual_id": "",
		})
	var ritual_id := String(ritual_state.get("ritual_id", ""))
	var ritual_definition: Dictionary = _content.get_ritual(StringName(ritual_id))
	var steps: Array = ritual_definition.get("steps", [])
	var step_index := int(ritual_state.get("step_index", 0))
	var step_count: int = steps.size()
	var status := String(ritual_state.get("status", "in_progress"))
	var snapshot := {
		"status": status,
		"ritual_id": ritual_id,
		"display_name_zh": String(
			ritual_definition.get("display_name_zh", ritual_id)
		),
		"description_zh": String(ritual_definition.get("description_zh", "")),
		"source_zh": String(ritual_definition.get("source_zh", "")),
		"step_titles": _ritual_step_titles(steps),
		"step_index": step_index,
		"step_count": step_count,
		"hints_used": int(ritual_state.get("hints_used", 0)),
		"hinted_step_indices": ritual_state.get("hinted_steps", []).duplicate(),
		"errors": int(ritual_state.get("errors", 0)),
		"hint_spirit_cost": int(
			ritual_definition.get("hint_spirit_cost", 1)
		),
		"hint_text": String(ritual_state.get("hint_text", "")),
		"corruption": int(_state.get("run_state", {}).get("corruption", 0)),
		"max_corruption": int(_state.get("run_state", {}).get("max_corruption", 10)),
		"spirit": int(_state.get("run_state", {}).get("spirit", 0)),
		"result": String(ritual_state.get("result", "")),
	}
	if status == "in_progress" and step_index >= 0 and step_index < step_count:
		var step: Dictionary = steps[step_index]
		snapshot["step"] = {
			"id": String(step.get("id", "")),
			"type": String(step.get("type", "")),
			"title_zh": String(step.get("title_zh", "")),
			"clue_zh": String(step.get("clue_zh", "")),
			"lore_zh": String(step.get("lore_zh", "")),
			"min_selections": int(step.get("min_selections", 1)),
			"max_selections": int(step.get("max_selections", 1)),
			"options": _public_ritual_options(step.get("options", [])),
		}
	else:
		snapshot["step"] = {}
	return RitualSnapshot.new(snapshot)


func _ritual_step_titles(steps: Array) -> Array:
	var titles: Array = []
	for step_value in steps:
		if step_value is Dictionary:
			titles.append(String(step_value.get("title_zh", "")))
	return titles


func get_sequence_state() -> SequenceState:
	var sequence_source: Dictionary = _route.get("sequence", {})
	var sequence_state := String(_state.get("sequence_state", "locked"))
	var next_sequence := int(sequence_source.get("next_sequence", 8))
	var current_sequence := int(
		sequence_source.get("current_sequence", 9)
	)
	if sequence_state == "completed":
		current_sequence = next_sequence
	return SequenceState.new({
		"pathway_id": String(sequence_source.get("pathway_id", "seer")),
		"pathway_name_zh": String(
			sequence_source.get("pathway_name_zh", "占卜家")
		),
		"current_sequence": current_sequence,
		"next_sequence": next_sequence,
		"next_sequence_name_zh": String(
			sequence_source.get("next_sequence_name_zh", "小丑")
		),
		"advancement_state": sequence_state,
	})


func mark_sequence_advanced() -> void:
	_state["sequence_state"] = "completed"
	_revision += 1
	_state["revision"] = _revision


func get_available_node_id() -> StringName:
	return StringName(_state.get("available_node_id", &""))


func get_battle_player_state() -> Dictionary:
	var run_state: Dictionary = _state.get("run_state", {})
	return {
		"actor_id": "player",
		"hp": int(run_state.get("hp", 1)),
		"max_hp": int(run_state.get("max_hp", 1)),
		"block": 0,
		"spirit": int(run_state.get("spirit", 0)),
		"max_spirit": int(run_state.get("max_spirit", 0)),
		"corruption": int(run_state.get("corruption", 0)),
		"max_corruption": int(run_state.get("max_corruption", 10)),
		"attention": int(run_state.get("attention", 0)),
		"max_attention": int(run_state.get("max_attention", 10)),
		"statuses": [],
	}


func export_persistent_state() -> Dictionary:
	return _state.duplicate(true)


func _select_node(node_id: StringName) -> RouteCommandResult:
	if StringName(_state.get("phase", "")) != PHASE_MAP:
		return _rejected(&"wrong_phase")
	var node: Dictionary = _node_by_id.get(String(node_id), {})
	if node.is_empty():
		return _rejected(&"unknown_node")
	var unlocked := _unlocked_node_ids()
	var completed: Array = _state.get("completed_node_ids", [])
	var node_id_str := String(node_id)
	var is_available := (
		node_id_str in unlocked
		or node_id_str == String(_state.get("available_node_id", ""))
	) and node_id_str not in completed
	if not is_available:
		return _rejected(&"node_not_available")
	var node_type := StringName(node.get("type", ""))
	if node_type == NODE_RITUAL:
		return _rejected(&"ascension_requires_begin")
	_state["selected_node_id"] = String(node_id)
	if node_type == NODE_REST:
		_state["phase"] = String(PHASE_REST_PENDING)
	else:
		_state["phase"] = String(PHASE_BATTLE_PENDING)
	_emit(&"RouteNodeSelected", {
		"node_id": String(node_id),
		"node_type": String(node_type),
		"encounter_id": String(node.get("encounter_id", "")),
	})
	return _success()


func _resolve_node(
	node_id: StringName,
	outcome: StringName,
	battle_player_state: Dictionary
) -> RouteCommandResult:
	if StringName(_state.get("phase", "")) != PHASE_BATTLE_PENDING:
		return _rejected(&"wrong_phase")
	if String(node_id) != String(_state.get("selected_node_id", "")):
		return _rejected(&"wrong_node")
	if outcome != OUTCOME_VICTORY and outcome != OUTCOME_DEFEAT:
		return _rejected(&"invalid_battle_outcome")
	if not battle_player_state.is_empty():
		_apply_battle_player_state(battle_player_state)
	_emit(&"BattleNodeResolved", {
		"node_id": String(node_id),
		"outcome": String(outcome),
	})
	_state["selected_node_id"] = ""
	if outcome == OUTCOME_DEFEAT:
		## Diary soft-fail: tragic annotation, attribute sting, re-ink one other clue.
		## Failed clue stays incomplete so the player may retry.
		_annotate_clue(
			String(node_id),
			_defeat_annotation_for(String(node_id))
		)
		_apply_defeat_diary_penalties()
		_reink_one_unlocked_clue(String(node_id))
		_unlock_node(String(node_id))
		_sync_available_node_id()
		_state["phase"] = String(PHASE_MAP)
		if _corruption_limit_reached():
			_state["phase"] = String(PHASE_FAILED)
			_state["route_outcome"] = String(ROUTE_OUTCOME_FAILED)
			_state["end_reason"] = "corruption_limit"
			_emit(&"RouteFailed", {"reason_code": "corruption_limit"})
		return _success()
	if _corruption_limit_reached():
		_state["phase"] = String(PHASE_FAILED)
		_state["route_outcome"] = String(ROUTE_OUTCOME_FAILED)
		_state["end_reason"] = "corruption_limit"
		_emit(&"RouteFailed", {"reason_code": "corruption_limit"})
		return _success()
	_annotate_clue(
		String(node_id),
		_victory_annotation_for(String(node_id))
	)
	_complete_node(String(node_id))
	_unlock_after_victory(String(node_id))
	_pen_rewrite_locked_clue(String(node_id))
	_advance_after_completed_node()
	return _success()


func _use_rest(rest_id: StringName) -> RouteCommandResult:
	if StringName(_state.get("phase", "")) != PHASE_REST_PENDING:
		return _rejected(&"wrong_phase")
	var option: Dictionary = _rest_options.get(String(rest_id), {})
	if option.is_empty():
		return _rejected(&"rest_not_available")
	var run_state: Dictionary = _state.get("run_state", {}).duplicate(true)
	var effects: Dictionary = option.get("effects", {})
	var max_spirit_before := int(run_state.get("max_spirit", 0))
	var max_spirit_after := maxi(
		0,
		max_spirit_before + int(effects.get("max_spirit_delta", 0))
	)
	run_state["max_spirit"] = max_spirit_after
	run_state["spirit"] = clampi(
		int(run_state.get("spirit", 0)),
		0,
		max_spirit_after
	)
	run_state["hp"] = clampi(
		int(run_state.get("hp", 0)) + int(effects.get("hp_delta", 0)),
		0,
		int(run_state.get("max_hp", 1))
	)
	run_state["corruption"] = clampi(
		int(run_state.get("corruption", 0))
		+ int(effects.get("corruption_delta", 0)),
		0,
		int(run_state.get("max_corruption", 10))
	)
	run_state["attention"] = clampi(
		int(run_state.get("attention", 0))
		+ int(effects.get("attention_delta", 0)),
		0,
		int(run_state.get("max_attention", 10))
	)
	_state["run_state"] = run_state
	var node_id := String(_state.get("selected_node_id", ""))
	_emit(&"RestUsed", {
		"node_id": node_id,
		"rest_id": String(rest_id),
		"effects": effects.duplicate(true),
	})
	_state["selected_node_id"] = ""
	_annotate_clue(node_id, REST_ANNOTATIONS[_revision % REST_ANNOTATIONS.size()])
	_complete_node(node_id)
	_unlock_after_victory(node_id)
	_advance_after_completed_node()
	return _success()


func _wipe_ink(node_id: StringName) -> RouteCommandResult:
	if StringName(_state.get("phase", "")) != PHASE_MAP:
		return _rejected(&"wrong_phase")
	var target := String(node_id)
	if target.is_empty() or not _node_by_id.has(target):
		return _rejected(&"invalid_node")
	var completed: Array = _state.get("completed_node_ids", [])
	var unlocked := _unlocked_node_ids()
	if target in completed:
		return _rejected(&"already_completed")
	if target in unlocked:
		return _rejected(&"already_readable")
	var annotations: Dictionary = _state.get("clue_annotations", {})
	if not annotations is Dictionary:
		annotations = {}
	var note := String(annotations.get(target, ""))
	if note.find("墨渍") < 0:
		return _rejected(&"nothing_to_wipe")
	var run_state: Dictionary = _state.get("run_state", {}).duplicate(true)
	var spirit := int(run_state.get("spirit", 0))
	if spirit < SPIRIT_WIPE_COST:
		return _rejected(&"insufficient_spirit")
	run_state["spirit"] = spirit - SPIRIT_WIPE_COST
	_state["run_state"] = run_state
	_unlock_node(target)
	var wipe_note := WIPE_ANNOTATIONS[_revision % WIPE_ANNOTATIONS.size()]
	_annotate_clue(target, wipe_note)
	_sync_available_node_id()
	_emit(&"InkWiped", {
		"node_id": target,
		"spirit_spent": SPIRIT_WIPE_COST,
		"spirit": int(run_state["spirit"]),
		"annotation_zh": wipe_note,
	})
	return _success()


func _begin_ascension() -> RouteCommandResult:
	if StringName(_state.get("phase", "")) != PHASE_MAP:
		return _rejected(&"wrong_phase")
	if not _can_begin_ascension():
		return _rejected(&"ascension_not_available")
	var ritual_node: Dictionary = _ritual_node_if_ready()
	if ritual_node.is_empty():
		ritual_node = _node_by_id.get(
			String(_state.get("available_node_id", "")),
			{}
		)
	_state["selected_node_id"] = String(ritual_node.get("id", ""))
	_state["ritual_state"] = {
		"ritual_id": String(ritual_node.get("ritual_id", "")),
		"step_index": 0,
		"hints_used": 0,
		"hinted_steps": [],
		"errors": 0,
		"hint_text": "",
		"status": "in_progress",
		"result": "",
	}
	_state["phase"] = String(PHASE_RITUAL)
	_emit(&"AscensionStarted", {
		"node_id": String(ritual_node.get("id", "")),
		"ritual_id": String(ritual_node.get("ritual_id", "")),
	})
	return _success()


func _submit_ritual_step(selections: Array[String]) -> RouteCommandResult:
	if StringName(_state.get("phase", "")) != PHASE_RITUAL:
		return _rejected(&"wrong_phase")
	var ritual_state: Dictionary = _state.get("ritual_state", {})
	var ritual_definition: Dictionary = _content.get_ritual(
		StringName(ritual_state.get("ritual_id", ""))
	)
	var steps: Array = ritual_definition.get("steps", [])
	var step_index := int(ritual_state.get("step_index", 0))
	if step_index < 0 or step_index >= steps.size():
		return _rejected(&"ritual_step_invalid")
	var step: Dictionary = steps[step_index]
	var min_selections := int(step.get("min_selections", 1))
	var max_selections := int(step.get("max_selections", 1))
	if selections.size() < min_selections or selections.size() > max_selections:
		return _rejected(&"ritual_selection_count")
	var valid_ids := {}
	for option in step.get("options", []):
		valid_ids[String(option.get("id", ""))] = true
	var seen := {}
	for selection in selections:
		if not valid_ids.has(String(selection)) or seen.has(String(selection)):
			return _rejected(&"invalid_ritual_selection")
		seen[String(selection)] = true
	if not _ritual_step_matches(step, selections):
		_apply_corruption(int(ritual_definition.get("wrong_step_corruption", 2)))
		ritual_state["errors"] = int(ritual_state.get("errors", 0)) + 1
		ritual_state["hint_text"] = ""
		_state["ritual_state"] = ritual_state
		_emit(&"RitualStepRejected", {
			"step_index": step_index,
			"step_id": String(step.get("id", "")),
			"corruption": int(_state["run_state"]["corruption"]),
		})
		if int(_state["run_state"]["corruption"]) >= int(_state["run_state"]["max_corruption"]):
			_fail_ritual(&"corruption_limit")
		return _success()
	ritual_state["step_index"] = step_index + 1
	ritual_state["hint_text"] = ""
	_state["ritual_state"] = ritual_state
	_emit(&"RitualStepAccepted", {
		"step_index": step_index,
		"step_id": String(step.get("id", "")),
	})
	if step_index + 1 >= steps.size():
		_complete_ritual()
	return _success()


func _request_ritual_hint() -> RouteCommandResult:
	if StringName(_state.get("phase", "")) != PHASE_RITUAL:
		return _rejected(&"wrong_phase")
	var ritual_state: Dictionary = _state.get("ritual_state", {})
	var step_index := int(ritual_state.get("step_index", 0))
	var hinted_steps: Array = ritual_state.get("hinted_steps", [])
	if step_index in hinted_steps:
		return _rejected(&"hint_already_used")
	var ritual_definition: Dictionary = _content.get_ritual(
		StringName(ritual_state.get("ritual_id", ""))
	)
	var hint_cost := int(ritual_definition.get("hint_spirit_cost", 1))
	if hint_cost < 0:
		return _rejected(&"content_invalid")
	var run_state: Dictionary = _state.get("run_state", {})
	if int(run_state.get("spirit", 0)) < hint_cost:
		return _rejected(&"insufficient_spirit")
	run_state["spirit"] = int(run_state.get("spirit", 0)) - hint_cost
	_state["run_state"] = run_state
	var steps: Array = ritual_definition.get("steps", [])
	if step_index < 0 or step_index >= steps.size():
		return _rejected(&"ritual_step_invalid")
	var step: Dictionary = steps[step_index]
	ritual_state["hints_used"] = int(ritual_state.get("hints_used", 0)) + 1
	hinted_steps.append(step_index)
	ritual_state["hinted_steps"] = hinted_steps
	ritual_state["hint_text"] = String(step.get("hint_zh", ""))
	_state["ritual_state"] = ritual_state
	_emit(&"RitualHintRevealed", {
		"step_index": step_index,
		"hint_zh": String(ritual_state["hint_text"]),
		"spirit": int(run_state["spirit"]),
	})
	return _success()


func _cancel_ritual() -> RouteCommandResult:
	if StringName(_state.get("phase", "")) != PHASE_RITUAL:
		return _rejected(&"wrong_phase")
	_state["selected_node_id"] = ""
	_state["ritual_state"] = {}
	_state["phase"] = String(PHASE_MAP)
	_emit(&"AscensionCancelled", {})
	return _success()


func _complete_ritual() -> void:
	var ritual_state: Dictionary = _state.get("ritual_state", {})
	ritual_state["status"] = "completed"
	ritual_state["result"] = "success"
	_state["ritual_state"] = ritual_state
	_state["sequence_state"] = "completed"
	var node_id := String(_state.get("selected_node_id", ""))
	_state["selected_node_id"] = ""
	_complete_node(node_id)
	_state["phase"] = String(PHASE_COMPLETED)
	_state["route_outcome"] = String(ROUTE_OUTCOME_COMPLETED)
	_state["end_reason"] = "ascension_completed"
	_emit(&"RitualCompleted", {"ritual_id": String(ritual_state["ritual_id"])})
	_emit(&"SequenceAdvanced", {
		"pathway_id": "seer",
		"from_sequence": 9,
		"to_sequence": 8,
		"sequence_name_zh": "小丑",
	})
	_emit(&"RouteCompleted", {"route_id": String(_route_id)})


func _fail_ritual(reason: StringName) -> void:
	## Soft fail: chapter progress kept; return to map so the ritual can be retried.
	var reason_str := String(reason)
	var ritual_node_id := String(_state.get("selected_node_id", ""))
	var run_state: Dictionary = _state.get("run_state", {})
	var max_c := int(run_state.get("max_corruption", 10))
	## Bleed off enough corruption that one careful retry + hints remains possible.
	run_state["corruption"] = mini(
		int(run_state.get("corruption", 0)),
		maxi(0, max_c - 2)
	)
	_state["run_state"] = run_state
	if not ritual_node_id.is_empty():
		var annotations: Dictionary = _state.get("clue_annotations", {})
		annotations[ritual_node_id] = (
			"【0-08】考核未通过。污染退潮一寸——日记仍摊开，可再起誓。"
		)
		_state["clue_annotations"] = annotations
	_state["ritual_state"] = {}
	_state["selected_node_id"] = ""
	_state["phase"] = String(PHASE_MAP)
	_emit(&"RitualFailed", {
		"reason_code": reason_str,
		"soft_retry": true,
		"corruption": int(run_state.get("corruption", 0)),
	})


func _continue_after_node(node_id: String) -> void:
	var node_index := _node_index(node_id)
	if node_index < 0:
		_state["phase"] = String(PHASE_FAILED)
		_state["end_reason"] = "route_node_missing"
		return
	if node_index + 1 >= _nodes.size():
		## Only complete the volume when every node is completed.
		var completed: Array = _state.get("completed_node_ids", [])
		if completed.size() >= _nodes.size():
			_state["phase"] = String(PHASE_COMPLETED)
			_state["route_outcome"] = String(ROUTE_OUTCOME_COMPLETED)
			_emit(&"RouteCompleted", {"route_id": String(_route_id)})
			return
		_sync_available_node_id()
		_state["phase"] = String(PHASE_MAP)
		return
	var next_node: Dictionary = _nodes[node_index + 1]
	var next_id := String(next_node.get("id", ""))
	_unlock_node(next_id)
	_sync_available_node_id()
	_state["phase"] = String(PHASE_MAP)
	_emit(&"RouteNodeAvailable", {
		"node_id": next_id,
		"node_type": String(next_node.get("type", "")),
	})


func _advance_after_completed_node() -> void:
	var completed: Array = _state.get("completed_node_ids", [])
	if completed.is_empty():
		_state["phase"] = String(PHASE_FAILED)
		return
	var last_completed := String(completed.back())
	var last_node: Dictionary = _node_by_id.get(last_completed, {})
	if StringName(last_node.get("type", "")) == NODE_BOSS:
		_state["sequence_state"] = "available"
	_continue_after_node(last_completed)


func _complete_node(node_id: String) -> void:
	var completed: Array = _state.get("completed_node_ids", [])
	if node_id.is_empty() or node_id in completed:
		return
	completed.append(node_id)
	_state["completed_node_ids"] = completed
	_unlock_node(node_id)
	_emit(&"RouteNodeCompleted", {"node_id": node_id})


func _unlocked_node_ids() -> Array:
	var unlocked_value: Variant = _state.get("unlocked_node_ids", [])
	var unlocked: Array = []
	if unlocked_value is Array:
		for item in unlocked_value:
			var node_id := String(item)
			if not node_id.is_empty() and node_id not in unlocked:
				unlocked.append(node_id)
	if unlocked.is_empty():
		var available_id := String(_state.get("available_node_id", ""))
		if not available_id.is_empty():
			unlocked.append(available_id)
	return unlocked


func _unlock_node(node_id: String) -> void:
	if node_id.is_empty() or not _node_by_id.has(node_id):
		return
	var unlocked := _unlocked_node_ids()
	if node_id in unlocked:
		return
	unlocked.append(node_id)
	_state["unlocked_node_ids"] = unlocked


func _unlock_after_victory(node_id: String) -> void:
	## v0.55: unlock exactly one next incomplete node (same-page free pick via diary gate).
	var unlocked := _unlocked_node_ids()
	var completed: Array = _state.get("completed_node_ids", [])
	var start := _node_index(node_id)
	for index in range(maxi(0, start + 1), _nodes.size()):
		var candidate := String(_nodes[index].get("id", ""))
		if candidate.is_empty() or candidate in completed or candidate in unlocked:
			continue
		_unlock_node(candidate)
		break
	_sync_available_node_id()


func _sync_available_node_id() -> void:
	var unlocked := _unlocked_node_ids()
	var completed: Array = _state.get("completed_node_ids", [])
	for node_id_value in unlocked:
		var node_id := String(node_id_value)
		if node_id not in completed:
			_state["available_node_id"] = node_id
			return
	_state["available_node_id"] = ""


func _annotate_clue(node_id: String, text_zh: String) -> void:
	var annotations: Dictionary = _state.get("clue_annotations", {})
	if not annotations is Dictionary:
		annotations = {}
	annotations[node_id] = text_zh
	_state["clue_annotations"] = annotations


func _pen_rewrite_locked_clue(after_node_id: String) -> void:
	## Branch B: 0-08 rewrites one still-locked clue without new card/route IDs.
	## Weight: about 1/3 of victories (revision modulo == 2), so A stays the common beat.
	if PEN_REWRITE_EVERY_N > 1 and (_revision % PEN_REWRITE_EVERY_N) != 2:
		return
	var unlocked := _unlocked_node_ids()
	var completed: Array = _state.get("completed_node_ids", [])
	var target := ""
	for node in _nodes:
		var candidate := String(node.get("id", ""))
		if (
			candidate.is_empty()
			or candidate == after_node_id
			or candidate in completed
			or candidate in unlocked
		):
			continue
		target = candidate
		break
	if target.is_empty():
		return
	var overlays: Dictionary = _state.get("clue_overlays", {})
	if not overlays is Dictionary:
		overlays = {}
	var text_zh := _pen_rewrite_text_for(target)
	overlays[target] = {
		"text_zh": text_zh,
		"source": "0-08",
		"margin_note_zh": "笔改过",
	}
	_state["clue_overlays"] = overlays
	_annotate_clue(target, "【0-08】墨迹改写了尚未读到的字句。")
	_emit(&"ClueRewritten", {
		"node_id": target,
		"text_zh": text_zh,
	})


func _pen_rewrite_text_for(node_id: String) -> String:
	var mapped := String(PEN_REWRITE_BY_NODE.get(node_id, ""))
	if not mapped.is_empty():
		return mapped
	if PEN_REWRITE_TEXTS.is_empty():
		return "「0-08 改写了这段尚未读到的字句。」"
	return PEN_REWRITE_TEXTS[_revision % PEN_REWRITE_TEXTS.size()]


func _victory_annotation_for(node_id: String) -> String:
	var mapped := String(VICTORY_ANNOTATIONS_BY_NODE.get(node_id, ""))
	if not mapped.is_empty():
		return mapped
	if VICTORY_ANNOTATIONS.is_empty():
		return "【0-08】真相落下。暗金字迹在页边停住。"
	return VICTORY_ANNOTATIONS[_revision % VICTORY_ANNOTATIONS.size()]


func _defeat_annotation_for(node_id: String) -> String:
	var mapped := String(DEFEAT_ANNOTATIONS_BY_NODE.get(node_id, ""))
	if not mapped.is_empty():
		return mapped
	if DEFEAT_ANNOTATIONS.is_empty():
		return "【0-08】夜色吞没这一叶。章节未灭，字句已半盲。"
	return DEFEAT_ANNOTATIONS[_revision % DEFEAT_ANNOTATIONS.size()]


func _reink_annotation_for(node_id: String) -> String:
	var mapped := String(REINK_ANNOTATIONS_BY_NODE.get(node_id, ""))
	if not mapped.is_empty():
		return mapped
	if REINK_ANNOTATIONS.is_empty():
		return "【0-08】墨渍回涌，这段字迹再次被夜色吞没。"
	return REINK_ANNOTATIONS[_revision % REINK_ANNOTATIONS.size()]


func _apply_defeat_diary_penalties() -> void:
	var run_state: Dictionary = _state.get("run_state", {}).duplicate(true)
	run_state["corruption"] = clampi(
		int(run_state.get("corruption", 0)) + 1,
		0,
		int(run_state.get("max_corruption", 10))
	)
	run_state["attention"] = clampi(
		int(run_state.get("attention", 0)) + 1,
		0,
		int(run_state.get("max_attention", 10))
	)
	_state["run_state"] = run_state


func _reink_one_unlocked_clue(exclude_node_id: String) -> void:
	var unlocked := _unlocked_node_ids()
	var completed: Array = _state.get("completed_node_ids", [])
	var candidates: Array[String] = []
	for node_id_value in unlocked:
		var node_id := String(node_id_value)
		if node_id == exclude_node_id or node_id in completed:
			continue
		candidates.append(node_id)
	if not candidates.is_empty():
		var victim := candidates[0]
		unlocked.erase(victim)
		_state["unlocked_node_ids"] = unlocked
		_annotate_clue(victim, _reink_annotation_for(victim))
		_sync_available_node_id()
		return
	## Fallback: stain the next locked clue so spirit wipe has a target.
	for node in _nodes:
		var candidate := String(node.get("id", ""))
		if (
			candidate.is_empty()
			or candidate == exclude_node_id
			or candidate in completed
			or candidate in unlocked
		):
			continue
		_annotate_clue(candidate, _reink_annotation_for(candidate))
		return


func _apply_battle_player_state(player_state: Dictionary) -> void:
	var run_state: Dictionary = _state.get("run_state", {}).duplicate(true)
	for key in ["hp", "corruption", "attention", "spirit"]:
		if player_state.has(key):
			run_state[key] = int(player_state[key])
	run_state["hp"] = clampi(
		int(run_state.get("hp", 0)),
		0,
		int(run_state.get("max_hp", 1))
	)
	run_state["corruption"] = clampi(
		int(run_state.get("corruption", 0)),
		0,
		int(run_state.get("max_corruption", 10))
	)
	run_state["attention"] = clampi(
		int(run_state.get("attention", 0)),
		0,
		int(run_state.get("max_attention", 10))
	)
	_state["run_state"] = run_state


func _corruption_limit_reached() -> bool:
	var run_state: Dictionary = _state.get("run_state", {})
	return int(run_state.get("corruption", 0)) >= int(
		run_state.get("max_corruption", 1)
	)


func _apply_corruption(amount: int) -> void:
	var run_state: Dictionary = _state.get("run_state", {}).duplicate(true)
	var before := int(run_state.get("corruption", 0))
	run_state["corruption"] = clampi(
		before + amount,
		0,
		int(run_state.get("max_corruption", 10))
	)
	_state["run_state"] = run_state
	_emit(&"RiskChanged", {
		"risk_id": "corruption",
		"before": before,
		"after": int(run_state["corruption"]),
		"reason_code": "ritual_error",
	})


func _ritual_step_matches(step: Dictionary, selections: Array[String]) -> bool:
	var step_type := StringName(step.get("type", ""))
	if step_type == &"select_ids":
		var expected: Array = step.get("correct_ids", [])
		if expected.size() != selections.size():
			return false
		var actual_sorted := selections.duplicate()
		var expected_sorted: Array[String] = []
		for value in expected:
			expected_sorted.append(String(value))
		actual_sorted.sort()
		expected_sorted.sort()
		return actual_sorted == expected_sorted
	if step_type == &"ordered_ids":
		var expected_order: Array = step.get("correct_order", [])
		if expected_order.size() != selections.size():
			return false
		for index in range(selections.size()):
			if String(selections[index]) != String(expected_order[index]):
				return false
		return true
	if step_type == &"select_id":
		return selections.size() == 1 and String(selections[0]) == String(
			step.get("correct_id", "")
		)
	return false


func _public_ritual_options(options_value: Variant) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if not options_value is Array:
		return result
	for value in options_value:
		if not value is Dictionary:
			continue
		result.append({
			"id": String(value.get("id", "")),
			"display_name_zh": String(
				value.get("display_name_zh", value.get("id", ""))
			),
		})
	return result


func _available_rest_options() -> Array[Dictionary]:
	if StringName(_state.get("phase", "")) != PHASE_REST_PENDING:
		return []
	var result: Array[Dictionary] = []
	for option in _rest_options.values():
		result.append(option.duplicate(true))
	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return String(a.get("id", "")) < String(b.get("id", ""))
	)
	return result


func _scene_id_for_node(node_id: String) -> String:
	if node_id.is_empty():
		return ""
	var node: Dictionary = _node_by_id.get(node_id, {})
	return String(node.get("scene_id", ""))


func _can_begin_ascension() -> bool:
	if StringName(_state.get("phase", "")) != PHASE_MAP:
		return false
	if String(_state.get("sequence_state", "")) != "available":
		return false
	return not _ritual_node_if_ready().is_empty()


func _ritual_node_if_ready() -> Dictionary:
	var completed: Array = _state.get("completed_node_ids", [])
	var unlocked := _unlocked_node_ids()
	var available_id := String(_state.get("available_node_id", ""))
	for node in _nodes:
		var node_id := String(node.get("id", ""))
		if StringName(node.get("type", "")) != NODE_RITUAL:
			continue
		if node_id in completed:
			continue
		if node_id in unlocked or node_id == available_id:
			return node
	return {}


func _available_commands() -> Array[String]:
	var result: Array[String] = []
	match StringName(_state.get("phase", PHASE_INIT_ERROR)):
		PHASE_MAP:
			result.append("select_node")
			result.append("wipe_ink")
			if _can_begin_ascension():
				result.append("begin_ascension")
		PHASE_BATTLE_PENDING:
			result.append("resolve_node")
		PHASE_REST_PENDING:
			result.append("use_rest")
		PHASE_RITUAL:
			result.append("submit_ritual_step")
			result.append("request_ritual_hint")
			result.append("cancel_ritual")
	return result


func _load_route() -> bool:
	var route_id := _requested_route_id
	if route_id.is_empty():
		route_id = _content.get_default_route_id()
	if route_id.is_empty():
		return false
	var route_value: Variant = _content.get_route(route_id)
	if not route_value is Dictionary or route_value.is_empty():
		return false
	_route = route_value.duplicate(true)
	_route_id = StringName(_route.get("id", ""))
	if _route_id != route_id:
		return false
	var nodes_value: Variant = _route.get("nodes")
	if not nodes_value is Array or nodes_value.size() < 3 or nodes_value.size() > 12:
		return false
	var seen_types: Dictionary = {}
	for value in nodes_value:
		if not value is Dictionary:
			return false
		var node: Dictionary = value.duplicate(true)
		var node_id := String(node.get("id", ""))
		if node_id.is_empty() or _node_by_id.has(node_id):
			return false
		var node_type := StringName(node.get("type", ""))
		if node_type not in [NODE_NORMAL, NODE_ELITE, NODE_REST, NODE_BOSS, NODE_RITUAL]:
			return false
		seen_types[node_type] = true
		if node.get("type") in ["normal", "elite", "boss"]:
			if String(node.get("encounter_id", "")).is_empty():
				return false
		if node.get("type") == "ritual":
			var ritual_id := String(node.get("ritual_id", ""))
			_ritual = _content.get_ritual(StringName(ritual_id)).duplicate(true)
			if _ritual.is_empty() or not _validate_ritual(_ritual):
				return false
		_nodes.append(node)
		_node_by_id[node_id] = node
	if not seen_types.has(NODE_RITUAL) or not seen_types.has(NODE_BOSS):
		return false
	var options_value: Variant = _route.get("rest_options")
	if not options_value is Array or options_value.size() < 2:
		return false
	for value in options_value:
		if not value is Dictionary:
			return false
		var option: Dictionary = value.duplicate(true)
		var option_id := String(option.get("id", ""))
		if option_id.is_empty() or _rest_options.has(option_id):
			return false
		_rest_options[option_id] = option
	return true


func _validate_ritual(ritual: Dictionary) -> bool:
	var steps_value: Variant = ritual.get("steps")
	if not steps_value is Array or steps_value.size() != 3:
		return false
	for value in steps_value:
		if not value is Dictionary:
			return false
		var step: Dictionary = value
		var step_type := StringName(step.get("type", ""))
		if step_type not in [&"select_ids", &"ordered_ids", &"select_id"]:
			return false
		var options_value: Variant = step.get("options")
		if not options_value is Array or options_value.size() < 2:
			return false
		var option_ids := {}
		for option_value in options_value:
			if not option_value is Dictionary:
				return false
			var option_id := String(option_value.get("id", ""))
			if option_id.is_empty() or option_ids.has(option_id):
				return false
			option_ids[option_id] = true
		if step_type == &"select_ids":
			var correct_ids: Variant = step.get("correct_ids")
			if not correct_ids is Array or correct_ids.size() != int(
				step.get("min_selections", 1)
			):
				return false
			for id_value in correct_ids:
				if not option_ids.has(String(id_value)):
					return false
		elif step_type == &"ordered_ids":
			var correct_order: Variant = step.get("correct_order")
			if not correct_order is Array or correct_order.size() != option_ids.size():
				return false
			for id_value in correct_order:
				if not option_ids.has(String(id_value)):
					return false
		elif not option_ids.has(String(step.get("correct_id", ""))):
			return false
	return true


func _new_state() -> Dictionary:
	var run_state_value: Variant = _route.get("initial_run_state", {})
	var run_state: Dictionary = (
		run_state_value.duplicate(true)
		if run_state_value is Dictionary
		else {}
	)
	run_state["hp"] = maxi(0, int(run_state.get("hp", 54)))
	run_state["max_hp"] = maxi(1, int(run_state.get("max_hp", 54)))
	run_state["spirit"] = maxi(0, int(run_state.get("spirit", 3)))
	run_state["max_spirit"] = maxi(0, int(run_state.get("max_spirit", 3)))
	run_state["corruption"] = maxi(0, int(run_state.get("corruption", 0)))
	run_state["max_corruption"] = maxi(1, int(run_state.get("max_corruption", 10)))
	run_state["attention"] = maxi(0, int(run_state.get("attention", 0)))
	run_state["max_attention"] = maxi(1, int(run_state.get("max_attention", 10)))
	run_state["hp"] = mini(int(run_state["hp"]), int(run_state["max_hp"]))
	run_state["corruption"] = mini(
		int(run_state["corruption"]),
		int(run_state["max_corruption"])
	)
	run_state["attention"] = mini(
		int(run_state["attention"]),
		int(run_state["max_attention"])
	)
	var first_id := String(_nodes[0]["id"]) if not _nodes.is_empty() else ""
	return {
		"route_id": String(_route_id),
		"phase": String(PHASE_MAP),
		"available_node_id": first_id,
		"selected_node_id": "",
		"completed_node_ids": [],
		"unlocked_node_ids": [first_id] if not first_id.is_empty() else [],
		"clue_annotations": {},
		"clue_overlays": {},
		"run_state": run_state,
		"ritual_state": {},
		"sequence_state": "locked",
		"route_outcome": "",
		"end_reason": "",
		"revision": 1,
	}


func _restore_state(value: Dictionary) -> bool:
	if not value.get("run_state") is Dictionary:
		return false
	var restored := value.duplicate(true)
	var phase := StringName(restored.get("phase", PHASE_MAP))
	if phase not in [
		PHASE_MAP,
		PHASE_BATTLE_PENDING,
		PHASE_REST_PENDING,
		PHASE_RITUAL,
		PHASE_COMPLETED,
		PHASE_FAILED,
	]:
		return false
	var completed_value: Variant = restored.get("completed_node_ids", [])
	if not completed_value is Array:
		return false
	var completed: Array = []
	for node_id_value in completed_value:
		var node_id := String(node_id_value)
		if not _node_by_id.has(node_id) or node_id in completed:
			return false
		completed.append(node_id)
	var available_id := String(restored.get("available_node_id", ""))
	var selected_id := String(restored.get("selected_node_id", ""))
	if not available_id.is_empty() and not _node_by_id.has(available_id):
		return false
	if not selected_id.is_empty() and not _node_by_id.has(selected_id):
		return false
	if phase in [PHASE_BATTLE_PENDING, PHASE_REST_PENDING, PHASE_RITUAL]:
		if selected_id.is_empty():
			return false
	if not _validate_run_state(restored["run_state"]):
		return false
	var ritual_state: Variant = restored.get("ritual_state", {})
	if phase == PHASE_RITUAL:
		if not ritual_state is Dictionary or ritual_state.is_empty():
			return false
		if not _content.get_ritual(
			StringName(ritual_state.get("ritual_id", ""))
		):
			return false
	restored["phase"] = String(phase)
	restored["completed_node_ids"] = completed
	_state = restored
	return true


func _validate_run_state(run_state: Dictionary) -> bool:
	var required := [
		"hp",
		"max_hp",
		"spirit",
		"max_spirit",
		"corruption",
		"max_corruption",
		"attention",
		"max_attention",
	]
	for key in required:
		if not run_state.has(key):
			return false
	if int(run_state["max_hp"]) <= 0 or int(run_state["hp"]) < 0:
		return false
	if int(run_state["hp"]) > int(run_state["max_hp"]):
		return false
	if int(run_state["max_spirit"]) < 0 or int(run_state["spirit"]) < 0:
		return false
	if int(run_state["max_corruption"]) <= 0 or int(run_state["corruption"]) < 0:
		return false
	if int(run_state["corruption"]) > int(run_state["max_corruption"]):
		return false
	if int(run_state["max_attention"]) <= 0 or int(run_state["attention"]) < 0:
		return false
	if int(run_state["attention"]) > int(run_state["max_attention"]):
		return false
	return true


func _node_index(node_id: String) -> int:
	for index in range(_nodes.size()):
		if String(_nodes[index].get("id", "")) == node_id:
			return index
	return -1


func _emit(event_type: StringName, event_data: Dictionary) -> void:
	_pending_events.append(RouteEvent.new(event_type, event_data))


func _success() -> RouteCommandResult:
	return RouteCommandResult.new(
		true,
		&"ok",
		_pending_events.duplicate(),
		get_snapshot(),
		get_ritual_snapshot(),
		get_sequence_state()
	)


func _rejected(reason: StringName) -> RouteCommandResult:
	return RouteCommandResult.new(
		false,
		reason,
		[],
		get_snapshot(),
		get_ritual_snapshot(),
		get_sequence_state()
	)


func _initialization_error(reason: StringName) -> RouteCommandResult:
	_state = {"phase": String(PHASE_INIT_ERROR)}
	_revision = 0
	return RouteCommandResult.new(
		false,
		reason,
		[],
		get_snapshot(),
		get_ritual_snapshot(),
		get_sequence_state()
	)


func _reset_runtime() -> void:
	_route = {}
	_route_id = &""
	_nodes.clear()
	_node_by_id.clear()
	_rest_options.clear()
	_ritual.clear()
	_state = {}
	_revision = 0
	_pending_events.clear()
