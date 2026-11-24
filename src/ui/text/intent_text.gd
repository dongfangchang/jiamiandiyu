extends RefCounted

## Chinese copy for enemy intents. Gameplay only emits intent_id / variant_id;
## content-authored display_name_zh still wins when present.

const NAMES := {
	"attack": "攻击",
	"curse": "诅咒",
	"fortify": "防备",
	"cry": "啼哭",
}
const VARIANTS := {
	"silenced": {
		"name": "失声后的扑击",
		"description": "能力被窃走或压制，只能发动普通攻击。",
	},
}


static func name_zh(intent: Dictionary) -> String:
	var specific := specific_name_zh(intent)
	if not specific.is_empty():
		return specific
	return String(NAMES.get(String(intent.get("intent_id", "attack")), NAMES["attack"]))


## Variant or authored name only; "" when the generic intent kind is all we know.
static func specific_name_zh(intent: Dictionary) -> String:
	var variant := String(intent.get("variant_id", ""))
	if VARIANTS.has(variant):
		return String(VARIANTS[variant]["name"])
	return String(intent.get("display_name_zh", ""))


static func description_zh(intent: Dictionary) -> String:
	var variant := String(intent.get("variant_id", ""))
	if VARIANTS.has(variant):
		return String(VARIANTS[variant]["description"])
	return String(intent.get("description_zh", ""))
