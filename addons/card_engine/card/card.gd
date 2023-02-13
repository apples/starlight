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

@export var ability1: CardAbility
@export var ability2: CardAbility

func _init():
	id = ""
	card_name = "New Card"
	artwork = null
	kind = Kind.UNIT
	unit_hp = 0
	ability1 = null
	ability2 = null

func _to_string():
	return "<%s>" % [card_name]

static func random_id() -> String:
	var chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
	var id = ""
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	for i in range(12):
		id += chars[rng.randi_range(0, 51)]
	return id
