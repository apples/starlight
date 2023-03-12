class_name Card
extends Resource

enum Kind {
	UNIT,
	ORDER,
}

@export var id: String
@export var card_name: String
@export var artwork: Texture

@export var kind: Kind = Kind.UNIT
@export var unit_hp: int
@export var unit_level: int

@export var ability0: CardAbility
@export var ability1: CardAbility

func _init():
	id = ""
	card_name = "New Card"
	artwork = null
	kind = Kind.UNIT
	unit_hp = 0
	ability0 = null
	ability1 = null

func _to_string():
	return "<%s>" % [card_name]

func get_ability(ability_index: int) -> CardAbility:
	assert(ability_index == 0 || ability_index == 1)
	return self["ability%s" % ability_index]

static func random_id() -> String:
	var chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
	var str = ""
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	for i in range(12):
		str += chars[rng.randi_range(0, 51)]
	return str
