class_name Card
extends Resource

enum Kind {
	UNIT,
	ORDER,
}

enum Mana {
	Colorless = 0,
	Holy = 1,
	Curse = 2,
	Flame = 3,
	Frost = 4,
	Shock = 5,
	Gale = 6,
}

@export var uid: String
@export var cardset_name: String
@export var cardset_idx: int
@export var card_name: String
@export_file("*.png") var artwork_path: String

@export var mana: Mana = Mana.Holy
@export var kind: Kind = Kind.UNIT
@export var unit_hp: int
@export_enum("0", "1", "2", "3") var level: int

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
