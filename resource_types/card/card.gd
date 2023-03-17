class_name Card
extends Resource

enum Kind {
	UNIT,
	ORDER,
}

enum Mana {
	Holy,
	Dark,
	Flame,
	Ice,
	Zipzap,
	Gust,
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

@export var ability0: CardAbility
@export var ability1: CardAbility

func _to_string():
	return "<%s>" % [card_name]

func get_ability(ability_index: int) -> CardAbility:
	assert(ability_index == 0 || ability_index == 1)
	return self["ability%s" % ability_index]



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
