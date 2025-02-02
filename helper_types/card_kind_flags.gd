class_name CardKindFlags
extends RefCounted

enum {
	UNIT = 1,
	SPELL = 2,
	TRAP = 4,
	
	SPELL_OR_TRAP = 6,
	ANY = 7,
}

static func matches(card_instance: Card, flags: int) -> bool:
	assert(card_instance)
	return false
	
