extends RefCounted

## Chinese copy for app-level notices (toasts, checkpoint status, fallbacks).
## The app passes message ids; only this file holds the wording (R2-12).

const MESSAGES := {
	"toast.new_game_failed": "新的调查未能开始。",
	"toast.test_profile_create_failed": "测试档案未能创建。",
	"toast.test_profile_save_failed": "测试档案未能保存。",
	"toast.challenge_start_failed": "挑战未能开始。",
	"toast.challenge_hub_unavailable": "挑战档案暂时无法打开。",
	"toast.battle_open_failed": "战斗未能展开。",
	"toast.potion_unavailable": "魔药当前不可服用。",
	"toast.route_retry_failed": "重新探索未能开始。",
	"toast.route_select_unavailable": "调查路线暂时无法载入。",
	"checkpoint.inspect_failed": "检查点检查失败。原始文件未被覆盖，请保留诊断记录。",
	"checkpoint.corrupt_with_backup": "主检查点损坏，可用上次备份恢复。恢复操作不会自动覆盖原档。",
	"checkpoint.corrupt_no_backup": "主检查点损坏，且没有可用的上次备份。原始文件已保留。",
	"checkpoint.backup_restored": "备份已恢复。",
	"challenge.reason.deck_unconfirmed": "请先通过继续游戏确认出战牌组",
	"challenge.fallback_name": "挑战",
	"encounter.fallback_name": "未知遭遇",
	"nav.back_to_identity": "回身份档案",
	"feedback.diagnostics_unavailable": "诊断服务未初始化。",
	"feedback.saved_locally": "已保存在本机。",
}


static func text(message_id: String) -> String:
	return String(MESSAGES.get(message_id, message_id))
