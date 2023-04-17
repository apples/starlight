class_name Card
extends Resource

enum Kind {
	UNIT = 0,
	GRACE = 1,
	STELLA = 2,
	STARLIGHT = 3,
}

enum Mana {
	COLORLESS = 0,
	HOLY = 1,
	CURSE = 2,
	FLAME = 3,
	FROST = 4,
	SHOCK = 5,
	GALE = 6,
}

@export var uid: String
@export var cardset_name: String
@export var cardset_idx: int
@export var card_name: String
@export_file("*.png") var artwork_path: String

@export var mana: Mana = Mana.HOLY
@export var kind: Kind = Kind.UNIT
@export var unit_hp: int
@export_enum("0", "1", "2", "3") var level: int
@export_enum("0", "1", "2", "3") var mana_value: int

@export var abilities: Array[CardAbility]

func _to_string():
	return "<%s>" % [card_name]


static func random_uid() -> String:
	var chars := "0123456789abcdefghijklmnopqrstuvwxyz"
	var base := chars.length()
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var num := (rng.randi() << 31) ^ rng.randi()
	var str := ""
	
	while num >= 36:
		var c := num % base
		str = chars[c] + str
		num /= base
	
	str = str.lpad(12, "0")
	
	return str
