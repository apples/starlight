class_name Card
extends Resource

enum Kind {
	UNIT = 0,
	SPELL = 1,
	#RULECARD = 2,
	GRACE = 3,
	TRAP = 4,
}

enum Mana {
	COLORLESS = 0,
	PINK = 1,
	GREEN = 2,
	YELLOW = 3,
	BLUE = 4,
}

@export var uid: String
@export var cardset_name: String
@export var cardset_idx: int
@export var card_name: String
@export_file("*.png") var artwork_path: String

@export var mana: Mana = Mana.COLORLESS
@export var kind: Kind = Kind.UNIT
@export var unit_hp: int
@export_enum("-", "1", "2", "3") var level: int
@export_enum("-", "1", "2", "3") var mana_value: int

@export var abilities: Array[CardAbility]

func _to_string():
	return "<%s>" % [card_name]


static func random_uid() -> String:
	var chars := "0123456789abcdefghijklmnopqrstuvwxyz"
	var base := chars.length()
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var num := (rng.randi() << 31) ^ rng.randi()
	var new_uid := ""
	
	while num >= 36:
		var c := num % base
		new_uid = chars[c] + new_uid
		num /= base
	
	new_uid = new_uid.lpad(12, "0")
	
	return new_uid
