class_name SequenceTier
extends RefCounted

## Sequence tiers are integers: 9 is the starting tier, lower numbers are
## higher tiers. Card definitions carry `required_sequence` (data/cards schema).

const BASE: int = 9
const CARD_FIELD := "required_sequence"


## Tier a card needs. Definitions without the field (pre-v0.7 cards) are base cards.
static func required_for(definition: Dictionary) -> int:
	return int(definition.get(CARD_FIELD, BASE))


static func is_unlocked(definition: Dictionary, current_sequence: int) -> bool:
	return current_sequence <= required_for(definition)
